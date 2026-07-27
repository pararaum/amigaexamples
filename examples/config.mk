AFLAGS=-m68000 -opt-speed
AS=vasmm68k_mot -Fhunk -I$$NDK39_ASMINC -I$$T7D/asminc -L $@.lst
CC=vc +kick13 -I$$NDK39_INCLUDE -I$$T7D/include
CFLAGS=-c99 -speed -O3 -DNDEBUG
LD=vc +kick13
LDFLAGS=$(LIBS)
LIBS=-L$$T7D -lamiga -lt7d
VLINKFLAGS=-s -L$$NDK39/Include/linker_libs
