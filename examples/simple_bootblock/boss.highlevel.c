#include <stdio.h>


char *ul2hex(unsigned long v1) {
  static char buf[9];
  int i;
  char c;

  for(i = 0; i < 8; ++i) { // Nibble for nibble.
    c = (v1 >> ((8-1 - i) * 4)) & 0xf;
    if(c < 10) {
      buf[i] = c + '0';
    } else {
      buf[i] = c -10 + 'A';
    }
  }
  buf[8] = 0;
  return buf;
}
