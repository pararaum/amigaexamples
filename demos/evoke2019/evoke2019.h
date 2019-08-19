#ifndef __EVOKE2019_h__
#define __EVOKE2019_h__
extern unsigned long volatile framecounter;
extern volatile struct Custom custom;
/* This should contain a zero if OCS or ECS and 1 if AGA. */
extern short non_aga_chipset;

#endif
