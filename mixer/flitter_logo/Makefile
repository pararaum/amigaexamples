#! /usr/bin/make -f

TARGET=flitter
OBJS=flitter.o logo.the_7th_division.o

include ../config.mk

all:	$(TARGET)

logo.the_7th_division.c: logo.the_7th_division.xpm
	convert_img2raw -O c -b -B 1 $+ > $@

flitter:	$(OBJS)

.PHONY: all clean
clean:
	rm -f *.o *.lst
	rm -f $(TARGET) logo.the_7th_division.c
