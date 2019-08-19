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
// Based on 3121609127_8f94cd4134_o.png.
#include "image.tune_in.inc"

#define BPLWIDTH 320
#define BPLHEIGHT 212
/* Dual-playfield mode. Playfield 1 is bitplane 0, 2. Plafield 2 is
 * bitplane 1. */
#define BPLNOS 3

#define FEEDBACKTERM 0x80000ACDUL
// Number of target positions aka number of characters.
#define NUM_TARGET_POS 12

static UWORD *coplistptr;
static UWORD coplist_data[] = {
  0x0180, 0, /* background black */
  0x0182, 0x0cbb, /* Colour 1: a light grey */
  0x0184, 0x0222,
  0x0186, 0x0565,
  0x0180 + 2 * 9, 0xff0,
  0x0180 + 2 * 10, 0xff0,
  0x0180 + 2 * 11, 0xff0,
  /* Other registers */
  0x0100, (1<<10) | 0x0200 | 0x1000 * BPLNOS, // BPLCON0, BPLNOS bitplanes, dual playfield.
  0x0102, 0, // BPLCON1
  0x0104, (1<<6), // BPLCON2: Playfield 2 priority.
  0x0108, 0, // BPL1MOD
  0x010a, 0, // BPL2MOD
  /* No end here! See init_copper(). */
  /* 0x008a, 0, // COPJMP2 */
  /* 0xFFFF, 0xFFFE */
};
static UBYTE *bitplaneptr[BPLNOS];
static unsigned long randlfsr = 1561487527UL;
static UBYTE *tune_in_chipmem;
/* Here we store the background while moving the characters of the
   tune in characters. */
static UBYTE *save_background;
static int tune_in_current_character = -1;
static int tune_in_target_pos[][2] = {
  { 80, 50 },
  { 120, 50 },
  { 160, 50 },
  { 200, 50 },
  { -1, -1 },
  { 60, 90 },
  { 100, 90 },
  { 140, 90 },
  { 180, 90 },
  { 220, 90 },
  { -1, -1 },
  { 140, 130 }
};
/*
 * In rainbow.inc we have the palette data from the image. We will
 * copy it two times into rainbow_data so that we do not have to use
 * the costly modulus operation add every line.
 */
#include "rainbow.inc"
static UWORD *rainbow_data;
static UWORD *rainbow_copper; //Pointer to the copper space for the rainbow effect.

/*! \brief Create copper rainbow effect
 *
 * This will generate a rainbow like copper effect, the colours are
 * taken from the rainbow_ilbm_palette. The parameter dpos can be used
 * to create a moving effect as the palette data is accessed via a
 * modulo.
 *
 * This function used the CPU so that it can be used in parallel to
 * the blitter (e.g. while the blitter is creating the noise effect,
 * etc.).
 * 
 * \param clp pointer to copper list (free area)
 * \param colour colour number (from 0 to 31)
 * \param dpos delta for colour
 * \return pointer after last written copper-command
 */
static UWORD *copy_rainbow(UWORD *clp, unsigned short colour, int dpos) {
  unsigned short int row;

  /* Make sure that we are within the first 255 colour words. */
  dpos = dpos % 255;
  colour = 0x180 + (colour << 1); // Adjust for custom chip register number.
  for(row = 0x2c << 8; row < (0x2c + 162) << 8; row += 0x0100) {
    *clp++ = row | 0x0007; // Wait for the line.
    *clp++ = 0xfffe; // WAIT mask.
    *clp++ = colour; // MOVE
    /*
     * dpos can be just incremented as we have copied the colour data
     * twice. Therefore we do not need to fear the wrap around.
     */
    *clp++ = rainbow_data[dpos++];
  }
  return clp;
}


