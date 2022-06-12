#include <stdio.h>
#include <string.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include "t7d/own.h"
#include "t7d/textmonochrome.h"
#include "globals.h"
#include "mathtab.h"
#include "part.swooshing.h"
#include "chipmemstorage.h"
#include "default_irq.h"

extern WORD part_swooshing_copper_list[];
extern WORD part_swooshing_copper_list_end[];

extern volatile struct Custom custom;

extern char fontdata[];

extern void init_swinging(void);
extern void swinging_display(int effect, int raster, int offset, char *bitmap);
extern void swinging_disable_slot(__reg("d0") UWORD slotnum);
extern void init_for_you(__reg("a0") char *bitmap);
extern void for_you_blit_it_is(__reg("a0") BYTE *bitmap, __reg("d0") int bitplane);
extern void for_you_unblit_it_is(__reg("a0") BYTE *bitmap, __reg("d0") int bitplane);

typedef struct SwingText {
  unsigned short rasterline;
  int amplitude;
  long t;
  short speed;
  unsigned short delay;
  unsigned short amplitude_step; //!< count before reducing.
} SwingText;

void clear_swinging_memory(void) {
  memset(&chip_gfx_memory[0], 0, SWINGING_width/8L*SWINGING_height*SWINGING_depth);
}  

void center_text(const char *str, short scanline) {
  long len = strlen(str);
  unsigned long off = (40 - len) / 2 + SWINGING_left_border/8 + SWINGING_width/8 * scanline;
  text_monochrome(str, fontdata, chip_gfx_memory + off, SWINGING_width/8);
}

int update_swinger(SwingText *ptr) {
  int ret = -32768;
  long a;

  #ifndef NDEBUG
  //printf("a=%d t=%ld s=%hd d=%4x\t", ptr->amplitude, ptr->t, ptr->speed, ptr->delay);
  #endif
  if(ptr->delay > 0) {
    ptr->delay -= 1;
    return ret;
  } else {
    ret = sinus[(ptr->t >> 5) % sinus_size];
    ptr->t += ptr->speed;
  }
  if(ret == 0) {
    if((ptr->amplitude_step++ > 3) == 0) {
      ptr->amplitude_step = 0;
      a = ptr->amplitude * 44769;
      a >>= 16;
      if(a < 30) {
	a = 0;
      }
      ptr->amplitude = a;
    }
  }
  return (ret * ptr->amplitude) >> 15;
}

void wait_frames(int num) {
  irqcounter = num;
  while(irqcounter > 0) {}
}

void wait_a_frame(void) {
  wait_frames(1);
}

void part_swingers(void) {
  SwingText swingers[] =
    {
     { 0x50 + 26*0, 320, (512/4) << 5, 64, 100       , 0 },
     { 0x50 + 26*1, 320, (512/4) << 5, 64, 100 + 50*3 },
     { 0x50 + 26*2, 320, (512/4) << 5, 64, 100 + 50*4 },
     { 0x50 + 26*3, 320, (512/4) << 5, 64, 100 + 50*7 },
     { 0x50 + 26*4, 320, (512/4) << 5, 64, 100 + 50*9 },
     { 0x50 + 26*6, 320, (512/4) << 5, 64, 100 + 50*18 }
    };
  int i;
  int pos;
  int asum; // Amplitude sum

  // First draw the texts.
  center_text("Are you fed up", SWINGING_step * 0);
  center_text("with watching", SWINGING_step * 1);
  center_text("crappy demos with", SWINGING_step * 2);
  center_text("repetitive music and", SWINGING_step * 3);
  center_text("psychedelic graphics?", SWINGING_step * 4);
  center_text("Then this opus is for you!", SWINGING_step * 5);
  init_swinging();
  do {
    wait_a_frame();
    //custom.color[0] = 0x000f;
    asum = 0;
    for(i = 0; i < sizeof(swingers)/(sizeof(SwingText)); ++i) {
      pos = update_swinger(&swingers[i]);
      if(pos != -32768) {
	swinging_display(i, swingers[i].rasterline, 320 + pos, &chip_gfx_memory[0] + SWINGING_step * i * SWINGING_width/8);
      }
      asum += swingers[i].amplitude;
    }
    //custom.color[0] = 0x0fff;
  } while(asum > 0);
}
  
void part_it_is_for_you(void) {
  int i;
  BYTE *bitmap = &chip_gfx_memory[0]; // Bitmap pointer.

  init_for_you(bitmap);
  wait_frames(75);
  for(i = 3; i >= 0; --i) {
    for_you_blit_it_is(bitmap, i);
    wait_frames(6);
  }
  wait_frames(3*50);
  for(i = 0; i <= 3; ++i) {
    for_you_unblit_it_is(bitmap, i);
    wait_frames(6);
  }
}

int main(void) {
  int i;
  puts("Mercifully short...");
  clear_swinging_memory();
#ifndef NDEBUG
  printf("%p\n", (void*)&main);
  printf("%p\n", (void*)chip_gfx_memory);
  printf("%p\n", (void*)image_mercifully);
  printf("%p\n", part_swooshing_copper_list);
  printf("%p\n", part_swooshing_copper_list_end);
  printf("diff=%d\n", part_swooshing_copper_list_end-part_swooshing_copper_list);
  printf("diff=%d\n", (ULONG)part_swooshing_copper_list_end-(ULONG)part_swooshing_copper_list);
  for(i=0; i<62000; ++i) {
    custom.color[0]=i;
  }
#endif
  own_machine(OWN_libraries|OWN_view|OWN_interrupt);
  install_enable_IRQ();
  // Enable sound DMA.
  custom.dmacon = DMAF_SETCLR | DMAF_AUDIO;
#ifdef NDEBUG
  part_swingers();
  irqcounter = 56;
  while(irqcounter > 0) {}
  for(i = 5; i >= 0; --i) {
    swinging_disable_slot(i);
    wait_frames(48);
  }
  // Enable Blitter.
  custom.dmacon = DMAF_SETCLR | DMAF_BLITTER;
  part_it_is_for_you();
  WAITFRAMES(30);
#endif
  part_swooshing();
  disown_machine();
  return 0;
}
