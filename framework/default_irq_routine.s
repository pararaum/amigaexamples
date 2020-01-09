        INCLUDE "hardware/custom.i"
        INCLUDE "hardware/intbits.i"

	XDEF	_framecounter
	XDEF	_set_irq_routine

	SECTION	CODE
_set_irq_routine:
	move.w  #INTF_INTEN|INTF_VERTB,$DFF000+intena ; Disable irqs
	move.l	a7,stack_trick_stackpointer ; Store stack pointer for stack trick
	move.l	4(a7),initfunptr$	; Store function to call
	move.l	8(a7),entryfunptr$	; Store entry function pointer to call later
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	initfunptr$(pc),d0
	beq.s	noi$
	move.l	d0,a0
	jsr	(a0)
noi$:	move.l	#main_irq_routine,$6c.w ; Set irq pointer
	move.w  #INTF_SETCLR|INTF_INTEN|INTF_VERTB,$DFF000+intena
	move.l	entryfunptr$(pc),a0
	jsr	(a0)
	movem.l	(sp)+,d0-d7/a0-a6
	rts
initfunptr$:	dc.l	-1
entryfunptr$:	dc.l	-1

main_irq_routine:
	movem.l	d0-d7/a0-a6,-(sp)
	addq.l	#1,_framecounter
	btst	#6,$BFE001
	bne.s	no_mouse$
	lea.l	stack_trick$(pc),a0 ; Get pointer to the exit function.
	move.l	a0,15*4+2(a7)	    ; d0-d7/a0-a6 + SR
no_mouse$:
	;; Acknowledge interrupts
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
