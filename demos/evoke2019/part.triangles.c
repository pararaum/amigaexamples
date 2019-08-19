#include <string.h>
#include <stdlib.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <hardware/intbits.h>
#include <exec/types.h>
#include "sprite_multiplexer.h"
#include "circallator.h"
#include "tools.h"
#include "introduction.barebone.h"
#include "evoke2019.h"
#include "credits.barebone.h"
#include "xoroshiro.h"

#define BPLWIDTH 320
#define BPLHEIGHT 212
#define BPLNOS 5

#define VERTEXSHIFT 6

/*! brief Store a corner of the triangle.
 *
 * All deltas and positions are store shifted by six bits to increase
 * the resolution.
 */
struct Trianglevertex {
  unsigned short x[3];
  unsigned short y[3];
  signed short dx[3];
  signed short dy[3];
};

static struct Trianglevertex triangles[5] = {
  {
    { 0 << VERTEXSHIFT, 280 << VERTEXSHIFT, 40 << VERTEXSHIFT },
    { 0 << VERTEXSHIFT, 160 << VERTEXSHIFT, 200 << VERTEXSHIFT },
    { 3 << VERTEXSHIFT,
      (signed short)(94),
      (signed short)(-88)
    },
    { 2 << VERTEXSHIFT,
      (signed short)(-209),
      (signed short)(-147)
    }
  }
  /* { 0, 0, 3 << VERTEXSHIFT, 2 << VERTEXTSHIFT }, */
  /* { 280, 160, (1<<VERTEXSHIFT)*.7, -(1<<VERTEXSHIFT)*1.7 }, */
  /* { 40, 200, -(1<<VERTEXSHIFT)*1.37, -(1<<VERTEXSHIFT)*2.17 } */
};
static UWORD *coplistptr;
static UWORD coplist_data[] = {
  0x0182, 0x02e7, /* Colour 1: a green */
  0x0180, 0, /* background black */
  0x0180 +  2 * 2, 0x0ddd,
  0x0180 +  3 * 2, 0x0800,
  0x0180 +  4 * 2, 0x0bbb,
  0x0180 +  5 * 2, 0x0800,
  0x0180 +  6 * 2, 0x0800,
  0x0180 +  7 * 2, 0x0800,
  0x0180 +  8 * 2, 0x0999,
  0x0180 +  9 * 2, 0x0800,
  0x0180 + 10 * 2, 0x0800,
  0x0180 + 11 * 2, 0x0800,
  0x0180 + 12 * 2, 0x0800,
  0x0180 + 13 * 2, 0x0800,
  0x0180 + 14 * 2, 0x0800,
  0x0180 + 15 * 2, 0x0800,
  0x0180 + 16 * 2, 0x0666,
  0x0180 + 17 * 2, 0x0800,
  0x0180 + 18 * 2, 0x0800,
  0x0180 + 19 * 2, 0x0800,
  0x0180 + 20 * 2, 0x0800,
  0x0180 + 21 * 2, 0x0800,
  0x0180 + 22 * 2, 0x0800,
  0x0180 + 23 * 2, 0x0800,
  0x0180 + 24 * 2, 0x0800,
  0x0180 + 25 * 2, 0x0800,
  0x0180 + 26 * 2, 0x0800,
  0x0180 + 27 * 2, 0x0800,
  0x0180 + 28 * 2, 0x0800,
  0x0180 + 29 * 2, 0x0800,
  0x0180 + 30 * 2, 0x0800,
  0x0180 + 31 * 2, 0x0800,
  /* Other registers */
  0x0100, 0x0200 | 0x1000 * BPLNOS, // BPLCON0, BPLNOS bitplanes.
  0x0102, 0, // BPLCON1
  0x0104, 0, // BPLCON2
  0x0108, 0, // BPL1MOD
  0x010a, 0, // BPL2MOD
  0x008a, 0, // COPJMP2
  0xFFFF, 0xFFFE
};
static UBYTE *bitplaneptr;
static UBYTE *bitplaneptrs[5]; // For multiple bitplanes.

static void set_new_colours(void) {
  int i, j;
  UWORD *clptr = coplistptr + 4 * 5; // Skip bitplane pointers.
  static UWORD cols[] = { 0xfff, 0xccc, 0x999, 0x666, 0x333 };
  unsigned int value;
  short counter;

  for(i = 0; i < 32; ++i) {
    clptr[2 * i] = 0x180 + 2 * i;
    switch(i) {
    case 0:
      clptr[2 * i + 1] = 0;
      break;
    case 1:
      clptr[2 * i + 1] = cols[0];
      break;
    case 2:
      clptr[2 * i + 1] = cols[1];
      break;
    case 4:
      clptr[2 * i + 1] = cols[2];
      break;
    case 8:
      clptr[2 * i + 1] = cols[3];
      break;
    case 16:
      clptr[2 * i + 1] = cols[4];
      break;
    default:
      value = 0;
      counter = 0;
      for(j = 0; j < 5; ++j) {
	if((i & (1 << j)) != 0) {
	  value += cols[j] & 0xf;
	  ++counter;
	}
      }
      value /= counter;
      clptr[2 * i + 1] = (value << 8) | (value << 4) | value;
    }
  }
}

