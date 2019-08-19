#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <hardware/intbits.h>
#include <ctype.h>
#include <string.h>
#include "circallator.h"
#include "tools.h"
#include "inflate.h"
#include "music.h"
#include "introduction.barebone.h"
#include "credits.barebone.h"
#include "textmonochrome.h"
#include "performance.h"

#define SCROLLERWIDTH 320
#define SCROLLEROUTSIDEWIDTH 32
#define SCROLLERWINDOWWIDTH (SCROLLERWIDTH+SCROLLEROUTSIDEWIDTH)
#define SCROLLERHEIGHT 32
#define PERFORMANCE_SONG_SIZE 212212

int generate_scroller_copperlist(__reg("d0") void *coplistptr, __reg("a0") void *scroller_bitplane);
void hypotrochoids_part(void);
void checkerboard_part(void);
void moire_part(void);
void vertical_bars_part(void);
void triangles_part(void);
void copperbar_part(void);
void atmospheric_noise_part();

extern volatile struct Custom custom;
extern unsigned long volatile framecounter;
extern UBYTE sentinel_font_deflated[];
extern UBYTE performance_muzak[];
static UBYTE *scroller_bitplane;
static UWORD *scroller_copperlist;
UBYTE *scroller_font;
static unsigned long next_frame_for_scroller = 0;
static const char *scroller_text = "Only Amiga makes it possible! ^ "
  "Our first one-file demo for the Amiga, programmed for the Evoke in 2019! "
  "We have prepared for you the finest old-skool effects to give you the right retro feeling... "
  "First, this is a scroller with a 32x32 colour(!) font... "
  " One thing we would like to present is multiplexed sprites called the SOBs (for sprite objects) part. Maybe we will add BOBs later... "
  "                     ";
static volatile const char *scroller_text_pointer;
static UBYTE *song_memory;

static void copy_char_cpu(int ch, UBYTE *font_, UBYTE *target_) {
  ULONG *source = (ULONG *)(font_);
  ULONG *target = (ULONG *)(target_);
  unsigned int pos;
  unsigned int y;

  ch = toupper(ch);
  // The font has to be 32 pixels wide as 32 pixels are four bytes or one long integer.
  pos = (ch - ' ') * SCROLLERBITPLANES * 32 /* 32 lines */;
  source += pos;
  for(y = 0; y < 32 * SCROLLERBITPLANES; ++y) {
    *target = *source++;
    target += SCROLLERWINDOWWIDTH/32;
  }  
}

static void blit_char(int ch, UBYTE *font, UBYTE *target) {
  unsigned int pos;

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
  /* A first word mask; The worst word in a line a seen by the
     blitter. Remember the descending mode! We will start at the end
     of the line. */
  custom.bltafwm = 0xffff;
  /* A last word mask */
  custom.bltalwm = 0xffff;
  /* channel A pointer */
  ch = toupper(ch);
  // The font has to be 32 pixels wide as 32 pixels are four bytes or one long integer.
  pos = (ch - ' ') * SCROLLERBITPLANES * 32 /* 32 lines */ * 4 /* in bytes */;
  custom.bltapt = scroller_font + pos;
  /* channel D pointer */
  custom.bltdpt = scroller_bitplane;
  custom.bltamod = 0; // Font has only a width of 32 pixels.
  /* Skip modulo bytes for every line */
  custom.bltdmod = (SCROLLERWIDTH)/8;
  /* H9-H0, W5-W0; width is in words. By writing the size into the
     custom chip register the blit begins and continues while the cpu
     is still running. */
  custom.bltsize = ((SCROLLERHEIGHT * SCROLLERBITPLANES) << 6) | ((SCROLLEROUTSIDEWIDTH/8) / 2);
}


/*! \brief scroll a rectangle using the blitter
 *
 * Handle the scrolling, the blitter ist used. 320 Pixels are
 * scrolled. And 32 lines.
 *
 * @param bitplane lower right corner
 */
