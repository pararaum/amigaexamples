#include <string.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <t7d/copper_tools.h>
#include "globals.h"
#include "chipmemstorage.h"
#include "default_irq.h"
#include "customchips.h"
#include "croppedsprite.101.11.sprite"
#include "croppedsprite.133.11.sprite"
#include "croppedsprite.101.42.sprite"
#include "croppedsprite.133.42.sprite"
#include "croppedsprite.101.100.sprite"
#include "croppedsprite.133.100.sprite"
#include "croppedsprite.101.71.sprite"
#include "croppedsprite.133.71.sprite"
#include "colours.sprite"

#define PEN_SIZE 20
#define DRAW_AHEAD 10
#define STROKE_DIST 9
#define SPRITEXSHIFT 3
#define SPRITEYSHIFT 7

#define COPPERPTRMOVE(ptr, reg, val) *ptr++ = reg; *ptr++ = val;
#define COPPERPTRMOVE32(ptr, reg, val) *ptr++ = reg; *ptr++ = (val)>>16; *ptr++ = (reg)+2; *ptr++ = (val)&0xFFFF;
#define COPPERPTRWAIT(ptr, vpos, hpos) *ptr++ = ((vpos)<<8)|(hpos)|1; *ptr++ = 0xfffe;
#define COPPERPTRBLITFIN(ptr) *ptr++ = 0x101; *ptr++ = 0x7ffe;

extern volatile struct Custom custom;

extern WORD part_swooshing_copper_list[];
extern WORD part_swooshing_copper_list_end[];
extern WORD part_swooshing_copspace4blit[];
extern WORD part_swooshing_copper_bplptr[];
extern WORD part_swooshing_copper_colours[];
extern WORD part_swooshing_copper_sprpt[]; //!< Space for the sprite pointers.

typedef struct Sprite_t {
  BYTE *sprimg; //!< Pointer to original sprite image data.
  WORD height; //!< height of sprite
  short dx;
  short dy;
  short x;
  WORD y;
  WORD *sprptr; //!< Pointer to the first word in the sprite structure.
} Sprite_t;

static Sprite_t spritedata[8][4] =
  {
   {
    { croppedsprite_101_11_png, sizeof(croppedsprite_101_11_png)/2/2, 3, 1, 0, 0x4a, NULL },
    { croppedsprite_101_11_png, sizeof(croppedsprite_101_11_png)/2/2, 6, 0, 200, 0x81, NULL },
    { croppedsprite_101_11_png, sizeof(croppedsprite_101_11_png)/2/2, 2, -1, 0, 0x7a, NULL },
    { NULL }
   },
   {
    { croppedsprite_133_11_png, sizeof(croppedsprite_133_11_png)/2/2, -4, -1, 200, 0xc1, NULL },
    { croppedsprite_133_11_png, sizeof(croppedsprite_133_11_png)/2/2, -5, 0, 200, 0x91, NULL },
    { croppedsprite_133_11_png, sizeof(croppedsprite_133_11_png)/2/2, -3, 1, 200, 0xc6, NULL },
    { NULL }
   },
   {
    { croppedsprite_101_42_png, sizeof(croppedsprite_101_42_png)/2/2, 7, 1, 0, 0x4c, NULL },
    { croppedsprite_101_42_png, sizeof(croppedsprite_101_42_png)/2/2, 2, 0, 197, 0x83, NULL },
    { croppedsprite_101_42_png, sizeof(croppedsprite_101_42_png)/2/2, 4, 1, 200, 0xc1, NULL },
    { NULL }
   },
   {
    { croppedsprite_133_42_png, sizeof(croppedsprite_133_42_png)/2/2, -4, 0, 0, 0x4f, NULL },
    { croppedsprite_133_42_png, sizeof(croppedsprite_133_42_png)/2/2, -3, 1, 197, 0x63, NULL },
    { croppedsprite_133_42_png, sizeof(croppedsprite_133_42_png)/2/2, -8, -1, 200, 0xf1, NULL },
    { NULL }
   },
   {
    { croppedsprite_101_71_png, sizeof(croppedsprite_101_71_png)/2/2, 1, 0, 0, 0x6a, NULL },
    { croppedsprite_101_71_png, sizeof(croppedsprite_101_71_png)/2/2, 3, 0, 197, 0xa3, NULL },
    { croppedsprite_101_71_png, sizeof(croppedsprite_101_71_png)/2/2, 5, 0, 200, 0xec, NULL },
    { NULL }
   },
   {
    { croppedsprite_133_71_png, sizeof(croppedsprite_133_71_png)/2/2, -3, 1, 17, 0x4f, NULL },
    { croppedsprite_133_71_png, sizeof(croppedsprite_133_71_png)/2/2, -5, 1, 169, 0x63, NULL },
    { croppedsprite_133_71_png, sizeof(croppedsprite_133_71_png)/2/2, -1, -1, 82, 0xff, NULL },
    { NULL }
   },
   {
    { croppedsprite_101_100_png, sizeof(croppedsprite_101_100_png)/2/2, 4, -1, 0, 0x7e, NULL },
    { croppedsprite_101_100_png, sizeof(croppedsprite_101_100_png)/2/2, 7, -1, 197, 0xa2, NULL },
    { croppedsprite_101_100_png, sizeof(croppedsprite_101_100_png)/2/2, 2, 0, 200, 0xc3, NULL },
    { NULL }
   },
   {
    { croppedsprite_133_100_png, sizeof(croppedsprite_133_100_png)/2/2, -7, 0, 17, 0x6d, NULL },
    { croppedsprite_133_100_png, sizeof(croppedsprite_133_100_png)/2/2, -2, 1, 169, 0x9b, NULL },
    { croppedsprite_133_100_png, sizeof(croppedsprite_133_100_png)/2/2, -4, 0, 82, 0xe1, NULL },
    { NULL }
   },
  };

