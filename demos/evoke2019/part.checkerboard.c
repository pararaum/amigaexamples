#include <string.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <hardware/intbits.h>
#include "sprite_multiplexer.h"
#include "circallator.h"
#include "tools.h"
#include "inflate.h"
#include "introduction.barebone.h"
#include "evoke2019.h"
#include "xoroshiro.h"

/*
 * Idea and some of the code shamelessly ripped from the Coppershade
 * website:
 * http://coppershade.org/articles/Code/Articles/2._Origins_of_the_First_Effects/. So
 * Photon of Scoopex, I hope you do not mind.
 */

#define BITPLANEWIDTH 640
#define BITPLANEHEIGHT (256 + 32)
#define NUMSTARS 64
#define STARS_BOTTOM_Y 72

struct Star {
  signed short x, y;
  signed short dx, dy;
};
static struct Star *stars;
static UWORD *coplist;
static UBYTE *bitplaneptr;
static UWORD coplist_data[] = {
  /* Bitplane pointers */
  0x00e0, 0, 0x00e2, 0,
  // Colors
  0x0180, 0, /* background black */
  0x0182, 0x0eef, /* Colour 1: not quite white */
  0x0100, 0x1200, // BPLCON0, one bitplane.
  0x102, 0, // BPLCON1
  0x0108, (640-320)/8, // BPL1MOD
  0x010a, (640-320)/8, // BPL2MOD
};
#include "image.checkerboard.c"
static UWORD chess_colors[] = {
  0x00f, 0,0x01f, 0,0x02f, 0,0x03f, 0,0x04f, 0,0x05f, 0,0x06f, 0,0x07f, 0,
  0x08f, 0,0x09f, 0,0x0af, 0,0x0bf, 0,0x0cf, 0,0x0df, 0,0x0ef, 0,0x0ff, 0,
  0x0ff, 0,0x0ef, 0,0x0df, 0,0x0cf, 0,0x0bf, 0,0x0af, 0,0x09f, 0,0x08f, 0,
  0x07f, 0,0x06f, 0,0x05f, 0,0x04f, 0,0x03f, 0,0x02f, 0,0x01f, 0,0x00f, 0,
  // Repeat colours so that we do not have to care about wrap around.
  0x00f, 0,0x01f, 0,0x02f, 0,0x03f, 0,0x04f, 0,0x05f, 0,0x06f, 0,0x07f, 0,
  0x08f, 0,0x09f, 0,0x0af, 0,0x0bf, 0,0x0cf, 0,0x0df, 0,0x0ef, 0,0x0ff, 0,
  0x0ff, 0,0x0ef, 0,0x0df, 0,0x0cf, 0,0x0bf, 0,0x0af, 0,0x09f, 0,0x08f, 0,
  0x07f, 0,0x06f, 0,0x05f, 0,0x04f, 0,0x03f, 0,0x02f, 0,0x01f, 0,0x00f, 0
};
static UWORD chesstopY = 110;
static UWORD *end_of_checkerboard;
static int chessz = 0;
static UWORD *chesscolorptr = &chess_colors[0];
/*
 * Use ghci for calculating:
 *
 * Prelude> let angles = [i/512.0*pi | i <- [0..511]]
 * Prelude> let cosinus32 = map ((*) 32 . cos) angles
 * Prelude> let sinus32 = map ((*) 32 . sin) angles
 * Prelude Data.List> putStrLn $ intercalate ", " $ map (show . round) sinus32
 * Prelude Data.List> putStrLn $ intercalate ", " $ map (show . round) cosinus32
 */
