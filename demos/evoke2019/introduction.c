#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include "music.h"
#include "copper_fade.h"
#include "introduction.barebone.h"

typedef void (*voidfunction_t)(void);
extern struct Custom custom;

UWORD *fader_colourlist;
static UWORD fader_spare_area[3*32+2];

void clear_fader_spare_area(void) {
  int i;

  for(i = 0; i < sizeof(fader_spare_area)/sizeof(WORD); ++i) {
    fader_spare_area[i] = 0;
  }
}

void fadeinfunction(void) {
  fade_in_copper_list(32, 2, fader_colourlist, &introduction_coppercolours[1], fader_spare_area);
}

void fadeoutfunction(void) {
  fade_out_colour_table(32, &introduction_coppercolours[1], 2);
}

void introduction(void) {
  unsigned int i;
  voidfunction_t *autovector300 = (voidfunction_t *)0x300UL;
  voidfunction_t *autovector304 = (voidfunction_t *)0x304UL;

  /* init_music(); */
  pt_InitMusic(mod_introspeech);
  /* set_vblank(); */
  *autovector300 = &pt_PlayMusic;
  fader_colourlist = introduction_create_copperlist(0);
  custom.bplcon0 = 0x5200; /* 5 bitplanes, colour burst */
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER|DMAF_AUDIO;
  *autovector304 = &fadeinfunction;
  wait_songposition(0, 0x37);
  *autovector304 = &fadeoutfunction;
  wait_songposition(0, 0x3f);
  clear_fader_spare_area();
  for(i = 1; i <= 4; ++i) {
    fader_colourlist = introduction_create_copperlist(i);
    *autovector304 = &fadeinfunction;
    wait_songposition(i, 0x1a);
    *autovector304 = &fadeoutfunction;
    wait_songposition(1 + i, 0);
    *autovector304 = (voidfunction_t)0;
    clear_fader_spare_area();
  }
  //Wait for end.
  wait_songposition(4, 0);
  //Now disable interrupts.
  custom.intena = 0x7fff;
  *autovector300 = (voidfunction_t)0;
  *autovector304 = (voidfunction_t)0;
  //Only display the background.
  custom.bplcon0 = 0x0200; /* 0 bitplanes, colour burst */
  /* stop_music(); */
  pt_StopMusic();
}

