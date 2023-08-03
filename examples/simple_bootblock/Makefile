#! /usr/bin/make -f

TARGETS = boot_and_do_nothing.adf boot_and_load_track.adf boot_and_search_memory.adf
# CURRENT is only used for run, which of the TARGETS is actually run?
CURRENT = boot_and_search_memory.adf # boot_and_load_track.adf

include ../config.mk

all:	$(TARGETS)

%.bootblock: %.o
	vlink $(VLINKFLAGS) -nostdlib -b rawbin1 $^ -o $@ $(LIBS)

%.adf: %.bootblock
	xdftool $@ format "BootDisk"
	xdftool $@ boot write $<

run:
	fs-uae --console_debugger=1 --floppy_drive_0=$(CURRENT)

.PHONY: clean run
clean:
	rm -f *.o *.adf *.bootblock *.lst
