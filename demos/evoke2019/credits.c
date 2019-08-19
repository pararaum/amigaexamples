#include <string.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <hardware/intbits.h>
#include "circallator.h"
#include "inflate.h"
#include "music.h"
#include "textmonochrome.h"
#include "starwarsscroll.h"
#include "tools.h"
#include "credits.barebone.h"
#include "evoke2019.h"

/*
 * Simple Logo (Only Amiga with ball) and a star wars like scroller
 * should be ok. Bitplanes 1 and 3 are used to display the "only
 * Amiga" logo, this is then playfield one, and bitplane 2 is used as
 * a single bitplane for playfield two.
 */

#define CREDITS_COPPERLIST_SIZE 0x40a
#define CREDITSWIDTH 320
#define CREDITSHEIGHT (256 + 20)
#define CREDITSBITPLANES 2
#define CREDITSEFFECTLINE 181
#define CREDITS_SONG_SIZE 54910

typedef struct Bitplaneinformation {
  unsigned char *bitplanedata[2];
  unsigned short bplidx; //!< Bitplane Index, which bitplane to use.
  unsigned char *row_addresses[2][CREDITSHEIGHT];
} Bitplaneinformation_t;

extern volatile struct Custom custom;
extern unsigned long volatile framecounter;
extern UBYTE credits_muzak[];
extern signed char long_sinusdat[];
extern void full_sinus_scroll(__reg("a0") Bitplaneinformation_t *bplptr, __reg("a1") UWORD *src, __reg("d0") signed short row);

static UBYTE *song_memory;
static Bitplaneinformation_t credits_bitplane; // for scroller
static UBYTE *background_bitplane; // for background image
static UWORD *scroll_area; //!< This is the scroller area which will be transformed into the sinus.
static UWORD *copperpointer;

static char scrolltext[] =
  "THANK YOU FOR WATCHING T7D'S MINIDEMO "
  // 234567890123456789
  "   \001 \"ONLY AMIGA\"   \011"
  "\002 RELEASED AT THE EVOKE 2019! "
  "CREDITS:"
  "   CODE: PARARAUM   \010"
  "    GFX: PARARAUM   \010"
  "MZK: JACK BEATMASTER\010"
  "  MZK: ANCIENT '?'  \010"
  " FONT: DNS/WILDCOP  \010"
  "FNT: ARTLINE DESIGNS\010"
  "   \003   "
  "GREETINGS GO TO"
  // 234567890123456789
  "       GLOEGG       \010"
  "  KYLEARAN/CLUSTER  \010"
  "  ABYSS CONNECTION  \010"
  "      HAREKIET      \010"
  "       SISSIM       \010"
  "        COYHOT      \010"
  "      PINKAMENA     \010"
  "\002CLASSIC VIDEOGAMES RADIO,\003 "
  "LPCHIP, "
  "ZIONA, "
  "KRAXXULTIMA, "
  "BOZ, K-8BIT, "
  "LEA, "
  "SEBASTIAN L., "
  "AND EVERYBODY WE FORGOT!"
  "                        \002"
  "  THAT IS THE END!  \010"
  "\001"
  "      BYE! BYE!     \010"
  ;
static volatile char * volatile scrolltext_ptr = scrolltext;
static short int scrolltext_counter = 0;
static unsigned short int scrolltext_speed = 2;

/*! \brief Create a copperlist
 *
 * This will allocate memory and create the necessary copperlist.
 *
 * @param btplbtr ?
 * @param background background bitplane pointer
 * @param left Left side sprite
 * @param right Right side sprite
 * @return pointer to the end of the generated copperlist.
 */
