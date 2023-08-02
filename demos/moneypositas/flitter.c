#include <string.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <hardware/intbits.h>
#include "t7d/lz4_uncrunch.h"
#include "t7d/inflate.h"
#include "images.h"
#include "flitter.h"
#include "t7d/xoroshiro.h"
#include "globals.h"


void flitter_update_cwftr(AtmosphericFlitter_t *flittermem, int row) {
  /*
   * Why all this "Gehampel"?
   *
   * The copper needs the very specific for the position $FFDF in
   * order to be able to access raster lines above 255. When sliding
   * the wait at copperlist position 40 is needed in order to reach
   * the bottom of the screen and turn bitplanes off. But if we are
   * going to start the bitplanes at a raster row above 255 than the
   * wait at copperlist position 40 will wait for raster position $100
   * + $ff -- and this is never reached! Then we have a flicker
   * because in the next frame the bitplanes are active and will be
   * displayed starting at the top. Therefore we disable the wait for
   * $FFDF near the end of the copper list if there are only a few
   * lines of the nice logo left. It is really phantastic that the
   * copper has a no-op.
   */
  if(row <= 255) {
    flittermem->copperlist[12] = 0x01fe; // NO-OP
    flittermem->copperlist[14] = (row << 8) | 0xff;
    flittermem->copperlist[40] = 0xffdf;
  } else {
    flittermem->copperlist[12] = 0xffdf;
    flittermem->copperlist[14] = ((row - 256) << 8) | 0xff;
    flittermem->copperlist[40] = 0x01fe; // NO-OP
  }
}


AtmosphericFlitter_t *prepare_flitter(AtmosphericFlitter_t *flittermem) {
  AtmosphericFlitter_t *flitter = flittermem;
  int i;
  static UWORD very_simple_copperlist[] = {
    0xe0, 0, /* Bitplane pointer */
    0xe2, 0,
    0xe4, 0,
    0xe6, 0,
    0xe8, 0,
    0xea, 0,
    0x01fe, 0xfffe, /* Copper NO-OP */
    0x01ff, 0xfffe, /* Copper wait for top row, yeah! */
    0x0100, 0x3200, /* BPLCON0: three bitplanes and colour burst. */
    0x0102, 0x0000, /* BPLCON1 */
    0x108, FLITTERWIDTH / 8, /* Two odd bitplanes, one line modulo. */
    0x10a, 0, /* Only a single even bitplane. */
    0x180, 0x211, /* 000 */
    0x182, 0x211, /* 001 */
    0x184, 0x303, /* 010 */
    0x186, 0x088, /* 011 */
    0x188, 0x211, /* 100 */
    0x18a, 0x211, /* 101 */
    0x18c, 0x0bb, /* 110 */
    0x18e, 0x0ee, /* 111 */
    0xffdf, 0xfffe, /* Wait for PAL. */
    0x13ff, 0xfffe, /* 232 lines visible. */
    0x0100, 0x0200, /* BPLCON0: zero bitplanes and colour burst. */
    0xffff, 0xfffe
  };

  //lz4_uncrunch(&lz4logo[0], &flitter->logoplane[0], lz4logo_end - lz4logo);
  inflate(&flitter->logoplane[0], &lz4logo[0]);
  flitter->modulo = FLITTERWIDTH/8;
  memcpy(&flitter->copperlist[0], very_simple_copperlist, sizeof(very_simple_copperlist));
  flitter->copperlist[1] = (ULONG)(&flitter->noiseplanes[0]) >> 16;
  flitter->copperlist[3] = (ULONG)(&flitter->noiseplanes[0]);
  flitter->copperlist[5] = (ULONG)(&flitter->logoplane[0]) >> 16;
  flitter->copperlist[7] = (ULONG)(&flitter->logoplane[0]);
  flitter->copperlist[9] = (ULONG)(&flitter->noiseplanes[flitter->modulo]) >> 16;
  flitter->copperlist[11] = (ULONG)(&flitter->noiseplanes[flitter->modulo]);
  for(i = 0; i < FLITTERWIDTH/8 * FLITTERHEIGHT * 2; ++i) {
    flitter->noiseplanes[i] = xoroshiro32plusplus();
  }
  custom.cop1lc = (ULONG)&flitter->copperlist[0];
  custom.bplcon0 = 0x3200; // Three bitplanes and colour out.
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER;
  custom.copjmp1 = 0;
  return flitter;
}


void blit_da_noise(AtmosphericFlitter_t *flitter, int frameno) {
  /* As we are using dual playfield we are going to produce the noise
     effect on the even bitplanes. */
  const short skip = ((frameno % 2) == 0) ? FLITTERWIDTH/8*FLITTERHEIGHT : 0;

  WAITBLIT;
  custom.bltafwm = -1;
  custom.bltalwm = -1;
  custom.bltapt = &flitter->noiseplanes[skip];
  custom.bltdpt = &flitter->noiseplanes[skip];
  custom.bltamod = 0;
  custom.bltdmod = 0;
  custom.bltcon1 = 0x10;
  custom.bltcon0 = 0x9f0;
  /*
   * Width is (all bits cleared) is 1024 pixels. Therefore we have to
   * fill (/ (* 320 212) 1024) 66 lines.
   */
  custom.bltsize = (FLITTERWIDTH * FLITTERHEIGHT / 1024 + 1) << 6;
}

