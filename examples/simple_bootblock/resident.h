#ifndef __RESIDENT_HH_20260723__
#define __RESIDENT_HH_20260723__
#include <stdint.h>

struct DemoData {
  uint16_t framecounter; // Will be reset at the start of each part.
  uint32_t totalframecounter; // Frames since the beginning of time.
  void *current_part; // Pointer to the memory of the current part,
		      // vertical blank uses this to get the right
		      // part. Set to zero if nothing should be
		      // called.
};

#endif