static void init_copper(void) {
  UWORD *coplist;
  unsigned short ccr; // Custom chip register
  int i;

  /* Allocate memory for copperlist: 5 times two moves for the
     bitplane pointers + the rest from above. */
  coplist = circalloc(sizeof(coplist_data) + 5 * 2 * (2 + 2) + 200 * 2 * (2 + 2) + 32);
  coplistptr = coplist;
  ccr = 0xe0; // Bitplane pointer
  for(i = 0; i < BPLNOS; ++i) {
    ULONG bpladdr = (ULONG)bitplaneptr[i];
    *coplist++ = ccr;
    ccr += 2;
    *coplist++ = bpladdr >> 16;
    *coplist++ = ccr;
    ccr += 2;
    *coplist++ = bpladdr & 0xFFFF;
  }
  // Now copy the remainder of the copperlist.
  memcpy(coplist, coplist_data, sizeof(coplist_data));
  coplist += sizeof(coplist_data)/sizeof(UWORD);
  rainbow_copper = coplist; //Store position.
  coplist = copy_rainbow(coplist, 9, 0);
  *coplist = 0x008a; //COPJMP2
}


/*! \brief Blit a character from the "TUNE IN" text
 *
 * This blits a single character from the "tune in" text into the
 * target bitplane. It will use the barrel shifter to have a
 * pixel-exact positioning of the character.
 *
 * The blit is done in an OR fashion.
 *
 * \param target pointer to target bitplane
 * \param x x-position in pixels
 * \param y y-position in rows
 * \param srcc source character, from 0 to len("tune in")
 */
static void tune_in(UBYTE *target, int x, int y, int srcc) {
  int bltwidth = 48;
  unsigned short leftmask = -1;
  unsigned long rightmask = 0xFFFF0000UL;
  unsigned short ashift;

  if(x <= -16) {
    return;
  } else if(x < 0) {
    leftmask >>= -x;
    ashift = 16 + x;
    x -= 7;
  } else if(x >= BPLWIDTH) {
    return;
  } else { // X >= 0
    ashift = x & 0xF;
    if(x > BPLWIDTH - 16) {
      bltwidth -= 32;
      rightmask >>= 15 - (x - (BPLWIDTH - 15));
    } else if(x > BPLWIDTH - 32) {
      bltwidth -= 16;
      // (- 289 320 -32)
      rightmask >>= 15 - (x - (BPLWIDTH - 31));
    }
  }
  target += BPLWIDTH/8 * y; // Get line address.
  target += (x / 8); // Get word address at x position.
  target = (UBYTE*)((ULONG)target & -2);
  srcc <<= 2; // Multiply by four to get the current character.

  WAITBLIT;
  custom.bltafwm = leftmask;
  custom.bltalwm = (UWORD)rightmask;
  custom.bltapt = tune_in_chipmem + srcc;
  custom.bltbpt = target;
  custom.bltdpt = target;
  custom.bltamod = (image_tune_in_png_width - bltwidth) / 8;
  custom.bltbmod = (BPLWIDTH - bltwidth) / 8;
  custom.bltdmod = (BPLWIDTH - bltwidth) / 8;
  custom.bltcon1 = 0;
  //custom.bltcon0 = 0x9f0 | (ashift << 12); // D = A, with shift
  /*
   * Common terms are given in
   * http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node011D.html.
   */
  custom.bltcon0 = 0xdfc | (ashift << 12); // D = A + B, with shift
  /*
   * Width is three words and height is 32 rows.
   */
  custom.bltsize = (32 << 6) | (bltwidth / 16);
}


/*! \brief Store the background.
 *
 * While moving the characters the background must be stored to be
 * restored later.
 *
 * \param source pointer to the source bitplane
 * \param x x-position
 * \param y y-position
 */
static void store_tune_in(UBYTE *source, int x, int y) {
  const int bltwidth = 48;

  source += BPLWIDTH/8 * y; // Get line address.
  source += (x / 8) & (-2); // Get word address at x position.
  WAITBLIT;
  custom.bltafwm = -1; // First word mask.
  custom.bltalwm = -1;
  custom.bltapt = source;
  custom.bltdpt = save_background;
  custom.bltamod = (BPLWIDTH - bltwidth) / 8;
  custom.bltdmod = 0;
  custom.bltcon1 = 0;
  custom.bltcon0 = 0x09f0; // only D=A, no shift
  /*
   * Width is three words and height is 32 rows.
   */
  custom.bltsize = (32 << 6) | (bltwidth / 16);
}


