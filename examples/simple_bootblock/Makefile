#! /usr/bin/make -f

TARGETS = boot_and_do_nothing.adf boot_and_load_track.adf boot_and_search_memory.adf bossdemo.adf
# CURRENT is only used for run, which of the TARGETS is actually run?
CURRENT = bossdemo.adf
#Not used "./fix-bb.py $@" as bootblock is handled by `xdftool`.

include ../config.mk


all:	boss.zx0 part0.c20000.bin.zx0 $(TARGETS)

resident: resident.entrypoint.o resident.o
	vlink $(VLINKFLAGS) -D STARTADDR=0x6000 -Tall_in_one.x -nostdlib -symfile $@.sym -b rawbin $(filter %.o, $^) -o $@ $(LIBS)

%.c20000.bin:	%.o %.entry.o
	vlink $(VLINKFLAGS) -D STARTADDR=0xc20000 -Tall_in_one.x -nostdlib -symfile $@.sym -b rawbin $(filter %.o, $^) -o $@ $(LIBS)
%.c50000.bin:	%.o %.entry.o
	vlink $(VLINKFLAGS) -D STARTADDR=0xc50000 -Tall_in_one.x -nostdlib -symfile $@.sym -b rawbin $(filter %.o, $^) -o $@ $(LIBS)



boss:	boss.o boss.memorymanagement.o boss.io.o boss.trackloader.o boss.highlevel.o
#boss:	boss.o
	vlink $(VLINKFLAGS) -Tboss.x -nostdlib -b rawbin -symfile $@.sym $^ -o $@ $(LIBS) -L$$VBCC/vbcc_target_m68k-kick13/targets/m68k-kick13/lib -lvc

bossdemo.adf:	boot.bossboot.bootblock boss.zx0 assets.cfg resident.zx0 part0.c20000.bin rogal.under_the_bridge.scaled.5bitplane.bin dream_08_wip_268x256_jok.5bitplane.bin LastOneClosesTheDoors.5bitplane.bin wilderness_preview-pikku_jok.5bitplane.bin flora.640x256.4bitplane.bin part1.c50000.bin
	./diskmaster.py -o $@ $< boss.zx0


%.5bitplane.bin: %.png
	convert_img2raw -O bin -B 5 -p -b $< > $@
%.5bitplane.bin: %.iff
	convert_img2raw -O bin -B 5 -p -b $< > $@

%.4bitplane.bin: %.png
	convert_img2raw -O bin -B 4 -p -b $< > $@

%.3bitplane.bin: %.png
	convert_img2raw -O bin -B 3 -p -b $< > $@
%.3bitplane.bin: %.iff
	convert_img2raw -O bin -B 3 -p -b $< > $@

%.bootblock: %.o
	vlink $(VLINKFLAGS) -D STARTADDR=0 -Tall_in_one.x -nostdlib -b rawbin $(filter %.o, $^) -o $@ $(LIBS)

%.adf: %.bootblock
	xdftool $@ format "BootDisk"
	xdftool $@ boot write $<
#To add some data:
	dd conv=notrunc seek=2 of=boot_and_search_memory.adf < Makefile

%.zx0:	%
	salvador $< $@

run:
	fs-uae --console_debugger=1 --floppy_drive_0=$(CURRENT)
	#fs-uae --scale_y=2 --scale_x=2 --window_width=1400 --window_height=1100 --console_debugger=1 --floppy_drive_0=boot_and_load_track.adf

.PHONY: clean run
clean:
	rm -f *.o *.adf *.bootblock *.lst *.sym *.zx0 *.bin
	rm -f $(TARGETS)
	rm -f boss resident part0
