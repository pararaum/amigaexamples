#ifndef KABOOM_1583140551
#define KABOOM_1583140551
#include <exec/types.h>

#define KABOOM_BPLWIDTH 320
#define KABOOM_SCRHEIGHT 268
#define KABOOM_BPLHEIGHT 232
// Move 20 ROWS down.
#define KABOOM_IMAGE_ROWSOFFSET 20
#define KABOOM_BPLNOS 5
#define KABOOM_SETUP_COPPERLISTSIZE 128

typedef struct Kaboom {
  // Copper setup for bitplane pointers (not used!?).
  UWORD copperlist_bpl[KABOOM_BPLNOS * 4];
  UWORD copperlist_stp[KABOOM_SETUP_COPPERLISTSIZE];
  UWORD copperlist_fin[4];
  UBYTE bitplanes[KABOOM_BPLWIDTH/8*KABOOM_SCRHEIGHT*KABOOM_BPLNOS];
  unsigned short colphase;
} Kaboom_t;

void prepare_kaboom(Kaboom_t *kaboom);
void init_kaboom(Kaboom_t *kaboom);
void irq_kaboom(Kaboom_t *kaboom);
void kaboom_green_out(Kaboom_t *kaboom);

#endif
