#include <stdio.h>
#include <stdarg.h>
#include "boss.h"

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
  for(sptr = buf; i > 0; --i) {
    *sptr++ = localbuf[i - 1];
  }
  *sptr = 0;
  return buf;
}


/*! simulated printf
 *
 * \warning This assumes that the stack is aligned to a longword!
 */
void boss_simprintf(const char *format, ...) {
  va_list ap;
  unsigned long ul;
  short s;

  va_start(ap, format);
  for(; *format; ++format) {
    s = *format;
    switch(*format) {
    case '%':
      switch(*(format + 1)) {
      case '%':
	BossPutc('%');
	break;
      case 'd': // Decimal number.
	ul = va_arg(ap, unsigned long);
	BossWrite(ul2dec(ul));
	break;
      case 'x': // Hexadecimal number.
	ul = va_arg(ap, unsigned long);
	BossWrite(ul2hex(ul));
	break;
      }
      ++format;
      break;
    default:
      BossPutc(*format);
    }
  }
  va_end(ap);
}
