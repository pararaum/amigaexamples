unsigned short *copy_credits_copperlist(__reg("a0") void *target, __reg("a1") void *credits_bitplane, __reg("a2") void *logo_bitplane);
void copy_bicolor_image(UBYTE *bitplane);
void *get_font_address(void);

extern UWORD liberation_single_column_png[];
extern UWORD spritenoise2_png[];
extern UWORD spritenoise2_png_end[];
