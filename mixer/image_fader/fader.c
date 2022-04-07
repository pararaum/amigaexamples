#include <stdio.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <own.h>

#define IMAGE_WIDTH 320
#define IMAGE_HEIGHT 256
#define IMAGE_BITPLANES 5

extern unsigned long set_interrupt();

extern struct Custom custom;
extern unsigned long volatile framecounter;
extern unsigned short volatile mousebutton;
extern volatile void (*vertical_blank_irqfun)(void);
extern int uncompress_next_image(__reg("a0") UBYTE *target, __reg("a1") UWORD *bplcon0store);
extern int fade_in_copper_list(__reg("d0") int colours, __reg("d1") modulo, __reg("a0") UWORD *colourdata, __reg("a1") UWORD *targetptr, __reg("a2") void *spare_area);
extern int fade_out_colour_table(__reg("d0") int number_of_colours, __reg("a0") UWORD *colourdata);
extern void *play_sample(__reg("d0") int sample_no);

/* These are pointers to the image data */
extern unsigned long image_pointers[];
extern UWORD image_colour_data[];

static UWORD *pointer_to_copper_bplcon0;
static UWORD spare_area_for_fader[32*4+1]; /*!< Here the fader stores it temporary data. */

static UWORD __chip copper_list[0xA0];
static UBYTE __chip bitplane_data[IMAGE_WIDTH * IMAGE_HEIGHT * IMAGE_BITPLANES / 8];

/*! This is the current number of image colours. It is accessed by multiple functions. */
int current_number_img_cols;

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

  /* $dff100	BPLCON0	Bitplane depth and screen mode */
  *cptr++ = 0x0100;
  pointer_to_copper_bplcon0 = cptr;
  *cptr++ = 0; /* All off! */
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
  /* WAIT: Display window start is at Y=$2c and we have only 200 lines which is $2c+200=$f4 */
  *cptr++ = 0xf401;
  *cptr++ = 0xFFFE;
  /* BPLCON0 */
  *cptr++ = 0x0100;
  *cptr++ = 0;
  /* END */
  *cptr++ = 0xFFFF;
  *cptr++ = 0xFFFE;
#ifndef NDEBUG
  fprintf(stderr, "Copper: %08lX < %08lX\n", (ULONG)cptr, (ULONG)cend);
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
  custom.bpl1mod = 0;
  custom.bpl2mod = 0;
  custom.fmode = 0;
  /* Clear colours (set to black). */
  for(i = 0; i < 32; ++i) {
    custom.color[i] = 0;
  }
  return set_interrupt();
}

void funnyirqfun(void) {
  static UWORD value = 0;
  custom.color[0] = value++;
}

void fadeinfunction(void) {
  if(fade_in_copper_list(current_number_img_cols, 0, image_colour_data, (void*)(0xDFF180UL), spare_area_for_fader) != 0) {
    vertical_blank_irqfun = NULL;
  }
}


void fadeoutfunction(void) {
  int i;

  i = fade_out_colour_table(current_number_img_cols, image_colour_data);
  if(i == 0) {
    /* Now finished! */
    vertical_blank_irqfun = NULL;
  }
  for(i = 0; i < current_number_img_cols; ++i) {
    custom.color[i] = image_colour_data[i];
  }
}

void wait4end(void) {
  while(vertical_blank_irqfun != NULL) {
    if(mousebutton != 0) {
      break;
    }
  }
}


void waitframes(int secs) {
  unsigned long tframe;

  tframe = framecounter + 50 * secs;
  while(framecounter < tframe) {
        if(mousebutton != 0) {
      break;
    }
  }
}


/*! Stop sample playback.
 *
 * We do not want the sample to loop all the time. Therefore we stop
 * it again by setting the length to 1 and pointing to a sample
 * consisting of zeros.
 *
 * Links:
 *  * http://eab.abime.net/showthread.php?t=59756
 *  * http://cyberpingui.free.fr/tuto_paula.htm
 */
void stop_sample(void) {
  int i;
  unsigned short rastpos;
  static __chip UWORD empty = 0;

  /* Read V0 to V7 */
  rastpos = custom.vhposr & 0xff00;
  rastpos += 0x0200; /* Next rasterline. */
  while(custom.vhposr < rastpos);
  /* This should have wasted enough time that Paula had time to start
   * the DMA fetch.  Now we can change the registers safely and it
   * will fetch the new values after the sample had been played.
   */
  for(i = 0; i < 4; ++i) {
    custom.aud[i].ac_len = 1;
    custom.aud[i].ac_ptr = &empty;
  }
}


void fadeloop(void) {
  int i;
  int counter = 0;

  while((current_number_img_cols = uncompress_next_image(bitplane_data, pointer_to_copper_bplcon0)) != 0) {
    for(i = 0; i < sizeof(spare_area_for_fader)/sizeof(UWORD); ++i) {
      spare_area_for_fader[i] = 0;
    }
    vertical_blank_irqfun = &fadeinfunction;
    play_sample(counter);
    stop_sample();
    wait4end();
    waitframes(3);
    vertical_blank_irqfun = &fadeoutfunction;
    wait4end();
    ++counter;
  }
  for(i = 1; i < 16; ++i) {
    custom.color[i] = i << 8 | i << 4 | i;
  }
  /* The default is *planar* images. */
  custom.bpl1mod = 0;
  custom.bpl2mod = 0;
  vertical_blank_irqfun = &funnyirqfun;
  waitframes(4);
}


void run_demo(void) {
  unsigned long ul;

#ifndef NDEBUG
  for(ul = 0; ul < 150000; ul++) ;
#endif
  if(own_machine(OWN_libraries|OWN_view|OWN_trap|OWN_interrupt) != 0) {
    ul = all_black();
    fadeloop();
#if 0
    printf("irq routine=$%lx\n", ul);
    printf("framecounter=%08lX\n", framecounter);
#endif
  }
  /* Disable DMA and interrupts before(!) quitting. */
  custom.dmacon = 0x7fff;
  custom.intena = 0x7fff;
  custom.intreq = 0x7fff;
}

int main(int argc, char **argv) {
#ifndef NDEBUG
  printf("run_demo=$%08lX\n", (ULONG)&run_demo);
  printf("spare_area_for_fader=$%08lX\n", (ULONG)&spare_area_for_fader);
  printf("copper_list=$%08lX\n", (ULONG)copper_list);
  printf("main=$%08lX\n", (ULONG)&main);
  printf("fadeloop=$%08lX\n", (ULONG)fadeloop);
  printf("bitplane_data=$%08lX\n", (ULONG)bitplane_data);
  printf("uncompress_next_image=$%08lX\n", (ULONG)uncompress_next_image);
  printf("fadeinfunction=$%08lX\n", (ULONG)fadeinfunction);
  printf("fadeoutfunction=$%08lX\n", (ULONG)fadeoutfunction);
  printf("image_colour_data=$%08lX\n", (ULONG)image_colour_data);
  printf("play_sample=$%08lX\n", (ULONG)play_sample);
#endif
  if(setup() != 0) {
    puts("ERROR! Not enough space in copper list!");
  }
  run_demo();
  disown_machine();
  return 0;
}
