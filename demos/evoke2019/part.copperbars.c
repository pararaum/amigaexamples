#include <ctype.h>
#include <string.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <hardware/intbits.h>
#include <exec/types.h>
#include "sprite_multiplexer.h"
#include "circallator.h"
#include "tools.h"
#include "introduction.barebone.h"
#include "evoke2019.h"
#include "textmonochrome.h"
#include "credits.barebone.h"
#include "performance.h"

#define BPLWIDTH 320
#define BPLHEIGHT (212*2)
#define BPLNOS 4
#define COPPERLISTSIZE (1<<13)
#define COPPERLISTBEGIN 0X30
#define COPPERSTRIPES 19

static UBYTE *bitplaneptr;
static volatile int bitplaneoffset = 0;
static UWORD *copperlists[2];
static UWORD colors[] = {
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0x111, 0x222, 0x333, 0x444, 0x555, 0x666, 0x777, 0x888, 0x999, 0xaaa, 0xbbb, 0xccc, 0xddd, 0xeee, 0xfff, 0xeee, 0xddd, 0xccc, 0xbbb, 0xaaa, 0x999, 0x888, 0x777, 0x666, 0x555, 0x444, 0x333, 0x222, 0x111, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0x100, 0x200, 0x300, 0x400, 0x500, 0x600, 0x700, 0x800, 0x900, 0xa00, 0xb00, 0xc00, 0xd00, 0xe00, 0xf00, 0xe00, 0xd00, 0xc00, 0xb00, 0xa00, 0x900, 0x800, 0x700, 0x600, 0x500, 0x400, 0x300, 0x200, 0x100, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0x101, 0x202, 0x303, 0x404, 0x505, 0x606, 0x707, 0x808, 0x909, 0xa0a, 0xb0b, 0xc0c, 0xd0d, 0xe0e, 0xf0f, 0xe0e, 0xd0d, 0xc0c, 0xb0b, 0xa0a, 0x909, 0x808, 0x707, 0x606, 0x505, 0x404, 0x303, 0x202, 0x101, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0x110, 0x220, 0x330, 0x440, 0x550, 0x660, 0x770, 0x880, 0x990, 0xaa0, 0xbb0, 0xcc0, 0xdd0, 0xee0, 0xff0, 0xee0, 0xdd0, 0xcc0, 0xbb0, 0xaa0, 0x990, 0x880, 0x770, 0x660, 0x550, 0x440, 0x330, 0x220, 0x110, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0x011, 0x022, 0x033, 0x044, 0x055, 0x066, 0x077, 0x088, 0x099, 0x0aa, 0x0bb, 0x0cc, 0x0dd, 0x0ee, 0x0ff, 0x0ee, 0x0dd, 0x0cc, 0x0bb, 0x0aa, 0x099, 0x088, 0x077, 0x066, 0x055, 0x044, 0x033, 0x022, 0x011, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0x001, 0x002, 0x003, 0x004, 0x005, 0x006, 0x007, 0x008, 0x009, 0x00a, 0x00b, 0x00c, 0x00d, 0x00e, 0x00f, 0x00e, 0x00d, 0x00c, 0x00b, 0x00a, 0x009, 0x008, 0x007, 0x006, 0x005, 0x004, 0x003, 0x002, 0x001, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0x010, 0x020, 0x030, 0x040, 0x050, 0x060, 0x070, 0x080, 0x090, 0x0a0, 0x0b0, 0x0c0, 0x0d0, 0x0e0, 0x0f0, 0x0e0, 0x0d0, 0x0c0, 0x0b0, 0x0a0, 0x090, 0x080, 0x070, 0x060, 0x050, 0x040, 0x030, 0x020, 0x010, 0,
  0
};
static unsigned int patcounter = 0;
static unsigned short copper_effect = 0;
/*
 * ghci: 
 * let as = map (+ 47) $ map (round . (* 45) . (/ 4) . asinh) [-32 .. 31]
 * as ++ reverse as
 */
static signed short asinh[] = {
  0,1,1,1,2,2,3,3,3,4,4,5,5,6,7,7,8,9,9,10,11,12,13,14,16,17,19,21,23,27,31,37,47,57,63,67,71,73,75,77,78,80,81,82,83,84,85,85,86,87,87,88,89,89,90,90,91,91,91,92,92,93,93,93,93,93,93,92,92,91,91,91,90,90,89,89,88,87,87,86,85,85,84,83,82,81,80,78,77,75,73,71,67,63,57,47,37,31,27,23,21,19,17,16,14,13,12,11,10,9,9,8,7,7,6,5,5,4,4,3,3,3,2,2,1,1,1,0
};
static volatile short asinh_gezappel = 1; //!< modify bitplane pointer in irq routine?

