#ifndef __SPRITE_MULTIPLEXER_H__2018
#define __SPRITE_MULTIPLEXER_H__2018

#define SPRITE_HEIGHT 10

typedef unsigned short * sprite_data_ptr_t;

struct Multiplexer {
  sprite_data_ptr_t sprite_data[8];
  unsigned short int numsprites;
};

void multiplex_sprites(unsigned short *phases, unsigned int num, unsigned short *positions, struct Multiplexer *multiplex);
#endif
