PDP-11
======

Features
========


Registers
=========

PDP-11 has 7 registers (r0 to r7) where r7 is pc (program counter) and
r6 is sp (stack pointer). The registers are all 16 bit.

There is also a status register which is only 8 bits wide:

    III T N Z V C

    C = carry
    V = overflow
    Z = zero
    N = negative
    T = trap
    I = 3 bits interrupt priority

Wikipedia says that the PSW (processor status word) is mapped to memory
address 177 776 (0xfffe) so it has read / write access.

Addressing Modes
================

There are 7 addressing modes that are encoded in 3 bits next to
each register in the opcode. The modes are:

    000  Rn       Register mode
    001  (Rn)     Register points to address of operand
    010  (Rn)+    Register points to address of operand, Increment Rn
    011  @(Rn)+   Register points to the address of the address, Increment Rn
    100  -(Rn)    Register points to address of operand, Decrement Rn
    101  @-(Rn)   Register points to the address of the address, Decrement Rn
    110  x(Rn)    Register + X points to the address of the operand
    111  @x(Rn)   Register + X points to the address of the address

When the register is the PC, it effectively functions as:

    010  #immediate  Same as 2(pc)+
    011  @#address   Same as @(pc)+
    110  relative    Same as x(pc)
    111  @relative   Same as @x(pc)

An example of loading an immediate value:

   00000: 15c3 mov #0x0009, r3
          0009

               |   src   |   dst
           op  | mod reg | mod reg
   15c3 = 0001 | 010 111 | 000 011

Breaking this down

    The opcode here is 0001 (mov).
    Destination register is 011 (r3) with a mode of 000: Rn
    Source register is 111 (pc) with a mode of 010: (Rn)+

After reading in the opcode, pc will point to address 0x0002 which contains
0x0009. Loading the source from (pc)+ will read in the 0x0009 and increment
pc by 2 pointing it to the next instruction.

Instructions
============

Two-Operand
--------------

            f  e d c  b a 9 8 7 6 5 4 3 2 1 0

    mov     0  0 0 1  x x x x x x x x x x x x OP_DOUBLE
    movb    1  0 0 1  x x x x x x x x x x x x OP_DOUBLE
    cmp     0  0 1 0  x x x x x x x x x x x x OP_DOUBLE
    cmpb    1  0 1 0  x x x x x x x x x x x x OP_DOUBLE
    bit     0  0 1 1  x x x x x x x x x x x x OP_DOUBLE
    bitb    1  0 1 1  x x x x x x x x x x x x OP_DOUBLE
    bic     0  1 0 0  x x x x x x x x x x x x OP_DOUBLE
    bicb    1  1 0 0  x x x x x x x x x x x x OP_DOUBLE
    bis     0  1 0 1  x x x x x x x x x x x x OP_DOUBLE
    bisb    1  1 0 1  x x x x x x x x x x x x OP_DOUBLE
    add     0  1 1 0  x x x x x x x x x x x x OP_DOUBLE
    sub     1  1 1 0  x x x x x x x x x x x x OP_DOUBLE

