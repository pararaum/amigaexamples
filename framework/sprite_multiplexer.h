#ifndef __SPRITE_MULTIPLEXER_H__2018
#define __SPRITE_MULTIPLEXER_H__2018

typedef unsigned short * sprite_data_ptr_t;

struct Multiplexer {
  sprite_data_ptr_t sprite_data[8];
  unsigned short int numsprites;
};

/*! \brief Multiplex the sprites
 *
 * Call the sprite multiplexer. In this simple version all sprites
 * must have the same height.
 *
 * \param num number of SOBs 
 */
void multiplex_sprites(unsigned short *phases, unsigned int num, unsigned int height, unsigned short *positions, struct Multiplexer *multiplex);
#endif
