include .knightos/variables.make

ALL_TARGETS:=$(BIN)bed $(APPS)bed.app $(SHARE)icons/bed.img $(ROOT)home/main.asm

$(BIN)bed: src/*.asm
	mkdir -p $(BIN)
	$(AS) $(ASFLAGS) --listing $(OUT)main.list src/main.asm $(BIN)bed

$(APPS)bed.app: config/bed.app
	mkdir -p $(APPS)
	cp config/bed.app $(APPS)bed.app

$(SHARE)icons/bed.img: config/bed.png
	mkdir -p $(SHARE)icons
	kimg -c config/bed.png $(SHARE)icons/bed.img

$(ROOT)home/main.asm: src/main.asm
	mkdir -p $(ROOT)home
	cp src/main.asm $(ROOT)home/main.asm

include .knightos/sdk.make
