#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <stdio.h>
#include <string.h>
#include "t7d/inflate.h"
#include "t7d/default_irq_routine.h"
#include "burning_earth.h"
#include "images.h"
#include "globals.h"
#include "t7d/textmonochrome.h"

extern unsigned short int 	coltopoffset;
extern unsigned short int	colbottomoffset;

extern unsigned long copperlist_burning(UWORD *dest, UBYTE *bitplanes, UBYTE *textplane);

unsigned short burning_earth_png_palette[] = {
	0x0000,
	0x0006,
	0x0013,
	0x0321,
	0x0236,
	0x0243,
	0x0641,
	0x0445,
	0x0458,
	0x0474,
	0x0873,
	0x0588,
	0x0886,
	0x088a,
	0x0a95,
	0x0ba2,
	0x0aa8,
	0x0aab,
	0x0cb6,
	0x0db3,
	0x0cb9,
	0x0ee5,
	0x0ddd,
	0x0fff,
	0x0f01,
	0x0c60,
	0x0d81,
	0x0eb2,
	0x0fd3,
	0x0ff5,
	0x0eb2,
	0x0d70,
	// Additional copy for colour cycling!
	0x0c60,
	0x0d81,
	0x0eb2,
	0x0fd3,
	0x0ff5,
	0x0eb2,
	0x0d70,
};


void prepare_burning(Burning_t *burning) {
  int i;
  UWORD *coplst = &burning->copperlist[0];
  UBYTE *bplptr = &burning->bitplanes[0];

#ifndef NDEBUG
  if(copperlist_burning(coplst, bplptr, &burning->textplane[0]) >= sizeof(burning->copperlist)) {
    // Kill the system if not enough space.
    *((long *)(3UL)) = -1;
  }
#else
  copperlist_burning(coplst, bplptr, &burning->textplane[0]);
#endif
  inflate(bplptr, &burning_earth[0]);
  inflate(&burning->font[0], &futurewriter_font[0]);
  text_monochrome("HOW DO WE SLEEP WHILE",
		  &burning->font[0],
		  &burning->textplane[0] + BURNING_WIDTH/8 * 4 + 9,
		  BURNING_WIDTH/8
		  );
  text_monochrome("OUR WORLD  IS BURNING?",
		  &burning->font[0],
		  &burning->textplane[0] + BURNING_WIDTH/8 * 20 + 9,
		  BURNING_WIDTH/8
		  );
  // This colour has to be restored at the top as it is changed in the
  // bottom of the screen.
  burning->copperlist[coltopoffset/sizeof(unsigned short int)] = burning_earth_png_palette[1];
}


void init_burning(Burning_t *burning) {
  int i;
  ULONG chunksize;

  custom.cop1lc = (ULONG)&burning->copperlist[0];
  custom.copjmp1 = 0; /* Make copper jump! */
  custom.bplcon0 = 0x5200; /* 1 bitplane, colour burst */
  custom.bplcon2 = 0;
  custom.bpl1mod = BURNING_WIDTH/8 * (BURNING_BPLNOS-1);
  custom.bpl2mod = BURNING_WIDTH/8 * (BURNING_BPLNOS-1);
  for(i = 0; i < (1 << BURNING_BPLNOS); ++i) {
    custom.color[i] = burning_earth_png_palette[i];
  }
}


void irq_burning(Burning_t *burning) {
  int i;
  int mycounter = 7 - (framecounter >> 3) % 7;

  for(i = 0; i < 7; ++i) {
    custom.color[i + 25] = burning_earth_png_palette[i + 25 + mycounter];
  }
  burning->copperlist[colbottomoffset/sizeof(unsigned short int)] = burning_earth_png_palette[25 + (framecounter / 11) % 7];
}

