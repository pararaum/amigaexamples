        include "t7d/music.i"
        include "hardware/custom.i"
        include "hardware/intbits.i"
	include	"boss.memorymanagement.i"
	include	"boss.io.i"

	xdef	_demodata
;;; We will put this part into chipmem via BOSS.

;;; Memory layout:
;;; c20000-c4ffff (format "%x" (- #xc47fff #xc20000))"27fff"
;;; c50000-c7f000 (format "%x" (- #xc7f000 #xc50000))"2f000"

	rsreset
rsResident_framecounter:	rs.w	0
rsResident_totalframecounter:	rs.l	0
rsResidentSize:	rs


;;; Warning! When using BSS our linkerscript will put it into the file!
	BSS
pingmem:	ds.l	1
pongmem:	ds.l	1

	DATA
_demodata:
	ds.b	rsResidentSize

	section	LOWCODE,CODE
	jmp	entrypoint(pc)
	rts
	rts
	rts
	rts

entrypoint:
	BossIO	BossIODumpRegisters
	bsr	setup_music
	bsr	get_memory
	jsr	_main
	bra	*

get_memory:
	move.l	#$28000,d0
	lea.l	$c20000,a0
	BossMem	BossMemTrapAllocSlowAt
	move.l	a0,pingmem
	BossIOWriteS "Pingmemory = "
	move.l	pingmem,d0
	BossIO	BossIOPrintHex
	BossIOnl
	tst.l	pingmem
	bne	pingmemok$
	BossIOWritelnS	"Failed to allocate Ping memory!"
	bra	*
pingmemok$:
	move.l	#$2f000,d0
	lea.l	$c50000,a0
	BossMem	BossMemTrapAllocSlowAt
	move.l	a0,pongmem
	BossIOWriteS "Pongmemory = "
	move.l	pongmem,d0
	BossIO	BossIOPrintHex
	BossIOnl
	tst.l	pongmem
	bne	pongmemok$
	BossIOWritelnS	"Failed to allocate Pong memory!"
	bra	*
pongmemok$:
	move.l	a7,d0
	BossIO	BossIOPrintHex
	BossIOnl
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
	lea.l	_demodata,a0
	addq.l	#1,rsResident_totalframecounter(a0)
	addq.w	#1,rsResident_framecounter(a0)
	movem.l	(sp)+,regs$
	rte

	DATA
songdata:
	incbin	"bassing.modified.mod"
	even


