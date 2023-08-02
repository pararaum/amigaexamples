#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include <stdio.h>
#include "t7d/inflate.h"
#include "for_a_fistful_of_dollars.h"
#include "t7d/iff.h"
#include "images.h"
#include "globals.h"

unsigned short font_16x16_4bpls_png_palette[] = {
	0x0000,
	0x00f0,
	0x00d0,
	0x00b0,
	0x0080,
	0x0060,
	0x0040,
	0x00ff,
	0x00cc,
	0x00aa,
	0x0077,
	0x0054,
	0x0022,
	0x0fff,
	0x0000,
	0x0000,
};

static UWORD font_data_16x16[16*960*4/16];

static short sinus_table[512] = {
  // Emacs:
  // (let (value)
  // (dotimes (number 512 value)
  //   (setq value
  // 	  (concat value
  // 		  (format "%d, " (* 64 (sin (* 2 pi (/ number 511.0)))))
  // 		  )
  // 	  )))
  0, 0, 1, 2, 3, 3, 4, 5, 6, 7, 7, 8, 9, 10, 10, 11, 12, 13, 14, 14, 15, 16, 17, 17, 18, 19, 20, 20, 21, 22, 23, 23, 24, 25, 25, 26, 27, 28, 28, 29, 30, 30, 31, 32, 32, 33, 34, 34, 35, 36, 36, 37, 38, 38, 39, 40, 40, 41, 41, 42, 43, 43, 44, 44, 45, 45, 46, 46, 47, 48, 48, 49, 49, 50, 50, 51, 51, 51, 52, 52, 53, 53, 54, 54, 54, 55, 55, 56, 56, 56, 57, 57, 57, 58, 58, 58, 59, 59, 59, 60, 60, 60, 60, 61, 61, 61, 61, 61, 62, 62, 62, 62, 62, 62, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 62, 62, 62, 62, 62, 62, 61, 61, 61, 61, 60, 60, 60, 60, 59, 59, 59, 59, 58, 58, 58, 57, 57, 57, 56, 56, 55, 55, 55, 54, 54, 53, 53, 53, 52, 52, 51, 51, 50, 50, 49, 49, 48, 48, 47, 47, 46, 46, 45, 45, 44, 43, 43, 42, 42, 41, 40, 40, 39, 39, 38, 37, 37, 36, 35, 35, 34, 33, 33, 32, 31, 31, 30, 29, 29, 28, 27, 27, 26, 25, 24, 24, 23, 22, 21, 21, 20, 19, 18, 18, 17, 16, 15, 15, 14, 13, 12, 12, 11, 10, 9, 9, 8, 7, 6, 5, 5, 4, 3, 2, 1, 1, 0, 0, -1, -1, -2, -3, -4, -5, -5, -6, -7, -8, -9, -9, -10, -11, -12, -12, -13, -14, -15, -15, -16, -17, -18, -18, -19, -20, -21, -21, -22, -23, -24, -24, -25, -26, -27, -27, -28, -29, -29, -30, -31, -31, -32, -33, -33, -34, -35, -35, -36, -37, -37, -38, -39, -39, -40, -40, -41, -42, -42, -43, -43, -44, -45, -45, -46, -46, -47, -47, -48, -48, -49, -49, -50, -50, -51, -51, -52, -52, -53, -53, -53, -54, -54, -55, -55, -55, -56, -56, -57, -57, -57, -58, -58, -58, -59, -59, -59, -59, -60, -60, -60, -60, -61, -61, -61, -61, -62, -62, -62, -62, -62, -62, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -63, -62, -62, -62, -62, -62, -62, -61, -61, -61, -61, -61, -60, -60, -60, -60, -59, -59, -59, -58, -58, -58, -57, -57, -57, -56, -56, -56, -55, -55, -54, -54, -54, -53, -53, -52, -52, -51, -51, -51, -50, -50, -49, -49, -48, -48, -47, -46, -46, -45, -45, -44, -44, -43, -43, -42, -41, -41, -40, -40, -39, -38, -38, -37, -36, -36, -35, -34, -34, -33, -32, -32, -31, -30, -30, -29, -28, -28, -27, -26, -25, -25, -24, -23, -23, -22, -21, -20, -20, -19, -18, -17, -17, -16, -15, -14, -14, -13, -12, -11, -10, -10, -9, -8, -7, -7, -6, -5, -4, -3, -3, -2, -1, 0, 0
};

