#ifndef __RESIDENT_HH_20260723__
#define __RESIDENT_HH_20260723__
#include <stdint.h>

struct DemoData {
  uint16_t framecounter; // Will be reset at the start of each part.
  uint16_t totalframecounter; // Frames since the beginning of time.
};

#endif
