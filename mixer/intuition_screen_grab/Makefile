#! /usr/bin/make -f

.PHONY:	all clean

all: intuition_screen_grab

clean:
	rm -f intuition_screen_grab

intuition_screen_grab: intuition_screen_grab.c
	vc -o $@ -O2 $+ -lamiga