Single-Operand
--------------

            f  e d c  b a 9 8 7 6 5 4 3 2 1 0

    clr     0  0 0 0  1 0 1 0 0 0 x x x x x x OP_SINGLE
    clrb    1  0 0 0  1 0 1 0 0 0 x x x x x x OP_SINGLE
    com     0  0 0 0  1 0 1 0 0 1 x x x x x x OP_SINGLE
    comb    1  0 0 0  1 0 1 0 0 1 x x x x x x OP_SINGLE
    inc     0  0 0 0  1 0 1 0 1 0 x x x x x x OP_SINGLE
    incb    1  0 0 0  1 0 1 0 1 0 x x x x x x OP_SINGLE
    dec     0  0 0 0  1 0 1 0 1 1 x x x x x x OP_SINGLE
    decb    1  0 0 0  1 0 1 0 1 1 x x x x x x OP_SINGLE
    neg     0  0 0 0  1 0 1 1 0 0 x x x x x x OP_SINGLE
    negb    1  0 0 0  1 0 1 1 0 0 x x x x x x OP_SINGLE
    adc     0  0 0 0  1 0 1 1 0 1 x x x x x x OP_SINGLE
    adcb    1  0 0 0  1 0 1 1 0 1 x x x x x x OP_SINGLE
    sbc     0  0 0 0  1 0 1 1 1 0 x x x x x x OP_SINGLE
    sbcb    1  0 0 0  1 0 1 1 1 0 x x x x x x OP_SINGLE
    tst     0  0 0 0  1 0 1 1 1 1 x x x x x x OP_SINGLE
    tstb    1  0 0 0  1 0 1 1 1 1 x x x x x x OP_SINGLE

    ror     0  0 0 0  1 1 0 0 0 0 x x x x x x OP_SINGLE
    rorb    1  0 0 0  1 1 0 0 0 0 x x x x x x OP_SINGLE
    rol     0  0 0 0  1 1 0 0 0 1 x x x x x x OP_SINGLE
    rolb    1  0 0 0  1 1 0 0 0 1 x x x x x x OP_SINGLE
    asr     0  0 0 0  1 1 0 0 1 0 x x x x x x OP_SINGLE
    asrb    1  0 0 0  1 1 0 0 1 0 x x x x x x OP_SINGLE
    asl     0  0 0 0  1 1 0 0 1 1 x x x x x x OP_SINGLE
    aslb    1  0 0 0  1 1 0 0 1 1 x x x x x x OP_SINGLE
    mark    0  0 0 0  1 1 0 1 0 0 x x x x x x OP_NN
    mtps    1  0 0 0  1 1 0 1 0 0 x x x x x x OP_SINGLE
    mfpi    0  0 0 0  1 1 0 1 0 1 x x x x x x OP_SINGLE
    mfpd    1  0 0 0  1 1 0 1 0 1 x x x x x x OP_SINGLE
    mtpi    0  0 0 0  1 1 0 1 1 0 x x x x x x OP_SINGLE
    mtpd    1  0 0 0  1 1 0 1 1 0 x x x x x x OP_SINGLE
    sxt     0  0 0 0  1 1 0 1 1 1 x x x x x x OP_SINGLE
    mfps    1  0 0 0  1 1 0 1 1 1 x x x x x x OP_SINGLE

Conditional Jump
----------------

            f  e d c  b a 9 8 7 6 5 4 3 2 1 0

    br      0  0 0 0  0 0 0 1 x x x x x x x x OP_BRANCH
    bne     0  0 0 0  0 0 1 0 x x x x x x x x OP_BRANCH
    beq     0  0 0 0  0 0 1 1 x x x x x x x x OP_BRANCH
    bge     0  0 0 0  0 1 0 0 x x x x x x x x OP_BRANCH
    blt     0  0 0 0  0 1 0 1 x x x x x x x x OP_BRANCH
    bgt     0  0 0 0  0 1 1 0 x x x x x x x x OP_BRANCH
    ble     0  0 0 0  0 1 1 1 x x x x x x x x OP_BRANCH
    bpl     1  0 0 0  0 0 0 0 x x x x x x x x OP_BRANCH
    bmi     1  0 0 0  0 0 0 1 x x x x x x x x OP_BRANCH
    bhi     1  0 0 0  0 0 1 0 x x x x x x x x OP_BRANCH
    blos    1  0 0 0  0 0 1 1 x x x x x x x x OP_BRANCH
    bvc     1  0 0 0  0 1 0 0 x x x x x x x x OP_BRANCH
    bvs     1  0 0 0  0 1 0 1 x x x x x x x x OP_BRANCH
    bcc     1  0 0 0  0 1 1 0 x x x x x x x x OP_BRANCH
    bhis    1  0 0 0  0 1 1 0 x x x x x x x x OP_BRANCH
    bcs     1  0 0 0  0 1 1 1 x x x x x x x x OP_BRANCH
    blo     1  0 0 0  0 1 1 1 x x x x x x x x OP_BRANCH

