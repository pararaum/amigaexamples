
	XDEF	_gen_copper_palette

	SECTION	CODE,CODE
;;; Generate copper list palette of 16 colours.
;;; Input
;;; A0 = target pointer
;;; D0 = number of palette
;;; Destroys: A0-A1/D0-D1
;;; Output:
;;; D0 & A0 = End of generated copper list
_gen_copper_palette:
	lea.l	palette_colours,a1
	lsl.w	#4+1,d0		; 16 colours and a WORD per colour
	add.w	d0,a1
	move.w	#$0180,d0
	moveq	#16-1,d1
l36$:	move.w	d0,(a0)+
	addq.w	#2,d0
	move.w	(a1)+,(a0)+
	dbf	d1,l36$
	move.l	a0,d0
	rts

	SECTION	DATA,DATA

palette_colours:
	INCLUDE	"image.past.asmpalette"
	INCLUDE	"image.present.asmpalette"
	INCLUDE	"image.future.asmpalette"
