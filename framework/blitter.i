;;; -*- mode: asm; -*-

;;; Wait until blitter finishes
	MACRO	WAITBLITM
l\@$:	btst.b	#6,$DFF000+dmaconr
	bne.s	l\@$
	ENDM

;;; Wait until blitter finishes
;;; Input: A6=$DFF000
	MACRO	WAITBLITMA6
l\@$:	btst.b	#6,dmaconr(a6)
	bne.s	l\@$
	ENDM
