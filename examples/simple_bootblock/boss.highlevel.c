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


char *ul2dec(unsigned long num) {
  // Largest possible number 4294967296, do not forget the string terminator.
  static char buf[12];
  char localbuf[12];
  char *sptr;
  int i = 0;

  do {
    localbuf[i++] = (num % 10) + '0';
    num /= 10;
  } while(num > 0);
  for(sptr = buf; i >= 0; --i) {
    *sptr++ = localbuf[i - 1];
  }
  return buf;
}

