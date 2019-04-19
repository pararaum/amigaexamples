	INCLUDE "hardware/custom.i"
	INCLUDE "hardware/intbits.i"
   
	XDEF	_setup_interrupt
	XDEF	_framecounter
	XDEF	_interrupt_pointer

;;; Setup the interrupt autovector for VBLANK.
	;; Out: d0: pointer to the framecounter
_setup_interrupt:
	move.l	a7,old_frame
	lea.l	irq$(pc),a0	; New IRQ routine
	move.l	a0,$6c.w	; Set level 3 autovector (VBLANK)
	;; Enable interrupt
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,$dff000+intena
	move.l	#_framecounter,d0
	rts
irq$:	movem.l	d0-d7/a0-a6,-(sp)
	addq.l	#1,_framecounter
	;; Acknowledge interrupt.
	move.w	#INTF_VERTB,$dff000+intreq
	movem.l	(sp)+,d0-d7/a0-a6
	rte
	
	section	DATA,data
_framecounter:	dc.l	0
_interrupt_pointer:	dc.l	0

	section BSS,bss
old_frame:	ds.l	1