int offsets[]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,3,3,2,2,2,2,2,2,1,1,1,1,0,0,0,0,0,-1,-1,-1,-1,-2,-2,-2,-2,-3,-3,-3,-3,-3,-4,-4,-4,-4,-4,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-4,-4,-4,-4,-3,-3,-3,-3,-2,-2,-2,-1,-1,-1,0,0,0,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,2,2,2,1,1,0,0,0,-1,-1,-2,-2,-2,-3,-3,-3,-4,-4,-4,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-4,-4,-4,-3,-3,-2,-2,-2,-1,-1,0,0,1,1,2,2,2,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,2,2,2,1,1,0,0,-1,-2,-2,-3,-3,-3,-4,-4,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-4,-4,-4,-3,-3,-2,-1,-1,0,0,1,1,2,2,3,3,4,4,4,4,4,4,4,4,4,4,4,3,3,2,2,1,1};
#define nOFFSETS (sizeof(offsets)/sizeof(int))
WORD __chip copperlists[4][160];
WORD __chip spritelist[8][240];

BYTE __chip swooshmask[IMAGE_BACKGROUND_FISH_width/8*IMAGE_BACKGROUND_FISH_height];
// Pointer into the bitmap, one for each line. It will be
// precalculated to speed up the image painting process.
BYTE *bitmap_pointers[IMAGE_BACKGROUND_FISH_height];

/** Copy copper list and add blitter commands
 *
 * @param dest destination area for copper list
 * @param offset offset to add to the bitplane (image)
 */
static void create_blitter(WORD *dest, int offset) {
  WORD *cptr;
  ULONG gfxmem = (ULONG)chip_gfx_memory;

  offset *= IMAGE_BACKGROUND_FISH_width / 8; // Adjust for lines.
  // Now create the blitpart.
  cptr = dest + (part_swooshing_copspace4blit - part_swooshing_copper_list);
  //COPPERPTRMOVE(cptr, COLOR(0), 0x0ffe);
  COPPERPTRBLITFIN(cptr);
  COPPERPTRMOVE32(cptr, BLTAPT, (ULONG)image_2022_04_17_20_37_59_png + offset);
  COPPERPTRMOVE32(cptr, BLTCPT, (ULONG)swooshmask);
  COPPERPTRMOVE32(cptr, BLTBPT, (ULONG)image_mercifully);
  COPPERPTRMOVE32(cptr, BLTDPT, (ULONG)gfxmem + offset);
  COPPERPTRMOVE(cptr, BLTCON0, 0x0ff8); // D = A + BC
  COPPERPTRMOVE(cptr, BLTCON1, 0);
  COPPERPTRMOVE(cptr, BLTAFWM, 0xffff);
  COPPERPTRMOVE(cptr, BLTALWM, 0xffff);
  COPPERPTRMOVE(cptr, BLTAMOD, IMAGE_BACKGROUND_FISH_width / 8 * (IMAGE_BACKGROUND_FISH_depth - 1));
  COPPERPTRMOVE(cptr, BLTBMOD, 0);
  COPPERPTRMOVE(cptr, BLTCMOD, 0);
  COPPERPTRMOVE(cptr, BLTDMOD, IMAGE_BACKGROUND_FISH_width / 8 * (IMAGE_BACKGROUND_FISH_depth - 1));
  COPPERPTRMOVE(cptr, BLTSIZE, (200 << 6) | (320/8/2));
  //COPPERPTRMOVE(cptr, COLOR(0), 0x0f00);
  //COPPERPTRBLITFIN(cptr);
  //COPPERPTRMOVE(cptr, COLOR(0), 0x00f0);
}

