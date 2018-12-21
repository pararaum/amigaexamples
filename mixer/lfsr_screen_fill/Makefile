#! /usr/bin/make -f

CFLAGS=-speed
AS=vasmm68k_mot -Fhunk -I$$HOME/include/ -I../../framework/
VLINKFLAGS=-s
LIBS=-lamiga -lm13
OOBJS=../../framework/own.o
CC=vc
ALL=lfsr

all:	$(ALL)

lfsr:	lfsr.o assembler_connector.o sprite_multiplexer.o hypotrochoid_data.o
	vc $(CFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

.PHONY: clean
clean:
	rm *.o
	rm $(ALL)

