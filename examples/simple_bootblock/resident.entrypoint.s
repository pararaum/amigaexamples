        include "t7d/music.i"
        include "hardware/custom.i"
        include "hardware/intbits.i"
	include	"boss.memorymanagement.i"
	include	"boss.io.i"

;;; We will put this part into chipmem via BOSS.

;;; Memory layout:
;;; c20000-c4ffff (format "%x" (- #xc47fff #xc20000))"27fff"
;;; c50000-c7f000 (format "%x" (- #xc7f000 #xc50000))"2f000"

;;; Warning! Do not use BSS, as the disk master does not know about BSS!
	;; BSS
	DATA
pingmem:	ds.l	1
pongmem:	ds.l	1

	section	LOWCODE,CODE

entry:
	bsr	setup_music
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


