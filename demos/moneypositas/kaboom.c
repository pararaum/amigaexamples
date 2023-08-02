#include <string.h>
#include <hardware/dmabits.h>
#include "t7d/inflate.h"
#include "globals.h"
#include "t7d/default_irq_routine.h"
#include "t7d/xoroshiro.h"
#include "kaboom.h"
#include "images.h"
#include "pixel.h"

static UWORD copperlist_kaboom_setup[] = {
  // BPLCON0 = BPLNOS bitplanes + colour burst
  0x0100, (0x1000 * KABOOM_BPLNOS) | 0x0200,
  // Set BPLCON1 and BPLCON2 to zero.
  0x0102, 0,
  0x0104, 0,
  // Adjust modulos.
  0x0108, (KABOOM_BPLNOS - 1) * KABOOM_BPLWIDTH/8,
  0x010a, (KABOOM_BPLNOS - 1) * KABOOM_BPLWIDTH/8,
  // Make screen a little smaller at the bottom.
  // DIWSTOP [http://www.amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node002E.html].
  0x0090, 0x20c1
};

//convert_img2raw -O c -B 5 -p image.kaboom.png 
static unsigned short image_kaboom_png_palette[] = {
	0x0101,
	0x0423,
	0x0336,
	0x0444,
	0x0843,
	0x0362,
	0x0d44,
	0x0776,
	0x057c,
	0x0d72,
	0x089a,
	0x06a2,
	0x0da9,
	0x06cc,
	0x0dd5,
	0x0ded,
	0x03a2,
	0x04b3,
	0x04c4,
	0x05d5,
	0x06e6,
	0x06f7,
	0x0490,
	0x05a0,
	0x05a0,
	0x06b1,
	0x07c1,
	0x07d1,
	0x08d2,
	0x08e2,
	0x09f2,
	0x09f3,
};


/* (let (value) */
/* (dotimes (number 32 value) */
/*   (setq value */
/* 	  (concat value */
/* 		  (format "%d, " (+ 12 (* 12 (sin (* 2 pi (/ number 31.0)))))) */
/* 		  ) */
/* 	  )))*/

static int slowsinus[] = {
  12, 14, 16, 18, 20, 22, 23, 23, 23, 23, 22, 21, 19, 17, 15, 13, 10, 8, 6, 4, 2, 1, 0, 0, 0, 0, 1, 3, 5, 7, 9, 11
};


void prepare_kaboom(Kaboom_t *kaboom) {
  int i;
  UWORD *coplst;
  UBYTE *bplptr;

  memset(kaboom, 0 /*xAA*/, sizeof(Kaboom_t));
  // And now uncompress the picture.
  inflate(&kaboom->bitplanes[KABOOM_BPLWIDTH/8*KABOOM_BPLNOS * KABOOM_IMAGE_ROWSOFFSET], &image_kaboom[0]);
  coplst = &kaboom->copperlist_bpl[0];
  bplptr = &kaboom->bitplanes[0];
  for(i = 0; i < KABOOM_BPLNOS; ++i) {
    // Write NOOPs otherwise Copper may hang.
    *coplst++ = 0X01fe;
    *coplst++ = 0X01fe;
    *coplst++ = 0X01fe;
    *coplst++ = 0X01fe;
    continue;
    *coplst++ = 0X00E0 + 4 * i;
    *coplst++ = (ULONG)bplptr >> 16;
    *coplst++ = 0X00E2 + 4 * i;
    *coplst++ = (ULONG)bplptr & 0xFFFF;
    bplptr += KABOOM_BPLWIDTH/8;
  }
  // First initialise with copper noop.
  for(i = 0; i < sizeof(kaboom->copperlist_stp)/sizeof(UWORD); i += 2) {
    kaboom->copperlist_stp[i + 0] = 0x01fe; // Copper NO-OP
    kaboom->copperlist_stp[i + 1] = 0xEAEA;
  }
  // Then copy.
  memcpy(&kaboom->copperlist_stp[0], copperlist_kaboom_setup, sizeof(copperlist_kaboom_setup));
  kaboom->copperlist_fin[0] = 0xFFFF;
  kaboom->copperlist_fin[1] = 0xFFFE;
  custom.color[0] = -1;
}


void init_kaboom(Kaboom_t *kaboom) {
  int i;

  custom.cop1lc = (ULONG)&kaboom->copperlist_bpl[0];
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER|DMAF_BLITTER;
  for(i = 0; i < (1 << KABOOM_BPLNOS); ++i) {
    custom.color[i] = image_kaboom_png_palette[i];
  }
}


void irq_kaboom(Kaboom_t *kaboom) {
  int i;
  long int phase;
  UBYTE *bplptr;

  // Colour cycling.
  phase = --kaboom->colphase / 7;
  for(i = 0; i < 6; ++i) {
    custom.color[16 + i] = image_kaboom_png_palette[16 + (i + phase) % 6];
  }
  for(i = 0; i < 10; ++i) {
    custom.color[22 + i] = image_kaboom_png_palette[22 + (i + phase) % 10];
  }
  // Wobbly up and down effect.
  bplptr = &kaboom->bitplanes[0] + KABOOM_BPLWIDTH/8*KABOOM_BPLNOS * slowsinus[(kaboom->colphase/2) & 31];
  custom.bplpt[0] = bplptr;
  custom.bplpt[1] = bplptr + KABOOM_BPLWIDTH/8 * 1;
  custom.bplpt[2] = bplptr + KABOOM_BPLWIDTH/8 * 2;
  custom.bplpt[3] = bplptr + KABOOM_BPLWIDTH/8 * 3;
  custom.bplpt[4] = bplptr + KABOOM_BPLWIDTH/8 * 4;
}


static void kaboom_pixel_fill(Kaboom_t *kaboom) {
  unsigned long i;
  for(i = 0; i < 320*169; ++i) {
    int x = xoroshiro32plusplus() % KABOOM_BPLWIDTH;
    int y = xoroshiro32plusplus() % KABOOM_BPLHEIGHT;
    int col = xoroshiro32plusplus() & 0xf;
    set_pixel_320_5bpl(&(kaboom->bitplanes[0]), x, y + KABOOM_IMAGE_ROWSOFFSET, 16 + col);
  }
}


static void kaboom_fade_to_green(void) {
  int cols[32][3];
  int i, j;
  unsigned long fc;

  for(i = 0; i < 32; ++i) {
    cols[i][0] = (image_kaboom_png_palette[i] >> 8) & 0xf;
    cols[i][1] = (image_kaboom_png_palette[i] >> 4) & 0xf;
    cols[i][2] = (image_kaboom_png_palette[i]) & 0xf;
  }
  for(j = 0; j <= 16; ++j) {
    for(i = 0; i < 32; ++i) {
      int r = (cols[i][0]*(16-j) + j*0x2) / 16;
      int g = (cols[i][1]*(16-j) + j*0xf) / 16;
      int b = (cols[i][2]*(16-j) + j*0xa) / 16;
      custom.color[i] = ((r & 0xf) << 8) | ((g & 0xf) << 4) | (b & 0xf);
      image_kaboom_png_palette[i] = ((r & 0xf) << 8) | ((g & 0xf) << 4) | (b & 0xf);
    }
    for(fc = framecounter + 2; framecounter < fc; ) {}
  }
}


void kaboom_green_out(Kaboom_t *kaboom) {
  kaboom_pixel_fill(kaboom);
  kaboom_fade_to_green();
}
