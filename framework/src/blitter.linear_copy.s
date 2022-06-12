	include	"t7d/blitter.i"
	xref	_custom

	xdef	_blitter_linear_copy
;;; Blit memory linearly from src to dest.
;;; Input: A0=src, A1=dest, d0=width (bytes), d1=height
_blitter_linear_copy:
Acustom$:	equr	A5
Dbltsize$:	equr	D2
regs$:	reg	Acustom$
	movem.l	regs$,-(sp)
	lea.l	_custom,Acustom$
	WAITBLITA5
	move.w	#$09F0,bltcon0(Acustom$)
	clr.w	bltcon1(Acustom$)
	move.w	#$FFFF,bltafwm(Acustom$)
	move.w	#$FFFF,bltalwm(Acustom$)
	move.l	a0,bltapt(Acustom$)
	move.l	a1,bltdpt(Acustom$)
	clr.w	bltamod(Acustom$)
	clr.w	bltdmod(Acustom$)
	;; http://www.winnicki.net/amiga/memmap/BLTSIZE.html
	move.w	d1,Dbltsize$		; Move height into Dbltsize$.
	lsl.w	#6,Dbltsize$		; Move height to corresponding bits in bltsize.
	lsr.w	#1,d0			; Width from bytes to words.
	or.w	d0,Dbltsize$		; Now blitsize has correct form.
	move.w	Dbltsize$,bltsize(Acustom$)
	movem.l	(sp)+,regs$
	rts

