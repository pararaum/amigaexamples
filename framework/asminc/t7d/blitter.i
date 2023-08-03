;;; -*- mode: asm -*-
	include	"hardware/custom.i"
	include	"hardware/dmabits.i"
* You need an XREF _custom for custom base!

	ifnd	__FRAMEWORK_BLITTER_i__
__FRAMEWORK_BLITTER_i__ equ 1

;;; Wait for the blitter to finish.
	macro	WAITBLIT
	.l\@:
	btst.b	#(DMAB_BLTDONE-8),_custom+dmaconr
	bne	.l\@
	endm

;;; Wait until blitter finishes. A5 must contain _custom!
	macro	WAITBLITA5
	.l\@:
	btst.b	#(DMAB_BLTDONE-8),dmaconr(a5)
	bne	.l\@
	endm

;;; Wait until blitter finishes. A6 must contain _custom!
;;; Input: A6=$DFF000
	MACRO	WAITBLITA6
	.l\@$:
	btst.b	#6,dmaconr(a6)
	bne.s	.l\@$
	ENDM


;;; Blit memory linearly from src to dest.
;;; The blitting is done linearly (modulus = 0) and plainly D=A.
;;; Input: A0=src, A1=dest, d0=width (bytes), d1=height
;;; Modifies: A0-A1/D0-D1
	PUBLIC	_blitter_linear_copy

*
	endif
