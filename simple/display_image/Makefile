#! /usr/bin/make -f

AS=vasmm68k_mot -Fhunk -I$$HOME/include/
LD=vlink
LDFLAGS=-s -L$$NDK39_LIBS -lamiga
VLINKFLAGS=-s
TARGET=display_image

all:	$(TARGET)

$(TARGET):	$(TARGET).o
	$(LD) $(LDFLAGS) -o $@ $+

%.o:	%.s
	$(AS) -o $@ $+

.PHONY: clean
clean:
	rm -f *.o
	rm -f $(TARGET)
