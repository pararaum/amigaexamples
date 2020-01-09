#! /usr/bin/make -f

#Framework directory
FWDIR=../../framework
AFLAGS=-m68000 -opt-speed
CFLAGS=-c99 -speed -O3 -DNDEBUG
AS=vasmm68k_mot -Fhunk -I$$HOME/include/ -I$(FWDIR)
VLINKFLAGS=-s
LIBS=-lamiga
OOBJS=$(FWDIR)/own.o $(FWDIR)/circallator.o $(FWDIR)/copper_fade.o $(FWDIR)/textmonochrome.o $(FWDIR)/inflate.o $(FWDIR)/default_irq_routine.o $(FWDIR)/xoroshiro.o
CC=vc -I$(FWDIR)
TARGET=flitter
OBJS=flitter.o logo.the_7th_division.o

all:	$(TARGET)

logo.the_7th_division.c: logo.the_7th_division.xpm
	../../tools/convert_img2raw -O c -b -B 1 $+ > $@

flitter:	$(OBJS)
	vc $(CFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

%.o:	%.s
	$(AS) $(AFLAGS) -L $@.lst -o $@ $+

.PHONY: clean
clean:
	rm -f *.o *.lst
	rm -f $(TARGET) logo.the_7th_division.c
