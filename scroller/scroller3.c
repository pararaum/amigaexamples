#include <stdio.h>
#include <hardware/custom.h>

/*
 * This scroller will have sound and a logo. The logo will occupy the
 * first 160 lines and the scroller will start at raster line 180.
 *
 * The scroller will use a space of (+ 320 32) = 352 pixels so the the
 * blitter can be used for scrolling with the effect that the
 * character is copied every 32 scrolls and then it is possible to see
 * the character appearing in the blank space.
 */

#include "logo.c"
#include "pompey.c"
#include "../data/font/demo_maker_a.c"
#define SCROLLER_FONT_WIDTH pompey_xpm_width
#define SCROLLER_FONT_HEIGHT pompey_xpm_width
#define SCROLLER_AREA_WIDTH (320 + SCROLLER_FONT_WIDTH)
#define SCROLLER_RASTERLINE 0x109
#define TEXTAREA_RASTERLINE 0xd9
#define TEXTAREA_HEIGHT (48 + 8 + 1)

extern void init_framework(__reg("a0") unsigned char *fontptr, __reg("a1") unsigned char *bitplaneptr);
extern void shutdown_framework(void);
extern void wait_for_mouse(void);
extern void text_monochrome(char __reg("a0") *text, unsigned char __reg("a1") *font, unsigned char __reg("a2") *target, unsigned int __reg("d0") modulo);
extern void fade_rasterbars(unsigned short __reg("a0") *rasterbarptr);
extern struct Custom custom;


/*! \brief scroller text to display
 *
 * This is the text which is displayed using the scroller.
 */
static const char *scroller_text = "This is a scroller with a 32x32 colour(!) font...   Greetings go to: Jack Beatmaster, Meepster, Roz, Strobo, zake, Paul Holt, Tez, Sebastian L., Kylearan of Cluster, Abyss Connection, CoyHot, Pinkamena, Classic Videogames RADIO.                  ";
static const char *scroller_text_pointer;

static const char *textarea_text[] = {
  /* 4567890123456789012345678901234567|90 */
  "Scroller Minidemo III",
  "Brought to you by T7D",
  "---------------------",
  "",
  "Code:  Pararaum",
  "Muzak: Jack Beatmaster",
  "Big Font: WildCop",
  "Small Font: ?",
  "",
  "",
  "I always hated it when demos had more",
  "than one scroller. It is so hard to",
  "read...",
  "Here you go... Now I am doing exactly",
  "the same thing. Enjoy!",
  "",
  "Just filling up the text area with",
  "some statistics:",
  " * ca. 500 lines of C code",
  " * ca. 150 lines of assembler code",
  "",
  "Visit:",
  "https://github.com/",
  "              pararaum/amigaexamples",
  "",
  "",
  NULL
};
static char **textarea_text_pointer = textarea_text;

/*! \brief frame counter
 */
static unsigned long int frame_counter = 0;

/* Maximal raster line used: */
static unsigned short max_rasterline_number = 0;

/* Pointer to the wait for the rasterbar */
static UWORD *rasterbar;
/*
 * Here we store the rasterbar line-position. The position is left
 * shifted by CURRENT_RASTBARPOSSHIFT bits so that we can have more
 * fine-grained movement.
 */
static struct {
  signed short red;
  signed short green;
  signed short blue;
} current_rastbarline = {
  0, 0, 0
};
#define CURRENT_RASTBARPOSSHIFT 7

