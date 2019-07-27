#include <stdio.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <hardware/intbits.h>
#include "own.h"

#define BPLWIDTH 320
#define BPLHEIGHT 256
#define BPLNO 1

extern volatile struct Custom custom;
UWORD __chip very_simple_copperlist[] = {
  0xe0, 0, /* Bitplane pointer */
  0xe2, 0,
  0xe4, 0,
  0xe6, 0,
  0x180, 0x0fff, // Background white
  0x182, 0x0125, // Foreground black/blue
  0xffff, 0xfffe
};
unsigned char __chip bitplanedata[BPLWIDTH/8 * BPLHEIGHT * BPLNO];

void set_bitplane_ptr(ULONG bplptr) {
  very_simple_copperlist[1] = bplptr >> 16;
  very_simple_copperlist[3] = bplptr & 0xFFFF;
}

/*! \brief Setup the custom chip registers
 *
 * This will set up the display window and other stuff and it will set
 * the copper list one pointer.
 *
 * @param coplist pointer to copper list.
 */
void setup_custom_chips(UWORD *coplist) {
  custom.cop1lc = (ULONG)coplist;
  custom.copjmp1 = 0;
  custom.diwstrt = 0x2c81;
  custom.diwstop = 0x2cc1;
  custom.ddfstrt = 0x0038;
  custom.ddfstop = 0x00d0;
  custom.bplcon0 = 0x0200 | (BPLNO * 0x1000);
  custom.bplcon1 = 0;
  custom.bplcon2 = 0;
  custom.bplcon3 = 0;
  custom.bpl1mod = 0;
  custom.bpl2mod = 0;
  custom.fmode = 0;
}

void wait4mouse(void) {
  volatile UBYTE *cia = (UBYTE *)0xBFE001;

  while((*cia & (1 << 6)) != 0) ;
}

void xor_pixel(UBYTE *bplptr, short int x, short int y) {
  // Multiply by the number of bytes in each row.
  bplptr += (y * (BPLWIDTH/8));
  // Advance in order to point the byte which contains the pixel.
  bplptr += x / 8;
  *bplptr ^= 1 << (7 - (x & 7));
}

int main(int argc, char **argv) {
  puts("Sinus-Scroller by Pararaum / T7D");
  printf("bitplanedata %lX\n", (ULONG)bitplanedata);
  printf("xor_pixel %lX\n", (ULONG)&xor_pixel);
  own_machine(OWN_libraries|OWN_view|OWN_trap|OWN_interrupt);
  custom.dmacon = DMAF_SETCLR | DMAF_MASTER | DMAF_COPPER | DMAF_RASTER | DMAF_BLITTER;
  set_bitplane_ptr((ULONG)&bitplanedata);
  setup_custom_chips(&very_simple_copperlist[0]);
  bitplanedata[40] = 0xff;
  for(int i = 0; i < 200; ++i) {
    xor_pixel(bitplanedata, i, i);
  }
  wait4mouse();
  disown_machine();
  return 0;
}
