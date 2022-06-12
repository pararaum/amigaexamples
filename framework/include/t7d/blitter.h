#ifndef __FRAMEWORK_BLITTER__
#define __FRAMEWORK_BLITTER__

// You need a definition of custom, probably as "extern volatile struct Custom custom;".
#define WAITBLIT while(custom.dmaconr & (1 << 14));

#endif
