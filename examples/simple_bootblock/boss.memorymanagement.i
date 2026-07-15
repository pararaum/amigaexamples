; -*- mode: asm -*-

;;; In:	D0.L = bytes to allocate
;;; Out: A0 = address of memory
BossMemTrapAlloc = 1
;;; A0 = address of memory to free
BossMemTrapFree = 2
;;; In:	D0.L = bytes to allocate
;;; Out: A0 = address of memory
BossMemTrapAllocSlow = 3
;;; A0 = address of memory to free
BossMemTrapFreeSlow = 4
;;; In: D0.l = number of bytes requested
;;;	A0.l = address requested
;;; Out: A0 = address we got or 0 on failure
BossMemTrapAllocChipAt = 5
;;; In: D0.l = number of bytes requested
;;;	A0.l = address requested
;;; Out: A0 = address we got or 0 on failure
BossMemTrapAllocSlowAt = 6
BossMemTrapCopyWords = 7
BossMemTrapClearWords = 8
;;; In:	a0.l = start of compressed data
;;;     a1.l = start of decompression buffer
BossMemDecompressZX0 = 9


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
