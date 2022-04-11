#! /usr/bin/make -f

include ../config.mk

all:	boot_and_do_nothing.adf

boot_and_do_nothing.adf: boot_and_do_nothing.o
	vlink $(VLINKFLAGS) -nostdlib -b rawbin1 $+ -o boot_and_do_nothing.bootblock $(LIBS)
	xdftool boot_and_do_nothing.adf format "BootDisk"
	xdftool boot_and_do_nothing.adf boot write boot_and_do_nothing.bootblock

.PHONY: clean
clean:
	rm -f *.o *.adf *.bootblock
