#! /usr/bin/make -f

AS=vasmm68k_mot -Fhunk -I$$HOME/include/ -I../framework/
VLINKFLAGS=-s
LIBS=-lamiga
OOBJS=../framework/own.o
CC=vc

all:	simple mix

simple:	simple.o
	vlink $(VLINKFLAGS) -o $@ $+

mix:	mix.assembler_part.o mix.c_part.o
	vc -o $@ $+ $(OOBJS) $(LIBS)

.PHONY: clean
clean:
	rm *.o
	rm simple mix

