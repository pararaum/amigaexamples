#! /usr/bin/make -f

# Possible call:
# docker run -e T7D=/opt/t7d -u 1000:uucp -v "$PWD/../framework":/opt/t7d -v "$PWD":/host -w /host --rm  vintagecomputingcarinthia/vbcc4vcc make

include config.mk

all:	simple mix
	make -C flitter_logo
	make -C dual_playfield
	make -C image_fader
	make -C intuition_screen_grab
	make -C lfsr_screen_fill

simple:	simple.o
	vlink $(VLINKFLAGS) $(LIBS) -o $@ $+

mix:	mix.assembler_part.o mix.c_part.o
	vc +aos68k -o $@ $+ $(LIBS)

.PHONY: clean
clean:
	rm -f *.o
	rm -f simple mix
	make -C flitter_logo clean
	make -C dual_playfield clean
	make -C image_fader clean
	make -C intuition_screen_grab clean
	make -C lfsr_screen_fill clean
