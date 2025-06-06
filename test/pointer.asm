.pdp11

.org 0
vectors:
  .dc16 main

.org 16
main:
  mov #data+0, r4
  movb (r4), r3

  halt

data:
  .dc16 0x1234

