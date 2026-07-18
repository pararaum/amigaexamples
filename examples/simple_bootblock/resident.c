#include "boss.h"


int main() {
  unsigned char *gfx;
  
  BossWriteln("Loading further assets.");
  gfx = BossManifestLoad(0x47465831UL);
  BossWrite("Asset was loaded at $");
  BossPrintHex((unsigned long)gfx);
  BossPutc('\n');

  return 0;
}
