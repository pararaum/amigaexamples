#! /usr/bin/make -f

OBJS=setup.o image.o sound.o

include ../config.mk

fader:	fader.o $(OBJS)

.PHONY: clean
clean:
	rm -f *.o fader

