#! /usr/bin/make -f

AS=vasmm68k_mot -Lnf -Fhunk -I$$HOME/include/ -I../../framework
LD=vlink
VLINKFLAGS=-s
TARGET=static_image
OBJS=draw_font.o music.o
LIB=../../framework/own.o ../../framework/iff.o

all:	$(TARGET) static2

static2:	static2.o
	$(LD) -e _start $(VLINKFLAGS) -o $@ $+ $(LIB)

$(TARGET):	$(TARGET).o $(OBJS)
	$(LD)-e _start $(VLINKFLAGS) -o $@ $+ $(LIB)

%.o:	%.s
	$(AS)  -L $@.lst -o $@ $+

.PHONY: clean
clean:
	rm *.o
	rm -f $(TARGET) *.lst