static void scroll_rect(void) {
  WAITBLIT;
  custom.bltcon0 = 0x29f0;
  custom.bltcon1 = 0x0002;
  /* A first word mask; The worst word in a line a seen by the
     blitter. Remember the descending mode! We will start at the end
     of the line. */
  custom.bltafwm = 0x3fff;
  /* A last word mask */
  custom.bltalwm = 0xffff;
  /* channel A pointer */
  custom.bltapt = scroller_bitplane + (SCROLLERHEIGHT * SCROLLERBITPLANES) * SCROLLERWINDOWWIDTH/8;
  /* channel D pointer */
  custom.bltdpt = scroller_bitplane + (SCROLLERHEIGHT * SCROLLERBITPLANES) * SCROLLERWINDOWWIDTH/8;
  custom.bltamod = 0;
  custom.bltdmod = 0;
  /* H9-H0, W5-W0; width is in words. By writing the size into the
     custom chip register the blit begins and continues while the cpu
     is still running. */
  custom.bltsize = ((SCROLLERHEIGHT * SCROLLERBITPLANES) << 6) | ((SCROLLERWINDOWWIDTH/8) / 2);
}


static void scroll_in_bottom(void) {
  int ch;
  
  if(framecounter > next_frame_for_scroller) {
    next_frame_for_scroller = framecounter + 19;
    ch = *scroller_text_pointer;
    if(ch == 0) {
      ch = ' ';
      //scroller_text_pointer = scroller_text;
    } else {
      scroller_text_pointer++;
    }
    copy_char_cpu(ch, scroller_font, scroller_bitplane + 4 * 10);
  }
  scroll_rect();
}


void only_amiga_part(void) {
  UWORD *coplist;
  UBYTE *bitplane;
  UBYTE *bitplanetmp;
  int i, j;
  UWORD coplist_data[] ={
    0xe0, 0,
    0xe2, 0,
    0xe4, 0,
    0xe6, 0,
    0x180, 0xfff,
    0x182, 0x9ab,
    0x184, 0xf31,
    0x186, 0x000,
    0x100, 0x2200, // BPLCON0
    0x102, 0, // BPLCON1
    0x0108, 320/8, // BPL1MOD [http://www.winnicki.net/amiga/memmap/BPLxMOD.html]
    0x010a, 320/8, // BPL2MOD [http://www.winnicki.net/amiga/memmap/BPLxMOD.html]
    // Fade off the white.
    0xe807, 0xfffe,
    0x0180, 0xeee,
    0xe907, 0xfffe,
    0x0180, 0xddd,
    0xea07, 0xfffe,
    0x0180, 0xccc,
    0xeb07, 0xfffe,
    0x0180, 0xbbb,
    0xec07, 0xfffe,
    0x0180, 0xaaa,
    0xed07, 0xfffe,
    0x0180, 0x999,
    0xee07, 0xfffe,
    0x0180, 0x888,
    0xef07, 0xfffe,
    0x0180, 0x777,
    0xf007, 0xfffe,
    0x0180, 0x666,
    0xf107, 0xfffe,
    0x0180, 0x555,
    0xf207, 0xfffe,
    0x0180, 0x444,
    0xf307, 0xfffe,
    0x0180, 0x333,
    0xf407, 0xfffe,
    0x0180, 0x222,
    0xf507, 0xfffe,
    0x0180, 0x111,
    0xf607, 0xfffe,
    0x0180, 0x000,
    0x008a, 0, // COPJMP2
    0xFFFF, 0xFFFE // Just to be sure.
  };
  bitplane = circalloc(320*256*2/8);
  for(bitplanetmp = bitplane, i = 0; i < 2; i++) {
    //Bitplane pointer
    coplist_data[4 * i + 1] = (ULONG)bitplanetmp >> 16;
    coplist_data[4 * i + 3] = (ULONG)bitplanetmp;
    bitplanetmp += 320/8;
  }
  copy_bicolor_image(bitplane);
  coplist = circalloc(sizeof(coplist_data));
  memcpy((void*)coplist, (void*)coplist_data, sizeof(coplist_data));
  custom.cop1lc = (ULONG)coplist;
  wait_songposition(1, 0x10);
  bitplanetmp = bitplane + 320/8 * 155 * 2; // Position of further informational text.
  // This text will be grey.
  text_monochrome("Only Amiga makes it possible.", get_font_address(), bitplanetmp + 6, 320/8*2);
  wait_songposition(1, 0x11);
  // And now black.
  text_monochrome("Only Amiga makes it possible.", get_font_address(), bitplanetmp + 320/8 + 6, 320/8*2);
  wait_songposition(1, 0x1f);
  clear_bitplane(bitplanetmp, 320/8/2, 8 * 2);
  wait_songposition(1, 0x20);
  text_monochrome("It will skyrocket!", get_font_address(), bitplanetmp + 11, 320/8*2);
  wait_songposition(1, 0x21);
  text_monochrome("It will skyrocket!", get_font_address(), bitplanetmp + 320/8 + 11, 320/8*2);
  wait_songposition(1, 0x2f);
  clear_bitplane(bitplanetmp, 320/8/2, 8 * 2);
  wait_songposition(1, 0x30);
  text_monochrome("Enjoy the 100% old-school demo!", get_font_address(), bitplanetmp + 5, 320/8*2);
  wait_songposition(1, 0x31);
  text_monochrome("Enjoy the 100% old-school demo!", get_font_address(), bitplanetmp + 320/8 + 5, 320/8*2);
  for(i = 0; i <= 15; ++i) {
    wait_songposition(2, i);
    for(j = 0; j < sizeof(coplist_data)/sizeof(UWORD); j += 2 ) {
      if((coplist[j] >= 0x180) && (coplist[j] <= 0x1be)) {
	if((coplist[j + 1] & 0xF00) > 0) {
	  coplist[j + 1] -= 0x100;
	}
	if((coplist[j + 1] & 0xF0) > 0) {
	  coplist[j + 1] -= 0x10;
	}
	if((coplist[j + 1] & 0xF) > 0) {
	  coplist[j + 1] -= 0x1;
	}
      }
    }
  }
}

