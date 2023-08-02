#include <hardware/custom.h>

#define BPLWIDTH (320+16)
#define BPLHEIGHT 256
#define BPLNOS 4
#define IMGWIDTH 320
#define IMGHEIGHT 240
#define IMGBPLNOS 4
#define LIBVERSION 34 /* Kickstart 1.3 */
#define WAITBLIT while(custom.dmaconr & (1 << 14));

#define ANMWIDTH 80
#define ANMHEIGHT 100
#define NUMBER_OF_ANIMATIONS 6
#define MAXMBOBS 4
#define BOBHOTSPOT_X (272 << 5)
#define BOBHOTSPOT_Y (25 << 5)

extern volatile struct Custom custom;