static UWORD __chip coplist[] = {
  /* Bitplane pointers for 4 bitplanes: the logo*/
  0x00e0, 0, 0x00e2, 0,
  0x00e4, 0, 0x00e6, 0,
  0x00e8, 0, 0x00ea, 0,
  0x00ec, 0, 0x00ee, 0,
  /* We have four bitplanes and need to skip that many lines. And then
     half a screen as the image is 640 pixels wide but we do display
     only the first 320. */
  0x0108, (logo_xpm_width * (logo_xpm_bitplanes - 1) + logo_xpm_width / 2) / 8, /* BPL1MOD: odd planes */
  0x010A, (logo_xpm_width * (logo_xpm_bitplanes - 1) + logo_xpm_width / 2) / 8, /* BPL2MOD: even planes */
  0x0100, 0x4200, /* BPLCON0: four bitplanes and COLOR (enable composition) */
  /* Colour registers */
  0x0180, 0x0fff,
  0x0182, 0x0000,
  0x01fe, 0, /* Copper NO-OP, will be filled by init copper routine. */
  0x01fe, 0,
  0x01fe, 0,
  0x01fe, 0,
  0x01fe, 0,
  0x01fe, 0,
  0x01fe, 0,
  0x01fe, 0,
  0x01fe, 0,
  0x01fe, 0,
  0x01fe, 0,
  0x01fe, 0,
  0x01fe, 0,
  0x01fe, 0,
  /* ################################################################## */
  0x2b8d, 0xfffe,	/* Wait for specific raster line. Top of
			   Screen (somewhere in the middle). */
  0x009c, 0x8004,	/* INTREQ: set SOFT interrupt */
  /* ################################################################## */
  /* Rasterbars! */
  0x2d07, 0xfffe,
  0x0180, 0x0fff,
  0x2e07, 0xfffe,
  0x0180, 0x0000,
  0x2f07, 0xfffe,
  0x0180, 0x0fff,
  0x3007, 0xfffe,
  0x0180, 0x0000,
  0x3107, 0xfffe,
  0x0180, 0x0fff,
  0x3207, 0xfffe,
  0x0180, 0x0000,
  0x3307, 0xfffe,
  0x0180, 0x0fff,
  0x3407, 0xfffe,
  0x0180, 0x0000,
  0x3507, 0xfffe,
  0x0180, 0x0fff,
  0x3607, 0xfffe,
  0x0180, 0x0000,
  0x3707, 0xfffe,
  0x0180, 0x0fff,
  0x3807, 0xfffe,
  0x0180, 0x0000,
  0x3907, 0xfffe,
  0x0180, 0x0fff,
  0x3a07, 0xfffe,
  0x0180, 0x0000,
  0x3b07, 0xfffe,
  0x0180, 0x0fff,
  0x3c07, 0xfffe,
  0x0180, 0x0000,
  0x3d07, 0xfffe,
  0x0180, 0x0fff,
  0x3e07, 0xfffe,
  0x0180, 0x0000,
  0x3f07, 0xfffe,
  0x0180, 0x0fff,
  0x4007, 0xfffe,
  0x0180, 0x0000,
  0x4107, 0xfffe,
  0x0180, 0x0fff,
  0x4207, 0xfffe,
  0x0180, 0x0000,
  0x4307, 0xfffe,
  0x0180, 0x0fff,
  0x4407, 0xfffe,
  0x0180, 0x0000,
  0x4507, 0xfffe,
  0x0180, 0x0fff,
  0x4607, 0xfffe,
  0x0180, 0x0000,
  0x4707, 0xfffe,
  0x0180, 0x0fff,
  0x4807, 0xfffe,
  0x0180, 0x0000,
  0x4907, 0xfffe,
  0x0180, 0x0fff,
  0x4a07, 0xfffe,
  0x0180, 0x0000,
  0x4b07, 0xfffe,
  0x0180, 0x0fff,
  0x4c07, 0xfffe,
  0x0180, 0x0000,
  0x4d07, 0xfffe,
  0x0180, 0x0fff,
  0x4e07, 0xfffe,
  0x0180, 0x0000,
  0x4f07, 0xfffe,
  0x0180, 0x0fff,
  0x5007, 0xfffe,
  0x0180, 0x0000,
  0x5107, 0xfffe,
  0x0180, 0x0fff,
  0x5207, 0xfffe,
  0x0180, 0x0000,
  0x5307, 0xfffe,
  0x0180, 0x0fff,
  0x5407, 0xfffe,
  0x0180, 0x0000,
  0x5507, 0xfffe,
  0x0180, 0x0fff,
  0x5607, 0xfffe,
  0x0180, 0x0000,
  0x5707, 0xfffe,
  0x0180, 0x0fff,
  0x5807, 0xfffe,
  0x0180, 0x0000,
  0x5907, 0xfffe,
  0x0180, 0x0fff,
  0x5a07, 0xfffe,
  0x0180, 0x0000,
  0x5b07, 0xfffe,
  0x0180, 0x0fff,
  0x5c07, 0xfffe,
  0x0180, 0x0000,
  0x5d07, 0xfffe,
  0x0180, 0x0fff,
  0x5e07, 0xfffe,
  0x0180, 0x0000,
  0x5f07, 0xfffe,
  0x0180, 0x0fff,
  0x6007, 0xfffe,
  0x0180, 0x0000,
  0x6107, 0xfffe,
  0x0180, 0x0fff,
  0x6207, 0xfffe,
  0x0180, 0x0000,
  0x6307, 0xfffe,
  0x0180, 0x0fff,
  0x6407, 0xfffe,
  0x0180, 0x0000,
  0x6507, 0xfffe,
  0x0180, 0x0fff,
  0x6607, 0xfffe,
  0x0180, 0x0000,
  0x6707, 0xfffe,
  0x0180, 0x0fff,
  0x6807, 0xfffe,
  0x0180, 0x0000,
  0x6907, 0xfffe,
  0x0180, 0x0fff,
  0x6a07, 0xfffe,
  0x0180, 0x0000,
  0x6b07, 0xfffe,
  0x0180, 0x0fff,
  0x6c07, 0xfffe,
  0x0180, 0x0000,
  0x6d07, 0xfffe,
  0x0180, 0x0fff,
  0x6e07, 0xfffe,
  0x0180, 0x0000,
  0x6f07, 0xfffe,
  0x0180, 0x0fff,
  0x7007, 0xfffe,
  0x0180, 0x0000,
  0x7107, 0xfffe,
  0x0180, 0x0fff,
  0x7207, 0xfffe,
  0x0180, 0x0000,
  0x7307, 0xfffe,
  0x0180, 0x0fff,
  0x7407, 0xfffe,
  0x0180, 0x0000,
  0x7507, 0xfffe,
  0x0180, 0x0fff,
  0x7607, 0xfffe,
  0x0180, 0x0000,
  0x7707, 0xfffe,
  0x0180, 0x0fff,
  0x7807, 0xfffe,
  0x0180, 0x0000,
  0x7907, 0xfffe,
  0x0180, 0x0fff,
  0x7a07, 0xfffe,
  0x0180, 0x0000,
  0x7b07, 0xfffe,
  0x0180, 0x0fff,
  0x7c07, 0xfffe,
  0x0180, 0x0000,
  0x7d07, 0xfffe,
  0x0180, 0x0fff,
  0x7e07, 0xfffe,
  0x0180, 0x0000,
  0x7f07, 0xfffe,
  0x0180, 0x0fff,
  0x8007, 0xfffe,
  0x0180, 0x0000,
  0x8107, 0xfffe,
  0x0180, 0x0fff,
  0x8207, 0xfffe,
  0x0180, 0x0000,
  0x8307, 0xfffe,
  0x0180, 0x0fff,
  0x8407, 0xfffe,
  0x0180, 0x0000,
  0x8507, 0xfffe,
  0x0180, 0x0fff,
  0x8607, 0xfffe,
  0x0180, 0x0000,
  0x8707, 0xfffe,
  0x0180, 0x0fff,
  0x8807, 0xfffe,
  0x0180, 0x0000,
  0x8907, 0xfffe,
  0x0180, 0x0fff,
  0x8a07, 0xfffe,
  0x0180, 0x0000,
  0x8b07, 0xfffe,
  0x0180, 0x0fff,
  0x8c07, 0xfffe,
  0x0180, 0x0000,
  0x8d07, 0xfffe,
  0x0180, 0x0fff,
  0x8e07, 0xfffe,
  0x0180, 0x0000,
  0x8f07, 0xfffe,
  0x0180, 0x0fff,
  0x9007, 0xfffe,
  0x0180, 0x0000,
  0x9107, 0xfffe,
  0x0180, 0x0fff,
  0x9207, 0xfffe,
  0x0180, 0x0000,
  0x9307, 0xfffe,
  0x0180, 0x0fff,
  0x9407, 0xfffe,
  0x0180, 0x0000,
  0x9507, 0xfffe,
  0x0180, 0x0fff,
  0x9607, 0xfffe,
  0x0180, 0x0000,
  0x9707, 0xfffe,
  0x0180, 0x0fff,
  0x9807, 0xfffe,
  0x0180, 0x0000,
  0x9907, 0xfffe,
  0x0180, 0x0fff,
  0x9a07, 0xfffe,
  0x0180, 0x0000,
  0x9b07, 0xfffe,
  0x0180, 0x0fff,
  0x9c07, 0xfffe,
  0x0180, 0x0000,
  0x9d07, 0xfffe,
  0x0180, 0x0fff,
  0x9e07, 0xfffe,
  0x0180, 0x0000,
  0x9f07, 0xfffe,
  0x0180, 0x0fff,
  0xa007, 0xfffe,
  0x0180, 0x0000,
  0xa107, 0xfffe,
  0x0180, 0x0fff,
  0xa207, 0xfffe,
  0x0180, 0x0000,
  0xa307, 0xfffe,
  0x0180, 0x0fff,
  0xa407, 0xfffe,
  0x0180, 0x0000,
  0xa507, 0xfffe,
  0x0180, 0x0fff,
  0xa607, 0xfffe,
  0x0180, 0x0000,
  0xa707, 0xfffe,
  0x0180, 0x0fff,
  0xa807, 0xfffe,
  0x0180, 0x0000,
  0xa907, 0xfffe,
  0x0180, 0x0fff,
  0xaa07, 0xfffe,
  0x0180, 0x0000,
  0xab07, 0xfffe,
  0x0180, 0x0fff,
  0xac07, 0xfffe,
  0x0180, 0x0000,
  0xad07, 0xfffe,
  0x0180, 0x0fff,
  0xae07, 0xfffe,
  0x0180, 0x0000,
  0xaf07, 0xfffe,
  0x0180, 0x0fff,
  0xb007, 0xfffe,
  0x0180, 0x0000,
  0xb107, 0xfffe,
  0x0180, 0x0fff,
  0xb207, 0xfffe,
  0x0180, 0x0000,
  0xb307, 0xfffe,
  0x0180, 0x0fff,
  0xb407, 0xfffe,
  0x0180, 0x0000,
  0xb507, 0xfffe,
  0x0180, 0x0fff,
  0xb607, 0xfffe,
  0x0180, 0x0000,
  0xb707, 0xfffe,
  0x0180, 0x0fff,
  0xb807, 0xfffe,
  0x0180, 0x0000,
  0xb907, 0xfffe,
  0x0180, 0x0fff,
  0xba07, 0xfffe,
  0x0180, 0x0000,
  0xbb07, 0xfffe,
  0x0180, 0x0fff,
  0xbc07, 0xfffe,
  0x0180, 0x0000,
  0xbd07, 0xfffe,
  0x0180, 0x0fff,
  0xbe07, 0xfffe,
  0x0180, 0x0000,
  0xbf07, 0xfffe,
  0x0180, 0x0fff,
  0xc007, 0xfffe,
  0x0180, 0x0000,
  0xc107, 0xfffe,
  0x0180, 0x0fff,
  0xc207, 0xfffe,
  0x0180, 0x0000,
  0xc307, 0xfffe,
  0x0180, 0x0fff,
  0xc407, 0xfffe,
  0x0180, 0x0000,
  0xc507, 0xfffe,
  0x0180, 0x0fff,
  0xc607, 0xfffe,
  0x0180, 0x0000,
  0xc707, 0xfffe,
  0x0180, 0x0fff,
  0xc807, 0xfffe,
  0x0180, 0x0000,
  0xc907, 0xfffe,
  0x0180, 0x0fff,
  0xca07, 0xfffe,
  0x0180, 0x0000,
  0xcb07, 0xfffe,
  0x0180, 0x0fff,
  0xcc07, 0xfffe,
  0x0180, 0x0000,
  0xcd07, 0xfffe,
  0x0180, 0x0fff,
  0xce07, 0xfffe,
  0x0180, 0x0000,
  0xcf07, 0xfffe,
  0x0180, 0x0fff,
  0xd007, 0xfffe,
  0x0180, 0x0000,
  0xd107, 0xfffe,
  0x0180, 0x0fff,
  0xd207, 0xfffe,
  0x0180, 0x0000,
  0xd307, 0xfffe,
  0x0180, 0x0fff,
  0xd407, 0xfffe,
  0x0180, 0x0000,
  0xd507, 0xfffe,
  0x0180, 0x0fff,
  0xd607, 0xfffe,
  0x0180, 0x0000,
  /* ################################################################## */
  /* And now the text output area. */
  (TEXTAREA_RASTERLINE << 8) | 7, 0xfffe,
  0x00e0, 0, 0x00e2, 0,
  0x0100, 0x1200, /* one bitplane */
  0x0108, 0, /* BPL1MOD: odd planes */
  0x010A, 0, /* BPL2MOD: even planes */
  0x0180, 0x0000,
  0x0182, 0x0222,
  ((TEXTAREA_RASTERLINE + 1) << 8) | 7, 0xfffe,
  0x0182, 0x0454,
  ((TEXTAREA_RASTERLINE + 2) << 8) | 7, 0xfffe,
  0x0182, 0x0685,
  ((TEXTAREA_RASTERLINE + 3) << 8) | 7, 0xfffe,
  0x0182, 0x09b8,
  /* ################################################################## */
  /* Wait for rasterlines below 255, essentially enabling using them
   * in pal. See:
   *
   * - http://eab.abime.net/showthread.php?t=80874
   * - http://ada.untergrund.net/?p=boardthread&id=29#msg5672
   */
  /* ################################################################## */
#if SCROLLER_RASTERLINE > 0xff - 3
  0xffdf, 0xfffe, /* Trick, or maybe waiting for any lower X pos is possible. */
#endif
  (((SCROLLER_RASTERLINE-3) & 0xFF) << 8) | 7, 0xfffe, /* Wait for scroller line in lower area */
  0x0182, 0x0685,
  (((SCROLLER_RASTERLINE-2) & 0xFF) << 8) | 7, 0xfffe, /* Wait for scroller line in lower area */
  0x0182, 0x0454,
  (((SCROLLER_RASTERLINE-1) & 0xFF) << 8) | 7, 0xfffe, /* Wait for scroller line in lower area */
  0x0182, 0x0222,
  ((SCROLLER_RASTERLINE & 0xFF) << 8) | 7, 0xfffe, /* Wait for scroller line in lower area */
  /* Set bitplanepointers again */
  0x00e0, 0, 0x00e2, 0,
  0x00e4, 0, 0x00e6, 0,
  0x00e8, 0, 0x00ea, 0,
  0x0100, 0x3200, /* BPLCON0: one bitplane and COLOR (enable composition) */
  0x0108, (SCROLLER_AREA_WIDTH * (3-1) + SCROLLER_FONT_WIDTH) / 8, /* BPL1MOD: odd planes */
  0x010A, (SCROLLER_AREA_WIDTH * (3-1) + SCROLLER_FONT_WIDTH) / 8, /* BPL2MOD: even planes */
  /* Colour registers */
  0x0180, 0x0fff,
  0x0182, 0x0000,
  0x01fe, 0, /* Copper NO-OP, will be filled by init copper routine. */
  0x01fe, 0,
  0x01fe, 0,
  0x01fe, 0,
  0x01fe, 0,
  0x01fe, 0,
  /* Stop DMA to finish the scroller (and dispose of garbage at the end of the screen. */
  (((SCROLLER_RASTERLINE + SCROLLER_FONT_HEIGHT) & 0xFF) << 8) | 7, 0xfffe, /* Wait for scroller end line in lower area */
  0x0100, 0, /* DMA off! */
  /* ################################################################## */
  /* Now we produce the nice color shade at the bottom. */
  0x2d41, 0xfffe,
  0x0180, 0x0000,
  0x0180, 0x0101,
  0x0180, 0x0202,
  0x0180, 0x0303,
  0x0180, 0x0404,
  0x0180, 0x0505,
  0x0180, 0x0606,
  0x0180, 0x0707,
  0x0180, 0x0808,
  0x0180, 0x0909,
  0x0180, 0x0a0a,
  0x0180, 0x0b0b,
  0x0180, 0x0c0c,
  0x0180, 0x0d0d,
  0x0180, 0x0e0e,
  0x0180, 0x0f0f,
  0x2da1, 0xfffe,
  0x0180, 0x0f0f,
  0x0180, 0x0e0e,
  0x0180, 0x0d0d,
  0x0180, 0x0c0c,
  0x0180, 0x0b0b,
  0x0180, 0x0a0a,
  0x0180, 0x0909,
  0x0180, 0x0808,
  0x0180, 0x0707,
  0x0180, 0x0606,
  0x0180, 0x0505,
  0x0180, 0x0404,
  0x0180, 0x0303,
  0x0180, 0x0202,
  0x0180, 0x0101,
  0x0180, 0x0000,
  /* End Of Copper List */
  0xFFFF, 0xFFFE
};

