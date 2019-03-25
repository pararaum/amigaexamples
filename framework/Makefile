#! /usr/bin/make -f

AS=vasmm68k_mot -Fhunk -I$$HOME/include/
ASFLAGS=-m68000 -L /dev/stdout -Lnf
LD=vlink
VLINKFLAGS=-s
#TARGET=sprite_example
OBJS=own.o iff.o copper_fade.o

all:	$(OBJS)

$(TARGET):	$(TARGET).o $(OBJS)
	$(LD) $(VLINKFLAGS) -o $@ $+

%.o:	%.s
	$(AS) $(ASFLAGS) -o $@ $+

.PHONY: clean
clean:
	rm *.o
	rm -f $(TARGET)

