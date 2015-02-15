include .knightos/variables.make

ALL_TARGETS:=$(BIN)bed $(APPS)bed.app

$(BIN)bed: *.asm
	mkdir -p $(BIN)
	$(AS) $(ASFLAGS) --listing $(OUT)main.list main.asm $(BIN)bed

$(APPS)bed.app: config/bed.app
	mkdir -p $(APPS)
	cp config/bed.app $(APPS)bed.app

include .knightos/sdk.make
