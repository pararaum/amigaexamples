#include <stdio.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include "font.h"

/* Custom chip registers. */
extern struct Custom custom;
extern UWORD copperlist[];
extern UWORD copperlist_colors[];
extern UWORD copperlist_blit_a_ptr[];
extern UWORD copperlist_blit_d_ptr[];
extern UWORD copperlist_blit_modulos[];
extern UWORD copperlist_blit_size[];
extern UWORD copperlist_scroller_bplpt[];
extern UWORD copperlist_bplmod_top[];
extern void wait_for_mouse(void);
extern ULONG *setup_interrupt(void *playfieldptr);
extern ULONG framecounter;

#include "logo_plate.inc"
unsigned char __chip playfield2data[320*256/8*2];
unsigned char __chip scrollerarea[(320+32)/8*55*3];
void **vectors = (void *)0UL;

void setup_copper(void) {
  int i;
  ULONG address;

  /* Bitplane pointers */
  for(i = 0; i < 3; ++i) {
    address = (ULONG)logo_plate_png;
    address += i * 320/8;
    copperlist[1+4*i] = address >> 16;
    copperlist[3+4*i] = address & 0xffff;
  }
  for(i = 0; i < 2; ++i) {
    address = (ULONG)playfield2data;
    address += i * 320/8;
    copperlist[13+4*i] = address >> 16;
    copperlist[15+4*i] = address & 0xffff;
  }
  for(i = 0; i < 3; ++i) {
    address = (ULONG)scrollerarea;
    address += i * (320+32)/8;
    copperlist_scroller_bplpt[1+4*i] = address >> 16;
    copperlist_scroller_bplpt[3+4*i] = address & 0xffff;
  }
  /* Blitter via Copper */
  /* Address of bitplane data (top left corner). */
  address = (ULONG)playfield2data;
  /* Now move to end as we are using descending mode. */
  address += 320*200/8*2;
  /* Set the blitter A pointer in copper list. */
  copperlist_blit_a_ptr[1] = address >> 16;
  copperlist_blit_a_ptr[3] = address & 0xffff;
  /* Set the blitter D pointer in copper list. */
  copperlist_blit_d_ptr[1] = address >> 16;
  copperlist_blit_d_ptr[3] = address & 0xffff;
  /* Module is zero. */
  copperlist_blit_modulos[1] = 0;
  copperlist_blit_modulos[3] = 0;
  /* Size is two bitplanes */
  copperlist_blit_size[1] = ((2*200)<<6)|(320/16);
  /* Bitplane colors */
  for(i = 0; i < 8; ++i) {
    copperlist_colors[1+2*i] = logo_plate_png_palette[i];
  }
  /* Modulos for the upper logo bitplanes. */
  copperlist_bplmod_top[1] = 320/8*(3-1);
  copperlist_bplmod_top[3] = 320/8*(2-1);
}


