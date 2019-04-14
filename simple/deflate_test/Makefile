#! /usr/bin/make -f

AS=vasmm68k_mot -Fhunk -I$$HOME/include/ -I../../framework
CC=vc
CFLAGS=-speed -DNDEBUG
LD=vc
LIBS=-lamiga
VLINKFLAGS=-s
TARGET=deflator
#OOBJS=inflate.o

all:	$(TARGET)

serene_scence.deflate: serene_scene.png
	../../tools/convert_img2raw serene_scene.png -B 3 -p -O bin|gzip -9|tail -c +11 > serene_scene.deflate

$(TARGET):	$(TARGET).o inflate.o image.o
	$(LD) $(VLINKFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

%.o:	%.s
	$(AS) -o $@ $+

%.o:	%.asm
	$(AS) -o $@ $+

.PHONY: clean
clean:
	rm *.o
	rm $(TARGET)