static signed short sinus32[] = {
  0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 11, 11, 11, 11, 11, 12, 12, 12, 12, 12, 12, 13, 13, 13, 13, 13, 14, 14, 14, 14, 14, 14, 15, 15, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 21, 21, 21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 22, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 27, 27, 27, 27, 27, 27, 27, 27, 27, 26, 26, 26, 26, 26, 26, 26, 26, 26, 25, 25, 25, 25, 25, 25, 25, 25, 24, 24, 24, 24, 24, 24, 24, 24, 23, 23, 23, 23, 23, 23, 23, 22, 22, 22, 22, 22, 22, 22, 21, 21, 21, 21, 21, 21, 21, 20, 20, 20, 20, 20, 20, 20, 19, 19, 19, 19, 19, 19, 18, 18, 18, 18, 18, 18, 17, 17, 17, 17, 17, 17, 16, 16, 16, 16, 16, 16, 15, 15, 15, 15, 15, 15, 14, 14, 14, 14, 14, 14, 13, 13, 13, 13, 13, 12, 12, 12, 12, 12, 12, 11, 11, 11, 11, 11, 10, 10, 10, 10, 10, 9, 9, 9, 9, 9, 9, 8, 8, 8, 8, 8, 7, 7, 7, 7, 7, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0
};
static signed short cosinus32[] = {
  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 27, 27, 27, 27, 27, 27, 27, 27, 27, 26, 26, 26, 26, 26, 26, 26, 26, 26, 25, 25, 25, 25, 25, 25, 25, 25, 24, 24, 24, 24, 24, 24, 24, 24, 23, 23, 23, 23, 23, 23, 23, 22, 22, 22, 22, 22, 22, 22, 21, 21, 21, 21, 21, 21, 21, 20, 20, 20, 20, 20, 20, 20, 19, 19, 19, 19, 19, 19, 18, 18, 18, 18, 18, 18, 17, 17, 17, 17, 17, 17, 16, 16, 16, 16, 16, 16, 15, 15, 15, 15, 15, 15, 14, 14, 14, 14, 14, 14, 13, 13, 13, 13, 13, 12, 12, 12, 12, 12, 12, 11, 11, 11, 11, 11, 10, 10, 10, 10, 10, 9, 9, 9, 9, 9, 9, 8, 8, 8, 8, 8, 7, 7, 7, 7, 7, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -2, -2, -2, -2, -2, -3, -3, -3, -3, -3, -4, -4, -4, -4, -4, -5, -5, -5, -5, -5, -5, -6, -6, -6, -6, -6, -7, -7, -7, -7, -7, -8, -8, -8, -8, -8, -9, -9, -9, -9, -9, -9, -10, -10, -10, -10, -10, -11, -11, -11, -11, -11, -12, -12, -12, -12, -12, -12, -13, -13, -13, -13, -13, -14, -14, -14, -14, -14, -14, -15, -15, -15, -15, -15, -15, -16, -16, -16, -16, -16, -16, -17, -17, -17, -17, -17, -17, -18, -18, -18, -18, -18, -18, -19, -19, -19, -19, -19, -19, -20, -20, -20, -20, -20, -20, -20, -21, -21, -21, -21, -21, -21, -21, -22, -22, -22, -22, -22, -22, -22, -23, -23, -23, -23, -23, -23, -23, -24, -24, -24, -24, -24, -24, -24, -24, -25, -25, -25, -25, -25, -25, -25, -25, -26, -26, -26, -26, -26, -26, -26, -26, -26, -27, -27, -27, -27, -27, -27, -27, -27, -27, -28, -28, -28, -28, -28, -28, -28, -28, -28, -28, -28, -29, -29, -29, -29, -29, -29, -29, -29, -29, -29, -29, -29, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -31, -31, -31, -31, -31, -31, -31, -31, -31, -31, -31, -31, -31, -31, -31, -31, -31, -31, -31, -31, -31, -31, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32, -32
};

static void create_checkboard(void) {
  // Pointer the are where the wait and move are generated.
  UWORD *copperptr = end_of_checkerboard;  //coplist + sizeof(coplist_data)/sizeof(UWORD);
  
  int stepspersquare = 32;
  int FOVScale=56;
  int ZStart=36*FOVScale;
  int ChessH=128;
  int ZStep=FOVScale*stepspersquare;
  int ZScale=ZStart*128;

  chessz -= 3;
  if(chessz < 0) {
    chessz += 32;
    if(++chesscolorptr > &chess_colors[0] + sizeof(chess_colors)/sizeof(UWORD)/2) {
      chesscolorptr = &chess_colors[0];
    }
  }
  unsigned int d3 = chessz * FOVScale + ZStart;
  for(int i = 0; i < 17; ++i) {
    unsigned int d0 = ZScale;
    d0 /= d3;
    d0 += chesstopY;
    copperptr -= 6;
    copperptr[0] = ((d0 & 0xff) << 8) | 0x7;
    copperptr[3] = chesscolorptr[2*i];
    copperptr[5] = chesscolorptr[2*i + 1];
    d3 += ZStep;
  }
}

