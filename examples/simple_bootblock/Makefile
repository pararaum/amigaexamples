#! /usr/bin/make -f

TARGETS = boot_and_do_nothing.adf boot_and_load_track.adf boot_and_search_memory.adf bossdemo.adf
# CURRENT is only used for run, which of the TARGETS is actually run?
CURRENT = bossdemo.adf
#Not used "./fix-bb.py $@" as bootblock is handled by `xdftool`.

include ../config.mk


all:	boss.zx0 part0.zx0 $(TARGETS)

resident: resident.entrypoint.o resident.o
	vlink $(VLINKFLAGS) -D STARTADDR=0x6000 -Tall_in_one.x -nostdlib -symfile $@.sym -b rawbin $(filter %.o, $^) -o $@ $(LIBS)

part0.entry.s:  bassing.modified.mod.zx0
part0:	part0.o part0.entry.o
	vlink $(VLINKFLAGS) -D STARTADDR=0xc60000 -Tall_in_one.x -nostdlib -symfile $@.sym -b rawbin $(filter %.o, $^) -o $@ $(LIBS)

boss:	boss.o boss.memorymanagement.o boss.io.o boss.trackloader.o boss.highlevel.o
#boss:	boss.o
	vlink $(VLINKFLAGS) -Tboss.x -nostdlib -b rawbin -symfile $@.sym $^ -o $@ $(LIBS) -L$$VBCC/vbcc_target_m68k-kick13/targets/m68k-kick13/lib -lvc

bossdemo.adf:	boot.bossboot.bootblock boss.zx0 resident.zx0 part0.zx0 assets.cfg
	./diskmaster.py -o $@ $< boss.zx0


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
	rm -f *.o *.adf *.bootblock *.lst *.sym *.zx0
	rm -f $(TARGETS)
	rm -f boss part0
