#include <string.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include "globals.h"
#include "t7d/inflate.h"
#include "t7d/textmonochrome.h"
#include "images.h"
#include "intermezzo_text.h"

#define SINPHASEMUL 4
#define FIRST_TEXTLINE 32
#define HEIGHT_OF_DOLLAR_BILL 33 // In rows...

const char *imezzotext[] = {
  "    WHEN THE LAST TREE IS CUT DOWN,",
  "         THE LAST  FISH EATEN,",
  "     AND THE LAST STREAM POISONED,",
  "         YOU WILL REALIZE THAT",
  "         YOU CANNOT EAT MONEY!",
};

/*
 * Intermezzo: "When the Last Tree Is Cut Down, the Last Fish Eaten,
 * and the Last Stream Poisoned, You Will Realize That You Cannot
 * Eat Money" As text screen and Flexible Line Distance? Counting
 * Characters? Textscreen with HAM-Effect?
 */

// ghci:
/* let angles = [i/31.0*pi*2 | i <- [0..31]] */
/* let sinus = map ((+) 3 . (*) 3 . sin) angles */
/* putStrLn $ intercalate ", " $ map (show . round) sinus */

static short sinustab[] = {
3, 4, 4, 5, 5, 6, 6, 6, 6, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 2, 2, 3
};
static short sinphase = 0;


static UWORD *make_wobble_copper(UWORD *coplst) {
  int i, myrow;
  int sinidx = sinphase / SINPHASEMUL;
  int nrow; //!< next row
  
  for(i = 0, nrow = 0; i < 185; ++i) {
    myrow = i + FIRST_TEXTLINE + 0x2c - 4;
    if(myrow == 0x100) {
      *coplst++ = 0xFFDF;
      *coplst++ = 0xFFFE;
    }
    *coplst++ = (myrow << 8) | 0x00C9; /* WAIT */
    *coplst++ = 0xFFFE;
    *coplst++ = 0x0102; /* MOVE BPLCON1 */
    // Move the even playfield.
    *coplst++ = sinustab[sinidx] << 4;
    //*coplst++ = 0x0108; /* MOVE BPL1MOD */
    *coplst++ = 0x010a; /* MOVE BPL2MOD */
    if(i < nrow) {
      *coplst++ = -320/8;
    } else {
      *coplst++ = 0;
      nrow += sinustab[sinidx];
      if(++sinidx >= sizeof(sinustab)/sizeof(short)) {
	sinidx = 0;
      }
    }
  }
  return coplst;
}


UWORD *make_copper_bplptrs(UWORD *coplst, UBYTE *even, UBYTE *odd) {
  UBYTE *bplptr;

  bplptr = odd;
  *coplst++ = 0x00e4;
  *coplst++ = ((ULONG)bplptr) >> 16;
  *coplst++ = 0x00e6;
  *coplst++ = (ULONG)bplptr;
  bplptr = even;
  *coplst++ = 0x00e0;
  *coplst++ = ((ULONG)bplptr) >> 16;
  *coplst++ = 0x00e2;
  *coplst++ = (ULONG)bplptr;
  bplptr = even + 320/8;
  *coplst++ = 0x00e8;
  *coplst++ = ((ULONG)bplptr) >> 16;
  *coplst++ = 0x00ea;
  *coplst++ = (ULONG)bplptr;
  return coplst;
}

void prepare_intermezzo_text(IntermezzoText_t *imezzo) {
  UBYTE *bplptr;
  int i;
  UWORD *coplst = &imezzo->copperlist[0];
  UBYTE *font = &imezzo->font[0];

  bplptr = &imezzo->bitplane[0];
  imezzo->bitplane_offset = 0;
  memset(&imezzo->bitplane[0], 0, sizeof(imezzo->bitplane));
  inflate(&imezzo->font[0], &futurewriter_font[0]);
  inflate(&imezzo->background[0], &dollarbackground[0]);
  for(i = 0; i < sizeof(imezzotext)/sizeof(const char *); ++i) {
    text_monochrome(imezzotext[i], font, bplptr + FIRST_TEXTLINE * 320/8 + 12 * 320/8 * i, 320/8);
  }
  coplst = make_copper_bplptrs(coplst, &imezzo->background[0], bplptr);
  *coplst++ = 0x100; // BPLCON0
  *coplst++ = 0x3600; // Three bitplanes, dual playfield
  *coplst++ = 0x108; // BPL1MOD
  *coplst++ = 320/8; // two bitplanes interleaved
  imezzo->copperlist_wabble = coplst;
  coplst = make_wobble_copper(coplst);
  /* *coplst++ = 0x0180; */
  /* *coplst++ = (i & 1) == 0 ? 0x0f0 : 0x00f; */
  *coplst++ = 0x010a; /* MOVE BPL2MOD */
  *coplst++ = 0;
  *coplst++ = 0xFFFF;
  *coplst++ = 0xFFFE;
#ifndef NDEBUG
  if(coplst > imezzo->copperlist + sizeof(imezzo->copperlist)) {
    do {
      custom.color[0] = 0xff0;
      custom.color[0] = 0xf00;
    } while(1);
  }
#endif
  //  *((long*)0x3fc) = coplst - &imezzo->copperlist[0];
}


void init_intermezzo_text(IntermezzoText_t *imezzo) {
  int i;
  static UWORD colours_odd[] = {
    0x0776,
    0x0999,
    0x0bba,
    0x0edc,
  };
  
  custom.cop1lc = (ULONG)&imezzo->copperlist[0];
  custom.copjmp1 = 0; /* Make copper jump! */
  custom.bplcon0 = 0x1200; /* 1 bitplane, colour burst */
  custom.bplcon2 = 1<<6; // Even has priority over odd.
  for(i = 0; i < 4; ++i) {
    custom.color[i] = colours_odd[i];
  }
  // Foreground for even bitplanes aka. dual playfield bitplane in front.
  custom.color[9] = 0x510;
}


void intermezzo_irq_routine(IntermezzoText_t *imezzo) {
  UWORD *coplst;
  UBYTE *bplptr;

  bplptr = &imezzo->background[0];
  bplptr += imezzo->bitplane_offset;
  make_copper_bplptrs(&imezzo->copperlist[0], bplptr, &imezzo->bitplane[0]);
  coplst = imezzo->copperlist_wabble;
  coplst = make_wobble_copper(coplst);
  *coplst++ = 0x010a; /* MOVE BPL2MOD */
  *coplst++ = 0;
  *coplst++ = 0xFFFF;
  *coplst++ = 0xFFFE;
  if(++sinphase >= SINPHASEMUL * sizeof(sinustab)/sizeof(short)) {
    sinphase = 0;
  }
  imezzo->bitplane_offset += 320/8*2; // Next line
  if(imezzo->bitplane_offset >= 320/8*2*HEIGHT_OF_DOLLAR_BILL) {
    imezzo->bitplane_offset = 0;
  }
}
