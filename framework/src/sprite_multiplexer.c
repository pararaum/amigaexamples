#include "t7d/sprite_multiplexer.h"

void multiplex_sprites(unsigned short *phases, unsigned int num, unsigned int height, unsigned short *positions, struct Multiplexer *multiplex) {
  unsigned int j;
  unsigned int csob; /*!< current sob number */
  unsigned short first_line_pos;
  unsigned short first_line_index;
  unsigned short first_line[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };
  unsigned short arraypos[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };
  unsigned short phasepos;
  // Height shifted 8 bits to the left. As this value is used quite
  // often we store it.
  unsigned short height8 = height << 8;

  /* Loop over each SOB. */
  for(csob = 0; csob < num; ++csob) {
    /* Look for the sprite with the lowest availabe position.*/
    first_line_pos = first_line[0];
    first_line_index = 0;
    for(j = 1; j < multiplex->numsprites; ++j) {
      if(first_line_pos > first_line[j]) {
	first_line_pos = first_line[j];
	first_line_index = j;
      }
    }
    /* This is the position (YX) encoded in an unsigned short int. */
    phasepos = positions[phases[csob]];
    /* Is the first available line for the current sprite slot smaller
       than the position? Then a sprite is available. If not we have
       to skip! */
    if(first_line_pos <= phasepos) {
      /* Set position in sprite data. */
      multiplex->sprite_data[first_line_index][arraypos[first_line_index]] = phasepos;
      /* Lower bits = X will create strange effects if not cleared... */
      phasepos &= 0xFF00;
      /* Add the height of the sprite for end position. */
      phasepos += height8;
      multiplex->sprite_data[first_line_index][arraypos[first_line_index] + 1] = phasepos;
      /* First available line is two lines below therefor increase Y
       * again.
       * http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node00C4.html
       * says that at least on video line must separate the bottom of
       * one usage from the starting point of the next usage.
       */
      phasepos += 0x0100;
      first_line[first_line_index] = phasepos;
      /* Every sprite has two times the height UWORDs of image
	 data plus one UWORD for (YX) position of the sprite plus one
	 UWORD for end position. */
      arraypos[first_line_index] += 2 * height + 2;
    }
  }
  /* Finish sprite DMA data. */
  for(j = 0; j < multiplex->numsprites; ++j) {
    multiplex->sprite_data[j][arraypos[j]] = 0;
    multiplex->sprite_data[j][arraypos[j] + 1] = 0;
  }
}
