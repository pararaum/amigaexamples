#include <stdio.h>
#include <hardware/custom.h>

#define SCROLL_LINE 90

/*
 * This scroller uses the blitter to scroll. It will not touch the
 * first 16 pixels to the left of the screen. When looking carefully
 * at the right side it can be seen that every n-th frame a character
 * is copied.
 */

extern void init_framework(__reg("a0") unsigned char *fontptr, __reg("a1") unsigned char *bitplaneptr);
extern void shutdown_framework(void);
extern void wait_for_mouse(void);
extern struct Custom custom;

/*! \brief scroller text to display
 *
 * This is the text which is displayed using the scroller.
 */
const char *scroller_text = "This is a simple scroller...  Greetings go to: Jack Beatmaster, Meepster, Roz, Strobo, zake, Paul Holt, Tez, Sebastian L., Kylearan/Cluster, Abyss Connection.                  ";
const char *scroller_text_pointer;

/*! \brief frame counter
 */
unsigned long int frame_counter = 0;

static UWORD __chip coplist[] = {
  /* Bitplane pointers */
  0x00e0, 0, 0x00e2, 0,
  0x00e4, 0, 0x00e6, 0,
  0xf001, 0xff00,	/* Wait for specific raster line. */
  0x009c, 0x8004,	/* INTREQ: set SOFT interrupt */
  0xFFFF, 0xFFFE
};

static unsigned char __chip bitplanedata[320 * 256 / 8];

#include "../data/font/demo_maker_a.c"

void init_copper(void *bitpl0) {
  UWORD *ptr;
  int spr;
  
  for(ptr = coplist; *ptr != 0xFFFF; ptr += 2) {
    if(*ptr == 0x00e0) /*bitplane0 pointer*/ {
      ptr[1] = (ULONG)bitpl0 >> 16;
      ptr[3] = (ULONG)bitpl0 & 0xFFFF;
    }
  }
}


void textoutput(unsigned char *targetplane, unsigned int width, const char *txt) {
  int c;

  while((c = *txt++) != 0) {
    c = (c - ' ') << 3; /*Multiply by 8*/
    /* Now copy a single character. */
    targetplane[0] = demo_maker_a_pbm[c++];
    targetplane[1*width] = demo_maker_a_pbm[c++];
    targetplane[2*width] = demo_maker_a_pbm[c++];
    targetplane[3*width] = demo_maker_a_pbm[c++];
    targetplane[4*width] = demo_maker_a_pbm[c++];
    targetplane[5*width] = demo_maker_a_pbm[c++];
    targetplane[6*width] = demo_maker_a_pbm[c++];
    targetplane[7*width] = demo_maker_a_pbm[c];
    /* Advance target pointer to next character. */
    ++targetplane;
  }
}


void waitblit(void) {
  while(custom.dmaconr & (1 << 14)) ;
}


void blit_rect(unsigned char *bitplane) {
  unsigned char *address;

  waitblit();
  custom.bltcon0 = 0x19f0;
  custom.bltcon1 = 0x0002;
  /* A first word mask; The worst word in a line a seen by the
     blitter. Remember the descending mode! We will start at the end
     of the line. */
  custom.bltafwm = 0xffff;
  /* A last word mask */
  custom.bltalwm = 0x7fff;
  /* Start at the end of the 100th line. Remember descending mode! */
  address = bitplane + 320/8*(SCROLL_LINE + 10) - 2;
  /* channel A pointer */
  custom.bltapt = address;
  /* channel D pointer */
  custom.bltdpt = address;
  custom.bltamod = 2; /* Skip 2 bytes (1 word) for every line */
  custom.bltdmod = 2;
  /* H9-H0, W5-W0; width is in words. By writing the size into the
     custom chip register the blit begins and continues while the cpu
     is still running. */
  custom.bltsize = (10 << 6) | ((320/8 - 2) / 2);
}


/*
 * This function is called by the assembler interrupt subroutine.
 */
void do_interrupt_warp() {
  int i;
  int ch;
  unsigned char *bitplane;

  /* Increment a frame counter once per frame. */
  frame_counter++;
  /* Every 8th frame print a new character. Scrolling is done in the
     assembler routine. */
  if(frame_counter % 8 == 0) {
    ch = *scroller_text_pointer++;
    if(ch == 0) {
      ch = ' ';
      scroller_text_pointer = scroller_text;
    }
    bitplane = bitplanedata + 320/8*(SCROLL_LINE+1) + 312/8;
    for(i = 0; i < 8; ++i) {
      *bitplane = demo_maker_a_pbm[(ch - ' ') * 8 + i];
      bitplane += 320/8;
    }
  }
  /* And now do the blit. */
  blit_rect(bitplanedata);
}


void fill_screen(unsigned char *bitplane) {
  unsigned int i;
  unsigned short *wptr = (unsigned short *)bitplane;

  for(i = 0; i < 320/8/2*256; ++i) {
    wptr[i] = i;
  }
}


int main(int argc, char **argv) {
  puts("Scroller by Pararaum / T7D");
  fill_screen(bitplanedata);
  textoutput(bitplanedata + 320/8*4 + 1, 320/8, "Scroller by Pararaum / T7D");
  /* Initialise scroll pointer to the beginning of the text. */
  scroller_text_pointer = scroller_text;
  init_copper(bitplanedata);
  init_framework(demo_maker_a_pbm, bitplanedata);
  waitblit();
  custom.cop1lc = (ULONG)coplist;
  custom.diwstrt = 0x2c81;
  custom.diwstop = 0x2cc1;
  custom.ddfstrt = 0x0038;
  custom.ddfstop = 0x00d0;
  custom.bplcon0 = 0x1200;
  custom.bplcon1 = 0;
  custom.bplcon2 = 0x0024;
  custom.bplcon3 = 0;
  custom.fmode = 0;
  custom.bpl1mod = 0; /* Set the bitplane modulo to zero (even and odd) */
  custom.bpl2mod = 0;
  custom.color[0] = 0x0fff;
  custom.color[1] = 0x017f;

  custom.dmacon = 1<<15 /*set*/
    | 1<<9 /*DMAEN*/
    | 1<<8 /*BPLEN*/
    | 1<<7 /*COPEN*/
    | 1<<6 /*BLTEN*/
    ;
  wait_for_mouse();
  shutdown_framework();
  return 0;
}
