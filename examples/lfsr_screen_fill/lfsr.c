#include <stdio.h>
#include <hardware/custom.h>
#include <math.h>
#include "sprite_multiplexer.h"

#define MAX_NUM_SPRITE_REUSE 10
#define NUMBER_of_SOBS 111

extern unsigned char *init_framework(void);
extern void shutdown_framework(void);
extern void wait_for_mouse(void);
extern struct Custom custom;

extern unsigned short hypotrochoid_pos_table[];
extern unsigned int hypotrochoid_pos_table_length;

const char *welcome = "LFSR screen fill\nCode: Pararaum / T7D";

volatile unsigned short *ptr = (volatile unsigned short *)0xDFF180;
/* pointer to a bitplane */
unsigned char *bitplaneptr;

struct Global_data {
  unsigned short feedback_term;
  unsigned short sprite_x_pos;
  unsigned short hypotrochoid_phase[NUMBER_of_SOBS];
} glodat = {
  0x1,
  0,
  /* { 0, 2, 4, 6, 8, 10, 12, 14, 16, 18 } */
  /* { 0, 5, 10, 15, 20, 25, 30, 35, 40, 45 } */
  { 0 } /* added by code */
  /* { 0, 17, 34, 51, 71, 91, 111, 131, 151, 171 } */
};

/* 
 * This will contain an array of arrays which can be used to display a
 * sprite. The memory is not initialised and must be filled.
 *
 * It is assumed that the sprite has a height of SPRITE_HEIGHT pixel.
 */
static unsigned short __chip sprite_array[8][(2 + 2 * SPRITE_HEIGHT) * MAX_NUM_SPRITE_REUSE + 2];
static struct Multiplexer multiplex = {
  { &(sprite_array[1][0]), &(sprite_array[2][0]), &(sprite_array[3][0]), &(sprite_array[4][0]), &(sprite_array[5][0]), &(sprite_array[6][0]), &(sprite_array[7][0]), &(sprite_array[0][0]) },
  7
};


static UWORD __chip coplist[] = {
  0x0180, 0, /* background black */
  0x0182, 0x0eef, /* Colour 1: not quite white */
  /* Sprites, colour 16, etc. $180+2*16=$1a0 */
  0x01a0,0x0fff,0x01a2,0x0b41,0x01a4,0x0ad4,0x01a6,0x0059,
  0x01a8,0x0fff,0x01aa,0x0b41,0x01ac,0x0ad4,0x01ae,0x0059,
  0x01b0,0x0fff,0x01b2,0x0b41,0x01b4,0x0ad4,0x01b6,0x0059,
  0x01b8,0x0fff,0x01ba,0x0b41,0x01bc,0x0ad4,0x01be,0x0059,
  /* Set sprite pointer of sprite 0, 1, ...; will be replaced later. */
  0x0120, 0x0000, 0x0122, 0x0000,
  0x0124, 0x0000, 0x0126, 0x0000,
  0x0128, 0x0000, 0x012a, 0x0000,
  0x012c, 0x0000, 0x012e, 0x0000,
  0x0130, 0x0000, 0x0132, 0x0000,
  0x0134, 0x0000, 0x0136, 0x0000,
  0x0138, 0x0000, 0x013a, 0x0000,
  0x013c, 0x0000, 0x013e, 0x0000,
  /* Bitplane pointers */
  0x00e0, 0, 0x00e2, 0,
  0x00e4, 0, 0x00e6, 0,
  0x2001, 0xFF00,
  0x0180, 0x0fff,
  0x2101, 0xff00,	/* Raster line 0x21. */
  0x009c, 0x8004,	/* INTREQ: set SOFT interrupt */
  0x0180, 0x0f00,
  0xFFFF, 0xFFFE
};


static unsigned char __chip bitplanedata[320 * 256 / 8];

#include "../../data/font/demo_maker_a.c"

