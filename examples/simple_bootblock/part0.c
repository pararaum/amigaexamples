#include "boss.h"
#include <hardware/custom.h>
#include <hardware/dmabits.h>

extern volatile struct Custom custom;

static void print_hello(void) {
  BossWriteln("This is C speaking.\n");
}

int main() {
  int i;
  print_hello();
  for(i = 0; i < 0x100000UL; ++i) {
    custom.color[1] = i;
  }
  BossWriteln("C is leaving.\n");
}
