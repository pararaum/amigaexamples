#include "blitterrama.h"
#include "blitterfuncs.h"
#include "globals.h"

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
void blit_bob(UBYTE *target, const Bob_t *bob) {
  unsigned short x = bob->x5 >> 5;
  unsigned short y = bob->y5 >> 5;
  unsigned short shift = (x & 0x0f) << 12;
  short i;
  UBYTE *bobsrc = bob->src;

  target += y * BPLWIDTH/8 * BPLNOS;
  target += (x / 8) & 0xFFFEU;
  WAITBLIT; // Wait for end of pending Blitter operation, otherwise kaputt...
  custom.bltcon0 = 0x0FCA | shift; // Four channels, D=AB+¬AC.
  custom.bltcon1 = 0 | shift; // No line drawing or other specialities.
  custom.bltafwm = -1;
  custom.bltalwm = 0;
  custom.bltamod = 0 - 2;
  custom.bltbmod = (bob->srcw/8 * 3) - 2;
  custom.bltcmod = (BPLWIDTH-bob->srcw) / 8 + BPLWIDTH/8*3 - 2;
  custom.bltdmod = (BPLWIDTH-bob->srcw) / 8 + BPLWIDTH/8*3 - 2;
  for(i = 0; i < BPLNOS; ++i) {
    WAITBLIT; // Wait for end of pending Blitter operation, otherwise kaputt...
    custom.bltapt = bob->cookie;
    custom.bltbpt = bobsrc;
    custom.bltcpt = target;
    custom.bltdpt = target;
    /* H9-H0, W5-W0; width is in words. By writing the size into the
     * custom chip register the blit begins and continues while the cpu
     * is still running. */
    custom.bltsize = ((bob->srch) << 6) | (1 + (bob->srcw / 8 / 2));
    // Now next interleaved line of bob:
    bobsrc += bob->srcw/8;
    // Now next interleaved target line:
    target += BPLWIDTH/8;
  }
}


void copy_image_to_framebuffer(UBYTE *target, UBYTE *anmsrc) {
  WAITBLIT; // Wait for end of pending Blitter operation, otherwise kaputt...
  custom.bltcon0 = 0x09f0; // D=A
  custom.bltcon1 = 0; // No line drawing or other specialities.
  custom.bltafwm = 0xFFFFU; // No masks.
  custom.bltalwm = 0xFFFFU;
  // Target is one words after the beginning of the screen.
  custom.bltdpt = target;
  custom.bltapt = anmsrc;
  custom.bltamod = 0;
  custom.bltdmod = 2; // Always skip a word at destination.
   /* H9-H0, W5-W0; width is in words. By writing the size into the
    * custom chip register the blit begins and continues while the cpu
    * is still running. */
  custom.bltsize = ((IMGHEIGHT/2 * IMGBPLNOS) << 6) | (IMGWIDTH / 8 / 2);
}
