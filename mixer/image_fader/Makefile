#! /usr/bin/make -f

CFLAGS=-speed -DNDEBUG
AS=vasmm68k_mot -Fhunk -I$$HOME/include/ -I../../framework/
VLINKFLAGS=-s
LIBS=-lamiga
OOBJS=../../framework/own.o
CC=vc
ALL=fader
OBJS=setup.o

all:	$(ALL)

fader:	fader.o $(OBJS)
	vc $(CFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

.PHONY: clean
clean:
	rm *.o
	rm $(ALL)