static UWORD *prepare_copper(UBYTE *btplptr, UBYTE *background, UWORD *left, UWORD *right) {
  UWORD *copperlist;
  UWORD *cptr;
  UWORD *empty_sprite;
  unsigned long bytes;
  int i;

  empty_sprite = circalloc(sizeof(UWORD) * 6);
  for(i = 0; i < 6; ++i) {
    empty_sprite[i] = 0;
  }
  copperlist = circalloc(CREDITS_COPPERLIST_SIZE);
  cptr = copy_credits_copperlist(copperlist, btplptr, background);
  // Now set up the sprite pointers.
  *cptr++ = 0x120;
  *cptr++ = (ULONG)left >> 16;
  *cptr++ = 0x122;
  *cptr++ = (ULONG)left;
  *cptr++ = 0x124;
  *cptr++ = (ULONG)right >> 16;
  *cptr++ = 0x126;
  *cptr++ = (ULONG)right;
  for(i = 0x128; i < 0x140; i += 4) {
    *cptr++ = i; // MOVE to SPRxPTH
    *cptr++ = (ULONG)&empty_sprite[0] >> 16;
    *cptr++ = i + 2; // MOVE to SPRxPTL
    *cptr++ = (ULONG)&empty_sprite[0];
  }
  *cptr++ = 0x01a2; //Paletter colour 17
  *cptr++ = 0x0fff; // Sprite Colour is white
  // Lighten the grey a little.
  *cptr++ = 0xb001;
  *cptr++ = 0xFF00;
  *cptr++ = 0x0180 + 2*1;
  *cptr++ = 0x0bbb; // Make grey lighter.
  // End of Copperlist
  *cptr++ = -1; // $FFFF, FFFE
  *cptr++ = -2;
  if((cptr - copperlist) >= CREDITS_COPPERLIST_SIZE) {
    for(;;) {
      custom.color[0] = 0xf00;
      custom.color[0] = 0xff0;
    }
  }
  return copperlist;
}


static void update_copper(UBYTE *scrbplptr) {
  ULONG ptr = (ULONG)scrbplptr;

  copperpointer[1] = ptr >> 16;
  copperpointer[3] = ptr;
}

/*! \brief Draw vertical line, prepare blitter
 *
 * This function does all the one time preparations for the
 * blitter. And it will wait for the blitter, before doing it...
 *
 * \warning Do not use anything else in-between as this may result in
 * funny(?) results.
 *
 * \param bplwidth Width of the bitplane in pixels. 
 */
static void dvl_prepare_blitter(unsigned short bplwidth) {
  const int dmax = 15; // Pixels down.
  const int dmin = 0;
  unsigned short bltcon1 =
    ((0xf) << 12)
    | (1 << 6) //  slope = (4 * dmin) - (2 * dmax) is negative, we have so set the sign bit...
    | (3 << 2) // Get the octant [http://www.winnicki.net/amiga/memmap/LineMode.html]. For a line straight down, the octant is 0 (or maybe 2?).
    | 1; // Bit0 = line drawing mode.
  /* 
   * The BSH? bits in BLTCON1 define where the line pattern starts
   * (first bit). If we set this to the MSB (aka bit 15) then the line
   * pattern will start immediately. This is what we want.
   *
   * See http://www.winnicki.net/amiga/memmap/LineMode.html.
   */

  WAITBLIT;
  custom.bltapt = (void *)((4 * dmin) - (2 * dmax));
  // Prepare the blitter first word and last word masks. They have to
  // be all set in order to draw the line fully.
  custom.bltafwm = -1;
  custom.bltalwm = -1;
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
  // Bitplane width.
  custom.bltcmod = bplwidth/8;
  custom.bltdmod = bplwidth/8;
  custom.bltcon1 = bltcon1;
}


/*! \brief Clear the current creditsbitplane
 *
 * This takes the index from the data structure and clears the current
 * bitplane using the blitter.
 */
static void clear_creditsbitplane(void) {
  unsigned short int idx = credits_bitplane.bplidx;
  UBYTE *bplptr = &credits_bitplane.bitplanedata[idx][0];

  /* On an A1200 the cpu is too fast, so we start the clearing before
     the data is actually displayed. The correct way to fix this is to
     use triple buffering but I ran out of time. This wait will
     (mostly) work...
   */
  while(non_aga_chipset && (custom.vhposr < 0xdcaaU)) {
  }
  clear_bitplane(bplptr, CREDITSWIDTH/8/2, CREDITSHEIGHT);
}