/*
 * This is the area for the text output. Here the program will output
 * all the funny stuff...
 */
static unsigned char __chip textoutputarea[320 * TEXTAREA_HEIGHT / 8];

/* This is the scroll area which has to be 32 pixel wider as we are
   going to put the new character there. */
static unsigned char __chip bitplanedata[SCROLLER_AREA_WIDTH * pompey_xpm_bitplanes * SCROLLER_FONT_HEIGHT / 8];


/*! \brief Initialise the copper structure
 *
 * This will put the bitmap pointers and colours into the copper list.
 *
 * @param logo pointer to the logo bitmap
 * @param bitplane pointer to the lower scroller area
 * @return the copper wait instruction for the upper rasterbars
 */
UWORD *init_copper(unsigned char *logo, unsigned char *bitplane) {
  UWORD *ptr;
  UWORD wait = 0;
  UWORD *rasterbar = NULL;
  int i;
  /* This may be low for pal... */
  const int scroller_rasterline = SCROLLER_RASTERLINE & 0xFF;
  
  for(ptr = coplist; *ptr != 0xFFFF; ptr += 2) {
    if(*ptr & 1) /* WAIT */ {
      wait = *ptr >> 8;
      if(*ptr == 0x2d07) {
	/* Wait for the copper bars, store into wait pointer */
	rasterbar = ptr;
      }
    } else if(wait == 0 && *ptr == 0x00e0) /*bitplane0 pointer*/ {
      for(i = 0; i < logo_xpm_bitplanes; ++i) {
	/* logo points to the log bitplane */
	ptr[4 * i + 1] = (ULONG)logo >> 16;
	ptr[4 * i + 3] = (ULONG)logo & 0xFFFF;
	/* Skip to the next line, remember that the logo is interleaved */
	logo += logo_xpm_width / 8;
      }
    } else if(wait == scroller_rasterline && *ptr == 0x00e0) /*bitplane0 pointer*/ {
      for(i = 0; i < pompey_xpm_bitplanes; ++i) {
	ptr[4 * i + 1] = (ULONG)bitplane >> 16;
	ptr[4 * i + 3] = (ULONG)bitplane & 0xFFFF;
	/* Skip to the next line, remember that the logo is interleaved */
	bitplane += SCROLLER_AREA_WIDTH / 8;
      }
    } else if(wait == TEXTAREA_RASTERLINE && *ptr == 0x00e0) /*bitplane0 pointer*/ {
      ptr[1] = (ULONG)textoutputarea >> 16;
      ptr[3] = (ULONG)textoutputarea & 0xFFFF;
    } else if(wait == 0 && *ptr == 0x0180) {
      for(i = 0; i < sizeof(logo_xpm_palette)/sizeof(unsigned short); ++i) {
	ptr[2 * i    ] = 0x0180 + 2 * i;
	ptr[2 * i + 1] = logo_xpm_palette[i];
      }
    } else if(wait == scroller_rasterline && *ptr == 0x0180) {
      for(i = 0; i < sizeof(pompey_xpm_palette)/sizeof(unsigned short); ++i) {
	ptr[2 * i    ] = 0x0180 + 2 * i;
	ptr[2 * i + 1] = pompey_xpm_palette[i];
      }
    }
  }
  return rasterbar;
}


