#include <stdint.h>
#include <string.h>
#include <hardware/custom.h>
#include <t7d/customchips.h>
#include "boss.h"

extern volatile struct Custom custom;
extern volatile uint32_t framecounter;

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


void show_graphics(void) {
  unsigned short *gfx;
  unsigned short *copperlist;
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
    for(i = 0; i < 8; ++i) {
      custom.color[i] = gfx[i];
    }
  }
  //Todo: freeing memory?
  framecounter = 0;
  while(framecounter < 250) ;
}


int main() {
  BossWriteln("Loading further assets.");
  show_graphics();
  BossManifestLoad(0x47465832);
  return 0;
}
