.pdp11

.org 0
vectors:
  .dc16 main

.org 16
main:
  mov #0xd000, sp
  mov #1, r3
  mov #100, r2

loop:
  xor r3, @#0x4010
  ;mov r3, @#0x4010
  ;add #1, r3
  jsr pc, delay
  jmp loop

delay:
  mov #0xffff, r2
delay_loop:
  sob r2, delay_loop
  rts pc

