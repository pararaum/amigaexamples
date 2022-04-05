#! /usr/bin/make -f

AS=vasmm68k_mot -Fhunk -I$$NDK39_ASMINC -I$$T7D/asminc
VLINKFLAGS=-s -L$$NDK39/Include/linker_libs
LIBS=-L$$T7D -lamiga -lt7d
CC=vc +aos68k

all:	simple mix

simple:	simple.o
	vlink $(VLINKFLAGS) $(LIBS) -o $@ $+

mix:	mix.assembler_part.o mix.c_part.o
	vc +aos68k -o $@ $+ $(LIBS)

.PHONY: clean
clean:
	rm -f *.o
	rm -f simple mix

