;;; Image data
	include	"hardware/custom.i"
	include	"iff.i"

	XDEF	_uncompress_next_image
	XDEF	_image_colour_data
	XDEF	_image_pointers

	;; Input
	;; A0: pointer to target area
	;; Output
	;; D0: Number of colours
_uncompress_next_image:
	;; A2: current image pointer
	;; A6: $DFF000
	movem.l	d2-d7/a0-a6,-(sp)
	lea.l	$DFF000,a6
	move.l	a0,a1
	move.l	image_pointers_ptr,a2 ;A2 points now to the next image ptr
	move.l	(a2),a2		      ;Get the pointer (image)
	move.l	a2,a0		      ;Copy it to A0
	move.l	#"BODY",d0
	jsr	find_iff_chunk
	jsr	uncompress_body_interleaved
	move.l	a2,a0
	;; 	lea.l	$180(a6),a1	;Target is $DFF180
	lea.l	_image_colour_data,a1
	moveq	#0,d0
	jsr	copy_cmap_chunk
	move.l	a2,a0		;current image
	move.l	#"BMHD",d0	;Bitmap Header
	jsr	find_iff_chunk
	jsr	interpret_bmhd
				; d0.l: compression type
				; d1.l: number of bitplanes
				; d2.l: width in pixels
				; d3.l: height in pixels
	;; Calculate number of colours
	moveq	#1,d4		; Put a 1 in D4
	lsl.w	d1,d4		; 2^D4 colours
	move.w	d1,d0		; Number of bitplanes in D0
	lsl.w	#8,d0		; Move to position of x: $x000
	lsl.w	#4,d0
	or.w	#$0200,d0	; Colour burst, zero bitplanes
	move.w	d0,bplcon0(a6)	; BPLCON0
	move.w	d1,d0		; Number of bitplanes in D0
	subq.w	#1,d0
	mulu	d2,d0		; Multiply with bitplanes-1
	lsr.w	#3,d0		; in Bytes (divide by 8)
	move.w	d0,bpl1mod(a6)
	move.w	d0,bpl2mod(a6)
	move.l	d4,d0		; Return number of colours
	movem.l	(sp)+,d2-d7/a0-a6
	rts

	SECTION	DATA,data

image_pointers_ptr:
	dc.l	_image_pointers
_image_pointers:
	dc.l	image1
	dc.l	0

	EVEN
image1:	INCBIN	"static_image.ilbm"

	SECTION BSS,bss
_image_colour_data:
	ds.w	32
