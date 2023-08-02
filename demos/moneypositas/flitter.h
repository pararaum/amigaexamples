#ifndef FLITTERWIDTH

#define FLITTERWIDTH 320
#define FLITTERHEIGHT 232

typedef struct AtmosphericFlitter {
  UWORD copperlist[64];
  UBYTE noiseplanes[FLITTERWIDTH/8 * (FLITTERHEIGHT + 1) * 2];
  UBYTE logoplane[FLITTERWIDTH/8 * FLITTERHEIGHT];
  unsigned short modulo;
} AtmosphericFlitter_t;


AtmosphericFlitter_t *prepare_flitter(AtmosphericFlitter_t *flittermem);
void blit_da_noise(AtmosphericFlitter_t *flitter, int frameno);
void flitter_update_cwftr(AtmosphericFlitter_t *flittermem, int row);

#endif
