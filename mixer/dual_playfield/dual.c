#include <stdio.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>

/* Custom chip registers. */
extern struct Custom custom;
extern UWORD copperlist[];
extern void wait_for_mouse(void);

unsigned char __chip bitplane1data[320*256/8*3];

int run_demo() {
  return 0;
}

void setup_copper(void) {
  int i;

  for(i = 0; i < sizeof(bitplane1data); ++i) {
    bitplane1data[i] = i;
  }
  for(i = 0; i < 3; ++i) {
    ULONG address = (ULONG)bitplane1data;
    address += i * 320/8;
    copperlist[1+4*i] = address >> 16;
    copperlist[3+4*i] = address & 0xffff;
  }
}


void setup_system(void) {
  /* Set up copper list */
  custom.cop1lc = (ULONG)copperlist;
  custom.dmacon = 0x7fff;
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER;
  custom.diwstrt = 0x2c81;
  custom.diwstop = 0x2cc1;
  custom.ddfstrt = 0x0038;
  custom.ddfstop = 0x00d0;
  custom.bplcon0 = 0x0200 | 0x1000 * 5; /* colour burst */
  custom.bplcon1 = 0;
  custom.bplcon2 = 0x0024;
  custom.bplcon3 = 0;
  custom.bpl1mod = 320/8*(3-1);
  custom.bpl2mod = 320/8*(2-1);
  custom.fmode = 0;
}


int main(int argc, char **argv) {
  printf("copperlist=$%08lX\n", (ULONG)copperlist);
  printf("bitplane1data=$%08lX\n", (ULONG)bitplane1data);
  printf("setup_copper=$%08lX\n", (ULONG)setup_copper);
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
  return 0;
}
