#include <stdio.h>

/*int start(int i, int j, int k, char *ptr);*/
int fun2(int i, int j);
char *fungen(void);
void funreg(int __reg("d0") i, unsigned long __reg("d1") j, __reg("a0") char * ptr);
void output(void);
void start(void);

/*! \brief Output text and hex number
 *
 * \param txt text before colon
 * \param x number to output
 */
void printhex(const char *txt, unsigned long x) {
  printf("%s: $%08lx\n", txt, x);
}

int main(int argc, char **argv) {
  char buf[80];
  printf("argc=%d argv=%p\n", argc, (void*)argv);
  /*  printf("%x\n", start(0xaa55, -1, 69105, "Some string"));*/
  printf("%08x\n", fun2(0x1000, 0x2000));
  funreg(0xFFFF, 0xdeadbea1UL, buf);
  puts(buf);
  output();
  start();
  return 0;
}



void output(void) {
  char *str;

  str = fungen();
  printf("'%s'\n", str);
}

