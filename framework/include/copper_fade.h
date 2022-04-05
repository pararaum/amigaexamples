int fade_in_copper_list(__reg("d0") int colours, __reg("d1") modulo, __reg("a0") UWORD *colourdata, __reg("a1") UWORD *targetptr, __reg("a2") void *spare_area);
int fade_out_colour_table(__reg("d0") int number_of_colours, __reg("a0") UWORD *colourdata, __reg("d1") int modulo_for_colours);
