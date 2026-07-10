; -*- mode: asm -*-

;;; D0 = character to output
BossIOTrapPutc = 0
;;; A0 = string to output
BossIOTrapWrite = 1
;;; A0 = string to output, append a NL.
BossIOTrapWriteln = 2

;;; General macro to call a BossIO trap.
	macro	BossIO
	moveq	#\1,d7
	trap	#1
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
	even
	CODE
	move.l	#.l\@,a0
	BossIO	BossIOTrapWriteln
	endm
