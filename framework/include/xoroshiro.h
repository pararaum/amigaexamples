#ifndef __XOROSHIRO_RNG_H__
#define __XOROSHIRO_RNG_H__

unsigned short xoroshiro32plusplus(void);
void seed_xoroshiro32plusplus(__reg("d0") unsigned long seed);

#endif
