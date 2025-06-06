;; Registers.
BUTTON     equ 0x4000
SPI_TX     equ 0x4002
SPI_RX     equ 0x4004
SPI_CTL    equ 0x4006
PORT0      equ 0x4010
SOUND      equ 0x4012
PORT1      equ 0x4014

;; Bits in SPI_CTL.
SPI_BUSY   equ 1
SPI_START  equ 2
;SPI_16     equ 4

;; Bits in SPI_IO (PORT1).
LCD_RES    equ 1
LCD_DC     equ 2
LCD_CS     equ 4

;; Bits in PORT0
LED0       equ 1

