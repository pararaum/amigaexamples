#! /usr/bin/make -f

FWDIR=../framework
AFLAGS=-m68000 -opt-speed -DNDEBUG
CFLAGS=-c99 -speed -O3 -DNDEBUG
AS=vasmm68k_mot -Fhunk -I$$HOME/include/ -I$(FWDIR)
VLINKFLAGS=-s
LIBS=-lamiga
OOBJS=../framework/own.o ../framework/music.o ../framework/textmonochrome.o
CC=vc -I$(FWDIR)
ALL=scroller scroller2 scroller3 scroller,sinus

all:	logo.c $(ALL)

scroller,sinus:	scroller,sinus.o
	vc $(CFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

scroller:	scroller.o assembler_connector.o
	vc $(CFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

scroller2:	scroller2.o scroller2.asm.o
	vc $(CFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

#The logo is included in the scroller.c file.
scroller3:	scroller3.o scroller3.asm.o music.o
	vc $(CFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

logo.c: logo.xpm
	../tools/convert_img2raw -h -p -b -B4 -O c $< > $@

.PHONY: clean
clean:
	rm *.o
	rm logo.c
	rm $(ALL)