static void scroll_scrarea_blitter(void) {
  WAITBLIT;
  custom.bltcon0 = 0x09f0; // AD channel, D=A logic function!
  custom.bltcon1 = 0x0000; // No B shift, normal mode.
  /* A first word mask; The first word in a line a seen by the
     blitter. */
  custom.bltafwm = -1;
  /* A last word mask */
  custom.bltalwm = -1;
  /* channel D pointer */
  custom.bltapt = scroll_area + scrolltext_speed;
  custom.bltdpt = scroll_area;
  custom.bltamod = 0; // No modulo.
  custom.bltdmod = 0;
  /* H9-H0, W5-W0; width is in words. By writing the size into the
     custom chip register the blit begins and continues while the cpu
     is still running. */
  custom.bltsize = ((CREDITSWIDTH + 16 - 1) << 6) | 1;
}


static void copy_char(void) {
  int i;
  UWORD *src;
  UWORD *dst;
  unsigned char c;

  if(--scrolltext_counter < 0) {
    scrolltext_counter = 16/scrolltext_speed - 1;
    switch(c = *scrolltext_ptr++) {
    case 0:
      // Restart the scroll text.
      scrolltext_ptr = scrolltext;
      c = ' ';
      break;
    case '\001':
      scrolltext_speed = 1;
      c = ' ';
      break;
    case '\002':
      scrolltext_speed = 2;
      c = ' ';
      break;
    case '\003':
      scrolltext_speed = 4;
      c = ' ';
      break;
    case '\010':
      // Wait just a little while...
      scrolltext_counter = -103;
      c = ' ';
      break;
    case '\011':
      // Wait just a little longer...
      scrolltext_counter = -181;
      c = ' ';
      break;
    }
    src = liberation_single_column_png + 16 * (c - ' ');
    dst = scroll_area + CREDITSWIDTH;
    for(i = 0; i < 16; ++i) {
      *dst++ = *src++;
    }
  }
}


static void scroll_up(void) {
  int len;
  UBYTE *bitplaneptr = &credits_bitplane.bitplanedata[0][0];

  dvl_prepare_blitter(CREDITSWIDTH);
  update_copper(&credits_bitplane.bitplanedata[credits_bitplane.bplidx][0]);
  full_sinus_scroll(&credits_bitplane, scroll_area, CREDITSEFFECTLINE);
  credits_bitplane.bplidx ^= 1;
  if(scrolltext_counter < 0) {
    if(++scrolltext_counter == 0) {
    }
  } else {
    copy_char();
    scroll_scrarea_blitter();
  }
}


static Bitplaneinformation_t *initialise_bplinfo(void *creditsplane0, void *creditsplane1) {
  int i;

  credits_bitplane.bitplanedata[0] = creditsplane0;
  credits_bitplane.bitplanedata[1] = creditsplane1;
  credits_bitplane.bplidx = 0;
  for(i = 0; i < CREDITSHEIGHT; ++i) {
    credits_bitplane.row_addresses[0][i] = credits_bitplane.bitplanedata[0] + i * CREDITSWIDTH/8;
    credits_bitplane.row_addresses[1][i] = credits_bitplane.bitplanedata[1] + i * CREDITSWIDTH/8;
  }
  return &credits_bitplane;
}


void build_sprites(UWORD **sprite_left, UWORD **sprite_right) {
  unsigned short datsize;
  unsigned short rows;
  UWORD *wptr;
  UWORD *dptr;
  short int i;

  rows = spritenoise2_png_end - spritenoise2_png;
  // The data there is only a single bitplane (16 pixels wide).
  datsize = sizeof(UWORD) * rows * 2;
  // Allocate the memory.
  *sprite_left = circalloc(datsize + 8);
  *sprite_right = circalloc(datsize + 8);
  // Prepare sprites; left
  (*sprite_left)[0] = 0x4040;
  (*sprite_left)[1] = 0x0100; // & (0x8000 + (rows << 8));
  wptr = &spritenoise2_png[0];
  dptr = &(*sprite_left)[2];
  for(i = 0; i < rows; ++i) {
    *dptr++ = *wptr++; // Copy bitplane data.
    *dptr++ = 0; // High word is zero.
  }
  *dptr++ = 0; //End the sprite
  *dptr++ = 0;
  // Prepare sprites; right
  (*sprite_right)[0] = 0x40d8;
  (*sprite_right)[1] = 0x0100; // & (0x3000 + (rows << 8));
  wptr = &spritenoise2_png[0];
  dptr = &(*sprite_right)[2];
  for(i = 0; i < rows; ++i) {
    *dptr++ = ~(*wptr++); // Copy bitplane data.
    *dptr++ = 0; // High word is zero.
  }
  *dptr++ = 0; //End the sprite
  *dptr++ = 0;
}


