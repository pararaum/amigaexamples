#include <string.h>
#include <hardware/custom.h>
#include <t7d/customchips.h>
#include "boss.h"
#include "resident.h"

typedef void (*partfunctionptr)(__reg("a0") volatile struct DemoData *dd);

#define NPARTS 2

extern volatile struct Custom custom;
extern volatile struct DemoData demodata;

int main() {
  partfunctionptr part_init, part_run, part_teardown;
  partfunctionptr part;
  unsigned int partcounter;
  partfunctionptr prev_teardown = 0; // This is the function of the previous part.
  
  BossWriteln("Loading parts.");
  for(partcounter = 0; partcounter < NPARTS; ++partcounter) {
    if((partcounter & 1) == 0) {
      BossWriteln("Loading even part at $C20000.");
    } else {
      BossWriteln("Loading odd  part at $C50000.");
    }
    part = BossManifestLoad(0x50543030 + partcounter);
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
    demodata.current_part = (void*)part;
    part_run(&demodata); // Run the next part.
    if(prev_teardown != 0) {
      prev_teardown(&demodata); // And tear down the previous part.
    }
    prev_teardown = part_teardown;
  }
  demodata.current_part = 0;
  prev_teardown(&demodata); // Teardown final part.
  BossWriteln("Demo has ended.");
  BossResetCopper();
  demodata.framecounter = 0;
  while(demodata.framecounter < 50*36) ;
  return 0;
}
