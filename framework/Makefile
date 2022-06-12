#! /usr/bin/make -f

# The environment variable $NDK39_ASMINC should contain the assembler
# includes from the NDK3.9. The "-Iasminc" is used to get the
# framework include files.
AS=vasmm68k_mot -Fhunk -I$$NDK39_ASMINC -Iasminc
# We use the 68000 configuration and with "-Iinclude" the frameworks
# header files are accessible.
CC=vc +kick13 -Iinclude
#ASFLAGS=-m68000 -L /dev/stdout -Lnf
ASFLAGS=-m68000
CFLAGS=-c99 -speed -O3 -DNDEBUG
LD=vlink
VLINKFLAGS=-s

# Set this to the directory where the T7D stuff will be put.
T7DDIR=/opt/t7d

OBJS=own.o iff.o copper_fade.o music.o circallator.o textmonochrome.o inflate.o sprite_multiplexer.o xoroshiro.o default_irq_routine.o lz4_uncrunch.o blitter.linear_copy.o copper.create_bitplanepointers.o
VPATH=src
T7DLIB=t7d.lib

all:	$(T7DLIB)

install:	$(T7DLIB)
	install -d $(T7DDIR)
	install -d $(T7DDIR)/include
	install -d $(T7DDIR)/asminc
	cp *.lib $(T7DDIR)
	cp include/*.h $(T7DDIR)/include
	cp asminc/*.i $(T7DDIR)/asminc

$(T7DLIB):	$(OBJS)
	cat $+ > $@

.PHONY: all clean install
clean:
	rm -f *.o $(T7DLIB)