void init_copper(void *bitpl0) {
  UWORD *ptr;
  int spr;
  
  for(ptr = coplist; *ptr != 0xFFFF; ptr += 2) {
    if(*ptr == 0x0120) {
      for(spr = 0; spr < 8; ++spr) {
	printf("sprite_data = $%08lX\n", (unsigned long)&(sprite_array[spr][0]));
	ptr[4 * spr + 1] = (ULONG)(&(sprite_array[spr][0])) >> 16;
	ptr[4 * spr + 3] = (ULONG)(&(sprite_array[spr][0])) & 0xFFFF;
      }
    } else if(*ptr == 0x00e0) /*bitplane0 pointer*/ {
      ptr[1] = (ULONG)bitpl0 >> 16;
      ptr[3] = (ULONG)bitpl0 & 0xFFFF;
    }
  }
}

/*! Sort hypotrochoids phase-array
 *
 * This function will take an array of phases and sort them according
 * to their value in the hypotrochoid_pos_table.
 *
 * The sorting algorithm used is the Gnome Sort, see
 * https://en.wikipedia.org/wiki/Gnome_sort, in its unoptimized
 * variant. This is much more stable and even faster than Bubble
 * Sort. If a higher speed is necessary the optimised variant may be
 * an option.
 *
 * @param phases poiner the the phases of the SOBs
 * @param num number of elements in the array
 */
void sort_hypotrochoids(unsigned short *phases, unsigned short num) {
  register unsigned short pos;
  register unsigned short temp;

  pos = 0;
  while(pos < num) {
    /* Either first element or already in right order. */
    if((pos == 0) || (hypotrochoid_pos_table[phases[pos]] >= hypotrochoid_pos_table[phases[pos - 1]])) {
      ++pos;
    } else {
      /* SWAP */
      temp = phases[pos - 1];
      phases[pos - 1] = phases[pos];
      phases[pos] = temp;
      /* decrement pos */
      --pos;
    }
  }
}

/*
 * This function is called by the assembler interrupt subroutine.
 */
void do_interrupt_warp(void) {
  short i;
  unsigned short xpos;
  unsigned short spos;
  short sum = 0;
  static unsigned char bitmasks[] = {
    128, 64, 32, 16, 8, 4, 2, 1
  };

  if(glodat.feedback_term & 1) {
    /*http://users.ece.cmu.edu/~koopman/lfsr/16.txt*/
    glodat.feedback_term = (glodat.feedback_term >> 1) ^ 0x855d;
  } else {
    glodat.feedback_term = (glodat.feedback_term >> 1);
  }
  bitplanedata[glodat.feedback_term / 8] ^= bitmasks[glodat.feedback_term & 7];
  custom.color[0] = 0x008;
  glodat.sprite_x_pos = (glodat.sprite_x_pos + 1) & 0x00FF;
  sprite_array[0][0] = glodat.sprite_x_pos | 0x2c00;
  sprite_array[0][1] = (0x2c00 + 0x0a00);
  for(i = 0; i < sizeof(glodat.hypotrochoid_phase)/sizeof(unsigned short int); ++i) {
    if(++glodat.hypotrochoid_phase[i] >= hypotrochoid_pos_table_length) {
      glodat.hypotrochoid_phase[i] = 0;
    }
  }
  custom.color[0] = 0x730;
  sort_hypotrochoids(glodat.hypotrochoid_phase, sizeof(glodat.hypotrochoid_phase)/sizeof(unsigned short int));
  custom.color[0] = 0x045;
  multiplex_sprites(&(glodat.hypotrochoid_phase[0]), NUMBER_of_SOBS, hypotrochoid_pos_table, &multiplex);
}

/*! \brief Prepare the sprite data by filling the sprite information
 */
