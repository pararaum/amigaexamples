        include "t7d/music.i"
        include "hardware/custom.i"
        include "hardware/intbits.i"
	include	"boss.memorymanagement.i"

	BSS
songmem:
	ds.l	1

	section	LOWCODE,CODE
	jmp	part_init(pc)
	jmp	part_run(pc)
	jmp	part_teardown(pc)
	jmp	part_vbirq(pc)
	;; Use this if nothing to do.
	rts
	nop
	;; or RTS RTS, ...

	CODE
part_run:
	rts
part_teardown:
	rts
part_vbirq:
	rts

part_init:
	move.l	#54810,d0
	BossMem	BossMemTrapAlloc
	move.l	a0,songmem
	beq	illegal$
	move.l	a0,a1
	lea.l	zx0songdata,a0
	BossMem	BossMemDecompressZX0
	bsr	setup_music
	jsr	_main
	move.l	songmem,a0
	BossMem	BossMemTrapFree
	rts
	
illegal$:	illegal

setup_music:
	lea.l	_custom,a6	; Custom register base into A6.
	lea.l	irqroutine(pc),a0
	move.l	a0,$6c.w	; Set level 3 interrupt routine.
	move.l	songmem,-(a7)
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
zx0songdata:
	incbin	"bassing.modified.mod.zx0"
	even


