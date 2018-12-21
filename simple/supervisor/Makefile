#! /usr/bin/make -f

AS=vasmm68k_mot -Fhunk -I$$HOME/include/ -I../../framework
LD=vlink
VLINKFLAGS=-s
TARGET=supervisor
LIB=../../framework/own.o


all:	$(TARGET)

$(TARGET):	$(TARGET).o
	$(LD) $(VLINKFLAGS) -o $@ $+ $(LIB)

%.o:	%.s
	$(AS) -o $@ $+

.PHONY: clean
clean:
	rm *.o
	rm $(TARGET)