static void init_copper(void *bitpl0) {
  UWORD *coplist;
  unsigned short ccr; // Custom chip register
  int i;
  ULONG bpladdr = (ULONG)bitpl0;

  /* Allocate memory for copperlist: 5 times two moves for the
     bitplane pointers + the rest from above. */
  coplist = circalloc(sizeof(coplist_data) + 5 * (2 + 2));
  coplistptr = coplist;
  ccr = 0xe0; // Bitplane pointer
  for(i = 0; i < 5; ++i) {
    *coplist++ = ccr;
    ccr += 2;
    *coplist++ = (ULONG)bpladdr >> 16;
    *coplist++ = ccr;
    ccr += 2;
    *coplist++ = (ULONG)bpladdr & 0xFFFF;
    bpladdr += BPLWIDTH * BPLHEIGHT / 8;
  }
  // Now copy the remainder of the copperlist.
  memcpy(coplist, coplist_data, sizeof(coplist_data));
}


static void draw_line(UBYTE *bplptr, int x1, int y1, int x2, int y2) {
  int dx = abs(x1 - x2);
  int dy = abs(y1 - y2);
  unsigned short bltcon1 = ((x1 & 0xf) << 12) | 1; // Bit0 = line drawing mode.
  int dmax;
  int dmin;
  int slope;

  if(dx > dy) {
    dmax = dx;
  } else {
    dmax = dy;
  }
  if(dx <= dy) {
    dmin = dx;
  } else {
    dmin = dy;
  }
  // Get the octant [http://www.winnicki.net/amiga/memmap/LineMode.html].
  if(((dx >= dy) && (x1 >= x2)) || ((dx < dy) && (y1 >= y2))) {
    bltcon1 |= 1 << 2;
  }
  if(((dx >= dy) && (y1 >= y2)) || ((dx < dy) && (x1 >= x2))) {
    bltcon1 |= 1 << 3;
  }
  if(dx >= dy) {
    bltcon1 |= 1 << 4;
  }
  slope = (4 * dmin) - (2 * dmax);
  /* Calculate the position in the bitplane here, as multiplication is
   * expensive and the blitter may be working anyway.*/
  int position = y1 * BPLWIDTH/8 + x1/8;
  position &= -2; // We need the word.
  WAITBLIT;
  /* The article in
   * http://www.stashofcode.fr/coder-une-cracktro-sur-amiga-1/ has the
   * right formula for bltamod, the text in
   * http://www.winnicki.net/amiga/memmap/LineMode.html seems to be
   * wrong! And
   * http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node0128.html
   * has it right again...
   */
  custom.bltamod = 4 * (dmin - dmax);
  custom.bltbmod = 4 * dmin;
  custom.bltapt = (void *)slope;
  if(slope < 0) {
    bltcon1 |= 1 << 6;
  }
  custom.bltcon1 = bltcon1;
  custom.bltbdat = -1; // Solid line
  custom.bltcmod = BPLWIDTH/8;
  custom.bltdmod = BPLWIDTH/8;
  custom.bltcpt = bplptr + position;
  custom.bltdpt = bplptr + position;
  custom.bltcon0 = ((x1 & 0xF) << 12)
    | 0x0b00 /* Channels to use. */
    | 0x004a; /* XOR */
  custom.bltadat = 0x8000;
  custom.bltafwm = -1;
  custom.bltalwm = -1;
  custom.bltsize = dmax * 64 + 66;
}


/*
 * This function is called by the assembler interrupt subroutine.
 */
static void do_interrupt_warp(void) {
  int x1, x2;
  int y1, y2;

#ifndef NDEBUG
  if((framecounter & 3) != 0) {
    return;
  }
#endif
  do {
    x1 = xoroshiro32plusplus() % 320;
    x2 = xoroshiro32plusplus() % 320;
    y1 = xoroshiro32plusplus() % 200;
    y2 = xoroshiro32plusplus() % 200;
  } while((x1 == x2) && (y1 == y2));
  draw_line(bitplaneptr, x1, y1, x2, y2);
}


static void draw_triangle(UBYTE *bplptr, const struct Trianglevertex *tri) {
  draw_line(bplptr, tri->x[0] >> VERTEXSHIFT, tri->y[0] >> VERTEXSHIFT, tri->x[1] >> VERTEXSHIFT, tri->y[1] >> VERTEXSHIFT);
  draw_line(bplptr, tri->x[0] >> VERTEXSHIFT, tri->y[0] >> VERTEXSHIFT, tri->x[2] >> VERTEXSHIFT, tri->y[2] >> VERTEXSHIFT);
  draw_line(bplptr, tri->x[1] >> VERTEXSHIFT, tri->y[1] >> VERTEXSHIFT, tri->x[2] >> VERTEXSHIFT, tri->y[2] >> VERTEXSHIFT);
}


