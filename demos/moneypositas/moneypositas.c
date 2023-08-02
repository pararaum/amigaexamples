#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <hardware/intbits.h>
#include <clib/dos_protos.h>
#include "t7d/own.h"
#include "t7d/default_irq_routine.h"
#include "t7d/lz4_uncrunch.h"
#include "t7d/inflate.h"
#include "t7d/xoroshiro.h"
#include "t7d/music.h"
//
#include "flitter.h"
#include "globals.h"
#include "monochrome_flicker.h"
#include "palette.h"
#include "blitterfuncs.h"
#include "blitterrama.h"
#include "muzak.h"
#include "toolkit.h"
#include "flitter.h"
#include "images.h"
#include "intermezzo_text.h"
#include "for_a_fistful_of_dollars.h"
#include "burning_earth.h"
#include "greetings.h"
#include "kaboom.h"
#include "pixel.h"

/*
  The screen size is 336x256(?) but only 320x240 or so will be
  displayed. I do not want to implement any type of clipping so just
  more memory is used when the money or gold coins are blitted.

       +----------------------------------------------------------+
       |       	      	       	        	                  |
       |    +-----------------------------------------------------+
       |    |         	       	               	                  |
       |    |         	       	               	                  |
       |    |	#	       	               	      anim        |
       |    |                  	               	                  |
       |    |    #                             	                  |
       |    |       #                          	                  |
       |    |                                  	                  |
       |    |          #                       	                  |
       |    |		#	#		                  |
       |    |                                                     |
       |    |   image              #                              |
       |    |                                                     |
       +----+-----------------------------------------------------+

  Copying four bitplanes takes 4(DMA)*240(lines)*320/8/2(words)/7.09 =
  10.832 µs. See http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node012A.html.
 */

// Welcome string in non-debug mode.
static char hello_string[] = "\v\n\nMoneypositas\n------------\n\n"
  "A Demo by the The 7th Division\n\n"
  "and nerdyFamily\n\n"
  "Credits\n-------\n\n"
  "Code: Pararaum / T7D\n"
  "Grahics: Pixel_Hexe, Nerouine / nerdyFamily\n"
  "Music: Deload / nerdyFamily\n"
  "Fonts:  DNS, Artline Design\n"
  ;



/*
 * Memory for double buffering.
 */
static UBYTE __chip bitplanememory[2][BPLWIDTH*BPLHEIGHT*BPLNOS/8];

// Union of Shared Effect Memory. Make sure that there are *never* two
// effects using this memory at the same time. Otherwise it may get
// interesting.
static union {
  // Memory for the flicker, needs to be separate from the
  // double-buffered bitplanes.
  struct MonochromeFlicker_t flickermem;
  // Memory for the flitter effect at the beginning and while
  // decrunching.
  AtmosphericFlitter_t flittermem;
  // Text intermezzo: Prophecy.
  IntermezzoText_t intermezzotext;
  // The money god.
  Fistful_t fistful;
  // Burning world...
  Burning_t burning;
  // Greetings...
  ScrGreetings_t greetings;
  // KABOOM
  Kaboom_t kaboom;
} __chip uSEM;

// Memory for the background images
static UBYTE __chip background_image[IMGWIDTH*IMGHEIGHT*IMGBPLNOS/8];

//! Memory for the animation
static __chip struct {
  /*! \brief image and cookie-cut mask
   *
   * This will contain e.g. 4 bitplanes of image data plus one
   * bitplane as a cookie-cut mask and all are interleaved.
   *
   * This should allow for saving an image with a palette which has
   * the doubled size. All colours in the first half will be then
   * considered as transparent!
   */
  UBYTE image_n_ccm[ANMWIDTH*ANMHEIGHT*(BPLNOS+1)/8];
} animation_image[NUMBER_OF_ANIMATIONS];

static unsigned char __chip music_memory[0x21000]; // (format "%x" 134202)"20c3a"
static UBYTE __chip whole_chipmem_end[4];
static short non_aga_chipset;
struct MonochromeFlicker_t *monfli;

