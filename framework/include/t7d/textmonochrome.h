
void text_monochrome(__reg("a0") const char *text, __reg("a1") void *font, __reg("a2") void *bitplane, __reg("d0") int modulo);

int char_monochrome(__reg("d0") int character, __reg("d1") int modulo, __reg("a0") void *font, __reg("a1") void *bitplane);
