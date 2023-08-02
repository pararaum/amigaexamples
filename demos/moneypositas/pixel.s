
	XDEF	_set_pixel_320_5bpl

;;; Input: A0=bitplanepointer, D0=X, D1=Y, D2=colour
;;; Destroys: A0, D0, D1, D2
;
; 0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15
; X set this pixel
; = bit 15
;     X set this pixel
;     = bit 14
;                                                            X set this pixel
; = bit 0
_set_pixel_320_5bpl:
	mulu	#320/8*5,d1	; Start of row
	add.l	d1,a0		; Add to bitplanepointer
	move.w	d0,d1		; D1=X
	lsr.w	#3,d1		; calculate byte
	add.w	d1,a0		; D1 now points to the byte.
	not.w	d0		; see above
	and.w	#$7,d0		; D0=which bit
	lsr.w	d2
	bcc.s	b0clr$
	bset	d0,(a0)
	bra.s	b0set$
b0clr$:	bclr	d0,(a0)
b0set$:
	lsr.w	d2
	bcc.s	b1clr$
	bset	d0,320/8*1(a0)
	bra.s	b1set$
b1clr$:	bclr	d0,320/8*1(a0)
b1set$:
	lsr.w	d2
	bcc.s	b2clr$
	bset	d0,320/8*2(a0)
	bra.s	b2set$
b2clr$:	bclr	d0,320/8*2(a0)
b2set$:
	lsr.w	d2
	bcc.s	b3clr$
	bset	d0,320/8*3(a0)
	bra.s	b3set$
b3clr$:	bclr	d0,320/8*3(a0)
b3set$:
	lsr.w	d2
	bcc.s	b4clr$
	bset	d0,320/8*4(a0)
	bra.s	b4set$
b4clr$:	bclr	d0,320/8*4(a0)
b4set$:
	rts






	
	rts
