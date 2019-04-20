#! /usr/bin/make -f

CFLAGS=-speed -DNDEBUG -c99 -O3
AS=vasmm68k_mot -Fhunk -I$$HOME/include/ -I../../framework/
VLINKFLAGS=-s
LIBS=-lamiga
OOBJS=../../framework/own.o ../../framework/iff.o ../../framework/copper_fade.o ../../framework/music.o
CC=vc
ALL=dual
OBJS=copperlist.o interrupt.o font.o music.o

all:	logo_plate.inc $(ALL)

logo_plate.inc: logo_plate.png
	../../tools/convert_img2raw -O c -B3 -h -p -b $+ > $@

dual:	dual.o $(OBJS)
	vc $(CFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

.PHONY: clean
clean:
	rm *.o
	rm $(ALL)