static void blit_char(int ch, UBYTE *font, UBYTE *target) {
  unsigned int pos;

  ch = toupper(ch);
  // The font has to be 32 pixels wide as 32 pixels are four bytes or one long integer.
  pos = (ch - ' ') * SCROLLERBITPLANES * 32 /* 32 lines */ * 4 /* in bytes */;
  /* We need the blitter! */
  custom.intena = INTF_VERTB;
  WAITBLIT;
  /* +--------------------------+---------------------------+ */
  /* | AREA MODE ("normal")     | LINE MODE (line draw)     | */
  /* +------+---------+---------+------+---------+----------+ */
  /* | BIT# | BLTCON0 | BLTCON1 | BIT# | BLTCON0 | BLTCON1  | */
  /* +------+---------+---------+------+---------+----------+ */
  /* | 15   | ASH3    | BSH3    | 15   | ASH3    | BSH3     | */
  /* | 14   | ASH2    | BSH2    | 14   | ASH2    | BSH2     | */
  /* | 13   | ASH1    | BSH1    | 13   | ASH1    | BSH1     | */
  /* | 12   | ASA0    | BSH0    | 12   | ASH0    | BSH0     | */
  /* | 11   | USEA    | 0       | 11   | 1       | 0        | */
  /* | 10   | USEB    | 0       | 10   | 0       | 0        | */
  /* | 09   | USEC    | 0       | 09   | 1       | 0        | */
  /* | 08   | USED    | 0       | 08   | 1       | 0        | */
  /* | 07   | LF7(ABC)| DOFF    | 07   | LF7(ABC)| DPFF     | */
  /* | 06   | LF6(ABc)| 0       | 06   | LF6(ABc)| SIGN     | */
  /* | 05   | LF5(AbC)| 0       | 05   | LF5(AbC)| OVF      | */
  /* | 04   | LF4(Abc)| EFE     | 04   | LF4(Abc)| SUD      | */
  /* | 03   | LF3(aBC)| IFE     | 03   | LF3(aBC)| SUL      | */
  /* | 02   | LF2(aBc)| FCI     | 02   | LF2(aBc)| AUL      | */
  /* | 01   | LF1(abC)| DESC    | 01   | LF1(abC)| SING     | */
  /* | 00   | LF0(abc)| LINE(=0)| 00   | LF0(abc)| LINE(=1) | */
  /* +------+---------+---------+------+---------+----------+ */
  custom.bltcon0 = 0x09f0;
  custom.bltcon1 = 0x0000;
  /* A first word mask; The first word in a line a seen by the
     blitter. Remember the descending mode! We will start at the end
     of the line. */
  custom.bltafwm = 0xffff;
  /* A last word mask */
  custom.bltalwm = 0xffff;
  /* channel A pointer */
  custom.bltapt = scroller_font + pos;
  /* channel D pointer */
  custom.bltdpt = target;
  custom.bltamod = 0; // Font has only a width of 32 pixels.
  /* Skip modulo bytes for every line */
  custom.bltdmod = (BPLWIDTH - 32)/8;
  /* H9-H0, W5-W0; width is in words. By writing the size into the
     custom chip register the blit begins and continues while the cpu
     is still running. */
  custom.bltsize = ((32 * SCROLLERBITPLANES) << 6) | ((32/8) / 2);
  custom.intena = INTF_SETCLR | INTF_VERTB;
}


UWORD *make_stripe(UWORD *ptr, unsigned short row, int colpos) {
  int i;
  UWORD *colptr = &colors[0] + colpos;
  UWORD col;

  /* Calculate the wait for the first row. */
  row = (row << 8);
  for(i = 0; i < 10; ++i, row += 0x0100) {
    col = *colptr++;
    switch(copper_effect) {
      //case 2:
    default:
      *ptr++ = row | 0x0007;
      *ptr++ = 0xFFFE;
      *ptr++ = 0x0180;
      *ptr++ = col;
      *ptr++ = row | 0x005f;
      *ptr++ = 0xFFFE;
      *ptr++ = 0x0180;
      *ptr++ = ~col;
      *ptr++ = row | 0x008f;
      *ptr++ = 0xFFFE;
      *ptr++ = 0x0180;
      *ptr++ = col;
      *ptr++ = row | 0x00bf;
      *ptr++ = 0xFFFE;
      *ptr++ = 0x0180;
      *ptr++ = ~col;
      break;
    case 1:
      *ptr++ = row | 0x0007;
      *ptr++ = 0xFFFE;
      *ptr++ = 0x0180;
      *ptr++ = col;
      *ptr++ = row | 0x008f;
      *ptr++ = 0xFFFE;
      *ptr++ = 0x0180;
      *ptr++ = ~col;
      break;
    case 0:
      *ptr++ = row | 0x0007;
      *ptr++ = 0xFFFE;
      *ptr++ = 0x0180;
      *ptr++ = col;
    }
  }
  return ptr;
}