struct {
  UWORD bitplanes[16];
  UWORD colours[16*2];
  UWORD rest[40];
} __chip moneypositas_copperlist = {
  {
    0xe0, 0, /* Bitplane pointer */
    0xe2, 0,
    0xe4, 0,
    0xe6, 0,
    0xe8, 0,
    0xea, 0,
    0xec, 0,
    0xee, 0
  },
  {
    0x180, 0x322,
    0x182, 0x654,
    0x184, 0xeb9,
    0x186, 0xedb,
    0x188, 0x246,
    0x18a, 0x677,
    0x18c, 0x699,
    0x18e, 0xbaa,
    0x190, 0xb34,
    0x192, 0xd84,
    0x194, 0xed7,
    0x196, 0x476
  },
  {
    0x0100, 0x4200, //BPLCON0, 4 bitplanes, colour burst.
    0x102, 0, // BPLCON1, scrolling set to zero.
    0x108, BPLWIDTH/8*3 + 2,
    0x10a, BPLWIDTH/8*3 + 2,
    0x0096, 1<<5, /* Disable sprite DMA during vblank so that there
		     will be no stripes. */
    0xffff, 0xfffe // End of Copper list
  }
};

Bob_t moneybobs[MAXMBOBS];


#ifndef NDEBUG
short breaking_function(void) {
  static short breaks = 0;

  return ++breaks;
}
#endif

/*! \brief fill a line
 *
 * Fill a line, bytewise.
 *
 * \param line pointer to the line
 * \param left byte
 * \param right byte
 */
static void fill_line(UBYTE *line, unsigned short left, unsigned short right) {
  while(left < right) {
    line[left++] = 0xFF;
  }
}

/*! \brief fill a block
 *
 * Fill a line, bytewise.
 *
 * \param line pointer to the line
 * \param left byte
 * \param right byte
 */
static void fill_block(UBYTE *line, unsigned short width, unsigned short left, unsigned short right) {
  fill_line(line, left, right);
  line += width * 2;
  fill_line(line, left, right);
  line += width * 2;
  fill_line(line, left, right);
}


/*! \brief setup all black screen
 *
 * This will set up the custom registers. It will also disable DMA and
 * interrupts so that the system starts in a clean state.
 */
static void all_black(void) {
  int i;

  custom.intena = 0x7fff; // Disable all interrupts.
  custom.dmacon = 0x7fff; // Disable all DMA.
  custom.diwstrt = 0x2c81;
  custom.diwstop = 0x2cc1;
  custom.ddfstrt = 0x0038;
  custom.ddfstop = 0x00d0;
  custom.bplcon0 = 0x0200; /* 0 bitplanes, colour burst */
  custom.bplcon1 = 0;
  custom.bplcon2 = 0;
  /* http://eab.abime.net/showthread.php?t=71661 */
  /* https://ada.untergrund.net/?p=boardthread&id=891 */
  custom.bplcon3 = 0x0c00;
  /* http://eab.abime.net/showthread.php?t=85342 and, of course,
   * http://www.winnicki.net/amiga/memmap/BPLCON4.html */
  custom.bplcon4 = 0x0011;
  /* The default is *planar* images. */
  custom.bpl1mod = 0;
  custom.bpl2mod = 0;
  custom.fmode = 0;
  /* Clear colours (set to black). */
  for(i = 0; i < 32; ++i) {
    custom.color[i] = 0;
  }
}


static int setup_amiga() {
  own_machine(OWN_libraries|OWN_view|OWN_trap|OWN_interrupt);
  all_black();
  //circinit(whole_chipmem, whole_chipmem_end);
  /*
   * Now do a quick and dirty AGA test. See
   * http://www.winnicki.net/amiga/memmap/LISAID.html. Hopefully
   * this is working from time to time...
   */
  non_aga_chipset = (custom.deniseid != 0xffffU);
  return 0;
}

static void clean_up_the_mess() {
  disown_machine();
}


static void irq_routine_flitter(void) {
  blit_da_noise(&uSEM.flittermem, framecounter);
}


static void flitter_effect(void) {
  /*
   * The first screen used for double buffering is now used to display
   * the logo, the second screen is misused as memory for the
   * `flitter` effect.
   */
  prepare_flitter(&uSEM.flittermem);
  irq_routine_funpointer = &irq_routine_flitter;
}


void uncompress_background_data(unsigned short i) {
  unsigned long size;
  void *data_ptr;

  size = get_image(i, &data_ptr);
    if(size != 0) {
      //lz4_uncrunch(data_ptr, &background_image[i][0], size);
      inflate(&background_image[0], data_ptr);
      // And copy to both framebuffers. This copy is done via the cpu...
      copy_modulo_cpu(&bitplanememory[0][2], &background_image[0], BPLWIDTH/8/2, IMGWIDTH/8/2, IMGHEIGHT*IMGBPLNOS);
      copy_modulo_cpu(&bitplanememory[1][2], &background_image[0], BPLWIDTH/8/2, IMGWIDTH/8/2, IMGHEIGHT*IMGBPLNOS);
  }
}


void wait_until_frame(unsigned long int n) {
  while(framecounter < n) {
  }
}


