#! /usr/bin/make -f

AS=vasmm68k_mot -Fhunk -I$$HOME/include/
LD=vlink
VLINKFLAGS=-s
TARGET=display_image

all:	$(TARGET)

$(TARGET):	$(TARGET).o
	$(LD) $(VLINKFLAGS) -o $@ $+

%.o:	%.s
	$(AS) -o $@ $+

.PHONY: clean
clean:
	rm *.o
	rm $(TARGET)
