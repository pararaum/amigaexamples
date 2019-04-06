
	XDEF	fade_out_copper_list
	XDEF	make_copper_list
	XDEF	_fade_in_copper_list

;;; Fade in (and generate the copperlist).
	;; Input
	;; A0: colour list of target colours
	;; A1: pointer to where the colour-data list should be generated
	;; A2: spare area (Must be initialised with zeros on first call), size is number of (3*colours)+1 WORDS!
	;; D0: number of colours
	;; D1: modulo to be added to A1 after each colour
	;; Output:
	;; D0: 0=still fading, 1=finished
	;; Destroys: D0-D1
_fade_in_copper_list:
	;; Spare area is:
	;;  - Counter (WORD)
	;;  - n colours (WORD)
	;; D2: Number of colours (copied from D0) - 1
	;; D3: = D1
	movem.l	a0-a2/d2-d3,-(sp)
	move.w	d0,d2		;Safe no. of colours
	move.l	d1,d3		;Safe modulo for generation
	cmp.w	#16,(a2)	;Maximum reached?
	bne.s	l2$		;Continue
	moveq	#1,d0
	bra.s	out$
l2$:	addq.w	#1,(a2)+	;Increment counter
	bra.s	in$		;Jump into loop -- this work even if d0==0
l1$:	move.w	(a0)+,d1	;Get next colour (source)
	move.w	d1,d0		;Only blue
	and.w	#$000f,d0
	add.w	d0,(A2)+
	lsr.w	#4,d1
	move.w	d1,d0		;Only green
	and.w	#$000f,d0
	add.w	d0,(A2)+
	lsr.w	#4,d1
	and.w	#$000f,d0
	move.w	d1,d0		;Only red
	add.w	d0,(A2)+
	move.w	-2(a2),d0	;Get red
	lsr.w	#4,d0		;divide by 16
	lsl.w	#8,d0		;move to position $0x00
	move.w	d0,d1
	move.w	-4(a2),d0	;Get green
	lsr.w	#4,d0		;divide by 16
	lsl.w	#4,d0		;move to position $00x0
	or.w	d0,d1
	move.w	-6(a2),d0	;Get blue
	lsr.w	#4,d0		;divide by 16
	or.w	d0,d1
	move.w	d1,(a1)+	;Store new colour (target)
	add.w	d3,a1		;Add modulo
in$:	dbf	d2,l1$
	moveq	#0,d0		;Fading not finished
out$:	movem.l	(sp)+,a0-a2/d2-d3
	rts

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