void setup_system(void) {
  int i;

  custom.dmacon = 0x7fff;
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER|DMAF_BLITTER;
  custom.diwstrt = 0x2c81;
  custom.diwstop = 0x2cc1;
  custom.ddfstrt = 0x0038;
  custom.ddfstop = 0x00d0;
  /* 9:colour burst, 10: dual playfield, upper nibble: number bitplanes */
  custom.bplcon0 = (1<<9) | (1<<10) | 0x1000 * 5;
  custom.bplcon1 = 0;
  custom.bplcon2 = 0x0024;
  custom.bplcon3 = 0;
  custom.bpl1mod = 320/8*(3-1);
  custom.bpl2mod = 320/8*(2-1);
  custom.fmode = 0;
  /* Allow the copper to access the blitter. */
  custom.copcon = 0xFFFF;
  /* Set up copper list */
  custom.cop1lc = (ULONG)copperlist;
  /* System misuse test: */
  for(i = 0xf0; i < 0x100; ++i) {
    /* vectors[i] = (void*)&run_demo; */
    vectors[i] = NULL;
  }
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
 * @param lines number of lines
 * @param width in pixels
 */
void scroll_rect(unsigned char *bitplane, unsigned short modulo, UWORD lines, UWORD width) {
  unsigned char *address = bitplane;

  waitblit();
  /*
BLTCON0

         These two control registers are used together to control blitter
         operations. There are 2 basic modes, are and line, which are
         selected by bit 0 of BLTCON1, as show below.


         +--------------------------+---------------------------+
         | AREA MODE ("normal")     | LINE MODE (line draw)     |
         +------+---------+---------+------+---------+----------+
         | BIT# | BLTCON0 | BLTCON1 | BIT# | BLTCON0 | BLTCON1  |
         +------+---------+---------+------+---------+----------+
         | 15   | ASH3    | BSH3    | 15   | ASH3    | BSH3     |
         | 14   | ASH2    | BSH2    | 14   | ASH2    | BSH2     |
         | 13   | ASH1    | BSH1    | 13   | ASH1    | BSH1     |
         | 12   | ASA0    | BSH0    | 12   | ASH0    | BSH0     |
         | 11   | USEA    | 0       | 11   | 1       | 0        |
         | 10   | USEB    | 0       | 10   | 0       | 0        |
         | 09   | USEC    | 0       | 09   | 1       | 0        |
         | 08   | USED    | 0       | 08   | 1       | 0        |
         | 07   | LF7(ABC)| DOFF    | 07   | LF7(ABC)| DPFF     |
         | 06   | LF6(ABc)| 0       | 06   | LF6(ABc)| SIGN     |
         | 05   | LF5(AbC)| 0       | 05   | LF5(AbC)| OVF      |
         | 04   | LF4(Abc)| EFE     | 04   | LF4(Abc)| SUD      |
         | 03   | LF3(aBC)| IFE     | 03   | LF3(aBC)| SUL      |
         | 02   | LF2(aBc)| FCI     | 02   | LF2(aBc)| AUL      |
         | 01   | LF1(abC)| DESC    | 01   | LF1(abC)| SING     |
         | 00   | LF0(abc)| LINE(=0)| 00   | LF0(abc)| LINE(=1) |
         +------+---------+---------+------+---------+----------+


         ASH 3-0 Shift value of A source
         BSH 3-0 Shift value of B source
         USEA Mode control bit to use source A
         USEB Mode control bit to use source B
         USEC Mode control bit to use source C
         USED Mode control bit to use destination D
         LF 7-0 Logic function minterm select lines
         EFE Exclusive fill enable
         IFE Inclusive fill enable
         FCI Fill carry input
         DESC Descending (decreasing address) control bit
         LINE Line mode control bit (set to 0 on normal mode)
         DOFF      Disables the D output- for external ALUs
                   The cycle occurs normally, but the data
                   bus is tristate (hires chips only)
   */
  custom.bltcon0 = 0x19f0;
  custom.bltcon1 = 0x0002;
  /* A first word mask; The worst word in a line a seen by the
     blitter. Remember the descending mode! We will start at the end
     of the line. */
  custom.bltafwm = 0xffff;
  /* A last word mask */
  custom.bltalwm = 0xffff;
  /* channel A pointer */
  custom.bltapt = address;
  /* channel D pointer */
  custom.bltdpt = address;
  custom.bltamod = modulo; /* Skip modulo bytes for every line */
  custom.bltdmod = modulo;
  /* H9-H0, W5-W0; width is in words. By writing the size into the
     custom chip register the blit begins and continues while the cpu
     is still running. */
  custom.bltsize = ((lines) << 6) | ((width/8 - modulo) / 2);
}

/*! \brief scoller routine in interrupt 
 *
 * This routine is scroller every VBLANK.
 */
void irq_scroller(void) {
  int i, j;
  const char characters[] = ",-. 0123456789:;(')?!ABCDEFGHIJKLMNOPQRSTUVWXYZ\"";
  unsigned char *sptr, *dptr;

  if(framecounter % 32 == 0) {
    custom.color[0] = 0x0b00;
    sptr = &KNIGHT2_png[16];
    dptr = &scrollerarea[320/8];
    for(j = 0; j < 25*3; ++j) {
      for(i = 0; i < 4; ++i) {
	*dptr++ = *sptr++;
      }
      sptr += 320/8 - 4;
      dptr += (320+32)/8 - 4;
    }
    custom.color[0] = 0x00b0;
  }
  /* Scroll the whole area. */
  scroll_rect(scrollerarea + (320+32)/8*3*25, 0, 25 * 3, 320+32);
}

void run(void) {
  ULONG *framecounterptr;

  setup_copper();
  own_machine(1|2|8);
  /* init muzak */
  setup_system();
  framecounterptr = setup_interrupt(playfield2data);
  if(framecounterptr != NULL) {
    while(*framecounterptr < 50*3);
    vectors[0xfc] = (void*)&irq_scroller;
    while(1) {
    }
    wait_for_mouse(); /* Just in case. */
  }
  /* stop all */
  custom.intena = 0x7fff;
  /* muzak off */
  disown_machine();
}

int main(int argc, char **argv) {
  unsigned long l;

  putchar('\f');
  printf("irq_scroller=$%08lX\n", (ULONG)&irq_scroller);
  printf("run=$%08lX\n", (ULONG)&run);
  printf("copperlist=$%08lX\n", (ULONG)copperlist);
  printf("logo_plate_png=$%08lX\n", (ULONG)logo_plate_png);
  printf("playfield2data=$%08lX\n", (ULONG)playfield2data);
  printf("scroll_rect=$%08lX\n", (ULONG)&scroll_rect);
  printf("setup_copper=$%08lX\n", (ULONG)setup_copper);
  for(l = 0; l < 100000; ++l) {
  }
  run();
  return 0;
}
