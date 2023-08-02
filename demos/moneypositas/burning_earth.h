#define BURNING_BPLNOS 5
#define BURNING_WIDTH 320
#define BURNING_HEIGHT 200
#define TEXTPLANE_HEIGHT 56

typedef struct Burning {
  unsigned char bitplanes[BURNING_WIDTH*BURNING_HEIGHT*BURNING_BPLNOS/8];
  unsigned short int copperlist[44];
  unsigned char textplane[BURNING_WIDTH*TEXTPLANE_HEIGHT/8];
  unsigned char font[1024];
} Burning_t;

void prepare_burning(Burning_t *burning);
void init_burning(Burning_t *burning);
void irq_burning(Burning_t *burning);
