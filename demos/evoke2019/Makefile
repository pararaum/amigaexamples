#! /usr/bin/make -f

#Framework directory
FWDIR=../../framework
AFLAGS=-m68000 -opt-speed
CFLAGS=-c99 -speed -O3 -DNDEBUG
AS=vasmm68k_mot -Fhunk -I$$HOME/include/ -I$(FWDIR)
VLINKFLAGS=-s
LIBS=-lamiga
OOBJS=$(FWDIR)/own.o $(FWDIR)/circallator.o $(FWDIR)/iff.o $(FWDIR)/music.o $(FWDIR)/copper_fade.o $(FWDIR)/textmonochrome.o $(FWDIR)/inflate.o $(FWDIR)/sprite_multiplexer.o $(FWDIR)/xoroshiro.o
CC=vc -I$(FWDIR)
TARGET=evoke2019
OBJS=introduction.o endgfx_screen.o introduction.barebone.o evoke2019.irqroutine.o credits.o credits.barebone.o starwarsscroll.o performance.o performance.barebone.o tools.o showstopper.o part.hypotrochoids.o part.checkerboard.o part.moire.o part.vbars.o part.triangles.o part.copperbars.o part.atmospheric_noise.o credits.sinusdat.o

all:	rainbow.inc image.tune_in.inc only_amiga.mod.deflated bassing.modified.mod.deflated rainbow.inc image.tune_in.inc image.moirepattern4.deflated image.moirepattern3.deflated image.moirepattern2.deflated image.moirepattern.deflated image.checkerboard.c image_guru_ilbm.c fader.flamewars.i dns_sentinel.deflated fader.t7d.i fader.minidemo.i $(TARGET)

rainbow.inc: rainbow.ilbm
	../../tools/convert_img2raw -O c -p $+ > $@

image.tune_in.inc: image.tune_in.png
	../../tools/convert_img2raw -O c -B 1 -b -h --bitplane-chip $+ > $@

image_guru_ilbm.c: image.guru.ilbm
	xxd -i $+ > $@

image.checkerboard.c: image.checkerboard.png
	echo "unsigned char image_checkerboard[] = {" > $@
	../../tools/convert_img2raw -O raw -B1 -b $+ | gzip -9| tail -c +11 | xxd -i >> $@
	echo "};" >> $@

fader.t7d.i: fader.t7d.png
	../../tools/convert_img2raw --small-palette -B5 -h -p -b $+ > $@

evoke.introduction.5planes.i: evoke.introduction.5planes.png
	../../tools/convert_img2raw --small-palette -B5 -h -p -b $+ > $@

fader.presents.i: fader.presents.png
	../../tools/convert_img2raw --small-palette -B5 -h -p -b $+ > $@

fader.minidemo.i: fader.minidemo.png
	../../tools/convert_img2raw --small-palette -B5 -h -p -b $+ > $@

fader.flamewars.i: fader.flamewars.png
	../../tools/convert_img2raw --small-palette -B5 -h -p -b $+ > $@

only_amiga.mod.deflated: only_amiga.mod
	cat $+ |gzip -9 | tail -c +11 > $@

bassing.modified.mod.deflated: bassing.modified.mod
	cat $+ |gzip -9 | tail -c +11 > $@

dns_sentinel.deflated: dns_sentinel.png
	../../tools/convert_img2raw -O raw -B4 -b dns_sentinel.png |gzip -9 | tail -c +11 > dns_sentinel.deflated

image.moirepattern.deflated: image.moirepattern.png
	../../tools/convert_img2raw -O raw -B1 -b $+ |gzip -9 | tail -c +11 > $@

image.moirepattern2.deflated: image.moirepattern2.png
	../../tools/convert_img2raw -O raw -B1 -b $+ |gzip -9 | tail -c +11 > $@

image.moirepattern3.deflated: image.moirepattern3.png
	../../tools/convert_img2raw -O raw -B1 -b $+ |gzip -9 | tail -c +11 > $@

image.moirepattern4.deflated: image.moirepattern4.png
	../../tools/convert_img2raw -O raw -B1 -b $+ |gzip -9 | tail -c +11 > $@

evoke2019:	evoke2019.o $(OBJS)
	vc $(CFLAGS) -o $@ $+ $(OOBJS) $(LIBS)

%.o:	%.s
	$(AS) $(AFLAGS) -L $@.lst -o $@ $+

.PHONY: clean
clean:
	rm -f *.o *.lst
	rm -f $(TARGET)

distclean: clean
	rm -f *.deflated
	rm -f *.i *.inc

