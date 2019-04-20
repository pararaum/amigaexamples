	INCLUDE "hardware/custom.i"
	INCLUDE "hardware/intbits.i"
   
	XDEF	_setup_interrupt
	XDEF	_framecounter
	XDEF	_interrupt_pointer

;;; Setup the interrupt autovector for VBLANK.
	;; Out: d0: pointer to the framecounter
_setup_interrupt:
	move.l	a7,old_frame
	move.l	4(a7),playfieldptr
	lea.l	irq$(pc),a0	; New IRQ routine
	move.l	a0,$6c.w	; Set level 3 autovector (VBLANK)
	;; Enable interrupt
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,$dff000+intena
	;; Get function pointer.
	move.l	8(a7),a0
	;; Call
	jsr	(a0)
	move.l	#_framecounter,d0
	rts
irq$:	movem.l	d0-d7/a0-a6,-(sp)
	addq.l	#1,_framecounter
	tst.l	$3f0.w
	beq.s	n1$
	move.l	($3f0).w,a0
	jsr	(a0)
n1$:	tst.l	$3f4.w
	beq.s	n2$
	move.l	($3f4).w,a0
	jsr	(a0)
n2$:
	bsr	irqroutine
	btst	#6,$BFE001	; Mouse button?
	bne.s	nom$		; No mouse button
	;; Button pressed, do the stack trick:
	lea.l	stacktrick$(pc),a0
	move.l	a0,15*4+2(a7)	; New return address
nom$:
	;; Acknowledge interrupt.
	move.w	#INTF_VERTB,$dff000+intreq
	movem.l	(sp)+,d0-d7/a0-a6
	rte
stacktrick$:
	move.l	old_frame,a7
	moveq	#0,d0
	rts


irqroutine:
	subq.w	#1,skipctr$
	bpl.s	skip$		; Only every 15th(!) frame...
	move.w	#$15-1,skipctr$
	move.l	playfieldptr,a1
	lea.l	rng_data,a0
	;; Read current value into d0-d1.
	move.w	(a0),d2
	move.w	d2,d0
	move.w	d2,d1
	;; See https://en.wikipedia.org/wiki/Linear_feedback_shift_register Xorshift LFSR.
	lsr.w	#7,d1
	eor.w	d1,d0
	move.w	d2,d1
	lsl.w	#8,d1
	lsl.w	#1,d1
	eor.w	d1,d0
	move.w	d2,d1
	lsr.w	#8,d1
	lsr.w	#5,d1
	eor.w	d1,d0
	move.w	d0,(a0)		; Store next value.
	and.w	#$01ff,d0	; Only lower 9 bit.
	cmp.w	#400,d0		; < 400? This is the number of lines times two bitplanes.
	bcc.s	skip$
	;; d0 containes the line number
	mulu.w	#320/8,d0	; 320 pixels per scanline.
	subq	#1,d0		; Move to the right end of the screen on the *previous* line.
	bset.b	#0,(a1,d0)
skip$:
	rts
skipctr$:	dc.w	0

	section	DATA,data
_framecounter:	dc.l	0
_interrupt_pointer:	dc.l	0

rng_data:	dc.w	$ACE1

	section BSS,bss
old_frame:	ds.l	1
playfieldptr:	ds.l	1
