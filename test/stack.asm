.pdp11

.org 0
vectors:
  .dc16 main

.org 16
main:
  mov #100, @#0xc010

  ;mov #0xd000, sp
  mov #0xc010, sp

  mov #0x1234, r5
  mov r5, -(sp)

  ;mov sp, r3
  ;mov (sp)+, r3
  mov (sp), r3
  ;mov @#0xc010, r3

  halt