static void copy_font_2_sprite(UWORD *tgt0, UWORD *tgt1, int chr) {
  int i;

  chr -= ' ';
  chr *= 16 * 4;
  for(i = 0; i < 16; ++i) {
    *tgt0++ = font_data_16x16[chr + 4 * i];
    *tgt0++ = font_data_16x16[chr + 4 * i + 1];
    *tgt1++ = font_data_16x16[chr + 4 * i + 2];
    *tgt1++ = font_data_16x16[chr + 4 * i + 3];
  }
}


/*! \brief copy a text into sprite buffer
 *
 * There are exactly FISTFUL_SPR_CHRNUM characters copied!
 *
 * \param tgt0 pointer to space for first attached sprite
 * \param tgt1 pointer to space for second attached sprite
 * \param txt text string
 * \return number of used lines
 */
static int copy_text_2_sprite(UWORD *tgt0, UWORD *tgt1, const char*txt) {
  int i, j;

  for(i = 0; i < FISTFUL_SPR_CHRNUM; ++i) {
    copy_font_2_sprite(tgt0, tgt1, *txt++);
    tgt0 += FISTFUL_SPR_CHRHGT * 2;
    tgt1 += FISTFUL_SPR_CHRHGT * 2;
    // Now clear the separation area.
    for(j = 0; j < FISTFUL_SPR_CHRSEP; ++j) {
      *tgt0++ = 0;
      *tgt0++ = 0;
      *tgt1++ = 0;
      *tgt1++ = 0;
    }
  }
  return FISTFUL_SPR_CHRNUM * (FISTFUL_SPR_CHRHGT + FISTFUL_SPR_CHRSEP);
}


void set_sprite_pointer(Fistful_t *fistful, int i, UWORD *sprptr) {
  ULONG sp = (ULONG)sprptr;

  fistful->copperlist_spr[i * 4] = 0x120 + i * 4;
  fistful->copperlist_spr[i * 4 + 1] = sp >> 16;
  fistful->copperlist_spr[i * 4 + 2] = 0x120 + i * 4 + 2;
  fistful->copperlist_spr[i * 4 + 3] = sp;
}


void prepare_fistful(Fistful_t *fistful) {
  void *dataptr;
  ULONG chunksize;
  UWORD *coplst;
  int i, height;
  UBYTE *bplptr = &fistful->bitplanes[0];
  UWORD *sprptr0, *sprptr1;
  int endpos;

  // Calculate the final row of the sprite.
  endpos = FISTFUL_SPR_TOPROW + (FISTFUL_SPR_CHRHGT + FISTFUL_SPR_CHRSEP) * FISTFUL_SPR_CHRNUM;
  // Is the final position greater than 255? If yes we need to set bit
  // 8 in the *following* word.
  if(endpos >= 0x100) {
    endpos = (endpos << 8) | 2; //EV8
  } else {
    endpos <<= 8;
  }
  endpos |= 0x0080; // And also set the ATT bit of the sprite.
  inflate(&font_data_16x16[0], &font16x16[0]);
  chunksize = find_iff_chunk(0x424f4459UL, &for_a_fistful_of_dollars[0], &dataptr);
  if(chunksize > 0) {
    uncompress_body_interleaved(dataptr, chunksize, bplptr);
  }
  fistful->pos = 0;
  coplst = &fistful->copperlist_bpl[0];
  for(i = 0; i < 6; ++i) {
    *coplst++ = 0xe0 + i * 4;
    *coplst++ = (ULONG)(bplptr) >> 16;
    *coplst++ = 0xe0 + i * 4 + 2;
    *coplst++ = (ULONG)(bplptr);
    bplptr += 320/8;
  }
  coplst = &fistful->copperlist_spr[0];
  for(i = 0; i < 8; ++i) {
    switch(i) {
    case 2:
    case 3:
      set_sprite_pointer(fistful, i, &fistful->sprites_credits[i & 1][0]);
      break;
    default:
      set_sprite_pointer(fistful, i, &fistful->sprites[i & 1][0]);
    }
  }
  coplst = &fistful->copperlist_fin[0];
  *coplst++ = 0xFFFF;
  *coplst++ = 0xFFFE;
  sprptr0 = &fistful->sprites[0][0];
  sprptr1 = &fistful->sprites[1][0];
  *sprptr0++ = FISTFUL_SPR_TOPROW << 8;
  *sprptr0++ = endpos;
  *sprptr1++ = FISTFUL_SPR_TOPROW << 8;
  *sprptr1++ = endpos;
  height = copy_text_2_sprite(sprptr0, sprptr1, "              ");
  sprptr0 += height;
  sprptr1 += height;
  *sprptr0++ = 0;
  *sprptr0++ = 0;
  *sprptr1++ = 0;
  *sprptr1++ = 0;
  for(i = 0; i < 2; ++i) {
    // SPRxPOS = (y, x)
    fistful->sprites_credits[i][0] = FISTFUL_SPR_TOPROW << 8;
    // SPRxCTL = (stop, att&...)
    /*
      BIT#    SYM       FUNCTION
      ----    --------  -----------------------------
      15-08   EV7-EV0   End (stop) vertical value low 8 bits
      07      ATT       Sprite attach control bit (odd sprites)
      06-04    X        Not used
      02      SV8       Start vertical value high bit
      01      EV8       End (stop) vertical value high bit
      00      SH0       Start horizontal value low bit
     */
    fistful->sprites_credits[i][1] = endpos;
  }  
  copy_text_2_sprite(&fistful->sprites_credits[0][2], &fistful->sprites_credits[1][2], "              ");

}


