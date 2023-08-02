#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <stdio.h>
#include <string.h>
#include "t7d/inflate.h"
#include "t7d/default_irq_routine.h"
#include "globals.h"
#include "t7d/textmonochrome.h"
#include "greetings.h"
#include "images.h"
#include "t7d/xoroshiro.h"

/* Greetings screen.
**
** Simple screen with a line saying "GREETINGS" at the top and several
** scrollers presentings all the nice people to be greeted. In the
** background we add a fire-like effect but only using cold
** colours. This is implemented using the copper.
*/

static const char *greetings[] = {
  "   ABYSS CONNECTION",
  "   GLOEGG",
  "   COYHOT",
  "   JASMIN68K",
  "   KYLEARAN",
  "   CHARLIE",
  "   PHIWA",
  "   HAREKIET",
  "   DOC.K",
  "   SISSIM",
  "   JAR",
  "   FYZIX",
  "   - -- --- -- -",
  "   XXX",
  "   CLASSIC VIDEOGAMES RADIO",
  "   FIESERWOLF",
  "   @@@@@"
};

void prepare_scrgreetings(ScrGreetings_t *scrgreetings) {
  UWORD *coplst = &scrgreetings->copperlist[0];
  int i;
  UBYTE *bplptr;

#ifndef NDEBUG
  if(copy_greetings_copperlist(coplst, &scrgreetings->bitplanes[0], SCRGREETINGS_TOPROW_PLASMA, &(scrgreetings->info)) >= sizeof(scrgreetings->copperlist)/sizeof(UWORD)) {
    // Kill the system if not enough space.
    *((long *)(3UL)) = -1;
  }
#else
  copy_greetings_copperlist(coplst, &scrgreetings->bitplanes[0], SCRGREETINGS_TOPROW_PLASMA, &(scrgreetings->info)) >= sizeof(scrgreetings->copperlist)/sizeof(UWORD);
#endif
  copy_greetings_colours(&scrgreetings->colours[0]);
  inflate(&scrgreetings->font[0], &futurewriter_font[0]);
  memset(&scrgreetings->bitplanes[0], 0, sizeof(scrgreetings->bitplanes));
#ifdef DDEBUG
  text_monochrome("HOW DO WE SLEEP WHILE",
                  &scrgreetings->font[0],
                  &scrgreetings->bitplanes[0] + SCRGREETINGS_WIDTH/8 * 40 + 9,
                  SCRGREETINGS_WIDTH/8
                  );
#endif
  for(i = 0; i < SCRGREETINGS_NUMSCROLLER; ++i) {
    bplptr = &scrgreetings->bitplanes[0];
    bplptr += SCRGREETINGS_WIDTH/8*(20 + i * 221 / SCRGREETINGS_NUMSCROLLER);
    scrgreetings->scroller[i].topline = bplptr;
    scrgreetings->scroller[i].speed = 2 + xoroshiro32plusplus() % 3;
    scrgreetings->scroller[i].pos = 8;
    scrgreetings->scroller[i].textptr = "GREETINGS FLY TO";
  }
  scrgreetings->greetingsptr = greetings;
  scrgreetings->info.rainbowpos = 0;
}


void init_scrgreetings(ScrGreetings_t *scrgreetings) {
  custom.cop1lc = (ULONG)&scrgreetings->copperlist[0];
  custom.copjmp1 = 0;
  custom.bplcon0 = 0x1200; /* 1 bitplane, colour burst */
  custom.bplcon1 = 0; /* horizontal scroll code */
  custom.bplcon2 = 0; /* playfield priorities */
  custom.bpl1mod = (SCRGREETINGS_WIDTH-320)/8;
  custom.bpl2mod = (SCRGREETINGS_WIDTH-320)/8;
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER|DMAF_RASTER|DMAF_COPPER;
  custom.color[1] = 0xfd5;
}


static void do_the_scrolling(ScrGreetings_t *scrgreetings) {
  int i;
  struct ScrollInfo *sptr = &scrgreetings->scroller[0];

  for(i = 0; i < SCRGREETINGS_NUMSCROLLER; ++i) {
    scroll_rect(sptr->topline + SCRGREETINGS_WIDTH/8*8, sptr->speed);
    sptr->pos += sptr->speed;
    if(sptr->pos > (8 + sptr->speed)) { //new char
      char_monochrome(*(sptr->textptr++),
		      SCRGREETINGS_WIDTH/8,
		      &scrgreetings->font[0],
		      sptr->topline + 40
		      );
      if(*sptr->textptr == '\0') {
	sptr->textptr = *scrgreetings->greetingsptr++;
	if(sptr->textptr[3] == '@') {
	  scrgreetings->greetingsptr = greetings;
	}
      }
      sptr->pos -= 8 + sptr->speed;
    }
    sptr++;
  }
}


void irq_scrgreetings(ScrGreetings_t *scrgreetings) {
  if(framecounter & 1) {
    fire_plasma(&scrgreetings->copperlist[0], &scrgreetings->info);
  } else {
    if(framecounter & 2) {
      copy_plasma(scrgreetings, 0);
    } else {
      copy_plasma(scrgreetings, 1);
    }
  }
  do_the_scrolling(scrgreetings);
  greetings_rainbow(scrgreetings, &scrgreetings->colours[0]);
#ifdef DDEBUG
  *(UWORD*)(0x3f0UL) = custom.vposr;
  *(UWORD*)(0x3f2UL) = custom.vhposr;
#endif
}

