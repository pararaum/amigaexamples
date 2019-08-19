	include	"own.i"

	XDEF _copy_endgfx_to_workbench

	SECTION CODE
_copy_endgfx_to_workbench:
	;; A5: target area
	move.l	4(sp),d0
	movem.l	d2-d7/a2-a7,-(sp)
	move.l	d0,a5		; Area to copy image to.
	lea.l	evoke_end_graphics,a0
	move.l	#"BODY",d0
	jsr	find_iff_chunk
	tst.l	d0
	bmi	out$
	;; A0=body data
	;; D0=body size (e.g. compressed data bytes)
	move.l	a5,a1		; Get target area.
	jsr	uncompress_body_interleaved
out$:	movem.l	(sp)+,d2-d7/a2-a7
	rts

	SECTION DATA
evoke_end_graphics:
	incbin	"evoke.width=640.bicolor.ilbm"
