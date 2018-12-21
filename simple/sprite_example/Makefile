#! /usr/bin/make -f

AS=vasmm68k_mot -Fhunk -I$$HOME/include/
LD=vlink
VLINKFLAGS=-e _start
TARGET=sprite_example
OBJS=sprite_example_move.o
LIB=../../framework/own.o

all:	$(TARGET)

$(TARGET):	 $(OBJS) $(TARGET).o
	$(LD) $(VLINKFLAGS) -o $@ $+ $(LIB)

%.o:	%.s
	$(AS) -o $@ $+

.PHONY: clean
clean:
	rm *.o
	rm $(TARGET)
