#! /usr/bin/make -f

CFLAGS=-speed -DNDEBUG
AS=vasmm68k_mot -Fhunk -I$$HOME/include/ -I../../framework/
VLINKFLAGS=-s
LIBS=-lamiga
OOBJS=../../framework/own.o ../../framework/iff.o ../../framework/copper_fade.o
CC=vc
ALL=fader
OBJS=setup.o image.o sound.o

all:	$(ALL)

fader:	fader.o $(OBJS)
	vc $(CFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

.PHONY: clean
clean:
	rm *.o
	rm $(ALL)

