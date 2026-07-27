#include <stdint.h>
#include <string.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <t7d/customchips.h>
#include "boss.h"
#include "resident.h"

#define NOBITPLANES 5

enum DemoStates {
  StateWait,
  StateFade
} demo_state;

extern volatile struct Custom custom;

unsigned short *gfx; //!< memory allocated for the graphics, first the 32 colours than bitplane data
unsigned short *copperlist; //!< memory allocated for the copperlist

unsigned short current_colours[32]; // Array for the current colours.

static unsigned short copperlist4gfx[] = {
  CNOOP,0,CNOOP,0,	// Bitplane pointers, set by loop.
  CNOOP,0,CNOOP,0,
  CNOOP,0,CNOOP,0,
  CNOOP,0,CNOOP,0,
  CNOOP,0,CNOOP,0,
  DIWSTRT,0x2C81,DIWSTOP,0x2CC1,
  DDFSTRT, 0X0038,DDFSTOP,0X00D0,
  BPLCON0,(NOBITPLANES<<12)|0X200, // 5 Bitplanes.
  BPLCON1,0X0000,BPLCON2,0X0000,
  BPLCON3,0X0000,
  BPL1MOD,320/8*(NOBITPLANES-1),BPL2MOD,320/8*(NOBITPLANES-1),
  0xFFFF,0xFFFE
};


void fix_copperlist_bitplanepointers(uint32_t bpladdr) {
  short i;
  uint16_t bplpt = BPLPT; // Bitplane pointer.
  unsigned short *cptr = copperlist;

  for(i = 0; i < NOBITPLANES; ++i) {
    *cptr++ = bplpt;
    *cptr++ = bpladdr >> 16;
    *cptr++ = bplpt + 2;
    *cptr++ = bpladdr;
    bplpt += 4;
    bpladdr += 320/8; // Next row, please.
  }
}


void part_init(__reg("a0") volatile struct DemoData *demodata) {
  int i;

  demo_state = StateWait;
  gfx = BossManifestLoad(0x47465830UL);
  BossWrite("Asset was loaded at $");
  BossPrintHex((unsigned long)gfx);
  BossPutc('\n');
  if((copperlist = BossMemAlloc(100)) != 0) {
    memcpy(copperlist, copperlist4gfx, sizeof(copperlist4gfx));
    fix_copperlist_bitplanepointers((uint32_t)&gfx[32]);
    custom.cop1lc = (uint32_t)copperlist;
    for(i = 0; i < 32; ++i) {
      custom.color[i] = 0;
      current_colours[i] = 0;
    }
  }
}

void fade_to(unsigned short *target) {
  unsigned short c, r, g, b, tr, tg, tb;
  unsigned short *col;
  short i;

  for(i = 0, col = &current_colours[0]; i < 32; ++i) {
    c = *col;
    r = (c >> 8) & 0xf;
    g = (c >> 4) & 0xf;
    b = (c) & 0xf;
    c = *target++;
    tr = (c >> 8) & 0xf;
    tg = (c >> 4) & 0xf;
    tb = (c) & 0xf;
    if(r > tr) --r; else if(r < tr) ++r;
    if(g > tg) --g; else if(g < tg) ++g;
    if(b > tb) --b; else if(b < tb) ++b;
    c = (r << 8) | (g << 4) | b;
    *col++ = c;
    custom.color[i] = c;
  }
}


void part_finalise(__reg("a0") volatile struct DemoData *demodata) {
  memset(gfx, 0, 32 * 2); // Set all target colours to black.
  wait_frames(demodata, 16 * 4 + 50); // Wait for fading to be done.
  demo_state = StateWait;
}


void part_teardown(__reg("a0") volatile struct DemoData *demodata) {
  BossMemFree(gfx);
  BossMemFree(copperlist);
}


void part_vbirq(__reg("a0") volatile struct DemoData *demodata) {
  if(demo_state == StateFade) {
    if((demodata->framecounter & 3) == 3) {
      fade_to(&gfx[0]);
    }
  }
}


void wait_frames(volatile struct DemoData *demodata, uint16_t frames) {
  demodata->framecounter = 0;
  while(demodata->framecounter < frames) ;
}


int main(__reg("a0") volatile struct DemoData *demodata) {
  int i;
  unsigned short *next_gfx;
  unsigned short *old_gfx;

  wait_frames(demodata, 50); // Wait one second.
  demo_state = StateFade;
  __asm("	move.l	$4.w,$4.w");
  for(i = 1; i <= 3; ++i) {
    demodata->framecounter = 0; // Clear the democounter.
    next_gfx = BossManifestLoad(0x47465830UL + i); // Load next image.
    BossWrite("next_gfx = ");
    BossPrintHex((unsigned long)next_gfx);
    BossPutc('\n');
    if(next_gfx == 0) {
      BossWriteln("Loading failed!");
    } else {
      while(demodata->framecounter < 10 * 50); // Wait 10s no matter the loading time.
      memset(gfx, 0, 32 * 2); // Set all target colours to black.
      wait_frames(demodata, 16 * 4 + 25); // Wait for fading to be done.
      demo_state = StateWait; // Disable fading for a moment.
      fix_copperlist_bitplanepointers((uint32_t)&next_gfx[32]);
      old_gfx = gfx;
      gfx = next_gfx;
      BossMemFree(old_gfx);
      demo_state = StateFade;
    }
  }
  wait_frames(demodata, 10 * 50);
  BossWriteln("\nPart 0 is leaving.\n");
  return 0;
}