static UWORD *make_copper_bplptrs(UWORD *ptr, UBYTE *bplptr) {
  int i;

  for(i = 0; i < BPLNOS; ++i) {
    *ptr++ = 0xe0 + 4 * i;
    *ptr++ = ((ULONG)bplptr + BPLWIDTH/8 * i) >> 16;
    *ptr++ = 0xe2 + 4 * i;
    *ptr++ = ((ULONG)bplptr + BPLWIDTH/8 * i) & 0xFFFF;
  }
  return ptr;
}


/*\brief Mape copperlist with jump
 *
 * Create the copperlist with colour effect.
 *
 * \param ptr pointer to the chip memory for the copper list
 * \return pointer after the last written copper instruction
 */
static UWORD *make_copperlist(UWORD *ptr) {
  static const UWORD srclist[] = {
    0x0100, 0x4200,
    0x0102, 0,
    /* 0x0108, -BPLWIDTH/8, // BPL1MOD */
    /* 0x010a, -BPLWIDTH/8, // BPL2MOD */
    0x0108, BPLWIDTH/8*(BPLNOS-1), // BPL1MOD
    0x010a, BPLWIDTH/8*(BPLNOS-1), // BPL2MOD
    0x0180, 0
  };
  int i;

  ptr = make_copper_bplptrs(ptr, bitplaneptr + bitplaneoffset);
  memcpy(ptr, &srclist[0], sizeof(srclist));
  ptr += sizeof(srclist)/sizeof(UWORD);
  for(i = 0; i < COPPERSTRIPES; ++i) {
    ptr = make_stripe(ptr, COPPERLISTBEGIN + i * 10, patcounter/2 + i);
  }
  // Wait for end of copper bars.
  *ptr++ = (COPPERLISTBEGIN + COPPERSTRIPES * 10) << 8 | 7;
  *ptr++ = 0xFFFE;
  // Turn black.
  *ptr++ = 0x180;
  *ptr++ = 0x000;
  *ptr++ = 0x008a; // COPJMP2
  return ptr;
}

static void do_interrupt_warp(void) {
  UWORD *temp;

  make_copperlist(copperlists[0]);
  custom.cop1lc = (ULONG)copperlists[0];
  temp = copperlists[0];
  copperlists[0] = copperlists[1];
  copperlists[1] = temp;
  ++patcounter;
  if(patcounter > sizeof(colors)/sizeof(UWORD)) {
    patcounter = 0;
  } else if((patcounter % (sizeof(colors)/sizeof(UWORD) / 2)) == 0) {
    ++copper_effect;
  }
  if(asinh_gezappel) {
    bitplaneoffset = (asinh[patcounter & 127]) * BPLWIDTH/8*BPLNOS;
  }
}


static UBYTE *blit_text(const char *txt, UBYTE *font, UBYTE *target) {
  while(*txt) {
    blit_char(*txt, font, target);
    ++txt;
    target += 4;
  }
  return target;
}


void copperbar_part(void) {
  bitplaneptr = circalloc(BPLWIDTH/8*BPLHEIGHT*BPLNOS);
  memset(bitplaneptr, 0, BPLWIDTH/8*BPLHEIGHT*BPLNOS);
  copperlists[0] = circalloc(COPPERLISTSIZE);
  copperlists[1] = circalloc(COPPERLISTSIZE);
#ifdef NDEBUG
  (void) make_copperlist(copperlists[0]);
#else
  copper_effect = 2;
  UWORD *debug_eocl = make_copperlist(copperlists[0]);
  copper_effect = 0;
  if(debug_eocl - copperlists[0] >= COPPERLISTSIZE) {
    for(;;) {
      custom.color[0] = 0xf00;
      custom.color[0] = 0xff0;
    }
  }
#endif
  custom.dmacon = DMAF_SETCLR /*set*/
    | DMAF_MASTER /*DMAEN*/
    | DMAF_RASTER /*BPLEN*/
    | DMAF_COPPER /*COPEN*/
    | DMAF_BLITTER;
  custom.cop1lc = (ULONG)copperlists[0];
  blit_text("Copper", scroller_font, bitplaneptr + (10 - 6)/2 * 4 + BPLNOS * BPLWIDTH / 8 * 110);
  blit_text("Bars", scroller_font, bitplaneptr + (10 - 4)/2 * 4 + BPLNOS * BPLWIDTH / 8 * 150);
  autovector[0x308/4] = (ULONG)&do_interrupt_warp;
  wait_songposition(3, 0x08);
  asinh_gezappel = 0;
  const int copper_bars_step = 3;
  for(int i = 0; i < 190; i += copper_bars_step) {
    for(unsigned long l = framecounter; framecounter < l + 1; ) {}
    //make_copper_bplptrs(copperlists[1], bitplaneptr + BPLWIDTH/8*BPLNOS * i);
    if(bitplaneoffset < BPLWIDTH/8*BPLNOS * 212) {
      bitplaneoffset += BPLWIDTH/8*BPLNOS * copper_bars_step;
    }
  }
}