static void setup_bitplanepointers(WORD *cptr) {
  short i;
  ULONG gfxmem = (ULONG)chip_gfx_memory;

  cptr += part_swooshing_copper_bplptr - part_swooshing_copper_list;
  for(i = 0; i < IMAGE_BACKGROUND_FISH_depth; ++i) {
    ULONG bmptr = gfxmem + i * IMAGE_BACKGROUND_FISH_width / 8;
    cptr[4 * i] = BPLPT + 4 * i;
    cptr[4 * i + 1] = bmptr >> 16;
    cptr[4 * i + 2] = BPLPT + 4 * i + 2;
    cptr[4 * i + 3] = bmptr;
  }
}

static void setup_spritepointers(WORD *cptr) {
  short i;

  cptr += part_swooshing_copper_sprpt - part_swooshing_copper_list;
  for(i = 0; i < 8; ++i) {
    ULONG gfxmem = (ULONG)(&spritelist[i][0]);
    cptr[4 * i] = SPRPT + 4 * i;
    cptr[4 * i + 1] = gfxmem >> 16;
    cptr[4 * i + 2] = SPRPT + 4 * i + 2;
    cptr[4 * i + 3] = gfxmem;
  }
}

static void setup_copperlist(void) {
  ULONG gfxmem = (ULONG)chip_gfx_memory;
  const size_t sizeofcopperlist = sizeof(WORD) * (part_swooshing_copper_list_end - part_swooshing_copper_list);
  short i;

  // Setup the basic colours.
  make_colour_copperlist_background(part_swooshing_copper_colours);
  for(i = 0; i < 4; ++i) {
    // Copy original list.
    memcpy(&copperlists[i][0], part_swooshing_copper_list, sizeofcopperlist);
    // Setup bitplanepointers
    setup_bitplanepointers(&copperlists[i][0]);
    // Setup blitteroperation
    create_blitter(&copperlists[i][0], i);
    // Setup spritepointers
    setup_spritepointers(&copperlists[i][0]);
  }
}

static void activate_next_copperlist(void) {
  static int counter = 0;
  WORD *cptr = &copperlists[counter & 3][0];
  custom.cop1lc = (ULONG)(cptr);
  ++counter;
}

static void init_setpixel(unsigned char *bitmap) {
  int y;

  for(y = 0; y < IMAGE_BACKGROUND_FISH_height; ++y) {
    bitmap_pointers[y] = bitmap + y * IMAGE_BACKGROUND_FISH_width / 8;
  }
}

static void setpixel(int x, int y) {
  if (x < 0) return;
  if (x >= IMAGE_BACKGROUND_FISH_width) return;
  if (y < 0) return;  
  if (y >= IMAGE_BACKGROUND_FISH_height) return;
  bitmap_pointers[y][x >> 3] |= 1 << (7 - (x & 7));
}

static void stroke(int startx, int starty) {
  int offset_idx,i;
  
  offset_idx=startx*starty % nOFFSETS;
  do {
     for(i=0;i<PEN_SIZE+offsets[offset_idx]/2;i++) {
	   setpixel(startx+offsets[offset_idx]+i,starty-PEN_SIZE);
     }
     startx++;
     offset_idx = (offset_idx+1) % nOFFSETS;	 
     starty--;
  } while (starty>-PEN_SIZE);
}

