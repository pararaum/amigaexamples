#include <stdio.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>

/* Custom chip registers. */
extern struct Custom custom;
extern UWORD copperlist[];
extern UWORD copperlist_blit_a_ptr[];
extern UWORD copperlist_blit_d_ptr[];
extern UWORD copperlist_blit_modulos[];
extern void wait_for_mouse(void);

unsigned char __chip bitplane1data[320*256/8*3];

int run_demo() {
  return 0;
}

void setup_copper(void) {
  int i;
  ULONG address;

  for(i = 0; i < sizeof(bitplane1data); ++i) {
    bitplane1data[i] = i;
  }
  for(i = 0; i < 3; ++i) {
    address = (ULONG)bitplane1data;
    address += i * 320/8;
    copperlist[1+4*i] = address >> 16;
    copperlist[3+4*i] = address & 0xffff;
  }
  address = (ULONG)bitplane1data;
  /* Set the blitter A pointer in copper list. */
  copperlist_blit_a_ptr[1] = address >> 16;
  copperlist_blit_a_ptr[3] = address & 0xffff;
  /* Set the blitter D pointer in copper list. */
  copperlist_blit_d_ptr[1] = address >> 16;
  copperlist_blit_d_ptr[3] = address & 0xffff;
  /* Module is zero. */
  copperlist_blit_modulos[1] = 0;
  copperlist_blit_modulos[3] = 0;
}


void setup_system(void) {
  custom.dmacon = 0x7fff;
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER;
  custom.diwstrt = 0x2c81;
  custom.diwstop = 0x2cc1;
  custom.ddfstrt = 0x0038;
  custom.ddfstop = 0x00d0;
  /* 9:colour burst, 10: dual playfield, upper nibble: no bitplanes */
  custom.bplcon0 = (1<<9) | (1<<10) | 0x1000 * 5;
  custom.bplcon1 = 0;
  custom.bplcon2 = 0x0024;
  custom.bplcon3 = 0;
  custom.bpl1mod = 320/8*(3-1);
  custom.bpl2mod = 320/8*(2-1);
  custom.fmode = 0;
  /* Allow the copper to access the blitter. */
  custom.copcon = 1;
  /* Set up copper list */
  custom.cop1lc = (ULONG)copperlist;
}


/*! \brief Wait for blitter operation to end.
 */
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
  custom.bltsize = ((32 * 3) << 6) | ((320/8 - modulo) / 2);
}


void run(void) {
  setup_copper();
  own_machine(1|2|8);
  /* init muzak */
  setup_system();
  if(run_demo()) {
  }
  wait_for_mouse();
  /* stop all */
  /* muzak off */
  disown_machine();
}

int main(int argc, char **argv) {
  long l;

  putchar('\f');
  printf("run=$%08lX\n", (ULONG)&run);
  printf("copperlist=$%08lX\n", (ULONG)copperlist);
  printf("bitplane1data=$%08lX\n", (ULONG)bitplane1data);
  printf("setup_copper=$%08lX\n", (ULONG)setup_copper);
  for(l = 0; l < 1000000; ++l) {
  }
  run();
  return 0;
}