static void cycle_bitplaneptrs(void) {
  short int i;
  unsigned short hi, lo;

  hi = coplistptr[4 * (5 - 1) + 1];
  lo = coplistptr[4 * (5 - 1) + 3];
  for(i = 5 - 1 - 1; i >= 0; --i) {
    coplistptr[4 * (i + 1) + 1] = coplistptr[4 * (i + 0) + 1];
    coplistptr[4 * (i + 1) + 3] = coplistptr[4 * (i + 0) + 3];
  }
  coplistptr[1] = hi;
  coplistptr[3] = lo;
}


static struct Trianglevertex *update_triangle(struct Trianglevertex *tri) {
  short int j;

  for(j = 0; j < 3; ++j) {
    tri->x[j] += tri->dx[j];
    if(tri->x[j] < 0) {
      tri->dx[j] *= -1;
      tri->x[j] += 2 * tri->dx[j];
    } else if(tri->x[j] >= 320 << VERTEXSHIFT) {
      tri->dx[j] *= -1;
      tri->x[j] += 2 * tri->dx[j];
    }
    tri->y[j] += tri->dy[j];
    if(tri->y[j] < 0) {
      tri->dy[j] *= -1;
      tri->y[j] += 2 * tri->dy[j];
    } else if(tri->y[j] >= 210 << VERTEXSHIFT) {
      tri->dy[j] *= -1;
      tri->y[j] += 2 * tri->dy[j];
    }
  }
  return tri;
}


static void do_interrupt_triangle(void) {
  int i;
  struct Trianglevertex *tri;
  static unsigned short counter = 0;

  tri = &triangles[counter]; // Get address of triangle.
  draw_triangle(bitplaneptrs[counter], tri); // Remove
  update_triangle(tri);
  update_triangle(tri);
  update_triangle(tri);
  update_triangle(tri);
  update_triangle(tri);
  draw_triangle(bitplaneptrs[counter], tri); // Draw
  /* for(i = 4; i >= 1; --i) { */
  /*   draw_triangle(bitplaneptrs[i], &triangles[i]); */
  /*   memcpy(&triangles[i], &triangles[i - 1], sizeof(struct Trianglevertex)); */
  /*   draw_triangle(bitplaneptrs[i], &triangles[i]); */
  /* } */
  cycle_bitplaneptrs();
  if(++counter >= 5) {
    counter = 0;
  }
}


void triangles_part(void) {
  int i;

  bitplaneptr = circalloc(BPLWIDTH*BPLHEIGHT/8*BPLNOS);
  for(i = 0; i < BPLNOS; ++i) {
    clear_bitplane(bitplaneptr + BPLWIDTH/8*BPLHEIGHT * i, BPLWIDTH/8/2, BPLHEIGHT);
    bitplaneptrs[i] = bitplaneptr + BPLWIDTH/8*BPLHEIGHT * i;
  }
  init_copper(bitplaneptr);
  WAITBLIT;
  custom.cop1lc = (ULONG)coplistptr;
  custom.copjmp1 = 0;
  custom.dmacon = DMAF_SETCLR /*set*/
    | DMAF_MASTER /*DMAEN*/
    | DMAF_RASTER /*BPLEN*/
    | DMAF_COPPER /*COPEN*/
    | DMAF_BLITTER;
  autovector[0x308/4] = (ULONG)&do_interrupt_warp;
  wait_songposition(get_songposition() + 1, 0);
  /* // Clear and new colour. */
  clear_bitplane(bitplaneptr, BPLWIDTH/8/2, BPLHEIGHT);
  coplistptr[5 * 4 + 1] = 0x27e;
  /* wait_songposition(get_songposition() + 1, 0); */
  // Stop simple effect.
  autovector[0x308/4] = 0;
  set_new_colours();
  // And clear.
  clear_bitplane(bitplaneptr, BPLWIDTH/8/2, BPLHEIGHT);
  /*
  ** 0   1   2   3   4
  ** 0  1δ  2δ  3δ  4δ
  */
  for(i = 1; i < 5; ++i) {
    triangles[i] = triangles[0];
    for(int j = 0; j < i; ++j) {
      update_triangle(&triangles[i]);
    }
    draw_triangle(bitplaneptrs[i], &triangles[i]);
  }
  draw_triangle(bitplaneptrs[0], &triangles[0]);
  autovector[0x308/4] = (ULONG)&do_interrupt_triangle;
  wait_songposition(get_songposition() + 2, 0);
  autovector[0x308/4] = 0;
}