void textoutput(unsigned char *targetplane, unsigned short width, const char *txt) {
  int c;
  unsigned char *sptr;
  unsigned char *tptr;

  while((c = *txt++) != 0) {
    c = (c - ' ') << 3; /*Multiply by 8*/
    tptr = targetplane;
    sptr = &(demo_maker_a_pbm[c]);
    /* Now copy a single character. */
    *tptr = *sptr++;
    tptr += width;
    *tptr = *sptr++;
    tptr += width;
    *tptr = *sptr++;
    tptr += width;
    *tptr = *sptr++;
    tptr += width;
    *tptr = *sptr++;
    tptr += width;
    *tptr = *sptr++;
    tptr += width;
    *tptr = *sptr++;
    tptr += width;
    *tptr = *sptr;
    /* Advance target pointer to next character. */
    ++targetplane;
  }
  /* This was the original code... The compiled code was very
     slow... */
  /* int c; */
  /* int i; */
  /* unsigned short pos[8]; */
  /* unsigned short cpos = width; */

  /* for(i = 1; i < 8; ++i) { */
  /*   pos[i] = cpos; */
  /*   cpos += width; */
  /* } */
  /* while((c = *txt++) != 0) { */
  /*   c = (c - ' ') << 3; /\*Multiply by 8*\/ */
  /*   /\* Now copy a single character. *\/ */
  /*   targetplane[0] = demo_maker_a_pbm[c++]; */
  /*   targetplane[pos[1]] = demo_maker_a_pbm[c++]; */
  /*   targetplane[pos[2]] = demo_maker_a_pbm[c++]; */
  /*   targetplane[pos[3]] = demo_maker_a_pbm[c++]; */
  /*   targetplane[pos[4]] = demo_maker_a_pbm[c++]; */
  /*   targetplane[pos[5]] = demo_maker_a_pbm[c++]; */
  /*   targetplane[pos[6]] = demo_maker_a_pbm[c++]; */
  /*   targetplane[pos[7]] = demo_maker_a_pbm[c]; */
  /*   /\* Advance target pointer to next character. *\/ */
  /*   ++targetplane; */
  /* } */
}


