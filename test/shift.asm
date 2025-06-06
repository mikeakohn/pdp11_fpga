.pdp11

.org 0
vectors:
  .dc16 main

.org 16
main:
  ;mov #0x8001, r4
  ;mov #0x0000, r3
  ;clc
  ;sec
  ;mfps r3

  ;asl r4
  ;rol r3

  mov #0x010a, r3
  asr r3

  halt

