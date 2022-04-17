#! /usr/bin/make -f

include ../../examples/config.mk

AS+=-Lnf
LD=vlink
TARGET=static_image
OBJS=draw_font.o music.o

all:	$(TARGET) static2

static2:	static2.o draw_font.o
	$(LD) -e _start $(VLINKFLAGS) -o $@ $+ $(LIBS)

$(TARGET):	$(TARGET).o $(OBJS)
	$(LD) -e _start $(VLINKFLAGS) -o $@ $+ $(LIBS)

%.o:	%.s
	$(AS)  -L $@.lst -o $@ $+

.PHONY: clean
clean:
	rm *.o
	rm -f $(TARGET) *.lst
