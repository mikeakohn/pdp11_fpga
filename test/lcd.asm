.pdp11

.include "test/registers.inc"
.include "lcd/ssd1331.inc"

.macro square_fixed(var)
.scope
  mov @#var, r0
  bit #0x8000, r0
  beq not_signed
  neg r0
not_signed:
  mov r0, r2
  jsr pc, multiply
  jsr pc, shift_right_10
.ends
.endm

;; r0: input 0
;; r1: input 1
;; r4: LSB return
;; r5: MSB return
.macro multiply_fixed(var1, var2)
  mov @#var1, r0
  mov @#var2, r2
  jsr pc, multiply_signed
  jsr pc, shift_right_10
.endm

.org 0
vectors:
  .dc16 start

.org 16

start:
  ;; Setup stack.
  mov #0xd000, sp

  ;; Clear LED.
  bic #LED0, @#PORT0

;mov #7, r0
;mov #5, r2
;jsr pc, multiply
;mov r4, r3
;bis #LED0, @#PORT0
;halt

main:
  jsr pc, lcd_init
  jsr pc, lcd_clear

while_1:
  bit #1, @#BUTTON
  bne run

  jsr pc, delay
  jsr pc, toggle_led
  jmp while_1

run:
  jsr pc, lcd_clear_2
  jsr pc, mandelbrot
  jmp while_1

lcd_init:
  mov #0, @#SPI_CTL
  mov #LCD_CS, @#PORT1
  jsr pc, delay
  mov #LCD_CS | LCD_RES, @#PORT1
  jsr pc, send_init_data
  rts pc

lcd_clear:
  mov #(96 * 64), r0
lcd_clear_loop:
  mov #0x0f, r5
  jsr pc, lcd_send_data
  mov #0x0f, r5
  jsr pc, lcd_send_data
  sob r0, lcd_clear_loop
  rts pc

lcd_clear_2:
  mov #(96 * 64), r0
lcd_clear_loop_2:
  mov #0xf0, r5
  jsr pc, lcd_send_data
  mov #0x0f, r5
  jsr pc, lcd_send_data
  sob r0, lcd_clear_loop_2
  rts pc

;; uint32_t multiply(int16_t, int16_t);
;; r0: input 0 LSB
;; r1: input 0 MSB (cleared here)
;; r2: input 1
;; r3: counter.
;; r4: output (LSB)
;; r5: output (MSB)
multiply:
  ; Set output to 0.
  clr r4
  clr r5
  ; Set temporary MSB input to 0.
  clr r1
  ; Set counter to 16.
  mov #16, r3
multiply_repeat:
  bit #1, r2
  beq multiply_ignore_bit
  add r0, r4
  adc r5
  add r1, r5
multiply_ignore_bit:
  asl r0
  rol r1
  asr r2
  sob r3, multiply_repeat
  rts pc

;; This is only 16x16=16.
;; r0: input 0
;; r2: input 1
;; r4: output (LSB)
;; r5: output (MSB)
multiply_signed:
  ;; Keep track of sign bits
  clr r3
  bit #0x8000, r0
  beq multiply_signed_var0_positive
  ;; abs(var0).
  inc r3
  neg r0
multiply_signed_var0_positive:
  bit #0x8000, r2
  beq multiply_signed_var1_positive
  ;; abs(var1).
  inc r3
  neg r2
multiply_signed_var1_positive:
  mov r3, -(sp)
  jsr pc, multiply
  mov (sp)+, r3
  bit #1, r3
  beq multiply_signed_not_neg
  com r4
  com r5
  inc r4
  adc r5
multiply_signed_not_neg:
  rts pc

;; r4: output (LSB)
;; r5: output (MSB)
shift_right_10_slow:
  mov #10, r0
shift_right_10_loop:
  asr r5
  ror r4
  sob r0, shift_right_10_loop
  rts pc

;; This reduces the time to generate the Mandelbrot from 54 seconds to
;; 45 seconds (over the shift_right_10_slow function).
;; r4: output (LSB)
;; r5: output (MSB)
shift_right_10:
  asr r5
  ror r4
  asr r5
  ror r4
  swab r4
  swab r5
  bic #0xff00, r4
  bic #0x00ff, r5
  bis r5, r4
  rts pc

curr_x equ 0xc000
curr_y equ 0xc002
curr_r equ 0xc004
curr_i equ 0xc006
color  equ 0xc008
zr     equ 0xc00a
zi     equ 0xc00c
zr2    equ 0xc00e
zi2    equ 0xc010
tr     equ 0xc012
ti     equ 0xc014

mandelbrot:
  ;; final int DEC_PLACE = 10;
  ;; final int r0 = (-2 << DEC_PLACE);
  ;; final int i0 = (-1 << DEC_PLACE);
  ;; final int r1 = (1 << DEC_PLACE);
  ;; final int i1 = (1 << DEC_PLACE);
  ;; final int dx = (r1 - r0) / 96; (0x0020)
  ;; final int dy = (i1 - i0) / 64; (0x0020)

  ;; for (y = 0; y < 64; y++)
  mov #64, @#curr_y

  ;; int i = -1 << 10;
  mov #0xfc00, @#curr_i

