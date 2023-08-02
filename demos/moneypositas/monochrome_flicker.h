#ifndef __MONOCHROME_FLICHER_H__
#define __MONOCHROME_FLICHER_H__
#include <hardware/custom.h>

struct MonochromeFlicker_t {
  UWORD copperlist[32];
  UBYTE graphik[320*256/8];
};

/*!\brief Initialise flicker graphics
 *
 * This prepares the new copperlist for a monochrome graphics. Then
 * the graphics is unpacked into the MonochromeFlicker_t structure at
 * graphik.
 *
 * \param chipmem memory for struct MonochromeFlicker_t
 * \param iidx image index
 * \return pointer to the struct MonochromeFlicker_t, may be the same as chipmem, may be not..., NULL on error.
 */
struct MonochromeFlicker_t *init_flicker(void *chipmem, unsigned short iidx);

/*! \brief Enable flicker graphics
 *
 * This will setup the custom chips to display the flicker effect.
 *
 * \param monfli pointer the the MonochromeFlicker_t structure
 */
void enable_flicker(struct MonochromeFlicker_t *monfli);

void irq_flicker(struct MonochromeFlicker_t *monfli);

#endif
