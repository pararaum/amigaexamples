#ifndef __IFF_h__
#define __IFF_h__
#include <exec/types.h>
signed long find_iff_chunk(__reg("d0") ULONG chunk, __reg("a0") void *iffdata, __reg("a1") void **call_by_reference_ptr_iff_data);
void uncompress_body_interleaved(__reg("a0") void*compressed_data, __reg("d0") ULONG compressed_bytes, __reg("a1") void *target);
#endif