void copy_sprite_data(void) {
  UWORD sprdat[] = {
    0x1e00,0x0000,
    0x3f00,0x0000,
    0x6780,0x1800,
    0xc3c0,0x3c40,
    0xc3c0,0x3c40,
    0xe7c0,0x1840,
    0xffc0,0x0040,
    0x7f80,0x0080,
    0x3f00,0x0100,
    0x1e00,0x0600
  };
  int i;
  int spr;
  int reuse;
  unsigned short coor;

  for(reuse = 0; reuse < MAX_NUM_SPRITE_REUSE; ++ reuse) {
    for(spr = 0; spr < 8; ++spr) {
      coor = 0x3000 | (0x30 + spr * 18);
      sprite_array[spr][reuse * (2*SPRITE_HEIGHT + 2) + 0] = coor;
      sprite_array[spr][reuse * (2*SPRITE_HEIGHT + 2) + 1] = (coor & 0xFF00) + (SPRITE_HEIGHT << 8);
      for(i = 0; i < 2*SPRITE_HEIGHT; ++i) {
	sprite_array[spr][reuse * (2*SPRITE_HEIGHT + 2) + 2 + i] = sprdat[i];
      }
      /* End Of Sprite */
      sprite_array[spr][reuse * (2*SPRITE_HEIGHT + 2) + 2 + 2*SPRITE_HEIGHT + 0] = 0;
      sprite_array[spr][reuse * (2*SPRITE_HEIGHT + 2) + 2 + 2*SPRITE_HEIGHT + 1] = 0;
    }
  }
}

void textoutput(unsigned char *targetplane, unsigned int width, const char *txt) {
  int c;

  while((c = *txt++) != 0) {
    c = (c - ' ') << 3; /*Multiply by 8*/
    /* Now copy a single character. */
    targetplane[0] = demo_maker_a_pbm[c];
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

void welcoming(void) {
  char buf[41];

  puts(welcome);
  textoutput(bitplanedata + 27*(8+1)*320/8, 320/8, "(C) The 7th Division in 2018");
  sprintf(buf, "coplist = $%08lX", (unsigned long)coplist);
  puts(buf);
  textoutput(bitplanedata + 1*(8+1)*320/8, 320/8, buf);
  sprintf(buf, "sort_hypotrochoids() = $%08lX", (unsigned long)&sort_hypotrochoids);
  puts(buf);
  textoutput(bitplanedata + 2*(8+1)*320/8, 320/8, buf);
  sprintf(buf, "hypotrochoid_phase = $%08lX", (unsigned long)glodat.hypotrochoid_phase);
  puts(buf);
  textoutput(bitplanedata + 3*(8+1)*320/8, 320/8, buf);
  sprintf(buf, "multiplex = $%08lX", (unsigned long)&multiplex);
  puts(buf);
  textoutput(bitplanedata + 4*(8+1)*320/8, 320/8, buf);
  sprintf(buf, "multiplex_sprites() = $%08lX", (unsigned long)&multiplex_sprites);
  puts(buf);
  textoutput(bitplanedata + 5*(8+1)*320/8, 320/8, buf);
  sprintf(buf, "textoutput() = $%08lX", (unsigned long)&textoutput);
  puts(buf);
  textoutput(bitplanedata + 6*(8+1)*320/8, 320/8, buf);
}

int main(int argc, char **argv) {
  unsigned short i;
  float d;

  welcoming();
  /* Initialise SOBs. */
  for(i = 0; i < NUMBER_of_SOBS; ++i) {
    glodat.hypotrochoid_phase[i] = i * 17;
  }
  init_copper(bitplanedata);
  copy_sprite_data();
  bitplaneptr = init_framework();
  /* Flicker background. */
  for(i = 0; i < 0xFFFF; ++i) {
    *ptr = i;
  }
  custom.cop1lc = (ULONG)coplist;
  custom.diwstrt = 0x2c81;
  custom.diwstop = 0x2cc1;
  custom.ddfstrt = 0x0038;
  custom.ddfstop = 0x00d0;
  custom.bplcon0 = 0x1200;
  /*custom.bplcon1 = 0;*/
  custom.bplcon2 = 0x0024;
  custom.bplcon3 = 0;
  custom.fmode = 0;
  custom.bpl1mod = 0; /* Set the bitplane modulo to zero (even and odd) */
  custom.bpl2mod = 0;
  
  custom.dmacon = 1<<15 /*set*/
    | 1<<9 /*DMAEN*/
    | 1<<8 /*BPLEN*/
    | 1<<7 /*COPEN*/
    | 1<<5 /*SPREN, apparently bitplane dma has to be enabled, too */;
  wait_for_mouse();
  shutdown_framework();
  printf("bitplaneptr = $%08lX\n", (unsigned long)bitplaneptr);
  return 0;
}