void init_fistful(Fistful_t *fistful) {
  int i;
  UWORD col = 0;
  UBYTE *dataptr;
  UBYTE r, g, b;
  ULONG chunksize;

  custom.cop1lc = (ULONG)&fistful->copperlist_bpl[0];
  custom.copjmp1 = 0; /* Make copper jump! */
  custom.bplcon0 = 0x6A00; /* 1 bitplane, colour burst, HAM */
  custom.bplcon2 = 0x24;
  custom.bpl1mod = 320/8 * 5;
  custom.bpl2mod = 320/8 * 5;
  chunksize = find_iff_chunk(0x434d4150UL, &for_a_fistful_of_dollars[0], (void*)&dataptr);
  if(chunksize == 0x30) {
    for(i = 0; i < 16; ++i) {
      r = dataptr[0] >> 4;
      g = dataptr[1] >> 4;
      b = dataptr[2] >> 4;
      col = (r << 8) | (g << 4) | b;
      custom.color[i] = col;
      dataptr += 3;
    }
  }
  for(i = 0; i < 16; ++i) {
    custom.color[16 + i] = font_16x16_4bpls_png_palette[i];
  }
}

static char greetings[][2][14] = {
//{ "12345678901234", "12345678901234" },
  { "     CODE     ", "   PARARAUM   " },
  { "    MUZAK     ", "    DELOAD    " },
  { "   GRAPHICS   ", "  PIXEL-HEXE  " },
  { "   GRAPHICS   ", "   NEROUINE   " },
  { "     MORE     ", "    OTHERS    " },
  /* { "     FONT     ", "     DNS      " }, */
  /* { "     FONT     ", "ARTLINE DESIGN" }, */
  /* { " IS THIS HAM? ", "- SURE IT IS -" } */
  { "\0", "\0" }
};

void irq_fistful(Fistful_t *fistful) {
  int fastsinus;
  int pos = 0x60 + sinus_table[(256 + 128 + (++fistful->pos * 2)) & 511];
  static int num = 0;
  char *what = &greetings[num][0][0];
  char *who = &greetings[num][1][0];

  copy_text_2_sprite(&fistful->sprites_credits[0][2], &fistful->sprites_credits[1][2], what);
  copy_text_2_sprite(&fistful->sprites[0][2], &fistful->sprites[1][2], who);
  /* custom.color[0] = 0xf00; */
  /* custom.color[15] = 0x0f0; */
  fastsinus = sinus_table[(fistful->pos << 3) & 511] >> 2;
  fistful->sprites_credits[0][0] = 0x3000 | (pos);
  fistful->sprites_credits[1][0] = 0x3000 | (pos);
  pos += fastsinus;
  fistful->sprites[0][0] = 0x3000 | (pos);
  fistful->sprites[1][0] = 0x3000 | (pos);
  if(fastsinus <= -8) {
    set_sprite_pointer(fistful, 0, &fistful->sprites_credits[0][0]);
    set_sprite_pointer(fistful, 1, &fistful->sprites_credits[1][0]);
  } else if(fastsinus >= 8) {
    set_sprite_pointer(fistful, 0, &fistful->sprites[0][0]);
    set_sprite_pointer(fistful, 1, &fistful->sprites[1][0]);
  }
  if(fistful->pos >= 256) {
    if(greetings[++num][0][0] == '\0') { // final element reached
      num = 0; // restart
    }
    fistful->pos = -1;
  }
}

