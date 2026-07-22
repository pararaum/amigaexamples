#include <stdint.h>
#include <string.h>
#include <hardware/custom.h>
#include <t7d/customchips.h>
#include "boss.h"

#define NPARTS 1

extern volatile struct Custom custom;
extern volatile uint16_t framecounter;

int main() {
  void *nextpart;
  int partcounter;
  
  BossWriteln("Loading parts.");
  for(partcounter = 0; partcounter < NPARTS; ++partcounter) {
    if((partcounter & 1) == 0) {
      BossWriteln("Loading even part at $C20000.");
    } else {
      BossWriteln("Loading odd part at $c50000.");
    }
    nextpart = BossManifestLoad(0x50543030);
    BossPrintHex((uint32_t)nextpart);
  }
  return 0;
}
