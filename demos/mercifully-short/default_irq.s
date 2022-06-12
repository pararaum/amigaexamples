	include	"t7d/music.i"
	include	"hardware/custom.i"
	include	"hardware/intbits.i"
	XREF	_custom

	XDEF	_install_enable_IRQ
	XDEF	_irqcounter
	XDEF	_irqVBLroutine

	DATA_C			; Chip memory
music:
	incbin	"MINISONG.MOD"

	DATA
_irqcounter:
	dc.l	0
_irqVBLroutine:
	dc.l	0

	TEXT			; Code
irqroutine:
regs$:	reg	d0-a6
	movem.l	regs$,-(a7)	; Save registers.
	lea.l	_custom,a6	; Put custom register base into A6.
	move.w	#INTF_VERTB,intreq(a6) ; Acknowledge interrupt.
	jsr	_pt_PlayMusic
	subq.l	#1,_irqcounter
	tst.l	_irqVBLroutine
	beq	.novbl
	move.l	_irqVBLroutine,a0
	jsr	(a0)
.novbl:
	movem.l	(a7)+,regs$	; Restore registers.
	rte

_install_enable_IRQ:
regs$:	reg	a6
	movem.l	regs$,-(a7)
	lea.l	_custom,a6	; Put custom register base into A6.
	lea.l	irqroutine(pc),a0
	move.l	a0,$6c.w	; Set level 3 interrupt routine.
	move.l	#music,-(a7)	; Address of the music onto stack.
	jsr	_pt_InitMusic	; Initialiase player
	addq.l	#4,a7		; Fix stack.
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,intena(a6)
	movem.l	(a7)+,regs$
	rts
