
/* Uncrunch LZ4 compressed data
 *
 * This version should have the LZ4 header $04224d18 removed.
 *
 * \param input_buffer pointer to the compressed data
 * \param output_buffer pointer where the uncomressed data is written
 * \param packed_bytes length of compressed data
 */
void lz4_uncrunch(__reg("a0") void *input_buffer, __reg("a1") void *output_buffer, __reg("d0") unsigned long int packed_bytes);

/* Uncrunch LZ4 compressed data
 *
 * \param input_buffer pointer to the compressed data
 * \param output_buffer pointer where the uncomressed data is written
 * \param packed_bytes length of compressed data
 */
void lz4_uncrunch_header(__reg("a0") void *input_buffer, __reg("a1") void *output_buffer, __reg("d0") unsigned long int packed_bytes);

