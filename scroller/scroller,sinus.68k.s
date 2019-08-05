        INCLUDE "hardware/custom.i"
        INCLUDE "hardware/intbits.i"

	XDEF	_set_irq

	SECTION TEXT

;;; Set vertical blank.
;;; INPUT
;;; A0=pointer to function
_set_irq:
	movem.l	d0-a6,-(sp)
	move.l	a0,funcptr	; Store function to call.
	lea.l	$DFF000,a6	; Custom base
	lea.l	irqroutine(pc),a0
	move.l	a0,$6c.w	; Vertical blank
	move.w  #INTF_SETCLR|INTF_INTEN|INTF_VERTB,intena(a6)
	movem.l	(sp)+,d0-a6
	rts

funcptr:	dc.l	-1

irqroutine:
	movem.l	d0-a6,-(sp)
	move.l	funcptr(pc),a0
	jsr	(a0)
	;; Acknowledge interrupt!
	move.w  #INTF_VERTB,$DFF000+intreq
	movem.l	(sp)+,d0-a6
	rte
