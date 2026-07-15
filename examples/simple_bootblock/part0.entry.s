	include	"boss.memorymanagement.i"

	BSS
songmem:
	ds.l	1

	section	LOWCODE,CODE

	move.l	#54810,d0
	BossMem	BossMemTrapAlloc
	tst.l	(a0)		; We got the memory?
	beq	illegal$
	move.l	a0,songmem
	move.l	a0,a1
	lea.l	zx0songdata,a0
	BossMem	BossMemDecompressZX0
	jsr	_main
	move.l	songmem,a0
	BossMem	BossMemTrapFree
	rts
	
illegal$:	illegal

	DATA
zx0songdata:
	incbin	"bassing.modified.mod.zx0"
	even


