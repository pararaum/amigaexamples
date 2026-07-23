#include <string.h>
#include <hardware/custom.h>
#include <t7d/customchips.h>
#include "boss.h"
#include "resident.h"

typedef void (*partfunctionptr)(__reg("a0") volatile struct DemoData *dd);

#define NPARTS 1

extern volatile struct Custom custom;
extern volatile struct DemoData demodata;

int main() {
  partfunctionptr part_init, part_run, part_teardown;
  partfunctionptr part;
  int partcounter;
  
  BossWriteln("Loading parts.");
  for(partcounter = 0; partcounter < NPARTS; ++partcounter) {
    if((partcounter & 1) == 0) {
      BossWriteln("Loading even part at $C20000.");
    } else {
      BossWriteln("Loading odd part at $c50000.");
    }
    part = BossManifestLoad(0x50543030);
    part_init = part;
    part_run = (partfunctionptr)((uint32_t)(part) + 4);
    part_teardown = (partfunctionptr)((uint32_t)(part) + 8);
    //
    BossPrintHex((uint32_t)part_init);
    BossPutc('\n');
    BossPrintHex((uint32_t)part_run);
    BossPutc('\n');
    BossPrintHex((uint32_t)part_teardown);
    BossPutc('\n');
    //
    part_init(&demodata); // Initialise the next part.
    part_run(&demodata); // Run the next part.
    //...
    part_teardown(&demodata); // And tear down the part.
  }
  BossResetCopper();
  while(1);
  return 0;
}
