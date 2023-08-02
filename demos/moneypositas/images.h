#ifndef __IMAGES_H__MONEYPOSITAS
#define __IMAGES_H__MONEYPOSITAS

extern unsigned long int get_image(__reg("d0") unsigned short num, __reg("a0") void **img_addr_cbr);

//#############################################################################
extern UBYTE lz4logo[];
extern UBYTE lz4logo_end[];
//#############################################################################

extern unsigned char one_dollar_png[];
extern unsigned short one_dollar_png_width;
extern unsigned short one_dollar_png_height;
extern unsigned char futurewriter_font[];
extern unsigned char for_a_fistful_of_dollars[];
extern unsigned char font16x16[];
extern unsigned char animation_plus_ccm[];
extern unsigned char burning_earth[];
extern unsigned char dollarbackground[];
extern unsigned char image_kaboom[];

#endif
