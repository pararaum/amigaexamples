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
;;; In:	d0.w = number of words (max. 32767!)
;;;	A0 = source
;;;	A1 = destination
BossMemTrapCopyWords = 7
;;; In:	d0.w = number of words (max. 32767!)
;;;	A0 = destination
BossMemTrapClearWords = 8
;;; In:	a0.l = start of compressed data
;;;     a1.l = start of decompression buffer
BossMemDecompressZX0 = 9
;;; Find an entry in the manifest list.
;;; In: d0.l = name of the entry
;;; Out: a0 = address of entry or 0
BossFindManifestEntry = 10


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

;;; Manifest memory structure.
	rsreset
rsManifestName:	rs.l	1
rsManifestStartSector:	rs.w	1
rsManifestNumSectors:	rs.w	1
rsManifestPackedSize:	rs.l	1
rsManifestUnpackedSize:	rs.l	1
rsManifestMemflags:	rs.l	1
rsManifestStructsize:	rs

;;; Address of the copperlist that is used by BOSS.
	PUBLIC	BOSSSCREENCOPPERLIST
;;; Address of the BOSS screen memory.
	PUBLIC	BOSSSCREENBITPLANE