Misc
----

            f  e d c  b a 9 8 7 6 5 4 3 2 1 0

    sob     0  1 1 1  1 1 1 x x x x x x x x x OP_SUB_BR

    mul     0  1 1 1  0 0 0 x x x x x x x x x OP_REG_S  (EIS extended)
    div     0  1 1 1  0 0 1 x x x x x x x x x OP_REG_S  (EIS extended)
    ash     0  1 1 1  0 1 0 x x x x x x x x x OP_REG_S  (EIS extended)
    ashc    0  1 1 1  0 1 1 x x x x x x x x x OP_REG_S  (EIS extended)
    xor     0  1 1 1  1 0 0 x x x x x x x x x OP_REG_D

    jsr     0  0 0 0  1 0 0 x x x x x x x x x OP_REG_D

    emt     1  0 0 0  1 0 0 0 x x x x x x x x OP_S_OPER
    trap    1  0 0 0  1 0 0 1 x x x x x x x x OP_S_OPER

    halt    0  0 0 0  0 0 0 0 0 0 0 0 0 0 0 0 OP_NONE
    wait    0  0 0 0  0 0 0 0 0 0 0 0 0 0 0 1 OP_NONE
    rti     0  0 0 0  0 0 0 0 0 0 0 0 0 0 1 0 OP_NONE
    bpt     0  0 0 0  0 0 0 0 0 0 0 0 0 0 1 1 OP_NONE
    iot     0  0 0 0  0 0 0 0 0 0 0 0 0 1 0 0 OP_NONE
    reset   0  0 0 0  0 0 0 0 0 0 0 0 0 1 0 1 OP_NONE
    rtt     0  0 0 0  0 0 0 0 0 0 0 0 0 1 1 0 OP_NONE

    jmp     0  0 0 0  0 0 0 0 0 1 x x x x x x OP_SINGLE
    swab    0  0 0 0  0 0 0 0 1 1 x x x x x x OP_SINGLE

    nop     0  0 0 0  0 0 0 0 1 0 1 0 0 0 0 0 OP_NONE
    rts     0  0 0 0  0 0 0 0 1 0 0 0 0 x x x OP_REG

Status Register
---------------

            f  e d c  b a 9 8 7 6 5 4 3 2 1 0

    c       0  0 0 0  0 0 0 0 1 0 1 0 x x x x OP_NZVC
    s       0  0 0 0  0 0 0 0 1 0 1 1 x x x x OP_NZVC

Not Supported
-------------

    fadd    0  0 1 1  1 1 0 1 0 0 0 0 0 x x x OP_REG (FPP floating point)
    fsub    0  0 1 1  1 1 0 1 0 1 0 0 0 x x x OP_REG (FPP floating point)
    fmul    0  0 1 1  1 1 0 1 1 0 0 0 0 x x x OP_REG (FPP floating point)
    fdiv    0  0 1 1  1 1 0 1 1 1 0 0 0 x x x OP_REG (FPP floating point)

Memory Map
==========

This implementation of the PDP-11 has 4 banks of memory. Each address
contains a 16 bit word instead of 8 bit byte like a typical CPU.

* Bank 0: 0x0000 ROM (4096 bytes) - Writable After Startup
* Bank 1: 0x4000 Peripherals
* Bank 2: 0x8000 RAM (4096 bytes)
* Bank 3: 0xf000 RAM (4096 bytes)

Peripherals
-----------

The peripherals area contain the following:

* 0x4000: input from push button
* 0x4002: SPI TX buffer
* 0x4004: SPI RX buffer
* 0x4006: SPI control: bit 1: start strobe, bit 0: busy
* 0x4010: ioport_A output (in this test case only 1 pin is connected)
* 0x4012: MIDI note value (60-96) to play a tone on the speaker or 0 to stop
* 0x4014: ioport_B output (3 pins)

Vectors
-------

     0x0000 Reserved
     0x0004 Illegal Instruction
     0x0008 Reserved
     0x000c BPT Instruction, Trace Trap
     0x0010 IOT Instruction
     0x0014 Power Fail
     0x0018 EMT Instruction
     0x001c TRAP Instruction
     0x00a4 Floating Point Exception
     0x00a8 Memory Management Fault

IO
--

SPI
---

