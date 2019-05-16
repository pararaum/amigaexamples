#! /usr/bin/make -f
CFLAGS=-speed -O3

.PHONY:	all clean

all: intuition_screen_grab

clean:
	rm -f intuition_screen_grab

intuition_screen_grab: intuition_screen_grab.c
	vc $(CFLAGS) -o $@ $+ -lamiga

