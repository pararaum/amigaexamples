
#define SCRGREETINGS_BPLNOS 1
#define SCRGREETINGS_WIDTH (320+16)
#define SCRGREETINGS_HEIGHT 256
#define SCRGREETINGS_FIREBLIBSPL 38
#define SCRGREETINGS_FIRELINES 31*3
#define SCRGREETINGS_NUMSCROLLER 4
#define SCRGREETINGS_TOPROW_PLASMA 0x52

typedef struct ScrGreetings {
  struct {
    short linewidth;
    short linewidthX3;
    unsigned short *fireplasmaptr;
    unsigned short *thirdlineptr;
    unsigned short *bottomlineptr;
    short rainbowpos;
  } info;
  const char **greetingsptr;
  struct ScrollInfo {
    unsigned char *topline;
    short speed;
    short pos;
    const char *textptr;
  } scroller[SCRGREETINGS_NUMSCROLLER];
  unsigned char bitplanes[SCRGREETINGS_WIDTH/8*SCRGREETINGS_HEIGHT*SCRGREETINGS_BPLNOS];
  unsigned short int copperlist[0x40+(SCRGREETINGS_FIRELINES)*(4*(SCRGREETINGS_FIREBLIBSPL+4))];
  unsigned char font[1024];
  unsigned short int colours[511*2];
} ScrGreetings_t;

unsigned short int copy_greetings_copperlist(__reg("a0") void *dest, __reg("a1") void *bpl, __reg("d0") int startline, __reg("d1") void *infoptr);

void fire_plasma(__reg("a0") unsigned short *copperlist, __reg("a1") void *info);

void copy_plasma(__reg("a0") ScrGreetings_t *info, __reg("d0") int skip);

void copy_greetings_colours(__reg("a0") unsigned short int *colours);

void prepare_scrgreetings(ScrGreetings_t *scrgreetings);

void init_scrgreetings(ScrGreetings_t *scrgreetings);

void irq_scrgreetings(ScrGreetings_t *scrgreetings);

void scroll_rect(__reg("a0") unsigned char *bitbpl, __reg("d0") int pixel);

void greetings_rainbow(__reg("a0") ScrGreetings_t *scrgreetings, __reg("a1") unsigned short *colours);
