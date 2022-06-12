#ifndef __COPPER_TOOLS_H_202205
#define __COPPER_TOOLS_H_202205

/*
 * Macros to build a copperlist, the ptr should be a pointer to a WORD
 * where the copper instruction will be written to.
 */
#define COPPERPTRMOVE(ptr, reg, val) *ptr++ = reg; *ptr++ = val;
#define COPPERPTRMOVE32(ptr, reg, val) *ptr++ = reg; *ptr++ = (val)>>16; *ptr++ = (reg)+2; *ptr++ = (val)&0xFFFF;
#define COPPERPTRWAIT(ptr, vpos, hpos) *ptr++ = ((vpos)<<8)|(hpos)|1; *ptr++ = 0xfffe;
#define COPPERPTRBLITFIN(ptr) *ptr++ = 0x101; *ptr++ = 0x7ffe;


#endif
