#include <stdio.h>
#include <string.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <own.h>
#include "customchips.h"

/*
 * This is code to test the swoosh. It will call the appropriate
 * routines and display the chip memory all the time.
 */

#define WIDTH 320
#define HEIGHT 256

extern volatile struct Custom custom;


char __chip chip_gfx_memory[WIDTH*HEIGHT/8];
UWORD __chip copperlist[129] =
  {
   CNOOP, CNOOP, // Make some space for setup.
   CNOOP, CNOOP,
   CNOOP, CNOOP,
   CNOOP, CNOOP,
   CNOOP, CNOOP,
   CNOOP, CNOOP,
   CNOOP, CNOOP,
   CNOOP, CNOOP,
   CNOOP, CNOOP,
   CNOOP, CNOOP,
   CNOOP, CNOOP,
   FMODE, 0, // AGA compatible
   BPLCON0, 0x1200, // One bitplane and enable the raster engine.
   BPLCON1, 0, // No scrolling.
   BPLCON2, 0, // No special mode and playfield priorities.
   BPLCON3, 0, // No special modes.
   COLOR(0), 0x0253,
   COLOR(1), 0x0cfc,
   0xFFFF, 0xFFFE // End of copper list.
  };


extern volatile long irqcounter;
extern void install_enable_IRQ(void);

void clear_swinging_memory(void) {
  memset(&chip_gfx_memory[0], 0, WIDTH/8L*HEIGHT);
}  

/*! Initialise and prepare copper.
 *
 * This routine will prepare the copper list and set up bitplane
 * pointer and other stuff. Hopefully there is enough space in the
 * copperlist...
 *
 * @return: number of entries written to the copperlist
 */
int prepare_copperlist(void) {
  int idx = 0;

  copperlist[idx++] = BPLPT;
  copperlist[idx++] = ((ULONG)chip_gfx_memory) >> 16;
  copperlist[idx++] = BPLPT + 2;
  copperlist[idx++] = ((ULONG)chip_gfx_memory) & 0xFFFF;
  // Initialise the DMACON register. This will enable RASTER and BLITTER DMA.
  copperlist[idx++] = DMACON;
  copperlist[idx++] = DMAF_SETCLR | DMAF_RASTER | DMAF_BLITTER;
  return idx;
}

/*! Blitter fill an area
 *
 * @param mem pointer to memory
 * @param width in pixel
 * @param height in rasterlines
 * @param word word pattern to fill the area with
 */
void blitter_fill_area(BYTE *mem, int width, int height, UWORD word) {
  // Wait for last blit.
  while(custom.dmaconr & DMAF_BLTDONE) ;
  custom.bltdpt = mem; // Pointer to target memory.
  // Preload value into blitter channel A.
  custom.bltadat = word;
  custom.bltcon0 = 0x01F0; // Use only D channel and equation D = A.
  custom.bltcon1 = 0; // No special mode.
  custom.bltafwm = 0xFFFF; //Masks
  custom.bltalwm = 0xFFFF;
  custom.bltdmod = 0; // No modulo.
  // And start the magic.
  custom.bltsize = height << 6 | (width/8/2);
}


// Just for fun.
void blitter_effect(void) {
  UWORD fill = 0xFFFF;
  int i;

  for(i = 1; i < 8; ++i) {
    blitter_fill_area(chip_gfx_memory, WIDTH, HEIGHT, fill);
    fill <<= i;
    fill >>= 2 * i;
    fill <<= i;
    irqcounter = 50 * 2; // Wait 2s.
    while(irqcounter > 0) ;
  }
}


/** routine to initialise the mercifully part
 *
 * @param bitmap pointer to chip memory 
 */
void part_mercifully_init(BYTE *bitmap) {
}

/** routine to update the mercifully part
 *
 * Call once per from. 
 * @param bitmap pointer to chip memory
 * @return 1=still running, 0=finished
 */
int part_mercifully_update(BYTE *bitmap) {
  return 0;
}

/** routine to run the mercifully part
 *
 * @param bitmap pointer to chip memory 
 */
void part_mercifully(BYTE *bitmap) {
  int ret;

  do {
    // Wait one frame.
    irqcounter = 1;
    while(irqcounter > 0) ;
    ret = part_mercifully_update(bitmap);
  } while(ret != 0);
}


int main(void) {
  int i;
  puts("Mercifully short...");
  printf("%p\n", (void*)&main);
  printf("%p\n", (void*)chip_gfx_memory);
  printf("prepare_copperlist()=%d\n", prepare_copperlist());
  clear_swinging_memory();
  own_machine(OWN_libraries|OWN_view|OWN_interrupt);
  install_enable_IRQ();
  custom.cop1lc = (ULONG)copperlist; // Set copperlist pointer.
  custom.copjmp1 = 0;
  // Enable sound and copper DMA.
  custom.dmacon = DMAF_SETCLR | DMAF_MASTER | DMAF_AUDIO | DMAF_COPPER;
  // Remove this, if fed up with it.
  blitter_effect();
  clear_swinging_memory(); // Just to be sure.
  part_mercifully_init(chip_gfx_memory);
  // Do some other stuff if needed.
  part_mercifully(chip_gfx_memory);
  custom.dmacon = DMAF_RASTER | DMAF_COPPER; // Yes, disable COPPER and RASTER DMA.
  custom.color[0] = 0x0fff; // Make background white.
  irqcounter = 50; // Wait one second.
  while(irqcounter > 0) ;
  disown_machine();
  return 0;
}