unsigned char __chip one_dollar_png_mask[1<<12];


/*!\brief Switch to another bitplanememory
 *
 * This will switch to another bitplanememory. Warning! No tests are
 * done, there are only two bitplanes available.
 *
 * \param n which bitplanememory to use (either 0 or 1)
 */
static void switch_2_bitplanememory(short int n) {
  unsigned long l;
  long int i;

  l = (ULONG)&(bitplanememory[n][0]);
  l += 2; //Skip one word so that there is a spare area to the left.
  for(i = 0; i < 4; ++i) {
    moneypositas_copperlist.bitplanes[4 * i + 1] = l >> 16;
    moneypositas_copperlist.bitplanes[4 * i + 3] = l & 0xFFFF;
    l += BPLWIDTH / 8;
  }
  custom.cop1lc = (ULONG)&moneypositas_copperlist.bitplanes[0];
}


void bob_update_routine() {
  int i;
  
  for(i = 0; i < MAXMBOBS; ++i) {
    if((moneybobs[i].x5 += moneybobs[i].speed5x) > BOBHOTSPOT_X) {
      moneybobs[i].x5 = 0;
      moneybobs[i].y5 = (xoroshiro32plusplus() % 120) << 5;
      moneybobs[i].speed5x = 33 + (xoroshiro32plusplus() & 63);
      moneybobs[i].speed5y = -(moneybobs[i].y5 - BOBHOTSPOT_Y) / (BOBHOTSPOT_X / moneybobs[i].speed5x);
    } else {
      moneybobs[i].y5 += moneybobs[i].speed5y;
    }
  }
}


void moneypositas_copy_BOBs(unsigned short int screennum) {
  short i;
  for(i = 0; i < MAXMBOBS; ++i) {
    blit_bob(&bitplanememory[screennum][0],
	     &moneybobs[i]
	     );
  }
}

static void moneypositas_IRQ_routine(void) {
  // This is the *next* screen.
  unsigned short int screennum = (framecounter + 1) & 1;

  // Blit Screen
  copy_image_to_framebuffer(&bitplanememory[screennum][2], &background_image[0]);
  // Play Muzak
  pt_PlayMusic();
  // And update the bobs.
  bob_update_routine();
  // Blit Animation
  blit_with_cc(&bitplanememory[screennum][BPLWIDTH/8*20+30],
	       &animation_image[(framecounter >> 3) % 6].image_n_ccm[0],
	       ANMWIDTH/8,
	       BPLWIDTH/8,
	       ANMHEIGHT,
	       BPLNOS);
  // Blit Bobs
  moneypositas_copy_BOBs(screennum);
  // And now switch
  switch_2_bitplanememory(screennum);
}


static void moneypositas_irq_burning(void) {
  irq_burning(&uSEM.burning);
  // Play Muzak
  pt_PlayMusic();
}


static void moneypositas_irq_flicker(void) {
  irq_flicker(monfli);
  // Play Muzak
  pt_PlayMusic();
}


static void moneypositas_mezzo_routine(void) {
  intermezzo_irq_routine(&uSEM.intermezzotext);
  // Play Muzak
  pt_PlayMusic();
}


static void moneypositas_fistful_routine(void) {
  irq_fistful(&uSEM.fistful);
  // Play Muzak
  pt_PlayMusic();
}


static void moneypositas_greetings_routine(void) {
#ifndef NDEBUG
  breaking_function();
#endif
  irq_scrgreetings(&uSEM.greetings);
  pt_PlayMusic();
}


static void moneypositas_kaboom_routine(void) {
  irq_kaboom(&uSEM.kaboom);
  pt_PlayMusic();
}


/*! \brief generata a cookie-cut mask
 *
 * ORs the rows together to get a cookie-cut mask.
 *
 * \param src pointer to the interleaved bitplanes
 * \param mask destination the mask is written to
 * \param bpr bytes per row
 * \param rows number of rows in the mask
 * \param bpls number of bitplanes
 */
void generate_cookie_cut_mask(const UBYTE *src, UBYTE *mask, unsigned short bpr, unsigned short rows, unsigned short bpls) {
  const UBYTE *srcptr;
  short int x, i;
  unsigned short maskval;

  while(--rows > 0) {
    for(x = 0; x < bpr; ++x) {
      srcptr = &src[x];
      maskval = 0;
      for(i = 0; i < bpls; ++i) {
	maskval |= *srcptr;
	srcptr += bpr;
      }
      *mask++ = maskval;
    }
    src += bpr * bpls;
  }
}


