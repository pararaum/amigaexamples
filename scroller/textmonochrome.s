
;;; Monochrome font functions.

	XDEF	_text_monochrome

	SECTION CODE
;;; Draw monochrome text onto a bitplane. The next must be null
;;; terminated. The font must be linear in memory and it must
;;; have a width of 8 pixels.
;;; Input
;;; A0: text
;;; A1:	font pointer
;;; A2: bitplane
;;; D0: Modulo
;;; Output: None
_text_monochrome:
	;; A0 text
	;; a1 current foint pointer
	;; a2 curretn bitplane pointer
	;; a3 contains the value of the targetplane (where the next character is put)
	;; A4 is a copy of the font pointer
	;; D1 current character
	movem.l	a2-a4,-(sp)
	move.l	a2,a3		;Target bitplane pointer
	move.l	a1,a4		;Font pointer
l1$:	moveq	#0,d1
	move.b	(a0)+,d1	;Load next character
	beq.s	out$		;Last character?
	sub.b	#' ',d1		;Font has to begin with a space!
	lsl.w	#3,d1		;Multiply by 8
	move.l	a4,a1		;Copy font pointer
	add.w	d1,a1		;Advance font to the character
	move.l	a3,a2		;Set bitplane pointer
	addq.l	#1,a3		;Increment target bitplane pointer
	move.b	(a1)+,(a2)	;Copy 8 bytes
	add.w	d0,a2
	move.b	(a1)+,(a2)
	add.w	d0,a2
	move.b	(a1)+,(a2)
	add.w	d0,a2
	move.b	(a1)+,(a2)
	add.w	d0,a2
	move.b	(a1)+,(a2)
	add.w	d0,a2
	move.b	(a1)+,(a2)
	add.w	d0,a2
	move.b	(a1)+,(a2)
	add.w	d0,a2
	move.b	(a1)+,(a2)
	bra.s	l1$
out$:	movem.l	(sp)+,a2-a4
	rts
