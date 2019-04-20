#! /usr/bin/make -f

CFLAGS=-speed -DNDEBUG
AS=vasmm68k_mot -Fhunk -I$$HOME/include/ -I../framework/
ASFLAGS=-DNDEBUG
VLINKFLAGS=-s
LIBS=-lamiga
OOBJS=../framework/own.o ../framework/music.o
CC=vc
ALL=scroller scroller2 scroller3

all:	logo.c $(ALL)

scroller:	scroller.o assembler_connector.o
	vc $(CFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

scroller2:	scroller2.o scroller2.asm.o
	vc $(CFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

#The logo is included in the scroller.c file.
scroller3:	scroller3.o scroller3.asm.o music.o textmonochrome.o
	vc $(CFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

logo.c: logo.xpm
	../tools/convert_img2raw -h -p -b -B4 -O c $< > $@

.PHONY: clean
clean:
	rm *.o
	rm logo.c
	rm $(ALL)

