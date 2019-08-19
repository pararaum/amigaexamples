#! /usr/bin/make -f

AS=vasmm68k_mot -Fhunk -I$$HOME/include/
CC=vc
#ASFLAGS=-m68000 -L /dev/stdout -Lnf
ASFLAGS=-m68000
CFLAGS=-c99 -speed -O3 -DNDEBUG
LD=vlink
VLINKFLAGS=-s
#TARGET=sprite_example
OBJS=own.o iff.o copper_fade.o music.o circallator.o textmonochrome.o inflate.o sprite_multiplexer.o xoroshiro.o

all:	$(OBJS)

$(TARGET):	$(TARGET).o $(OBJS)
	$(LD) $(VLINKFLAGS) -o $@ $+

%.o:	%.s
	$(AS) $(ASFLAGS) -o $@ $+

.PHONY: clean
clean:
	rm *.o
	rm -f $(TARGET)