static void uncompress_background_while_flickering(short back, short flick) {
  // Set flicker to flick-number image.
  monfli = init_flicker(&uSEM.flickermem, flick);
  // And wait.
  wait_until_frame(framecounter + 546);
  // Now do the flicker!
  enable_flicker(monfli);
  irq_routine_funpointer = &moneypositas_irq_flicker;
  // Meanwhile get next palette and image...
  gen_copper_palette(&moneypositas_copperlist.colours[0], back);
  // Already get the next background image.
  uncompress_background_data(back);
  // And wait.
  wait_until_frame(framecounter + 66);
  irq_routine_funpointer = &moneypositas_IRQ_routine;
}


static void entrypoint(void) {
  int i;

  custom.dmacon = 0x0020; //Sprites?
  all_black();
  /* Now enable interrupts! */
  custom.intena = INTF_SETCLR|INTF_INTEN|INTF_VERTB;
  custom.dmacon = DMAF_SETCLR|DMAF_BLITTER;
#ifndef NDEBUG
  goto label;
#endif
#ifndef NDEBUG
  breaking_function();
#endif
  // Start up the flitter effect with IRQ routine. This will display
  // something on the screen while preparations are done.
  flitter_effect();
  // Now set up the palette...
  gen_copper_palette(&moneypositas_copperlist.colours[0], 0);
  // Decrunching is done.
  uncompress_background_data(0);
  fill_block(&uSEM.flittermem.logoplane[0], 320/8, 1, 2);
  // TODO: change
  memset(&one_dollar_png_mask[0], 0xFF, sizeof(one_dollar_png_mask));
  fill_block(&uSEM.flittermem.logoplane[0], 320/8, 1, 4);
  decrunch_muzak(&music_memory[0]);
  fill_block(&uSEM.flittermem.logoplane[0], 320/8, 1, 6);
  for(i = 0; i < MAXMBOBS; ++i) {
    moneybobs[i].src = &one_dollar_png[0];
    moneybobs[i].srcw = one_dollar_png_width;
    moneybobs[i].srch = one_dollar_png_height;
    moneybobs[i].cookie = &one_dollar_png_mask[0];
    // If the bob is farther then the X coordinate then a new bob is
    // created so the following line will force an initialisation of
    // all bobs.
    moneybobs[i].x5 = BOBHOTSPOT_X + 1;
  }
  fill_block(&uSEM.flittermem.logoplane[0], 320/8, 1, 20);
  inflate(&animation_image[0].image_n_ccm[0], &animation_plus_ccm[0]);
  fill_block(&uSEM.flittermem.logoplane[0], 320/8, 1, 39);
  // Just make sure that people had some time to enjoy the logo.
  wait_until_frame(358); // (* 50.0 7.1579812373)
  for(i = 0x2c; i < 0x2c + 232; i += 4) {
    flitter_update_cwftr(&uSEM.flittermem, i);
    wait_until_frame(framecounter + 1);
  }
  // Disable the interrupt
  irq_routine_funpointer = NULL;
  // Turn everything to black again.
  all_black();
  // TODO: maybe: all black and start playing music for several
  // seconds before enabling the image.
  // Reset the frame counter
  framecounter = 0;
  // Initialise the music player.
  pt_InitMusic(&music_memory[0]);
  /* Now enable interrupts! */
  custom.intena = INTF_SETCLR|INTF_INTEN|INTF_VERTB;
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER|DMAF_BLITTER|DMAF_BLITHOG;
  // Set normal IRQ routine.
  irq_routine_funpointer = &moneypositas_IRQ_routine;
  uncompress_background_while_flickering(0, 0);
  // burning #######################################################
  prepare_burning(&uSEM.burning);
  set_irq_routine_funpointer(NULL);
  init_burning(&uSEM.burning);
  set_irq_routine_funpointer(&moneypositas_irq_burning);
  wait_until_frame(framecounter + 541);
  set_irq_routine_funpointer(&moneypositas_IRQ_routine);
  // burning #######################################################
  uncompress_background_while_flickering(0, 1);
  // fistful #######################################################
  prepare_fistful(&uSEM.fistful);
  wait_until_frame(framecounter + 541);
  init_fistful(&uSEM.fistful);
  custom.dmacon = DMAF_SETCLR|DMAF_SPRITE;
  set_irq_routine_funpointer(&moneypositas_fistful_routine);
  wait_until_frame(framecounter + 256 * 5);
  set_irq_routine_funpointer(&moneypositas_IRQ_routine);
  // fistful #######################################################
  uncompress_background_while_flickering(1, 2);
  wait_until_frame(framecounter + 540);
  prepare_intermezzo_text(&uSEM.intermezzotext);
  set_irq_routine_funpointer(NULL);
  init_intermezzo_text(&uSEM.intermezzotext);
  set_irq_routine_funpointer(&moneypositas_mezzo_routine);
  wait_until_frame(framecounter + 571);
  set_irq_routine_funpointer(&moneypositas_IRQ_routine);
  // Optimiser optimises away...
  uncompress_background_while_flickering(1, 3);
  // greetings #######################################################
  prepare_scrgreetings(&uSEM.greetings);
  //#TODO: remove#wait_until_frame(framecounter + 540);
  set_irq_routine_funpointer(NULL);
  init_scrgreetings(&uSEM.greetings);
  set_irq_routine_funpointer(&moneypositas_greetings_routine);
  wait_until_frame(framecounter + 612);
  set_irq_routine_funpointer(&moneypositas_IRQ_routine);
  // greetings #######################################################
  uncompress_background_while_flickering(2, 4);
  uncompress_background_while_flickering(2, 5);
  // KABOOM #######################################################
#ifndef NDEBUG
 label:
  custom.intena = INTF_SETCLR|INTF_INTEN|INTF_VERTB;
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER|DMAF_BLITTER|DMAF_BLITHOG;
#endif
  prepare_kaboom(&uSEM.kaboom);
  set_irq_routine_funpointer(NULL);
  init_kaboom(&uSEM.kaboom);
  set_irq_routine_funpointer(moneypositas_kaboom_routine);
  wait_until_frame(framecounter + 141);
  kaboom_green_out(&uSEM.kaboom);
  //wait_until_frame(framecounter + 158);
  // KABOOM #######################################################
  /*
    - set normal irq routine
    - wait
    - set to obey mode
      * change copperlist
      * change IRQ
    - decrunch next image
    - wait(?)
    - set to animation mode again
    - wait
    - etc.

    - after that: black again?
    - display animated BOOM
    - credits
   */
  custom.intena = INTF_SETCLR|INTF_INTEN|INTF_VERTB;
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER|DMAF_RASTER|DMAF_COPPER;
#ifdef DEBUG
  do {
    custom.color[0] = ~framecounter;
  } while(1);
#endif
}


