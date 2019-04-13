#! /usr/bin/make -f

AS=vasmm68k_mot -Fhunk -I$$HOME/include/ -I../../framework
CC=vc
CFLAGS=-speed -DNDEBUG
LD=vc
LIBS=-lamiga
VLINKFLAGS=-s
TARGET=deflator
#OOBJS=inflate.o

all:	$(TARGET)

$(TARGET):	$(TARGET).o inflate.o
	$(LD) $(VLINKFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

%.o:	%.s
	$(AS) -o $@ $+

%.o:	%.asm
	$(AS) -o $@ $+

.PHONY: clean
clean:
	rm *.o
	rm $(TARGET)
