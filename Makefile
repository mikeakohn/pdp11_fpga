
NAKEN_INCLUDE=../naken_asm/include
PROGRAM=pdp11
SOURCE= \
  src/$(PROGRAM).v \
  src/memory_bus.v \
  src/peripherals.v \
  src/ram.v \
  src/rom.v \
  src/spi.v

default:
	yosys -q -p "synth_ice40 -top $(PROGRAM) -json $(PROGRAM).json" $(SOURCE)
	nextpnr-ice40 -r --hx8k --json $(PROGRAM).json --package cb132 --asc $(PROGRAM).asc --opt-timing --pcf icefun.pcf
	icepack $(PROGRAM).asc $(PROGRAM).bin

program:
	iceFUNprog $(PROGRAM).bin

blink:
	naken_asm -l -type bin -o rom.bin test/blink.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

lcd:
	naken_asm -l -type bin -o rom.bin -I$(NAKEN_INCLUDE) test/lcd.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

simple:
	naken_asm -l -type bin -o rom.bin test/simple.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

branch:
	naken_asm -l -type bin -o rom.bin test/branch.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

pointer:
	naken_asm -l -type bin -o rom.bin test/pointer.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

shift:
	naken_asm -l -type bin -o rom.bin test/shift.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

math:
	naken_asm -l -type bin -o rom.bin test/math.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

stack:
	naken_asm -l -type bin -o rom.bin test/stack.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

clean:
	@rm -f $(PROGRAM).bin $(PROGRAM).json $(PROGRAM).asc *.lst
	@rm -f blink.bin load_byte.bin store_byte.bin test_subroutine.bin
	@rm -f button.bin
	@echo "Clean!"

