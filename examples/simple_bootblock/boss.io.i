; -*- mode: asm -*-

;;; Reset copperlist: reset the copperlist and enable bitplane DMA. Attention, no clearing of screen is done!
;;; Out: A0 = address of copperlist
;;;	 A1 = address of bitplane memory
BossIOTrapResetCopper = 0
;;; D0 = character to output
BossIOTrapPutc = 1
;;; A0 = string to output
BossIOTrapWrite = 2
;;; A0 = string to output, append a NL.
BossIOTrapWriteln = 3
;;; Bring cursor to (0, 0).
BossIOTrapHome = 4
;;; Clear Screen. Cursor to (0, 0).
BossIOTrapClrscr = 5
;;; Scroll screen up.
BossIOTrapScrollUp = 6
;;; Output a hexadecimal number.
;;; In: D0.l = value to output
BossIOPrintHex = 7
;;; Set foreground colour.
;;; In:	D0.w = foreground colour
BossIOForeground = 8
;;; Set background colour.
;;; In:	D0.w = background colour
BossIOBackground = 9
;;; Dump current register contents.
BossIODumpRegisters = 10

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
BossIOWriteS_DATA_\@:
	dc.b	\1
	dc.b	0
	even
	CODE
	move.l	#BossIOWriteS_DATA_\@,a0
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

