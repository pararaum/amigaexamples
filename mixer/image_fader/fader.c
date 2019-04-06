#include <stdio.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>

#define IMAGE_WIDTH 320
#define IMAGE_HEIGHT 200
#define IMAGE_BITPLANES 5

extern unsigned long own_machine();
extern void disown_machine();
extern unsigned long set_interrupt();

extern struct Custom custom;
extern unsigned long framecounter;
extern unsigned short volatile mousebutton;
extern void (*vertical_blank_irqfun)();
extern void uncompress_next_image(__reg("a0") UBYTE *target);
/* These are pointers to the image data */
extern unsigned long image_pointers[];

static UWORD __chip copper_list[0xA0];
static UBYTE __chip bitplane_data[IMAGE_WIDTH * IMAGE_HEIGHT * IMAGE_BITPLANES / 8];

/*! \brief setup the copper
 *
 * This function will try to fill up the copper list. If there is not
 * enough space it will return an error.
 * 
 * \return 0 = OK, everything else error!
 */
int setup() {
  unsigned short reg, plane;
  unsigned long bitplptr;
  UWORD *cptr = copper_list;
  /*Pointer to the end of the copper list.*/
  UWORD *cend = copper_list + sizeof(copper_list)/sizeof(UWORD);

  /* Setup the bitplane pointers. */
  bitplptr = (unsigned long)(bitplane_data);
  for(plane = 0; plane <= IMAGE_BITPLANES; plane++) {
    reg = 0x00E0 + plane * 4;
    /* Select bitplane pointer registers. */
    *cptr++ = reg;
    *cptr++ = bitplptr >> 16;
    *cptr++ = reg + 2;
    *cptr++ = bitplptr & 0xFFFF;
    bitplptr += IMAGE_WIDTH / 8;
  }
  /* /\* Write colour copper list. *\/ */
  /* for(reg = 0x180; reg < 0x180 + 32 * 2; ++reg) { */
  /*   *cptr++ = reg; */
  /*   *cptr++ = 0; */
  /* } */
#ifndef NDEBUG
  fprintf(stderr, "Copper: %08lX %08lX\n", (ULONG)cptr, (ULONG)cend);
#endif
  return cptr >= cend;
}


/*! \brief setup all black screen
 *
 * This will set the custom registers and the first default copperlist
 * up.
 */
unsigned long all_black() {
  int i;

  /* Set up copper list */
  custom.cop1lc = (ULONG)copper_list;
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER;
  custom.diwstrt = 0x2c81;
  custom.diwstop = 0x2cc1;
  custom.ddfstrt = 0x0038;
  custom.ddfstop = 0x00d0;
  custom.bplcon0 = 0x5200; /* 5 bitplanes, colour burst */
  custom.bplcon1 = 0;
  custom.bplcon2 = 0x0024;
  custom.bplcon3 = 0;
  /* The default is *planar* images. */
  custom.bpl1mod = IMAGE_WIDTH * IMAGE_BITPLANES / 8;
  custom.bpl2mod = IMAGE_WIDTH * IMAGE_BITPLANES / 8;
  custom.fmode = 0;
  for(i = 0; i < 32; ++i) {
    custom.color[i] = 0;
  }
  return set_interrupt();
}

void funnyirqfun(void) {
  static UWORD value = 0;
  custom.color[0] = value++;
}

int main(int argc, char **argv) {
  unsigned long ul;

#ifndef NDEBUG
  printf("bitplane_data=$%08lX\n", (ULONG)bitplane_data);
  printf("uncompress_next_image=$%08lX\n", (ULONG)uncompress_next_image);
#endif
  if(setup() != 0) {
    puts("ERROR! Not enough space in copper list!");
  }
  ul = own_machine();
  ul = all_black();
  uncompress_next_image(bitplane_data);
  vertical_blank_irqfun = &funnyirqfun;
  /* fadeloop(); */
  while(mousebutton == 0) {}
  disown_machine();
  printf("irq routine=$%lx\n", ul);
  printf("framecounter=%08lX\n", framecounter);
  return 0;
}
