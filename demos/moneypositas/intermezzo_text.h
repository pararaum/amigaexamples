typedef struct IntermezzoText {
  unsigned char bitplane[320*256/8];
  unsigned char background[320*289/8*2];
  unsigned char font[1024 + 32];
  unsigned short copperlist[1154];
  unsigned short *copperlist_wabble;
  unsigned short bitplane_offset;
} IntermezzoText_t;

void prepare_intermezzo_text(IntermezzoText_t *imezzo);

void init_intermezzo_text(IntermezzoText_t *imezzo);

void intermezzo_irq_routine(IntermezzoText_t *imezzo);
