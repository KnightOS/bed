include .knightos/variables.make

ALL_TARGETS:=$(BIN)bed $(APPS)bed.app $(SHARE)icons/bed.img

$(BIN)bed: *.asm
	mkdir -p $(BIN)
	$(AS) $(ASFLAGS) --listing $(OUT)main.list main.asm $(BIN)bed

$(APPS)bed.app: config/bed.app
	mkdir -p $(APPS)
	cp config/bed.app $(APPS)bed.app

$(SHARE)icons/bed.img: config/bed.png
	mkdir -p $(SHARE)icons
	kimg -c config/bed.png $(SHARE)icons/bed.img

include .knightos/sdk.make
