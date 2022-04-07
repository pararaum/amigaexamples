#ifndef __CIRCALLATOR_H__
#define __CIRCALLATOR_H__
void circinit(void *begin, void *end);
void *circalloc(unsigned long numbytes);
void circfreeall(void);
void circfreeze(void);
#endif