void waitblit(void) {
  while(custom.dmaconr & (1 << 14)) ;
}


/*! \brief scroll a rectangle using the blitter
 *
 * Handle the scrolling, the blitter ist used. 320 Pixels are
 * scrolled. And 32 lines.
 *
 * @param bitplane lower right corner
 * @param modulo modulo in bytes for even and odd planes
 */
void scroll_rect(unsigned char *bitplane) {
  unsigned char *address = bitplane; /* + SCROLLER_AREA_WIDTH / 8 - modulo * 2;*/
  /* No modulo, we need to scroll the whole area. */
  unsigned short modulo = 0;

  waitblit();
  custom.bltcon0 = 0x29f0;
  custom.bltcon1 = 0x0002;
  /* A first word mask; The worst word in a line a seen by the
     blitter. Remember the descending mode! We will start at the end
     of the line. */
  custom.bltafwm = 0xffff;
  /* A last word mask */
  custom.bltalwm = 0x7fff;
  /* channel A pointer */
  custom.bltapt = address;
  /* channel D pointer */
  custom.bltdpt = address;
  custom.bltamod = modulo; /* Skip modulo bytes for every line */
  custom.bltdmod = modulo;
  /* H9-H0, W5-W0; width is in words. By writing the size into the
     custom chip register the blit begins and continues while the cpu
     is still running. */
  custom.bltsize = ((32 * 3) << 6) | ((SCROLLER_AREA_WIDTH/8 - modulo) / 2);
}


