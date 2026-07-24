#include <stdint.h>
#include <string.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <t7d/customchips.h>
#include "boss.h"
#include "resident.h"

extern volatile struct Custom custom;
extern volatile uint16_t framecounter;

unsigned short *gfx; //!< memory allocated for the graphics
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
  BPLCON0,(3<<12)|0X200,
  BPLCON1,0X0000,BPLCON2,0X0000,
  BPLCON3,0X0000,
  BPL1MOD,320/8*(3-1),BPL2MOD,320/8*(3-1),
  0xFFFF,0xFFFE
};

void part_init(__reg("a0") volatile struct DemoData *demodata) {
  int i;
  uint32_t baddr; // Bitplane address.
  uint16_t bplpt = BPLPT; // Bitplane pointer.
  
  gfx = BossManifestLoad(0x47465831UL);
  BossWrite("Asset was loaded at $");
  BossPrintHex((unsigned long)gfx);
  BossPutc('\n');
  if((copperlist = BossMemAlloc(100)) != 0) {
    memcpy(copperlist, copperlist4gfx, sizeof(copperlist4gfx));
    unsigned short *cptr = copperlist;
    baddr = (uint32_t)&gfx[8];
    for(i = 0; i < 3; ++i) {
      *cptr++ = bplpt;
      *cptr++ = baddr >> 16;
      *cptr++ = bplpt + 2;
      *cptr++ = baddr;
      bplpt += 4;
      baddr += 320/8; // Next row, please.
    }
    custom.cop1lc = (uint32_t)copperlist;
    for(i = 0; i < 32; ++i) {
      custom.color[i] = 0;
      current_colours[i] = 0;
    }
  }
  framecounter = 0;
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

void part_teardown(__reg("a0") volatile struct DemoData *demodata) {
  BossMemFree(gfx);
  BossMemFree(copperlist);
}


void part_vbirq(__reg("a0") volatile struct DemoData *demodata) {
  if((demodata->framecounter & 3) == 3) {
    fade_to(&gfx[0]);
  }
}


int main(__reg("a0") volatile struct DemoData *demodata) {
  short i;

  BossPrintHex((uint32_t)demodata);
  while(demodata->framecounter < 325) ;
  for(i = 0; i < 8; ++i) gfx[i] = 0;
  demodata->framecounter = 0;
  while(demodata->framecounter < 16*4+25) ;  
  BossWriteln("\nC is leaving.\n");
  return 0;
}
