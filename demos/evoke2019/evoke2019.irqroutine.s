        INCLUDE "hardware/custom.i"
        INCLUDE "hardware/intbits.i"

	XDEF	_framecounter
	XDEF	_set_irq_routine

	SECTION	CODE
_set_irq_routine:
	move.l	a7,stack_trick_stackpointer ; Store stack pointer for stack trick
	move.l	4(a7),funcptr$	; Store funcion to call
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	#main_irq_routine,$6c.w ; Set irq pointer
	lea.l	$300.w,a1	; My own dangerous autovectors.
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	move.w  #INTF_SETCLR|INTF_INTEN|INTF_VERTB,$DFF000+intena
	move.l	funcptr$(pc),a0
	jsr	(a0)
	movem.l	(sp)+,d0-d7/a0-a6
	rts
funcptr$:	dc.l	0

main_irq_routine:
	movem.l	d0-d7/a0-a6,-(sp)
	addq.l	#1,_framecounter
	tst.l	$300.w
	beq.s	out$
	move.l	$300.w,a0
	jsr	(a0)
	tst.l	$304.w
	beq.s	out$
	move.l	$304.w,a0
	jsr	(a0)
	tst.l	$308.w
	beq.s	out$
	move.l	$308.w,a0
	jsr	(a0)
	tst.l	$30C.w
	beq.s	out$
	move.l	$30C.w,a0
	jsr	(a0)
out$:
	btst	#6,$BFE001
	bne.s	no_mouse$
	lea.l	stack_trick$(pc),a0 ; Get pointer to the exit function.
	move.l	a0,15*4+2(a7)	    ; d0-d7/a0-a6 + SR
no_mouse$:
	move.w	#INTF_VERTB,$DFF000+intreq
	move.w	#INTF_VERTB,$DFF000+intreq
	movem.l	(sp)+,d0-d7/a0-a6
	rte
stack_trick$:
	move.l	stack_trick_stackpointer,a7
	move.w  #$7fff,$DFF000+intena
	clr.l	d0
	rts

	SECTION	BSS,bss
stack_trick_stackpointer:	ds.l	1
_framecounter:	ds.l	1	; One longword for the framecounter.