void scroll_textarea_upward(void) {
  unsigned char *address = textoutputarea;
  unsigned char modulo = 0;

  waitblit();
  custom.bltcon0 = 0x09f0;
  custom.bltcon1 = 0x0000;
  /* A first word mask; The worst word in a line a seen by the
     blitter. Remember the descending mode! We will start at the end
     of the line. */
  custom.bltafwm = 0xffff;
  /* A last word mask */
  custom.bltalwm = 0xffff;
  /* channel A pointer */
  custom.bltapt = address + 320/8;
  /* channel D pointer */
  custom.bltdpt = address;
  custom.bltamod = modulo; /* Skip modulo bytes for every line */
  custom.bltdmod = modulo;
  /* H9-H0, W5-W0; width is in words. By writing the size into the
     custom chip register the blit begins and continues while the cpu
     is still running. */
  custom.bltsize = ((TEXTAREA_HEIGHT * 1) << 6) | ((320/8 - modulo) / 2);
}

void pompey_putchar(char ch, unsigned char *target) {
  unsigned char *source = pompey_xpm;
  unsigned int pos;
  unsigned int x, y;

  ch = toupper(ch);
  pos = (ch - ' ') * (pompey_xpm_width / 8) * pompey_xpm_bitplanes * 32 /* lines */;
  source += pos;
  for(y = 0; y < 32 * pompey_xpm_bitplanes; ++y) {
    for(x = 0; x < pompey_xpm_width / 8; ++x) {
      /* target[x + y * SCROLLER_AREA_WIDTH / 8] = */
      /* 	source[x + y * (pompey_xpm_width / 8)]; */
      /*
       * The above was the original code but using the multiplication
       * for each byte that has to be copied is using too much cpu
       * cycles. Therefore we use pointer arithmetics and increment
       * the pointers for each line. This is much faster!
       */
      target[x] = source[x];
    }
    target += SCROLLER_AREA_WIDTH / 8;
    source += pompey_xpm_width / 8;
  }
}

