#! /usr/bin/make -f

AS=vasmm68k_mot -Lnf -Fhunk -I$$HOME/include/ -I../../framework
LD=vlink
VLINKFLAGS=-e _start
TARGET=interrupt
OBJS=
LIB=../../framework/own.o

all:	$(TARGET)

$(TARGET):	$(TARGET).o $(OBJS)
	$(LD) $(VLINKFLAGS) -o $@ $+ $(LIB)

%.o:	%.s
	$(AS)  -L $@.lst -o $@ $(ASFLAGS) $+

.PHONY: clean
clean:
	rm *.o
	rm -f $(TARGET) *.lst
