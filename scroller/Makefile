#! /usr/bin/make -f

AS=vasmm68k_mot -Fhunk -I$$NDK39_ASMINC/ -I$$T7D/asminc
ASFLAGS=-m68000 -opt-speed -DNDEBUG
CC=vc +kick13 -I$$NDK39_INCLUDE -I$$T7D/include
CFLAGS=-c99 -speed -O3 -DNDEBUG
LDFLAGS=$(LIBS)
LIBS=-L$$T7D -lamiga -lt7d
VLINKFLAGS=-s

ALL=scroller scroller2 scroller3 scroller,sinus

all:	logo.c $(ALL)

scroller,sinus:	scroller,sinus.o scroller,sinus.68k.o

scroller:	scroller.o assembler_connector.o

scroller2:	scroller2.o scroller2.asm.o

#The logo is included in the scroller.c file.
scroller3:	scroller3.o scroller3.asm.o music.o

logo.c: logo.xpm
	convert_img2raw -h -p -b -B4 -O c $< > $@

.PHONY: clean
clean:
	rm -f *.o
	rm -f logo.c
	rm -f $(ALL)