int main(int argc, char **argv) {
  unsigned short int i;

  putchar('\f');
#ifndef NDEBUG
  unsigned long l0, l1;
  unsigned long size;
  void *data_ptr;

  printf("uSEM=$%08lX\n", (ULONG)&uSEM);
  printf("sizes: uSEM %lx kaboom %lx\n", sizeof(uSEM), sizeof(struct Kaboom));
  printf("breaking_function=$%08lx\n", (ULONG)&breaking_function);
  printf("set_irq_routine=$%08lx\n", (ULONG)&set_irq_routine);
  printf("entrypoint=$%08lx\n", (ULONG)&entrypoint);
  printf("chipmem end=$%08lx\n", (ULONG)&whole_chipmem_end[0]);
  printf("get_image()=$%08lx\n", (ULONG)&get_image);
  printf("moneypositas_copperlist=$%08lx\n", (ULONG)&moneypositas_copperlist);
  printf("prepare_flitter=$%08lx\n", (ULONG)&prepare_flitter);
  printf("irq_flicker=$%08lx\n", (ULONG)&irq_flicker);
  printf("generate_cookie_cut_mask=$%08lx\n", (ULONG)&generate_cookie_cut_mask);
  printf("blit_single_plane=$%08lx\n", (ULONG)&blit_single_plane);
  printf("copy_modulo_cpu=$%08lx\n", (ULONG)&copy_modulo_cpu);
  printf("moneypositas_IRQ_routine=$%08lx\n", (ULONG)&moneypositas_IRQ_routine);
  printf("intermezzo_irq_routine=$%08lx\n", (ULONG)&intermezzo_irq_routine);
  printf("irq_burning=$%08lx\n", (ULONG)&irq_burning);
  printf("bit_bob=$%08lx\n", (ULONG)&blit_bob);
  puts("DEBUG Version! Do *not* spread!");
  for(i=0; i < 31991; ++i) {
    int j;
    for(j=0; j < 7; ++j) {
      custom.color[0] = j;
    }
  }
#else
  puts(hello_string);
#endif
  setup_amiga();
  set_irq_routine(NULL, &entrypoint, NULL);
  pt_StopMusic();
  custom.intena = 0x7fff;
  custom.dmacon = (1<<15)|(1<<9)|(1<<6); //Reenable for wait.
  //WAITBLIT;
  custom.dmacon = 0x7fff; //And disable again...
  clean_up_the_mess();
  return 0;
}
