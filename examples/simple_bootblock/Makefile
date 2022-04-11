#! /usr/bin/make -f

TARGETS = boot_and_do_nothing.adf
# CURRENT is only used for run, which of the TARGETS is actually run?
CURRENT = boot_and_do_nothing.adf

include ../config.mk

all:	$(TARGETS)

%.bootblock: %.o
	vlink $(VLINKFLAGS) -nostdlib -b rawbin1 $^ -o $@ $(LIBS)

boot_and_do_nothing.adf: boot_and_do_nothing.bootblock
	xdftool $@ format "BootDisk"
	xdftool $@ boot write $(basename $@).bootblock

run:
	fs-uae --console_debugger=1 --floppy_drive_0=boot_and_do_nothing.adf

.PHONY: clean run
clean:
	rm -f *.o *.adf *.bootblock
