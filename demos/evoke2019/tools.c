#include "tools.h"
#include <hardware/custom.h>
#include <hardware/dmabits.h>

extern volatile struct Custom custom;

/*! \brief Autovector pointer
 *
 * This is a pointer to zero so that the 68K autovectors can be
 * accessed easily.
 */
ULONG *autovector = (ULONG*)(0x0UL);

void clear_bitplane(unsigned char *btplptr, int width, int height) {
#ifndef NDEBUG
  if((width >= (1<<7)) || (height >= 1024)) {
    for(;;) {
      custom.color[0] = 0xf00;
      custom.color[0] = 0xff0;
    }
  }
#endif
  WAITBLIT;
  custom.bltcon0 = 0x0100; // Only D channel, no logic function!
  custom.bltcon1 = 0x0000; // No B shift, normal mode.
  /* A first word mask; The first word in a line a seen by the
     blitter. */
  custom.bltafwm = 0;
  /* A last word mask */
  custom.bltalwm = 0;
  /* channel D pointer */
  custom.bltdpt = btplptr;
  custom.bltamod = 0; // No modulo.
  custom.bltdmod = 0;
  /* H9-H0, W5-W0; width is in words. By writing the size into the
     custom chip register the blit begins and continues while the cpu
     is still running. */
  custom.bltsize = (height << 6) | (width);
}
