#include <exec/types.h>             /* The Amiga data types file.         */
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <hardware/intbits.h>
#include <string.h>
#include "evoke2019.h"
#include "tools.h"
#include "circallator.h"
#include "iff.h"

#define FEEDBACKTERM 0x80000ACDUL
static unsigned long rand = 1559572863UL;

#include "image_guru_ilbm.c"

static unsigned long nextran(void) {
  //http://users.ece.cmu.edu/~koopman/lfsr/32.txt
  if(rand & 1) {
    rand = (rand >> 1) ^ FEEDBACKTERM;
  } else {
    rand = (rand >> 1);
  }
  return rand;
}

static void prepare_blitter(void) {
  WAITBLIT;
  custom.bltbdat = 0xf0ff;
  // D = A~B + BC
  custom.bltcon0 = 0x0bb8; //ACD, no shift, B channel is not needed as it has a fixed value anyway.
  custom.bltcon1 = 0x0002; //Descending
  /* A first word mask; The worst word in a line a seen by the
     blitter. Remember the descending mode! We will start at the end
     of the line. */
  custom.bltafwm = 0xffff;
  /* A last word mask */
  custom.bltalwm = 0xffff;
  /* Skip modulo bytes for every line, b stays. */
  custom.bltamod = 640/8-4;
  custom.bltbmod = -2;
  custom.bltcmod = 640/8-4;
  custom.bltdmod = 640/8-4;
}

static void do_blit(UBYTE *bitplane, int xpos, int ypos, int height, unsigned int masknum) {
  UBYTE *btop;
  UBYTE *bbot;
  unsigned int masksize;
  unsigned int maskshift;
  unsigned int mask = -1;

  btop = bitplane + ypos * 640 / 8 + ((xpos / 8) & (~1));
  bbot = btop + height * 640/8;
  WAITBLIT;
  custom.bltapt = bbot - 640/8;
  custom.bltcpt = bbot;
  custom.bltdpt = bbot;
  masksize = masknum & 7 + 7;
  mask &= (1 << masksize) - 1;
  maskshift = masknum >> 3;
  custom.bltbdat = ~(mask << (maskshift % (16 - masksize)));
  /* H9-H0, W5-W0; width is in words. By writing the size into the
   * custom chip register the blit begins and continues while the cpu
   * is still running.
   */
  custom.bltsize = (((height - 1) << 6) | (4) / 2);
}

static void irqroutine(void) {
  static UWORD colcounter = 0xf00;

  if(colcounter >= 0) {
    custom.color[1] = colcounter;
    colcounter -= 0x100;
  }
}

void show_stopper(void) {
  ULONG *autovector = (ULONG*)(0x0UL); //Autovector pointer
  UBYTE *bitplane;
  unsigned long l;
  UWORD very_simple_copperlist[] = {
    0xe0, 0, /* Bitplane pointer */
    0xe2, 0,
    0x0100, 0x9200, // HIRES and one bitplane.
    0x5401, 0xfffe, // Wait for end of guru meditation.
    0x0100, 0x0200, // Deactivate Bitplanes.
    0xffff, 0xfffe
  };
  UWORD *copptr;
  void *dataptr;
  long chunksize;
  int i;

  autovector[0x300/4] = 0;
  autovector[0x304/4] = 0;
  custom.intena = INTF_SETCLR|INTF_INTEN|INTF_VERTB;
  custom.dmacon = DMAF_AUDIO;
  custom.dmacon = DMAF_RASTER;
  bitplane = circalloc(640*256/8);
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER;
  chunksize = find_iff_chunk(0x424f4459UL, image_guru_ilbm, &dataptr);
  if(chunksize > 0) {
    uncompress_body_interleaved(dataptr, chunksize, bitplane);
  }
  very_simple_copperlist[1] = (ULONG)bitplane >> 16;
  very_simple_copperlist[3] = (ULONG)bitplane;
  copptr = circalloc(sizeof(very_simple_copperlist));
  memcpy(copptr, very_simple_copperlist, sizeof(very_simple_copperlist));
  custom.color[0] = 0x888;
  for(l = framecounter; framecounter < l + 60; ) {
  }
  custom.color[0] = 0xFFF;
  for(l = framecounter; framecounter < l + 60; ) {
  }
  custom.color[0] = 0x111;
  custom.color[1] = 0xF21;
  custom.bplcon1 = 0;
  /* http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node0085.html */
  custom.ddfstrt = 0x3c; // Hires Display Data Fetch
  custom.ddfstop = 0xd4; // Hires Display Data Fetch
  custom.cop1lc = (ULONG)copptr;
  custom.copjmp1 = 0;
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER;
  for(i = 0; i < 3; ++i) {
    for(l = framecounter; framecounter < l + 60; ) {}
    copptr[1] = (ULONG)(bitplane + 640/8*64) >> 16;
    copptr[3] = (ULONG)(bitplane + 640/8*64);
    for(l = framecounter; framecounter < l + 60; ) {}
    copptr[1] = (ULONG)bitplane >> 16;
    copptr[3] = (ULONG)bitplane;
  }
  clear_bitplane(bitplane + 640/8*42, 640/8/2, 256-42);
  // Prematurely end the copperlist as the second image is cleared.
  copptr[6] = 0xFFFF;
  // Prepare blitter for future melt copies.
  prepare_blitter();
  for(l = framecounter; framecounter < l + 271; ) {
    unsigned long ypos = nextran() % 60;
    do_blit(bitplane, nextran() % (640-8), ypos + 2, 255-2-ypos, nextran());
    if(framecounter > l + 271 - 15) {
      autovector[0x300/4] = (ULONG)&irqroutine;
    }
  }
  autovector[0x300/4] = 0;
}