/* Update the information text... */
void information_screen(void) {
  if(*textarea_text_pointer) {
    text_monochrome(*textarea_text_pointer++, demo_maker_a_pbm, textoutputarea + 320 / 8 * (TEXTAREA_HEIGHT - 8) + 1, 320/8);
  } else {
    textarea_text_pointer = textarea_text;
  }
}

/*! \brief Create nice bars
 *
 * The values for the increment are chosen to be prime numbers so that
 * the pattern does not repeat to fast. This is the cicada effect at
 * work.
 */
void create_bar(void) {
  short int crbline;

  fade_rasterbars(rasterbar);
  if(current_rastbarline.red >= 0) {
    current_rastbarline.red += 113;
    if(current_rastbarline.red > ((0xd6-0x2d - 5) << CURRENT_RASTBARPOSSHIFT)) {
      current_rastbarline.red = -current_rastbarline.red;
    }
  } else {
    current_rastbarline.red += 113;
    if(current_rastbarline.red > 0) {
      current_rastbarline.red = 0;
    }
  }
  /* Absolute value of rastbarline. */
  crbline = current_rastbarline.red >= 0 ? current_rastbarline.red : -current_rastbarline.red;
  /* Divide */
  crbline >>= CURRENT_RASTBARPOSSHIFT;
  /* Every fourth word is a colour value. */
  crbline *= 4;
  rasterbar[crbline + 3] |= 0x0f00;
  /* Now green. */
  if(current_rastbarline.green >= 0) {
    current_rastbarline.green += 127;
    if(current_rastbarline.green > ((0xd6-0x2d - 5) << CURRENT_RASTBARPOSSHIFT)) {
      current_rastbarline.green = -current_rastbarline.green;
    }
  } else {
    current_rastbarline.green += 127;
    if(current_rastbarline.green > 0) {
      current_rastbarline.green = 0;
    }
  }
  /* Absolute value of rastbarline. */
  crbline = current_rastbarline.green >= 0 ? current_rastbarline.green : -current_rastbarline.green;
  /* Divide */
  crbline >>= CURRENT_RASTBARPOSSHIFT;
  /* Every fourth word is a colour value. */
  crbline *= 4;
  rasterbar[crbline + 3] |= 0x00f0;
  /* Now blue. */
  if(current_rastbarline.blue >= 0) {
    current_rastbarline.blue += 109;
    if(current_rastbarline.blue > ((0xd6-0x2d - 5) << CURRENT_RASTBARPOSSHIFT)) {
      current_rastbarline.blue = -current_rastbarline.blue;
    }
  } else {
    current_rastbarline.blue += 109;
    if(current_rastbarline.blue > 0) {
      current_rastbarline.blue = 0;
    }
  }
  /* Absolute value of rastbarline. */
  crbline = current_rastbarline.blue >= 0 ? current_rastbarline.blue : -current_rastbarline.blue;
  /* Divide */
  crbline >>= CURRENT_RASTBARPOSSHIFT;
  /* Every fourth word is a colour value. */
  crbline *= 4;
  rasterbar[crbline + 3] |= 0x000f;
}

