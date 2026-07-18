; -*- mode: asm -*-

;;; D0 = character to output
BossIOTrapPutc = 0
;;; A0 = string to output
BossIOTrapWrite = 1
;;; A0 = string to output, append a NL.
BossIOTrapWriteln = 2
;;; Bring cursor to (0, 0).
BossIOTrapHome = 3
;;; Clear Screen. Cursor to (0, 0).
BossIOTrapClrscr = 4
;;; Scroll screen up.
BossIOTrapScrollUp = 5
;;; Output a hexadecimal number
;;; In: D0.l = value to output
BossIOPrintHex = 6
;;; Trackload data.
;;; D0.w = start sector, D1.w = number of sectors to load, A0.l = data destination address
BossIOTrapTrackload = 21
;;; Load data from manifest.
;;; In:	D0.l = id of entry to load
;;; Out: D0.l and A0.l = address of memory (or zero)
BossManifestLoad = 22

;;; General macro to call a BossIO trap.
	macro	BossIO
	moveq	#\1,d7
	trap	#1
	endm

	macro	BossIOnl
	moveq	#10,d0
	moveq	#7,d7
	BossIO	BossIOTrapPutc
	endm

	macro	BossIOWrite
	BossIO	BossIOTrapWrite
	endm
	
	macro	BossIOWriteS
	DATA
.l\@:	dc.b	\1
	dc.b	0
	even
	CODE
	move.l	#.l\@,a0
	BossIO	BossIOTrapWrite
	endm

	macro	BossIOWriteln
	BossIO	BossIOTrapWriteln
	endm
	
	macro	BossIOWritelnS
	DATA
.l\@:	dc.b	\1
	dc.b	0
	even
	CODE
	move.l	#.l\@,a0
	BossIO	BossIOTrapWriteln
	endm

