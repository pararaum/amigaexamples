;;; Functions regarding the fading of the image.
	include	"image.defs.i"
	XDEF	do_fade_in
	XDEF	fade_in_copper_list
	XDEF	fade_color

	section	text,code

;;; Perform the fade in.
	;; A0: pointer to colour list of the image
	;; A1: pointer to copper colour area
do_fade_in:
	movem.l	d0-d7/a0-a5,-(sp) ;save registers
	move.l	a0,a5
	link	a6,#-IMAGE_COLOURS*4*2 ;three words per colour
	movem.l	d0-d1/a0,-(sp)	       ;save registers, again
	moveq	#0,d0		       ;clear
	moveq	#IMAGE_COLOURS*2-1,d1  ;4 words per colour (is easier to calculate)
	move.l	a7,a0		       ;address of spare area
l1$:	move.l	d0,(a0)+	       ;clear
	dbf	d1,l1$
	movem.l	(sp)+,d0-d1/a0	;restore
	moveq	#16-1,d2	;16 steps
	move.l	a7,a2		;spare address
l49$:	moveq	#IMAGE_COLOURS,d0 ;number of colours
	move.l	a5,a0		;pointer to colour list
	jsr	fade_in_copper_list ;do one fade
	bsr	wait_4_vblank	    ;wait
	bsr	wait_4_vblank
	bsr	wait_4_vblank
	bsr	wait_4_vblank
	bsr	wait_4_vblank
	bsr	wait_4_vblank
	dbf	d2,l49$		;16 times
	unlk	a6		;free spare area
	movem.l	(sp)+,d0-d7/a0-a5 ;restore registers
	rts

;;; Fade in (and generate the copperlist).
	;; A0: colour list of target colours
	;; A1: pointer to where the copper list should be generated
	;; A2: spare area
	;; D0: number of colours
	;; Destroys: D0-D1
fade_in_copper_list:
	;; D2: Number of colours (copied from D0) - 1
	;; D3: colour register number
	movem.l	a0-a2/d2-d3,-(sp)
	move.w	#$180,d3
	move.w	d0,d2
	bra.s	in$		;Jump into loop -- this work even if d0==0
l1$:	move.w	(a0)+,d1	;Get next colour
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
	move.w	d3,(a1)+	;Colour register (copper MOVE)
	addq	#2,d3		;Next register
	move.w	d1,(a1)+
in$:	dbf	d2,l1$
	movem.l	(sp)+,a0-a2/d2-d3
	rts


	;; a0: pointer to colour copper list begin
	;; d0.w: number of colours
fade_color:
	movem.l	d2-d7/a2-a6,-(sp)
	link	a5,#-32		; http://68k.hax.com/LINK
	;; A5 contains now the old SP, A7 points 32 bytes lower.
copbeg$ SET 0
copend$ SET 4
	move.l	a0,copbeg$(A7)	; Store begin of copper list.
	mulu.w	#4,d0
	add.l	d0,a0
	move.l	a0,copend$(A7)	; After end of copper list.
	lea.l	$DFF000,a4
l1$	move.l	copbeg$(A7),a0
	move.l	copend$(A7),a1
	jsr	fade_out_copper_list
	tst.l	d0
	beq	out$
	bsr	wait_4_vblank
	bsr	wait_4_vblank
	bsr	wait_4_vblank
	bsr	wait_4_vblank
	bra.s	l1$
out$:	nop
	;; Restore old stack pointer.
	unlk	a5
	movem.l	(sp)+,d2-d7/a2-a6
	rts