void performance(void) {
  unsigned long l;

  // Reset scroller text pointer to the beginning of the text.
  scroller_text_pointer = scroller_text;
  /* Enable blitter for clearing memory, etc. This will leave the
   * raster DMA enabled still showing the "Decrunching!" text.
   */
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER;
  // Allocate the memory for the scroller bitplane and copperlist.
  scroller_bitplane = circalloc(SCROLLERWINDOWWIDTH * SCROLLERHEIGHT * SCROLLERBITPLANES);
  scroller_copperlist = circalloc(generate_scroller_copperlist((void*)0, scroller_bitplane));
  clear_bitplane(scroller_bitplane, SCROLLERWINDOWWIDTH/8/2, SCROLLERHEIGHT*SCROLLERBITPLANES);
  // Allocate memory for the scroller font.
  scroller_font = circalloc(32/8*2240*4);
  // Allocate memory for the song, take care that this is sufficiently large.
  song_memory = circalloc(PERFORMANCE_SONG_SIZE);
  /*
   * At this point the memory for the scroller font, the scroller
   * bitplanes, and the music has been allocated. We now freeze the
   * circulatory memory allocator so that this memory will never be
   * overwritten. Any left-over memory is available for the effects.
   */
  circfreeze();
  // Set the second copper list to the scroller list.
  custom.cop2lc = (ULONG)scroller_copperlist;
  // Do some preparations, uncompress the data and initialise the song.
  generate_scroller_copperlist(scroller_copperlist, scroller_bitplane);
  inflate(scroller_font, sentinel_font_deflated);
  inflate(song_memory, performance_muzak);
  pt_InitMusic(song_memory);
  //Strobe copper.
  custom.copjmp1 = 0;
  // Enable DMA
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER|DMAF_AUDIO;
  // Enable Interrupts.
  custom.intena = INTF_SETCLR|INTF_INTEN|INTF_VERTB;
  autovector[0x300/4] = (ULONG)&scroll_in_bottom;
  autovector[0x304/4] = (ULONG)&pt_PlayMusic;
#ifndef NDEBUG
  goto debug;
#endif
  only_amiga_part();
  copperbar_part();
#ifndef NDEBUG
 debug:
#endif
  hypotrochoids_part();
  checkerboard_part();
  moire_part();
  vertical_bars_part();
  triangles_part();
  atmospheric_noise_part();
  /*
   * setup copper
   * init muzak 2
   * enable all
   * effect loop
   * - init next effect
   * - wait for pattern signaling begin
   * - fire up effect
   * - (set vblank function pointer)
   * - wait for pattern signaling end
   * - destroy current effect
   * boom with guru meditation()
   * stop music
   * stop irq
   */
  custom.dmacon = 0x7fff;
  custom.intena = 0x7fff;
  autovector[0x300/4] = 0;
  autovector[0x304/4] = 0;
  autovector[0x308/4] = 0;
  autovector[0x30c/4] = 0;
  pt_StopMusic();
  custom.color[0] = 0;
}
