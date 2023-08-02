#include <exec/types.h>

#define FISTFUL_SPR_CHRHGT 16
#define FISTFUL_SPR_CHRSEP 2
#define FISTFUL_SPR_CHRNUM 14
#define FISTFUL_SPR_TOPROW 0x30

typedef struct Fistful {
  UBYTE bitplanes[320*256*6/8];
  UWORD copperlist_bpl[6 * 4];
  UWORD copperlist_spr[8 * 4];
  UWORD copperlist_fin[4];
  UWORD sprites[2][2 + 2 * FISTFUL_SPR_CHRNUM * (FISTFUL_SPR_CHRHGT + FISTFUL_SPR_CHRSEP) + 2];
  UWORD sprites_credits[2][2 + 2 * FISTFUL_SPR_CHRNUM * (FISTFUL_SPR_CHRHGT + FISTFUL_SPR_CHRSEP) + 2];
  short pos;
} Fistful_t;

void prepare_fistful(Fistful_t *fistful);
void init_fistful(Fistful_t *fistful);
void irq_fistful(Fistful_t *fistful);
