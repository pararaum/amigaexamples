
	XDEF	fade_out_copper_list
	XDEF	make_copper_list

;;; Produce a simple copper list for the colours. It will generate the number of colours colour-entries for a copper list. Make sure that there is enough space available.
	;; A0: pointer to where the copper list is do be stored
	;; D0: Number of colours
	;; D1: initial colour
	;; Destroys: A0-A1/D0-D1
	;; Output: A0 pointer after the end of the copper list.
make_copper_list:
	;; D2: colour register number
	subq	#1,d0		;Reduce by one for the dbf below.
	move.l	d2,-(sp)
	move.w	#$0180,d2	;First colour registers
l1$:	move.w	d2,(a0)+	;Writer copper MOVE
	addq	#2,d2		;Increment colour register for next MOVE
	move.w	d1,(a0)+	;Write default colour
	dbf	d0,l1$		;Branch as long as d0 is not equal to zero.
	move.l	(sp)+,d2
	rts

;;; Fade a copper colour list out. This function will iterate through a copper list and subtract from the red, green, and blue components until the colour black is reached. It will return the number of non-black colours left.
	;; a0: pointer to colour copper list begin
	;; a1: pointer to end of copper list (AFTER last copper command)
	;; Destroys: a0, a1, d0, d1
	;; Output: D0: number of non-black colours
fade_out_copper_list:
	;; D2: Number of non-zero values.
	move.l	d2,-(sp)
	addq	#2,a0		;Points to the first colour value
	addq	#2,a1		;Points to the last colour value
	moveq	#0,d2		; number of non-zero values
l1$:	move.w	(a0),d0		; Colour value into d0
	beq	azero$		; Is it zero? Then skip!
	move.w	d0,d1		; Copy current colour into d1
	and.w	#$0f00,d1	; And red component.
	beq.s	noR$		; No red component left.
	sub.w	#$0100,d0	; Subtract red
noR$:	move.w	d0,d1		; Again copy colour into d1
	and.w	#$00f0,d1	; Check for green
	beq.s	noG$		; No green left.
	sub.w	#$0010,d0	; Subtract one from green.
noG$:	move.w	d0,d1		; Again copy colour into d1
	and.w	#$000f,d1	; Blue component left?
	beq.s	noB$		; No blue.
	sub.w	#$0001,d0	; Subtract from blue
noB$:	move.w	d0,(a0)		; Write colour back.
	addq	#1,d2		; If we are here a non-zero colour was found.
azero$:	addq	#4,a0		; Go to the next colour code
	cmp.l	a1,a0		; Still smaller?
	blt.s	l1$		; Branch on less.
	move.l	d2,d0
	move.l	(sp)+,d2
	rts

