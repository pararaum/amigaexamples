#! /usr/bin/make -f

AS=vasmm68k_mot -Fhunk -I$$HOME/include/ -I../../framework
LD=vlink
VLINKFLAGS=-s
TARGET=scroller_n_image
OOBJS=../../framework/copper_fade.o

all:	$(TARGET)

$(TARGET):	$(TARGET).o fader.code.o
	$(LD) $(VLINKFLAGS) -o $@ $+ $(OOBJS)

%.o:	%.s
	$(AS) -o $@ $+

.PHONY: clean
clean:
	rm *.o
	rm $(TARGET)
