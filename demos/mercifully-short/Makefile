#! /usr/bin/make -f

AFLAGS=-m68000 -opt-speed -DNDEBUG
AS=vasmm68k_mot -Fhunk -I$(NDK39_ASMINC) -I$(T7D_ASMINC) -L $@.lst
CC=vc +kick13 -I$(NDK39_INCLUDE) -I$(T7D)/include
CFLAGS=-c99 -speed -O3 -DNDEBUG
LD=vc +kick13
LDFLAGS=$(LIBS)
LIBS=-L$(T7D) -lamiga -lt7d
VLINKFLAGS=-s -L$(NDK39)/Include/linker_libs

TARGET=mshort

all:	globals.h colours.sprite image.mercifully_short.raw image.it_is.raw image_2022-04-17_20-37-59.inc $(TARGET)

tests:	test_swoosh

run:
	AMIGA=`mktemp -d` && cp $(TARGET) $$AMIGA && mkdir $$AMIGA/S && (echo $(TARGET) > $$AMIGA/S/Startup-Sequence) && fs-uae --console-debugger=1 --hard-drive-0=$$AMIGA --amiga-model=A500 && rm -r $$AMIGA

colours.sprite: spritesheet.png
	./spritetool.py $^
	convert_img2raw -B 4 -p -O c $^ > $@
	convert_img2raw -B 2 -b -O c croppedsprite.101.100.png > croppedsprite.101.100.sprite
	convert_img2raw -B 2 -b -O c croppedsprite.101.11.png > croppedsprite.101.11.sprite
	convert_img2raw -B 2 -b -O c croppedsprite.101.128.png > croppedsprite.101.128.sprite
	convert_img2raw -B 2 -b -O c croppedsprite.101.156.png > croppedsprite.101.156.sprite
	convert_img2raw -B 2 -b -O c croppedsprite.101.42.png > croppedsprite.101.42.sprite
	convert_img2raw -B 2 -b -O c croppedsprite.101.71.png > croppedsprite.101.71.sprite
	convert_img2raw -B 2 -b -O c croppedsprite.133.100.png > croppedsprite.133.100.sprite
	convert_img2raw -B 2 -b -O c croppedsprite.133.11.png > croppedsprite.133.11.sprite
	convert_img2raw -B 2 -b -O c croppedsprite.133.128.png > croppedsprite.133.128.sprite
	convert_img2raw -B 2 -b -O c croppedsprite.133.156.png > croppedsprite.133.156.sprite
	convert_img2raw -B 2 -b -O c croppedsprite.133.42.png > croppedsprite.133.42.sprite
	convert_img2raw -B 2 -b -O c croppedsprite.133.71.png > croppedsprite.133.71.sprite


image_2022-04-17_20-37-59.inc: image_2022-04-17_20-37-59.png
	convert_img2raw -B 4 -b -p $^ > $@

image.it_is.raw: image.it_is.gif
	convert_img2raw -B 1 -b -O raw $^ > $@

image.mercifully_short.raw: image.mercifully_short.png
	convert_img2raw -B 1 -b -O raw $^ > $@

globals.h: globals.ini
	./ini2headers.py $^

mshort:	mshort.o part.swooshing.o part.swooshing.lowlevel.o chipmemstorage.o mathtab.o swinging-text.o part.for_you.o font.o default_irq.o

mshort.x: mshort
	vamos -m 8192 -- /opt/amiga/cranker -d cinema mshort mshort.x
#docker run -e HOME=/dev/shm -u 1000:uucp -v "$(PWD):/host" -w /host  --rm vintagecomputingcarinthia/vbcc4vcc vamos -m 8192 -- /opt/amiga/cranker -d cinema mshort mshort.x

infotext: infotext.o

test_swoosh: test_swoosh.o default_irq.o

adf:	mshort.x infotext
	xdftool $(TARGET).adf format "Mercifully Short"
	xdftool $(TARGET).adf makedir S
	t=`mktemp` && (echo "infotext\\nmshort.x" > $$t) && xdftool $(TARGET).adf write $$t S/Startup-Sequence
	xdftool $(TARGET).adf write mshort.x
	xdftool $(TARGET).adf write infotext
	xdftool $(TARGET).adf write /opt/amiga/Shell
	xdftool $(TARGET).adf boot install boot1x

.PHONY: all clean
clean:
	rm -f *.o *.raw *.lst $(TARGET) image_2022-04-17_20-37-59.s *.x *.inc globals.i globals.h
	rm -f infotext *.adf
	rm -f croppedsprite.*.png
	rm -f test_swoosh
	rm -f colours.sprite
