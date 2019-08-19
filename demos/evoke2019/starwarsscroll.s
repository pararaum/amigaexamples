
	XDEF	_starwarsscroll

;;; A0=pointer to the beginning of the line
;;; D0=number of bytes to ror (must be even!)
;;; Destroys:
	;; D1
sweffect_ror:
	andi	#~(1<<4),CCR	; Clear X flag. http://www.chibiakumas.com/68000/
	moveq	#20,d1
	sub.w	d0,d1
	jmp	(pc,d1)		; Skip d1 roxr's.
	roxr	(a0)+
	roxr	(a0)+
	roxr	(a0)+
	roxr	(a0)+
	roxr	(a0)+
	roxr	(a0)+
	roxr	(a0)+
	roxr	(a0)+
	roxr	(a0)+
	roxr	(a0)		; Postincrement not needed...
	rts

;;; A0=pointer to the beginning of the line
;;; D0=number of bytes to rol (must be even!)
;;; Destroys:
	;; D1
sweffect_rol:
	andi	#~(1<<4),CCR	; Clear X flag. http://www.chibiakumas.com/68000/
	moveq	#20,d1
	sub.w	d0,d1
	jmp	(pc,d1)		; Skip d7 roxr's.
	roxl	-(a0)
	roxl	-(a0)
	roxl	-(a0)
	roxl	-(a0)
	roxl	-(a0)
	roxl	-(a0)
	roxl	-(a0)
	roxl	-(a0)
	roxl	-(a0)
	roxl	-(a0)
	rts


;;; Do the star wars effect.
;;; Input
;;; A0=bitplane pointer
;;; D0=bitplane width
;;; D1=number of lines to crunch
_starwarsscroll:
	;; LLM$: line length mask, see linelength$
LLM$	SET	$3e
	;; A6=storage for bitplane pointer
	;; A5=line lengths table
	;; D7=line counter of star wars lines
	;; D6=bitplane width
	;; D5=line counter for left/right part
	movem.l	d5-d7/a5-a6,-(sp)
	lea.l	linelength$(pc),a5
	move.l	a0,a6		; Store bitplane pointer.
	move.w	d0,d6		; Store bitplane line width...
	neg.w	d6		; ...as a negative value.
	move.w	d1,d7
	;; Left part.
	lea.l	0(a6),a1	; Copy bottom line into A1
	moveq	#0,d5		; Clear line counter
l1$:	lea.l	(a1,d6.w),a1	; Previous line
	lea.l	(a1),a0		; Get address of line
	move.w	d5,d0
	and.w	#LLM$,d0
	move.w	(a5,d0.w),d0
	bsr	sweffect_ror
	addq.w	#1,d5
	cmp.w	d5,d7
	bcc.s	l1$
	;; Now the right part.
	lea.l	0(a6),a1	; Copy bottom line into A1
	moveq	#0,d5		; Clear line counter
l4$:	lea.l	(a1,d6.w),a1	; Previous line
	lea.l	(a1),a0		; Get address of line
	move.w	d5,d0
	and.w	#LLM$,d0
	move.w	(a5,d0.w),d0
	bsr	sweffect_rol
	addq.w	#1,d5
	cmp.w	d5,d7
	bcc.s	l4$
	movem.l	(sp)+,a5-a6/d5-d7
	rts
linelength$:
	;; 2,4,6,8,10
	;; 18,16,14,12,10
	dc.w	2,6,2,4,8,4,6,10
	dc.w	12,14,16,4
	dc.w	2,18,4,16,10,6,14,8
	dc.w	12,2
	dc.w	2,18,4,16,20,6,14,8
	dc.w	12,10
