; -*- mode: asm -*-

BossMemTrapAlloc = 1
BossMemTrapFree = 2
BossMemTrapAllocSlow = 3
BossMemTrapFreeSlow = 4
BossMemTrapCopyWords = 5
BossMemTrapClearWords = 6

	MACRO	BossMem
	moveq	#\1,d7
	trap	#15
	ENDM

	macro	BossMemCopyWords
	lea.l	\1,a1		; To
	lea.l	\2,a0		; From
	move.w	#\3,d0		; Number of words
	BossMem BossMemTrapCopyWords
	endm

	macro	BossMemClearWords
	lea.l	\1,a0		; Memory address
	move.w	#\2,d0		; Number of bytes
	BossMem	BossMemTrapClearWords
	endm
