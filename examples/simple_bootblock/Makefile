#! /usr/bin/make -f

include ../config.mk

all:	boot_and_do_nothing.adf

boot_and_do_nothing.adf: boot_and_do_nothing.o
	vlink $(VLINKFLAGS) -nostdlib -b rawbin1 $+ -o boot_and_do_nothing.bootblock $(LIBS)
	xdftool boot_and_do_nothing.adf format "BootDisk"
	xdftool boot_and_do_nothing.adf boot write boot_and_do_nothing.bootblock

run:
	fs-uae --console_debugger=1 --floppy_drive_0=boot_and_do_nothing.adf

.PHONY: clean run
clean:
	rm -f *.o *.adf *.bootblock