mandelbrot_for_y:
  ;; for (x = 0; x < 96; x++)
  mov #96, @#curr_x

  ;; int r = -2 << 10;
  mov #0xf800, @#curr_r

mandelbrot_for_x:
  ;; zr = r;
  ;; zi = i;
  mov @#curr_r, @#zr
  mov @#curr_i, @#zi

  ;; for (int count = 0; count < 15; count++)
  clr @#color

mandelbrot_for_count:
  ;; zr2 = (zr * zr) >> DEC_PLACE;
  square_fixed(zr)
  mov r4, @#zr2

  ;; zi2 = (zi * zi) >> DEC_PLACE;
  square_fixed(zi)
  mov r4, @#zi2

  ;; if (zr2 + zi2 > (4 << DEC_PLACE)) { break; }
  ;; cmp does: 4 - (zr2 + zi2).. if it's negative it's bigger than 4.
  mov @#zi2, r5
  add @#zr2, r5
  cmp #(4 << 10), r5
  bge mandelbrot_stop

  ;; tr = zr2 - zi2;
  mov @#zr2, r5
  sub @#zi2, r5
  mov r5, @#tr

  ;; ti = ((zr * zi) >> DEC_PLACE) << 1;
  multiply_fixed(zr, zi)
  asl r4
  mov r4, @#ti

  ;; zr = tr + curr_r;
  mov @#tr, r5
  add @#curr_r, r5
  mov r5, @#zr

  ;; zi = ti + curr_i;
  mov @#ti, r5
  add @#curr_i, r5
  mov r5, @#zi

  inc @#color
  cmp #16, @#color
  bne mandelbrot_for_count
mandelbrot_stop:

  mov @#color, r5
  asl r5
  add #colors, r5
  mov (r5), r5
  swab r5
  jsr pc, lcd_send_data
  swab r5
  jsr pc, lcd_send_data

  ;; r += dx;
  add #0x0020, @#curr_r
  dec @#curr_x
  bne mandelbrot_for_x

  ;; i += dy;
  add #0x0020, @#curr_i
  dec @#curr_y
  bne mandelbrot_for_y

  rts pc

;; lcd_send_cmd(r5)
lcd_send_cmd:
  mov r5, @#SPI_TX
  bis #SPI_START, @#SPI_CTL
lcd_send_cmd_wait:
  bit #SPI_BUSY, @#SPI_CTL
  bne lcd_send_cmd_wait
  rts pc

;; lcd_send_data(r5)
lcd_send_data:
  bis #LED0, @#PORT0
  bis #LCD_DC, @#PORT1
  bic #LCD_CS, @#PORT1

  mov r5, @#SPI_TX

  bis #SPI_START, @#SPI_CTL
lcd_send_data_wait:
  bit #SPI_BUSY, @#SPI_CTL
  bne lcd_send_data_wait
  bis #LCD_CS, @#PORT1
  rts pc

delay:
  mov #0xffff, r5
delay_loop:
  sob r5, delay_loop
  rts pc

toggle_led:
  inc @#PORT0
  rts pc

send_init_data:
  mov #init_data_end - init_data, r1
  mov #init_data, r0
  bic #LCD_DC | LCD_CS, @#PORT1
send_init_data_loop:
  movb (r0)+, r5
  jsr pc, lcd_send_cmd
  sob r1, send_init_data_loop
  bis #LCD_CS, @#PORT1
  rts pc

init_data:
  .db SSD1331_DISPLAY_OFF
  .db SSD1331_SET_REMAP
  .db 0x72
  .db SSD1331_START_LINE
  .db 0x00
  .db SSD1331_DISPLAY_OFFSET
  .db 0x00
  .db SSD1331_DISPLAY_NORMAL
  .db SSD1331_SET_MULTIPLEX
  .db 0x3f
  .db SSD1331_SET_MASTER
  .db 0x8e
  .db SSD1331_POWER_MODE
  .db SSD1331_PRECHARGE
  .db 0x31
  .db SSD1331_CLOCKDIV
  .db 0xf0
  .db SSD1331_PRECHARGE_A
  .db 0x64
  .db SSD1331_PRECHARGE_B
  .db 0x78
  .db SSD1331_PRECHARGE_C
  .db 0x64
  .db SSD1331_PRECHARGE_LEVEL
  .db 0x3a
  .db SSD1331_VCOMH
  .db 0x3e
  .db SSD1331_MASTER_CURRENT
  .db 0x06
  .db SSD1331_CONTRAST_A
  .db 0x91
  .db SSD1331_CONTRAST_B
  .db 0x50
  .db SSD1331_CONTRAST_C
  .db 0x7d
  .db SSD1331_DISPLAY_ON
init_data_end:

colors:
  .dc16 0xf800
  .dc16 0xe980
  .dc16 0xcaa0
  .dc16 0xaaa0
  .dc16 0xa980
  .dc16 0x6320
  .dc16 0x9cc0
  .dc16 0x64c0
  .dc16 0x34c0
  .dc16 0x04d5
  .dc16 0x0335
  .dc16 0x0195
  .dc16 0x0015
  .dc16 0x0013
  .dc16 0x000c
  .dc16 0x0000

