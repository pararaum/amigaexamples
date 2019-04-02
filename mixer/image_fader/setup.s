;;; ASM function for setup and configuration of machine.
	INCLUDE	"own.i"
	XDEF	_own_machine
	XDEF	_disown_machine

	XDEF	_some_var

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

	SECTION	DATA,data
_some_var:	dc.l	$DEADBEA1