static void swoosh_init(unsigned char *bitmap) {
  int xd, nextstroke;
  int strokes[(IMAGE_BACKGROUND_FISH_width+IMAGE_BACKGROUND_FISH_height)/STROKE_DIST];
  int r,i;

  init_setpixel(bitmap);
  for(i = 0; i < sizeof(strokes)/sizeof(int); i++) {
    strokes[i]=0;
  }
  //phase 1: do the regular strokes
  xd=0;
  do {
    do {
      nextstroke=xd+r%DRAW_AHEAD;
      r++;
    } while(strokes[nextstroke]);
    // PRNG, fast enough(?)
    r = (r + 1) * 4711;
    stroke(-IMAGE_BACKGROUND_FISH_height+1+nextstroke*STROKE_DIST,IMAGE_BACKGROUND_FISH_height+PEN_SIZE-1);
    strokes[nextstroke]++;
    while(strokes[xd]) xd++; //advance pointer
  } while(xd*STROKE_DIST<IMAGE_BACKGROUND_FISH_width+IMAGE_BACKGROUND_FISH_height);
  //phase 2: add well placed strokes until everything is painted
}

void update_sprite(Sprite_t *spr) {
  spr->x += spr->dx;
  spr->y += spr->dy;
  short tx = spr->x >> SPRITEXSHIFT;
  WORD ty = spr->y >> SPRITEYSHIFT;
  WORD *dest = spr->sprptr;
  WORD tyhi; // True y moved to high byte.
  tyhi = ty << 8; // Put to high byte.
  *dest++ = (tx >> 1) | tyhi;
  *dest = tyhi + (spr->height << 8);
  if((spr->x & 1) != 0) {
    *dest |= 1;
  }
  if(ty >= 256) {
    *dest |= 4;
  }
  if((ty + spr->height) >= 256) {
    *dest |= 2;
  }
  if(tx > 447) {
    spr->x = 0;
  }
  if(spr->x < 0) {
      spr->x = 447 << SPRITEXSHIFT;
  }
}

WORD *make_sprite(WORD *dest, Sprite_t *spr) {
  short tx = spr->x; // true X
  WORD ty = spr->y; // true Y
  spr->sprptr = dest; // Set pointer to the sprite list.
  spr->x <<= SPRITEXSHIFT;
  spr->y <<= SPRITEYSHIFT;
  ty <<= 8; // Put to high byte.
  *dest++ = tx | ty;
  *dest = ty + (spr->height << 8);
  if(spr->x & 2 /*0b00000000000000010*/) {
    *dest |= 1;
  }
  memcpy(++dest, spr->sprimg, 2*2*spr->height);
  return dest + spr->height * 2;
}

void init_sprite() {
  Sprite_t *sprptr;
  int i;

  for(i = 0; i < 8; ++i) {
    WORD *dest = &spritelist[i][0];
    for(sprptr = &spritedata[i][0]; sprptr->sprimg != NULL; ++sprptr) {
      dest = make_sprite(dest, sprptr);
    }
  }
}

void update_spritepos(__reg("a0") WORD *ptr, __reg("d0") WORD pos) =
  "	lsr.w	#2,d0\n\
	addq	#1,a0\n\
	move.b	d0,(a0)\n\
	addq	#2,a0\n\
	moveq	#0,d0\n\
	addx.b	d0,d0\n\
	move.b	d0,(a0)";

void irq_vbl_routine(void) {
  Sprite_t *sprptr;
  int i;

  activate_next_copperlist();
  for(i = 0; i < 8; ++i) {
    for(sprptr = &spritedata[i][0]; sprptr->sprimg != NULL; ++sprptr) {
      update_sprite(sprptr);
    }
  }
}

void part_swooshing(void) {
  // Disable blitter and sprites for a moment.
  custom.dmacon = DMAF_SPRITE | DMAF_BLITTER;
  memcpy(&custom.color[16], spritesheet_png_palette, sizeof(spritesheet_png_palette));
  memcpy(chip_gfx_memory, IMAGE_BACKGROUND_FISH_name, IMAGE_BACKGROUND_FISH_width*IMAGE_BACKGROUND_FISH_height*IMAGE_BACKGROUND_FISH_depth/8);
  memset(swooshmask, 0, sizeof(swooshmask));
  setup_copperlist();
  custom.copcon = 2; // Give the force to the copper!
  init_sprite();
  // Enable Blitter.
  custom.dmacon = DMAF_SETCLR | DMAF_MASTER | DMAF_RASTER | DMAF_SPRITE | DMAF_COPPER | DMAF_BLITTER | DMAF_AUDIO;
  irqVBLroutine = &irq_vbl_routine;
  swoosh_init(swooshmask);
  WAITFRAMES(75);
}
