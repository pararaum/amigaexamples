;;; ASM function for setup and configuration of machine.
	INCLUDE	"hardware/custom.i"
	INCLUDE	"hardware/intbits.i"
	INCLUDE	"own.i"
	XDEF	_own_machine
	XDEF	_disown_machine
	XDEF	_set_interrupt

	XDEF	_framecounter
	XDEF	_mousebutton
	XDEF	_vertical_blank_irqfun

;;; Set up everything to control the machine fully.
;;; O: D0: pointer to gfx library
_own_machine:
	moveq	#OWN_libraries|OWN_view|OWN_trap|OWN_interrupt,d0
	jsr	own_machine
	move.l	a0,d0
	rts

;;; Relent control over machine.
_disown_machine:
	jsr	disown_machine
	rts

;;; Set the interrupt for vertical blanking. (Level 3)
	;; Output: D0: interrupt routine address
_set_interrupt:
	lea.l	irq_routine(pc),a0
	move.l	a0,$6c.w	;Lvl 3 autovector
	move.w  #INTF_SETCLR|INTF_INTEN|INTF_VERTB,$DFF000+intena
	move.l	a0,d0
	rts

;;; ---------------------------------------------------------------------------

;;; This routine is called on every (VBLANK) interrupt.
irq_routine:
	movem.l	d0-d7/a0-a6,-(sp)
	;; Incremtent framecounter
	addq.l	#1,_framecounter
	move.l	_vertical_blank_irqfun,d0
	beq.s	nocall$
	move.l	d0,a0
	jsr	(a0)
nocall$:
	;; Test mouse
	btst	#6,$BFE001
	bne.s	nom$		;No mouse
	move.w	#1,_mousebutton
nom$:	move.w  #INTF_VERTB,$DFF000+intreq
	movem.l	(sp)+,d0-d7/a0-a6
	rte

	SECTION	DATA,data
	;; Number of vertical blanks
_framecounter:	dc.l	-1
	;; This will have a non-zero value until a mouse button is pressed.
_mousebutton:	dc.w	0
	;; This is a function pointer to a function called at every vertical blank.
_vertical_blank_irqfun:	dc.l	0
