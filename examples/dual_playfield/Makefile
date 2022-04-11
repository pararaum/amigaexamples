#! /usr/bin/make -f

include ../config.mk

OBJS=copperlist.o interrupt.o font.o music.o

all:	logo_plate.inc dual

logo_plate.inc: logo_plate.png
	convert_img2raw -O c -B3 -h -p -b $+ > $@

dual:	dual.o $(OBJS)

.PHONY: clean
clean:
	rm -f *.o dual logo_plate.inc
