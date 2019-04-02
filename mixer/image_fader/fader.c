#include <stdio.h>

extern unsigned long own_machine();
extern void disown_machine();

int main(int argc, char **argv) {
  unsigned long ul;
  
  ul = own_machine();
  /* set_up(); */
  /* all_black(); */
  /* fadeloop(); */
  disown_machine();
  printf("gfxbase=$%lx\n", ul);
  return 0;
}
