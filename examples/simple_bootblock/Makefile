#! /usr/bin/make -f

TARGETS = boot_and_do_nothing.adf boot_and_load_track.adf boot_and_search_memory.adf boot_and_search_memory.raw.adf boot_salvadore.raw.adf
# CURRENT is only used for run, which of the TARGETS is actually run?
CURRENT = boot_salvadore.raw.adf # boot_and_load_track.adf
#Not used "./fix-bb.py $@" as bootblock is handled by `xdftool`.

include ../config.mk

all:	boss.zx0 $(TARGETS)

boss:	boss.o
	vlink $(VLINKFLAGS) -Tboss.x -nostdlib -b rawbin -symfile $@.sym $^ -o $@ $(LIBS)

boot_salvadore.track0.o: boot_salvadore.track0.s boss.zx0

%.bootblock: %.o
	vlink $(VLINKFLAGS) -Tall_in_one.x -nostdlib -b rawbin $(filter %.o $^) -o $@ $(LIBS)

%.track0: %.track0.o
	vlink $(VLINKFLAGS) -Tall_in_one.x -nostdlib -b rawbin $(filter %.o, $^) -o $@ $(LIBS)

%.raw.adf: %.track0
	printf "\e[31mRemoving '%s'\e[0m: " "$@"
	rm -f $@
	xdftool $@ create
	dd conv=notrunc of=$@ < $<
	./fix-bb.py $@

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
	rm -f *.o *.adf *.bootblock *.lst *.sym *.track0
	rm -f $(TARGETS)
	rm -f boss
