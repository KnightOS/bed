include .knightos/variables.make

ALL_TARGETS:=$(BIN)bed

$(BIN)bed: *.asm
	mkdir -p $(BIN)
	$(AS) $(ASFLAGS) --listing $(OUT)main.list main.asm $(BIN)bed

include .knightos/sdk.make
