#include <stdio.h>
#include <string.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <hardware/intbits.h>
#include "own.h"
#include "xoroshiro.h"
#include "default_irq_routine.h"
//
#include "music.h"
#include "textmonochrome.h"

#define BPLWIDTH 320
#define BPLHEIGHT 256
#define BPLNOS 3
#define LIBVERSION 34 /* Kickstart 1.3 */
#define DECRUNCHCOPPERLIST_MAXSIZE 64
#define WAITBLIT while(custom.dmaconr & (1 << 14));

extern volatile struct Custom custom;
extern UBYTE whole_chipmem[];
extern UBYTE whole_chipmem_end[];
extern unsigned char __chip logo_the_7th_division_xpm[];
short non_aga_chipset;
static UWORD __chip copperlistmemory[421];
static UBYTE __chip bitplanememory[BPLWIDTH*BPLHEIGHT*BPLNOS/8];

static void prepare_decrunch(UBYTE *bitplane_odd, UBYTE *bitplane_even, UWORD *copperlist) {
  const int llen = BPLWIDTH / 8; /* Line length used here. */
  static UWORD very_simple_copperlist[] = {
    0xe0, 0, /* Bitplane pointer */
    0xe2, 0,
    0xe4, 0,
    0xe6, 0,
    0xe8, 0,
    0xea, 0,
    0x0100, 0x3200, /* BPLCON0: three bitplanes and colour burst. */
    //0x102, 0x0010, /* Playfield two moved one low-res pixel to the right. */
    //0x108, BPLWIDTH / 8, /* Two odd bitplanes, one line modulo. */
    0x10a, 0, /* Only a single even bitplane. */
    0x180, 0x211, /* 000 */
    0x182, 0x211, /* 001 */
    0x184, 0x033, /* 010 */
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
  int i;

  memcpy(copperlist, very_simple_copperlist, sizeof(very_simple_copperlist));
  copperlist[1] = (ULONG)bitplane_odd >> 16;
  copperlist[3] = (ULONG)bitplane_odd;
  copperlist[5] = (ULONG)(bitplane_even) >> 16;
  copperlist[7] = (ULONG)(bitplane_even);
  copperlist[9] = (ULONG)(bitplane_odd + llen) >> 16;
  copperlist[11] = (ULONG)(bitplane_odd + llen);
  for(i = 0; i < llen * BPLHEIGHT * 2; ++i) {
    bitplane_odd[i] = xoroshiro32plusplus();
  }
  /* text_monochrome("Decrunching!", */
  /* 		  get_font_address(), */
  /* 		  bitplane + llen * 120 + 14, */
  /* 		  llen); */
  custom.cop1lc = (ULONG)copperlist;
  custom.bplcon0 = 0x3200; // Three bitplanes and colour out.
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER;
  custom.copjmp1 = 0;
}


/*! \brief setup all black screen
 *
 * This will set up the custom registers. It will also disable DMA and
 * interrupts so that the system starts in a clean state.
 */
static void all_black(void) {
  int i;

  custom.diwstrt = 0x2c81;
  custom.diwstop = 0x2cc1;
  custom.ddfstrt = 0x0038;
  custom.ddfstop = 0x00d0;
  custom.bplcon0 = 0x0200; /* 0 bitplanes, colour burst */
  custom.bplcon1 = 0;
  custom.bplcon2 = 0;
  /* http://eab.abime.net/showthread.php?t=71661 */
  /* https://ada.untergrund.net/?p=boardthread&id=891 */
  custom.bplcon3 = 0x0c00;
  /* http://eab.abime.net/showthread.php?t=85342 and, of course,
   * http://www.winnicki.net/amiga/memmap/BPLCON4.html */
  custom.bplcon4 = 0x0011;
  /* The default is *planar* images. */
  custom.bpl1mod = 0;
  custom.bpl2mod = 0;
  custom.fmode = 0;
  /* Clear colours (set to black). */
  for(i = 0; i < 32; ++i) {
    custom.color[i] = 0;
  }
  custom.intena = 0x7fff; // Disable all interrupts.
  custom.dmacon = 0x7fff; // Disable all DMA.
}


static int setup_amiga() {
  own_machine(OWN_libraries|OWN_view|OWN_trap|OWN_interrupt);
  all_black();
  //circinit(whole_chipmem, whole_chipmem_end);
  /*
   * Now do a quick and dirty AGA test. See
   * http://www.winnicki.net/amiga/memmap/LISAID.html. Hopefully
   * this is working from time to time...
   */
  non_aga_chipset = (custom.deniseid != 0xffffU);
  return 0;
}

static void clean_up_the_mess() {
  disown_machine();
}


static void blit_da_noise(UBYTE *bitplaneptr) {
  /* As we are using dual playfield we are going to produce the noise
     effect on the even bitplanes. */
  
  WAITBLIT;
  custom.bltafwm = -1;
  custom.bltalwm = -1;
  custom.bltapt = bitplaneptr;
  custom.bltdpt = bitplaneptr;
  custom.bltamod = 0;
  custom.bltdmod = 0;
  custom.bltcon1 = 0x10;
  custom.bltcon0 = 0x9f0;
  /*
   * Width is (all bits cleared) is 1024 pixels. Therefore we have to
   * fill (/ (* 320 212) 1024) 66 lines.
   */
  custom.bltsize = (BPLWIDTH * BPLHEIGHT / 1024 + 1) << 6;
}


static void flitter_effect(void) {
  unsigned long old;

  do {
    old = framecounter;
    while(framecounter == old) {
    }
    blit_da_noise(&bitplanememory[(framecounter % 2) * BPLWIDTH * BPLHEIGHT / 8]);
  } while(1);
}


static void entrypoint(void) {
  custom.dmacon = 0x0020; //SPrites?
#ifndef NDEBUG
  goto label;
#endif
#ifndef NDEBUG
 label:
#endif
  all_black();
  prepare_decrunch(bitplanememory, &logo_the_7th_division_xpm[0], copperlistmemory);
  /* Now enable interrupts! */
  custom.intena = INTF_SETCLR|INTF_INTEN|INTF_VERTB;
  custom.dmacon = DMAF_SETCLR|DMAF_BLITTER;
  flitter_effect();
}


int main(int argc, char **argv) {
  int i;

#ifndef NDEBUG
  putchar('\f');
  printf("set_irq_routine=$%08lx\n", (ULONG)&set_irq_routine);
  printf("entrypoint=$%08lx\n", (ULONG)&entrypoint);
  puts("DEBUG Version! Do *not* spread!");
  for(i=0; i < 31991; ++i) {
    int j;
    for(j=0; j < 7; ++j) ;
  }
#endif
  setup_amiga();
  set_irq_routine(NULL, &entrypoint);
  custom.intena = 0x7fff;
  custom.dmacon = (1<<15)|(1<<9)|(1<<6); //Reenable for wait.
  //WAITBLIT;
  custom.dmacon = 0x7fff; //And disable again...
  clean_up_the_mess();
  return 0;
}
