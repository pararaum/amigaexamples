#! /usr/bin/make -f

AS=vasmm68k_mot -Lnf -Fhunk -I$$HOME/include/ -I../../framework
LD=vlink
VLINKFLAGS=-s
TARGET=plasma
OBJS=sinus.o
LIB=../../framework/own.o ../../framework/iff.o

all:	$(TARGET) plasma2

$(TARGET):	$(TARGET).o $(OBJS)
	$(LD) -e _start $(VLINKFLAGS) -o $@ $+ $(LIB)

plasma2:	plasma2.o $(OBJS)
	$(LD) -e _start $(VLINKFLAGS) -o $@ $+ $(LIB)

%.o:	%.s
	$(AS)  -L $@.lst -o $@ $+

.PHONY: clean
clean:
	rm *.o
	rm -f $(TARGET) *.lst
