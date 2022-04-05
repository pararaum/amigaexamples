#! /usr/bin/make -f

AFLAGS=-m68000 -opt-speed
CFLAGS=-c99 -speed -O3 -DNDEBUG
AS=vasmm68k_mot -Fhunk -I$$NDK39_ASMINC -I$$T7D/asminc
CC=vc +kick13 -I$$NDK39_INCLUDE -I$$T7D/include
LD=vc +kick13
VLINKFLAGS=-s
LIBS=-L$$T7D -lamiga -lt7d
TARGET=flitter
OBJS=flitter.o logo.the_7th_division.o

all:	$(TARGET)

logo.the_7th_division.c: logo.the_7th_division.xpm
	../../tools/convert_img2raw -O c -b -B 1 $+ > $@

flitter:	$(OBJS)
	$(LD) $(CFLAGS) -o $@ $+ $(LIBS)

%.o:	%.s
	$(AS) $(AFLAGS) -L $@.lst -o $@ $+

.PHONY: all clean
clean:
	rm -f *.o *.lst
	rm -f $(TARGET) logo.the_7th_division.c
