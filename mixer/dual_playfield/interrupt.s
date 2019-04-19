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
	move.l	#_framecounter,d0
	rts
irq$:	movem.l	d0-d7/a0-a6,-(sp)
	addq.l	#1,_framecounter
	tst.l	$3f0.w
	beq.s	n1$
	jsr	($3f0).w
n1$:	tst.l	$3f4.w
	beq.s	n2$
	jsr	($3f4).w
n2$:
	bsr	irqroutine
	;; Acknowledge interrupt.
	move.w	#INTF_VERTB,$dff000+intreq
	movem.l	(sp)+,d0-d7/a0-a6
	rte

irqroutine:
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
	and.w	#$00ff,d0	; Only lower 8 bit.
	cmp.w	#200,d0		; < 200? This is the number of lines.
	bcc.s	skip$
	;; d0 containes the line number
	mulu.w	#320/8*2,d0	; 320 pixels and 2 bitplanes.
	subq	#1,d0		; Move to the right end of the screen on the *previous* line.
	bset.b	#0,(a1,d0)
skip$:
	rts


	section	DATA,data
_framecounter:	dc.l	0
_interrupt_pointer:	dc.l	0

rng_data:	dc.w	$ACE1

	section BSS,bss
old_frame:	ds.l	1
playfieldptr:	ds.l	1
