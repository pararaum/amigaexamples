	include "hardware/custom.i"
	include	"own.i"
	
	XDEF	_init_framework
	XDEF	_shutdown_framework
	XDEF	_wait_for_mouse
	XREF	_do_interrupt_warp

interrupt_autovector:
	movem.l	d0-d7/a0-a6,-(sp)	;Store registers
	jsr	_do_interrupt_warp
	move.w	#$0010,$dff180		;Change background
	move.w	#(1<<2),$dff000+intreq	;Acknowledge interrupt
	movem.l	(sp)+,d0-d7/a0-a6	;Restore registers
	rte

;;; Initialise using the framework, will set interrupt, etc.
;;; Output:
;;; D0 = pointer to the bitplane space.
_init_framework:
	movem.l	d2-d7/a2-a6,-(sp)
        moveq   #OWN_libraries|OWN_view|OWN_trap|OWN_interrupt,d0
        jsr     own_machine
	lea.l	$dff000,a6
	move.w	#$0fff,180(a6)
	;; Now set the level 1 autovector (for SOFT interrupt).
	lea.l	interrupt_autovector(pc),a0
	move.l	a0,$64.w
	move.w	#$8000|(1<<14)|(1<<2),intena(a6)
	move.l	#bitplane,d0
	movem.l	(sp)+,d2-d7/a2-a6
	rts

;;; Restore the system.
_shutdown_framework:
	movem.l	d2-d7/a2-a6,-(sp)
        jsr     disown_machine
	movem.l	(sp)+,d2-d7/a2-a6
	rts

;;; Wait for mouse button.
;;; Destroys: A0
_wait_for_mouse:
	lea	$BFE001,a0		;CIA A
l$:	btst	#6,(a0)
	bne.b	l$
	rts

	section	chipbss,bss_c
bitplane:
	ds.b	320*256/8	;(/ (* 320 256) 8)10240