static void restore_tune_in(UBYTE *target, int x, int y) {
  const int bltwidth = 48;

  target += BPLWIDTH/8 * y; // Get line address.
  target += (x / 8) & (-2); // Get word address at x position.
  WAITBLIT;
  custom.bltafwm = -1; // First word mask.
  custom.bltalwm = -1;
  custom.bltapt = save_background;
  custom.bltdpt = target;
  custom.bltamod = 0;
  custom.bltdmod = (BPLWIDTH - bltwidth) / 8;
  custom.bltcon1 = 0;
  custom.bltcon0 = 0x09f0; // D=A, no shift
  /*
   * Width is three words and height is 32 rows.
   */
  custom.bltsize = (32 << 6) | (bltwidth / 16);
}


static void clear_tune_in(UBYTE *target, int x, int y) {
  const int bltwidth = 48;

  target += BPLWIDTH/8 * y; // Get line address.
  target += (x / 8) & (-2); // Get word address at x position.
  WAITBLIT;
  custom.bltafwm = 0; // First word mask.
  custom.bltalwm = 0;
  custom.bltdpt = target;
  custom.bltdmod = (BPLWIDTH - bltwidth) / 8;
  custom.bltcon1 = 0;
  custom.bltcon0 = 0x0100; // only D, no shift
  /*
   * Width is three words and height is 32 rows.
   */
  custom.bltsize = (32 << 6) | (bltwidth / 16);
}


static void blit_da_noise(void) {
  /* As we are using dual playfield we are going to produce the noise
     effect on the even bitplanes. */
  int bitbplno = (framecounter & 1) == 0 ? 0 : 2;
  
  WAITBLIT;
  custom.bltafwm = -1;
  custom.bltalwm = -1;
  custom.bltapt = bitplaneptr[bitbplno];
  custom.bltdpt = bitplaneptr[bitbplno];
  custom.bltamod = 0;
  custom.bltdmod = 0;
  custom.bltcon1 = 0x10;
  custom.bltcon0 = 0x9f0;
  /*
   * Width is (all bits cleared) is 1024 pixels. Therefore we have to
   * fill (/ (* 320 212) 1024) 66 lines.
   */
  custom.bltsize = (BPLWIDTH * BPLHEIGHT / 1024 + 1) << 6;
  /* WAITBLIT; */
  /* custom.bltapt = bitplaneptr[1]; */
  /* custom.bltdpt = bitplaneptr[1]; */
  /* custom.bltsize = (BPLWIDTH * BPLHEIGHT / 1024 + 1) << 6; */
}


static unsigned long nextlfsr(void) {
  //http://users.ece.cmu.edu/~koopman/lfsr/32.txt
  if(randlfsr & 1) {
    randlfsr = (randlfsr >> 1) ^ FEEDBACKTERM;
  } else {
    randlfsr = (randlfsr >> 1);
  }
  return randlfsr;
}


static void fill_bitplane(UBYTE *bplptr) {
  int i;
  ULONG *bp = (ULONG *)bplptr;

  for(i = 0; i < BPLWIDTH*BPLHEIGHT/8; ++i) {
    *bp++ = nextlfsr();
  }
}


/* \brief This function is called by the assembler interrupt subroutine.
 *
 * It will first blit the moving "tune in" characters and then create
 * the noise effect with the blitter. There is enough raster time so
 * that we do not need double buffering for the character
 * movement. Nobody will see the screen update in the noise routine.
 */
