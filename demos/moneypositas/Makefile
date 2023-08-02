#! /usr/bin/make -f

#Framework directory
AFLAGS=-m68000 -opt-speed
CFLAGS=-c99 -speed -O4 -DNDEBUG
AS=vasmm68k_mot -Fhunk -I$$NDK39_ASMINC -I$$T7D/asminc
VLINKFLAGS=-s -L$$NDK39/Include/linke_libs
LIBS=-lamiga -L$$T7D -lt7d
CC=vc +kick13 -I$$NDK39_INCLUDE -I$$T7D/include
TARGET=moneypositas
#
DATAS=rainbow.i image.past.asmpalette image.present.asmpalette image.future.asmpalette
#
OBJS=moneypositas.o images.o flitter.o monochrome_flicker.o palette.o blitterfuncs.o muzak.o toolkit.o intermezzo_text.o blitterrama.o for_a_fistful_of_dollars.o burning_earth.o burning_earth.asm.o greetings.asm.o greetings.o kaboom.o pixel.o
#
IMAGES=image.past.deflated image.present.deflated image.future.deflated logo.the_7th_division.lz4 futurewriter.bpl~1.deflated font.16x16.4bpls.deflated animation.bpl~5.deflated logo.the_7th_division.bpl~1.deflated burning_earth.bpl~5.deflated image.dollarbackground.bpl~2.deflated image.kaboom.bpl~5.deflated
#
MUZAK=umwelt.mod.deflated

all:	$(MUZAK) $(IMAGES) $(DATAS) $(TARGET)

run:
	AMIGA=`mktemp -d` && cp $(TARGET) $$AMIGA && mkdir $$AMIGA/S && (echo $(TARGET) > $$AMIGA/S/Startup-Sequence) && fs-uae --console-debugger=1 --hard-drive-0=$$AMIGA --amiga-model=A500 && rm -r $$AMIGA

debug:
	$(MAKE) AFLAGS="-m68000 -opt-speed -DDEBUG" CFLAGS="-c99 -speed -O3 -DDEBUG"

%.asmpalette: %.png
	convert_img2raw -O asm -p -B 4 $^ > $@

rainbow.i: rainbow.ilbm
	convert_img2raw -O asm -p $+ > $@

umwelt.mod.deflated: umwelt.mod
	cat $+ |gzip -9 | tail -c +11 > $@

logo.the_7th_division.lz4: logo.the_7th_division.xpm
	convert_img2raw -O raw -b -B 1 $+ | lz4 -9 --no-frame-crc | tail -c +11 | head -c -4 > $@

%.bpl~5.deflated: 	%.png
	convert_img2raw -O raw -b -B 5 $+ | gzip -9 | tail -c +11 > $@

%.bpl~2.deflated: 	%.png
	convert_img2raw -O raw -b -B 2 $+ | gzip -9 | tail -c +11 > $@

%.bpl~1.deflated: 	%.png
	convert_img2raw -O raw -b -B 1 $+ | gzip -9 | tail -c +11 > $@

%.bpl~1.deflated: 	%.xpm
	convert_img2raw -O raw -b -B 1 $+ | gzip -9 | tail -c +11 > $@

%.deflated:	%.png
	convert_img2raw -O raw -b -B 4 $+ | gzip -9 | tail -c +11 > $@

%.raw.lz4:	%.png
	convert_img2raw -O raw -b -B 4 $+ | lz4 -9 --no-frame-crc | tail -c +11 | head -c -4 > $@

moneypositas:	$(OBJS)
	vc +kick13 $(CFLAGS) $(LIBS) -o $@ $+

$(TARGET).x: $(TARGET)
	vamos -m 8192 -- /opt/amiga/cranker -d cinema $(TARGET) $(TARGET).x

adf:	$(TARGET).x
	xdftool $(TARGET).adf format "Moneypositas"
	xdftool $(TARGET).adf makedir S
	t=`mktemp` && (echo "moneypositas.x" > $$t) && xdftool $(TARGET).adf write $$t S/Startup-Sequence
	xdftool $(TARGET).adf write moneypositas.x
	xdftool $(TARGET).adf write /opt/amiga/Shell
	xdftool $(TARGET).adf boot install boot1x

%.o:	%.s
	$(AS) $(AFLAGS) -L $@.lst -o $@ $+

.PHONY: clean
clean:
	rm -f *.o *.lst $(TARGET).x $(TARGET).adf
	rm -f $(TARGET) logo.the_7th_division.c
	rm -f $(IMAGES) $(MUZAK) $(DATAS)
