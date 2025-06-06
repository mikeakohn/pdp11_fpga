.pdp11

.org 0
vectors:
  .dc16 main

.org 16
main:
  mov #0x8001, r4
  mov #0x0007, r3

  ;sub r4, r3
  sub r3, r4
  mov r4, r3

  ;sec
  ;adc r3

  ;add r4, r3

  ;clr r3

  ;mov #0x8000, r4
  ;add #0x8000, r4
  ;adc r3

  halt

