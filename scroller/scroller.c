#include <stdio.h>
#include <hardware/custom.h>
#include <math.h>

/*
 * This scroller uses the ROXL command to scroll. No blitter was
 * harmed during this production.
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


/*
 * This function is called by the assembler interrupt subroutine.
 */
void do_interrupt_warp(unsigned char *spare_area, unsigned int scanlines) {
  int i;
  int ch;
  char buf[41];

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
    for(i = 0; i < 8; ++i) {
      spare_area[1 + (i * 2)] = demo_maker_a_pbm[(ch - ' ') * 8 + i];
    }
  }
  sprintf(buf, "%04X", scanlines);
  textoutput(bitplanedata + 320/8*24 + 1, 320/8, buf);
}

int main(int argc, char **argv) {
  puts("Scroller by Pararaum / T7D");
  textoutput(bitplanedata + 320/8*4 + 1, 320/8, "Scroller by Pararaum / T7D");
  /* Initialise scroll pointer to the beginning of the text. */
  scroller_text_pointer = scroller_text;
  init_copper(bitplanedata);
  init_framework(demo_maker_a_pbm, bitplanedata);
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
    ;
  wait_for_mouse();
  shutdown_framework();
  return 0;
}
