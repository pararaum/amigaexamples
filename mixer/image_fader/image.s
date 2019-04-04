;;; Image data
	include	"iff.i"

	XDEF	_uncompress_next_image
	XDEF	_image_pointers

	;; A0: pointer to target area
_uncompress_next_image:
	movem.l	d2-d7/a0-a6,-(sp)
	move.l	a0,a1
	lea.l	image1,a0
	move.l	#"BODY",d0
	jsr	find_iff_chunk
	jsr	uncompress_body_interleaved
	lea.l	image1,a0
	lea.l	$dff180,a1
	moveq	#0,d0
	jsr	copy_cmap_chunk
	movem.l	(sp)+,d2-d7/a0-a6
	rts

	SECTION	DATA,data

_image_pointers:
	dc.l	image1
	dc.l	0

	EVEN
image1:	INCBIN	"static_image.ilbm"

