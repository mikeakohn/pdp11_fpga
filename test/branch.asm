.pdp11

.org 0
vectors:
  .dc16 main

.org 16
main:
  mov #10, r2
  mov #0, r3
loop:
  add #1, r3
  dec r2
  bne loop

  halt

