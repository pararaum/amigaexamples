#! /usr/bin/make -f

AS=vasmm68k_mot -Lnf -Fhunk -I$$HOME/include/ -I../../framework
LD=vlink
VLINKFLAGS=-s
TARGET=moire
OBJS=
LIB=../../framework/own.o ../../framework/iff.o

all:	$(TARGET)

$(TARGET):	$(TARGET).o $(OBJS)
	$(LD) -e _start $(VLINKFLAGS) -o $@ $+ $(LIB)

%.o:	%.s
	$(AS)  -L $@.lst -o $@ $+

.PHONY: clean
clean:
	rm *.o
	rm -f $(TARGET) *.lst