void print_text(void) {
  char *txt[] = {
    /* 456789012345678901234567890123456789 */
    "Only Amiga makes it possible!",
    "By The Seventh Division in 2019",
    "Enjoy Beer and the Retro Style",
    "~ ~~ ~~~ ^ ~~~ ~~ ~",
    "And special Greetings to all Atarians!",
    "(Do not take the flames too seriously)",
    NULL
  };
  short i = 256 - sizeof(txt)/sizeof(char *) * 9;
  char **s;
  short len;

  for(s = txt; *s; ++s, i += 9) {
    len = strlen(*s);
    text_monochrome(*s, get_font_address(), background_bitplane + i * CREDITSWIDTH/8*2 + (40 - len) / 2, 2*CREDITSWIDTH/8);
  }
}

void credits() {
  ULONG l;
  ULONG *autovector = (ULONG*)(0x0UL); //Autovector pointer
  UWORD *sprleft;
  UWORD *sprright;
  
  //credits_bitplane = circalloc(CREDITSWIDTH*CREDITSHEIGHT/8);
  initialise_bplinfo(circalloc(CREDITSWIDTH*CREDITSHEIGHT/8),
		     circalloc(CREDITSWIDTH*CREDITSHEIGHT/8));
  background_bitplane = circalloc(CREDITSWIDTH*CREDITSHEIGHT/8 * CREDITSBITPLANES);
  build_sprites(&sprleft, &sprright);
  copperpointer = prepare_copper(&credits_bitplane.bitplanedata[0][0], background_bitplane, sprleft, sprright);
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER|DMAF_BLITTER;
  clear_creditsbitplane();
  clear_bitplane(background_bitplane, CREDITSWIDTH/8/2, CREDITSHEIGHT*CREDITSBITPLANES);
  // The 16 additional words are just in case... It seems that on
  // faster speeds the buffer was overrun which caused garbage on the
  // screen. This fixes this. It should be investigated what
  // happened...
  scroll_area = circalloc(sizeof(UWORD) * (CREDITSWIDTH + 16 + 16));
  // Clear the scroll area.
  memset(scroll_area, 0, sizeof(UWORD) * (CREDITSWIDTH + 16 + 16));
  // Allocate memory for the song, take care that this is sufficiently large.
  song_memory = circalloc(CREDITS_SONG_SIZE);
  inflate(song_memory, credits_muzak);
  copy_bicolor_image(background_bitplane);
  WAITBLIT;
  custom.cop1lc = (ULONG)copperpointer;
  custom.copjmp1 = 0;
  custom.bpl1mod = 320/8; //Background image is interleaved.
  custom.bpl2mod = 0;
  // Nice fade effect...
  custom.intena = INTF_SETCLR|INTF_INTEN|INTF_VERTB;
  for(int i = 0; i <= 0xfff; i += 0x111) {
    custom.color[0] = i;
    l = framecounter;
    while(framecounter == l);
  }
  pt_InitMusic(song_memory);
  // Activate the Scroller!
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER|DMAF_BLITTER|DMAF_AUDIO|DMAF_SPRITE;
  autovector[0x300/4] = (ULONG)&scroll_up;
  autovector[0x304/4] = (ULONG)&pt_PlayMusic;
  // The clearing of the bitplane is done *after* the music. Otherwise
  // the blitter may be fast enough to clear the bitplane while it is
  // still displayed. Thankfully we have to possibility to shuffle the
  // calls a little.
  autovector[0x308/4] = (ULONG)&clear_creditsbitplane;
  print_text();
  // Wait for the End.
#ifndef NDEBUG
 loop:
#endif
  l = framecounter;
  do {
  } while((scrolltext_ptr != scrolltext) || (l + 60 > framecounter));
#ifndef NDEBUG
  goto loop;
#endif
  // Wait a little more until the scroller text has vanished.
  //for(l = framecounter + CREDITSHEIGHT + 101; framecounter < l; ) ;
  autovector[0x300/4] = 0;
  autovector[0x304/4] = 0;
  autovector[0x308/4] = 0;
  pt_StopMusic();
  custom.intena = 0x7fff;
  custom.dmacon = 0x7fff;
}
