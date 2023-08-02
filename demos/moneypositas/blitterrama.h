#ifndef __BLITTERRAMA_H_1582303486
#define  __BLITTERRAMA_H_1582303486
#include <exec/types.h>

typedef struct Bob {
  UBYTE *src; //!< Pointer to interleaved source
  unsigned short srcw; //!< source width (bytes)
  unsigned short srch; //!< source height (rows)
  UBYTE *cookie; //!< Pointer to cookie cut mask
  unsigned short x5; //!< x << 5
  unsigned short y5; //!< y << 5
  unsigned short speed5x; //!< speed << 5
  short int speed5y; //!< speed << 5
} Bob_t;


/*! \brief copy an image using the blitter
 *
 * This will copy one of the uncompressed images into one of the
 * bitplane memories available (two as we are using double buffering).
 *
 * \param target pointer to target area
 * \param anmsrc pointer to animation source
 */
void copy_image_to_framebuffer(UBYTE *target, UBYTE *anmsrc);


/*! \brief Blit a Bob with cookie cut and horizontal pixel-accuracy
 *
 * Blit a single plane from the animation into the target plane. The
 * cookie-cut mask is taken from the cookie pointer. No Masking is
 * done.
 *
 * \param target pointer to the target area
 * \param bob pointer to the Bob_t structure
 * \param boff offset in bob
 */
void blit_bob(UBYTE *target, const Bob_t *bob);


#endif
