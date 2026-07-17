        include "t7d/music.i"
        include "hardware/custom.i"
        include "hardware/intbits.i"
	include	"boss.memorymanagement.i"
;;; We will put this part into chipmem via BOSS.
	
	BSS
	section	LOWCODE,CODE

	bsr	setup_music
	;; 	jsr	_main
	bra	*
	rts
setup_music:
	lea.l	_custom,a6	; Custom register base into A6.
	lea.l	irqroutine(pc),a0
	move.l	a0,$6c.w	; Set level 3 interrupt routine.
	pea.l	songdata
	jsr	_pt_InitMusic
	addq.l	#4,a7
	move.w  #INTF_SETCLR|INTF_INTEN|INTF_VERTB,intena(a6)
	rts

irqroutine:
regs$:	reg	d0-a6
	movem.l	regs$,-(sp)
	lea.l	_custom,a6
	move.w	#INTF_VERTB,intreq(a6)
	jsr	_pt_PlayMusic
	movem.l	(sp)+,regs$
	rte

	DATA
songdata:
	incbin	"bassing.modified.mod"
	even


