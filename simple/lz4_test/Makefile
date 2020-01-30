#! /usr/bin/make -f

#Framework directory
FWDIR=../../framework
AFLAGS=-m68000 -opt-speed
CFLAGS=-c99 -speed -O3 -DNDEBUG
AS=vasmm68k_mot -Fhunk -I$$HOME/include/ -I$(FWDIR)
VLINKFLAGS=-s
LIBS=-lamiga
OOBJS=$(FWDIR)/lz4_uncrunch.o
CC=vc -I$(FWDIR)
TARGET=lz4
OBJS=lz4.o


all:	$(TARGET)

$(TARGET):	$(OBJS)
	vc $(CFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

%.o:	%.s
	$(AS) $(AFLAGS) -L $@.lst -o $@ $+

.PHONY: clean
clean:
	rm -f *.o *.lst
	rm -f $(TARGET)
