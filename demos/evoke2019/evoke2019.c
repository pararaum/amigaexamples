#include <stdio.h>
#include <string.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <hardware/intbits.h>
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#include <exec/types.h>             /* The Amiga data types file.         */
#include <intuition/intuition.h>    /* Intuition data strucutres, etc.    */
#include <proto/exec.h>
#include <proto/intuition.h>
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#include "own.h"
#include "circallator.h"
#include "music.h"
#include "textmonochrome.h"
#include "credits.barebone.h"
#include "tools.h"
#include "iff.h"
#include "showstopper.h"
#include "evoke2019.h"

#define LIBVERSION 34 /* Kickstart 1.3 */
#define DECRUNCHCOPPERLIST_MAXSIZE 64

extern UBYTE whole_chipmem[];
extern UBYTE whole_chipmem_end[];
struct IntuitionBase *IntuitionBase = NULL;
struct BitMap *workbenchbitmap = NULL;
short non_aga_chipset;

void introduction(void);
void performance(void);
void credits(void);
void copy_endgfx_to_workbench(void *bitplaneptr);
void set_irq_routine(void (*funptr)(void));
void performance(void);
static void all_black(void);

static void prepare_decrunch(void) {
  UBYTE *scary_memory = &(workbenchbitmap->Planes[0][0]);
  UWORD *copperlist = (UWORD *)scary_memory;
  UBYTE *bitplane = scary_memory + DECRUNCHCOPPERLIST_MAXSIZE;
  const int llen = 320 / 8; /* Line length used here. */
  UWORD very_simple_copperlist[] = {
    0xe0, 0, /* Bitplane pointer */
    0xe2, 0,
    0xe4, 0,
    0xe6, 0,
    0x102, 0x0010, /* Playfield two moved one low-res pixel to the right. */
    0x180, 0x0,
    0x182, 0x0ff,
    0x184, 0x0bb,
    0x186, 0x0ff,
    0xffff, 0xfffe
  };
  int i;

  memcpy(copperlist, very_simple_copperlist, sizeof(very_simple_copperlist));
  copperlist[5] = (ULONG)bitplane >> 16;
  copperlist[7] = (ULONG)bitplane;
  copperlist[1] = (ULONG)(bitplane + llen) >> 16;
  copperlist[3] = (ULONG)(bitplane + llen);
  for(i = 0; i < llen * 257; ++i) {
    bitplane[i] = 0;
  }
  text_monochrome("Decrunching!",
		  get_font_address(),
		  bitplane + llen * 120 + 14,
		  llen);
}


static void display_decrunch(void) {
  UBYTE *scary_memory = &(workbenchbitmap->Planes[0][0]);
  UWORD *copperlist = (UWORD *)scary_memory;

  custom.cop1lc = (ULONG)copperlist;
  custom.bplcon0 = 0x2200; // Two bitplanes and colour out.
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER;
  custom.copjmp1 = 0;
}


static void entrypoint(void) {
  custom.dmacon = 0x0020; //SPrites?
#ifndef NDEBUG
  goto label;
#endif
  introduction();
  all_black();
  display_decrunch();
  circfreeall();
  performance();
  all_black();
  show_stopper();
#ifndef NDEBUG
 label:
#endif
  all_black();
  display_decrunch();
  circfreeall();
  credits();
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
  IntuitionBase = (struct IntuitionBase *)OpenLibrary("intuition.library", LIBVERSION);
  if(IntuitionBase != NULL) {
    CloseWorkBench();
    own_machine(OWN_libraries|OWN_view|OWN_trap|OWN_interrupt);
    all_black();
    circinit(whole_chipmem, whole_chipmem_end);
    /*
     * Now do a quick and dirty AGA test. See
     * http://www.winnicki.net/amiga/memmap/LISAID.html. Hopefully
     * this is working from time to time...
     */
    non_aga_chipset = (custom.deniseid != 0xffffU);
    return 0;
  }
  do {
    custom.color[0] = 0xFFF;
    custom.color[0] = 0xF00;
  } while(1);
  return -1;
}

static void clean_up_the_mess() {
  disown_machine();
  if(IntuitionBase != NULL) {
    OpenWorkBench();
    /* RemakeDisplay(); */
    CloseLibrary((struct Library *)IntuitionBase);
  }
}

/*\brief get the pointer to the workbench bitmap
 *
 * This function is a hack and it will just get the current *active*
 * screen and take the bitmap from there. This is a dangerous
 * operation and hopefully will work on the competition machine.
 */
static struct BitMap *get_wb_bitmap_pointer(void) {
  struct Screen *wbscreen;
  struct BitMap *bitmap;
  /* struct BitMap */
  /* { */
  /*     UWORD   BytesPerRow; */
  /*     UWORD   Rows; */
  /*     UBYTE   Flags; */
  /*     UBYTE   Depth; */
  /*     UWORD   pad; */
  /*     PLANEPTR Planes[8]; */
  /* }; */

  //This assumes that there only is the workbenchscreen...
  wbscreen = IntuitionBase->ActiveScreen;
  bitmap = &(wbscreen->BitMap);
  return bitmap;
}

static void copy_image_data_to_wb(void) {
  long int pos, maxpos;

  /* Only perform the copy if there are at least two planes. */
  if(workbenchbitmap->Depth >= 2) {
    // Subtract one row as the image may be interleaved and we run
    // into the problem of overwriting something important in
    // memory. This could be solved more intelligently but it is good
    // enough for now.
    maxpos = (workbenchbitmap->Rows - 1) * workbenchbitmap->BytesPerRow;
    for(pos = 0; pos < maxpos; ++pos) {
      workbenchbitmap->Planes[1][pos] = 0;
    }
    copy_endgfx_to_workbench(workbenchbitmap->Planes[0]);
  }
}


int main(int argc, char **argv) {
  ULONG saveauto[4];
  int i;

  for(i = 0; i < 4; ++i) {
    saveauto[i] = autovector[0x300/4 + i];
  }			 
  setup_amiga();
  workbenchbitmap = get_wb_bitmap_pointer();
  prepare_decrunch();
  set_irq_routine(&entrypoint);
  custom.intena = 0x7fff;
  custom.dmacon = (1<<15)|(1<<9)|(1<<6); //Reenable for wait.
  WAITBLIT;
  custom.dmacon = 0x7fff; //And disable again...
  for(i = 0; i < 4; ++i) {
    autovector[0x300/4 + i] = saveauto[i];
  }			 
  clean_up_the_mess();
  copy_image_data_to_wb();
#ifndef NDEBUG
  puts("DEBUG Version! Do *not* spread!");
  printf("IntuitionBase=$%08lX\n", (ULONG)IntuitionBase);
  printf("whole_chipmem=$%08lX\n", (ULONG)whole_chipmem);
  printf("whole_chipmem_end=$%08lX\n", (ULONG)whole_chipmem_end);
  printf("main=$%08lX\n", (ULONG)&main);
  printf("circalloc=$%08lx\n", (ULONG)&circalloc);
  printf("setup_amiga=$%08lx\n", (ULONG)&setup_amiga);
  printf("performance=$%08lX\n", (ULONG)&performance);
  printf("display_decrunch=$%08lX\n", (ULONG)&display_decrunch);
  printf("show_stopper=$%08lX\n", (ULONG)&show_stopper);
  printf("workbenchbitmap=$%08lX\n", (ULONG)workbenchbitmap);
#endif
  return 0;
}
