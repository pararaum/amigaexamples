#include <stdio.h>
#include <hardware/custom.h>

#define IMAGE_WIDTH 320
#define IMAGE_HEIGHT 200
#define IMAGE_BITPLANES 5

extern unsigned long own_machine();
extern void disown_machine();
extern unsigned long some_var;

static UWORD __chip copper_list[0x30];
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
  for(plane = 0; plane <= IMAGE_BITPLANES; plane++) {
    reg = 0x00E0 + plane * 4;
    bitplptr = (unsigned long)(&bitplane_data[IMAGE_WIDTH * IMAGE_HEIGHT / 8 * plane]);
    /* Select bitplane pointer registers. */
    *cptr++ = reg;
    *cptr++ = bitplptr >> 16;
    *cptr++ = reg + 2;
    *cptr++ = bitplptr & 0xFFFF;
  }
#ifndef NDEBUG
  if(cptr >= cend) {
    fprintf(stderr, "%08lX %08lX\n", (ULONG)cptr, (ULONG)cend);
  }
#endif
  return cptr >= cend;
}

int main(int argc, char **argv) {
  unsigned long ul;

  printf("%08lX\n", some_var);
  printf("bitplane_data=$%08lX\n", (ULONG)bitplane_data);
  if(setup() != 0) {
    puts("ERROR! Not enough space in copper list!");
  }
  ul = own_machine();
  /* all_black(); */
  /* fadeloop(); */
  disown_machine();
  printf("gfxbase=$%lx\n", ul);
  return 0;
}