static void do_interrupt_warp(void) {
  static int xpos = -1;
  static int ypos = -1;
  int xtarget, ytarget;

  if((tune_in_current_character < NUM_TARGET_POS)) {
    if(ypos < 0) {
      // We need a new character
      // First, clear the background storage.
      memset(save_background, 0, 48 / 8 * 32);
      ypos = (2 + xoroshiro32plusplus() % 194) & (-2);
      if((xoroshiro32plusplus() & 1) == 0) {
	xpos = -32;
      } else {
	xpos = 320;
      }
      ++tune_in_current_character;
    } else {
      // restore at old position
      restore_tune_in(bitplaneptr[1], xpos, ypos);
      // calculate new position
      xtarget = tune_in_target_pos[tune_in_current_character][0];
      ytarget = tune_in_target_pos[tune_in_current_character][1];
      if(xpos > xtarget) {
	xpos -= 2;
      } else if(xpos < xtarget) {
	xpos += 2;
      }
      if(ypos > ytarget) {
	ypos -= 2;
      } else if(ypos < ytarget) {
	ypos += 2;
      }
      // store at new position
      store_tune_in(bitplaneptr[1], xpos, ypos);
      // draw at new position
      tune_in(bitplaneptr[1], xpos, ypos, tune_in_current_character);
      //clear_tune_in(bitplaneptr[1], 222 + (framecounter - 1) % 100, 100);
      if((xpos == xtarget) && (ypos == ytarget)) {
	ypos = -1;
      }
      /* The character has been painted and will stay there as the
	 background is not restored. */
    }
  }
  // Last but not least: the noise effect.
  blit_da_noise();
  copy_rainbow(rainbow_copper, 9, framecounter);
#ifndef NDEBUG
  WAITBLIT;
  custom.color[0] = 0x040;
#endif
}


void atmospheric_noise_part(void) {
  int i;

  // Discard a random number...
  i = xoroshiro32plusplus();
  // Get Memory for the rainbow data.
  rainbow_data = circalloc(2 * (2 * 255));
  /* Now copy 255 words worth of RGB4 palette data. */
  memcpy(rainbow_data, &rainbow_ilbm_palette[1], 2 * 255);
  /* And copy again so that we do not have to check for overflow. */
  memcpy(rainbow_data + 255, &rainbow_ilbm_palette[1], 2 * 255);
  /* Memory to save the background into. */
  save_background = circalloc(48 / 8 * 32);
  // Done in irq: memset(save_background, 0, 48 / 8 * 32);
  // We add 128 Bytes (1024/8) in order to have a safety area for the
  // blitter fill operation. I am just to lazy to calculate the exact
  // value and we do have enough memory.
  for(i = 0; i < BPLNOS; ++i) {
    bitplaneptr[i] = circalloc(BPLWIDTH*BPLHEIGHT/8 + 1024/8);
    switch(i) {
    case 0:
    case 2:
      fill_bitplane(bitplaneptr[i]);
      break;
    default:
      custom.intena = INTF_VERTB;
      clear_bitplane(bitplaneptr[i], BPLWIDTH/8/2, BPLHEIGHT);
      custom.intena = INTF_SETCLR | INTF_VERTB;
      /* for(int k = 40; k < 400; ++k) { */
      /* 	bitplaneptr[i][k] = 0xFF; */
      /* } */
    }
  }
  init_copper();
  custom.cop1lc = (ULONG)coplistptr;
  custom.copjmp1 = 0;
  custom.dmacon = DMAF_SETCLR /*set*/
    | DMAF_MASTER /*DMAEN*/
    | DMAF_RASTER /*BPLEN*/
    | DMAF_COPPER /*COPEN*/
    | DMAF_BLITTER;
  autovector[0x308/4] = (ULONG)&do_interrupt_warp;
  tune_in_chipmem = circalloc(sizeof(image_tune_in_png));
  memcpy(tune_in_chipmem, &image_tune_in_png[0], sizeof(image_tune_in_png));
  wait_songposition(get_songposition() + 2, 0x30);
/* #ifndef NDEBUG */
/*   wait_songposition(get_songposition() + 6, 0); */
/* #endif */
  autovector[0x308/4] = 0;
}
