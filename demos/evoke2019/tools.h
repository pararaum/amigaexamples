#ifndef __TOOLS_H__
#define __TOOLS_H__
#include <exec/types.h>

#define WAITBLIT while(custom.dmaconr & (1 << 14));

extern ULONG *autovector;

/*! \brief Clear a bitplane using the blitter
 *
 * The memory is cleared using the blitter. Blitter DMA has to be
 * enabled as otherwise there will be an endless wait.
 *
 * @param btplptr pointer to the bitplane to clean
 * @param width in words
 * @param height in lines
 */
void clear_bitplane(unsigned char *btplptr, int width, int height);
#endif
