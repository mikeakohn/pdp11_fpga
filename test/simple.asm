.pdp11

.include "test/registers.inc"

.org 0
vectors:
  .dc16 main
  .dc16 7
  .dc16 9

.org 16
main:
  mov #5, r3
loop:
  ;sob r3, loop
  ;halt

  bis #0x0003, @#PORT1
  bic #0x0001, @#PORT1
  mov @#PORT1, r3
  halt

  ;mov #0xa5, r3
  ;mov #2, r2
  ;add r2, r3
  ;mov vectors, r3

  ;mov #vectors+2, r3

  ;mov #vectors, r4
  ;mov 2(r4), r3

  ;mov @table, r3
  mov @table, 0x0060
  mov 0x0060, r3

  halt

table:
  .dc16 vectors+2