/*
 * This function is called by the assembler interrupt subroutine.
 *
 * For the parameters see scroller3.asm.s
 */
void do_interrupt_warp(void) {
  int i;
  int ch;
  unsigned char *bitplane;

  /* Increment a frame counter once per frame. */
  frame_counter++;
  if(frame_counter % 3 == 0) {
    scroll_textarea_upward();
  }
  /* Every n-th frame print a new character. Scrolling is done in the
     assembler routine. */
  if(frame_counter % (SCROLLER_FONT_WIDTH / 2) == 0) {
    ch = *scroller_text_pointer++;
    if(ch == 0) {
      ch = ' ';
      scroller_text_pointer = scroller_text;
    }
    /*Do character...*/
    pompey_putchar(ch, bitplanedata + 320 / 8);
  }
  /* And now do the blit. */
  scroll_rect(bitplanedata + SCROLLER_AREA_WIDTH / 8 * 32 * 3 - 2);
  /* Every 8-th frame print a line... This is done down here so that
     the blit should be finished by now. Otherwise you get tearing und
     other pleasantries. */
  if(frame_counter % (8 * 3) == 0) {
    information_screen();
  }
  create_bar();
#ifndef NDEBUG
  custom.color[0]=0x0fff;
#endif
  /* Store the largest rasterline used, ever. */
  if(custom.vhposr > max_rasterline_number) {
    max_rasterline_number = custom.vhposr;
  }
}


int main(int argc, char **argv) {
  puts("Scroller by Pararaum / T7D");
  printf("coplist = %08lX\n", (ULONG)coplist);
  printf("textoutput() = %08lX\n", (ULONG)(&textoutput));
  printf("text_monochrome() = %08lX\n", (ULONG)(&text_monochrome));
  /* Initialise scroll pointer to the beginning of the text. */
  scroller_text_pointer = scroller_text;
  rasterbar = init_copper(logo_xpm, bitplanedata);
  printf("rasterbar = %08lX\n", (ULONG)(rasterbar));
  init_framework(demo_maker_a_pbm, bitplanedata);
  waitblit();
  custom.cop1lc = (ULONG)coplist;
  custom.diwstrt = 0x2c81;
  custom.diwstop = 0x2cc1;
  custom.ddfstrt = 0x0038;
  custom.ddfstop = 0x00d0;
  custom.bplcon0 = 0x1200;
  custom.bplcon1 = 0;
  custom.bplcon2 = 0x0024;
  custom.bplcon3 = 0;
  custom.fmode = 0;
  custom.dmacon = 1<<15 /*set*/
    | 1<<9 /*DMAEN*/
    | 1<<8 /*BPLEN*/
    | 1<<7 /*COPEN*/
    | 1<<6 /*BLTEN*/
    ;
  wait_for_mouse();
  shutdown_framework();
  printf("max_rasterline_number = %04X\n", (int)max_rasterline_number);
  return 0;
}
