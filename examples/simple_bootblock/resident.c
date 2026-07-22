#include <stdint.h>
#include <string.h>
#include <hardware/custom.h>
#include <t7d/customchips.h>
#include "boss.h"

extern volatile struct Custom custom;
extern volatile uint16_t framecounter;

int main() {
  void *nextpart;
  
  BossWriteln("Loading parts.");
  nextpart = BossManifestLoad(0x47465832);
  return 0;
}
