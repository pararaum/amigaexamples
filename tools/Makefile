#! /usr/bin/make -f

CXXFLAGS=-std=c++14 -O2 -Wall -Wextra -g -DNDEBUG

#

LIBS=`pkg-config --libs sdl2 SDL2_image`
BIN=convert_img2raw

all:	$(BIN)

install:
	install -d $(DESTDIR)/usr/local/bin
	install -s -t $(DESTDIR)/usr/local/bin $(BIN)

convert_img2raw: cli_parser.o convert_img2raw.o
	g++ -o $@ $+ $(LIBS)

.PHONY:	clean
clean:
	rm -f *.o $(BIN)
	rm -f cli_parser.o cli_parser.c cli_parser.h

cli_parser.c: cli_parser.ggo
	gengetopt --unamed-opts -F cli_parser < $<