static void init_copper(UBYTE *bplptr) {
  int i;
  ULONG *ptr;
  UWORD *wordptr;

  //Allocate enough space for large copperlist.
  coplist = circalloc(sizeof(coplist_data) + (200+4) * 4);
  memcpy(coplist, coplist_data, sizeof(coplist_data));
  // Now set the bitplane pointers (must be at the beginning).
  coplist[1] = (ULONG)bplptr >> 16;
  coplist[3] = (ULONG)bplptr & 0xFFFF;
  ptr = (ULONG*)(coplist + sizeof(coplist_data)/sizeof(UWORD)); // Point to end of copied data.
  for(int i = 0; i < 10; ++i) {
    // Fill with copper NOP.
    *ptr++ = 0x01feEAEAUL;
  }
  //From here on use words
  wordptr = (UWORD*)ptr;
  *wordptr++ = (chesstopY << 8) | 0x7;
  *wordptr++ = 0xfffe;
  *wordptr++ = 0x180;
  *wordptr++ = 0;
  *wordptr++ = 0x182;
  *wordptr++ = 0xfff;
  for(i = 0; i < 17; ++i) {
    *wordptr++ = ((chesstopY + 1 + i*8) << 8) | 7;
    *wordptr++ = 0xfffe;
    if(i & 1) {
      *wordptr++ = 0x182;
      *wordptr++ = 0;
      *wordptr++ = 0x180;
      *wordptr++ = 0xfff;
    } else {
      *wordptr++ = 0x180;
      *wordptr++ = 0;
      *wordptr++ = 0x182;
      *wordptr++ = 0xfff;
    }
  }
  end_of_checkerboard = wordptr;
  // Wait for last line
  *wordptr++ = 0xff03;
  *wordptr++ = 0xfffe;
  // Turn black.
  *wordptr++ = 0x180;
  *wordptr++ = 0;
  *wordptr++ = 0x182;
  *wordptr++ = 0;
  *wordptr++ = 0x008a; // COPJMP2
  custom.cop1lc = (ULONG)coplist;
  custom.copjmp1 = 0;
}


static void reset_star(struct Star *star) {
  star->x = (BITPLANEWIDTH/2) << 4;
  star->y = STARS_BOTTOM_Y << 4;
  star->dx = cosinus32[xoroshiro32plusplus() >> (15 - 9 + 1)];
  star->dy = -sinus32[xoroshiro32plusplus() >> (15 - 9 + 1)];
}

static void move_stars(void) {
  int i;
  int x, y;
  struct Star *sp = stars; // Star Pointer

  for(i = 0; i < NUMSTARS; ++i) {
    // Get screen coordinates.
    x = sp->x >> 4;
    y = sp->y >> 4;
    // Clear the pixel.
    bitplaneptr[BITPLANEWIDTH/8*y + x/8] &= ~(1 << (7 - (x & 7)));
    // Next position
    sp->x += sp->dx;
    sp->y += sp->dy;
    if((x < 0) || (x >= BITPLANEWIDTH) || (y < 0)) {
      reset_star(sp);
    }
    // Get new screen coordinates.
    x = sp->x >> 4;
    y = sp->y >> 4;
    // Set the pixel.
    bitplaneptr[BITPLANEWIDTH/8*y + x/8] |= (1 << (7 - (x & 7)));
    // Next star...
    ++sp;
  }
}


void checkerboard_part(void) {
  int i;
  unsigned long l;

  bitplaneptr = circalloc(BITPLANEWIDTH*BITPLANEHEIGHT/8);
  stars = (struct Star *) circalloc(sizeof(struct Star) * NUMSTARS);
  //clear_bitplane(bitplaneptr, BITPLANEWIDTH/8/2, BITPLANEHEIGHT);
  inflate(bitplaneptr, image_checkerboard);
  init_copper(bitplaneptr + 160/8);
  custom.dmacon = DMAF_SETCLR /*set*/
    | DMAF_MASTER /*DMAEN*/
    | DMAF_RASTER /*BPLEN*/
    | DMAF_COPPER /*COPEN*/
    ;
  for(i = 0; i < NUMSTARS; ++i) {
    reset_star(&stars[i]);
  }
  for(i = 0; i < 20; ++i) {
    move_stars();
  }
  autovector[0x308/4] = (ULONG)&create_checkboard;
  autovector[0x30c/4] = (ULONG)&move_stars;
  wait_songposition(8, 0);
  autovector[0x308/4] = 0;
  autovector[0x30c/4] = 0;
}


