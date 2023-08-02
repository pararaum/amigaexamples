/*! \brief Blit a single plane with cookie cut
 *
 * Blit a single plane from the animation into the target plane. The
 * cookie-cut mask is taken from the cookie pointer. No Masking is
 * done.
 *
 * \param target pointer to the target area
 * \param src
 * \param cookie
 */
void blit_single_plane(__reg("a0") UBYTE *target, __reg("a1") UBYTE *src, __reg("a2") UBYTE *cookie, __reg("d0") unsigned short anmwid, __reg("d1") unsigned short scrwid, __reg("d2") unsigned short anmhgt);


/*! \brief Blit with cookie cut, interleaved
 *
 * Blit a multiple planes from the animation into the destination
 * planes. The cookie-cut mask is taken from the additional bitplane
 * in the animation. No further masking is done.
 *
 * \param destination pointer to the destination area
 * \param src
 * \param anmwid animation width in bytes
 * \param scrwid destination screen width in bytes
 * \param anmhgt rows in animation
 * \param nobpl number of bitplanes (w/o cookie-cut mask)
 */
void blit_with_cc(__reg("a0") UBYTE *destination,
		  __reg("a1") UBYTE *src,
		  __reg("d0") unsigned short anmwid,
		  __reg("d1") unsigned short scrwid,
		  __reg("d2") unsigned short anmhgt,
		  __reg("d3") unsigned short nobpl
		  );
