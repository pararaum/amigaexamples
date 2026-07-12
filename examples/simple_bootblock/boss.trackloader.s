;;; Trackloader, for further resources, see:
;;;  * Interphase trackloader
;;;  * https://cyberpingui.pages-perso.free.fr/tuto_trackloader.htm
;;;  * https://github.com/amigadev/trackloader/blob/master/bootblock.asm
;;;  * https://cyberpingui.pages-perso.free.fr/oldies/sources/crktrosrcs/hardwaretrackloadermultidisk.s

	include "boss.memorymanagement.i"
	include "boss.io.i"
	include	hardware/custom.i
	include	hardware/dmabits.i
	include hardware/adkbits.i
	include hardware/cia.i
	XREF _ciab		; $BFD000

	XDEF	boss_trackloader_init

SyncWord	Equ	$4489	; Default sync value.

; Structure for our disk.
	rsreset
rsDiskPosition		rs.b	1
rsDiskDirection		rs.b	1
rsDiskStartTrack	rs.b	1
rsDiskStartSector	rs.b	1
rsDiskTracks		rs.b	1
rsDiskEndSector		rs.b	1
rsDiskBuf		rs.l	1		 ; Pointer to the Memory for the track buffer, must be in CHIP.
rsDiskStructSize	rs

	BSS
current_diskstruct:	ds.b	rsDiskStructSize
	even


	code
boss_trackloader_init:
	link	a6,#0
	moveq	#0,d0
	lea	$DFF000,a5
	lea	current_diskstruct,a0
	move.b	d0,rsDiskPosition(a0)
	move.b	d0,rsDiskDirection(a0)
	move.b	d0,rsDiskStartTrack(a0)
	move.b	d0,rsDiskTracks(a0)
	move.b	d0,rsDiskEndSector(a0)
	move.l	#$1000,rsDiskBuf(a0) ; Hard coded for now.
	;move.l	#rsDiskStructSize,d0
	;BossMem	BossMemTrapAlloc
	;move.l	a0,current_diskstruct
	;move.l	a0,-(sp)
	;bsr	_ul2hex
	;move.l	d0,a0
	;BossIO	BossIOTrapWriteln

	move.w	#SyncWord,dsksync(a5)	; DSKSYNC, this is the default synchronisation mode.
	move.w	#$7f00,adkcon(a5)	; clear all disk bits
	move.w	#ADKF_SETCLR|ADKF_MFMPREC|ADKF_FAST|ADKF_WORDSYNC,adkcon(a5)
	move.b	#CIACRAF_OUTMODE|CIACRAF_RUNMODE|CIACRAF_SPMODE,ciacra+_ciab ; Stop, one-shot mode.

	bsr	SelDF0MotOn
;		Bsr	GoToTrack00
;		Bsr	SelDF0MotOff
;		Rts
	unlk	a6
	rts


;	lea	trackbuffer(pc),a1
;	bsr	Init
;	lea	$400.w,a0
;	moveq	#2,d0		; start block 0-1803
;	move.l	#130,d1		; number of blocks
;	bsr	Loader
;
;	lea	$10000,a0
;	move.l	#128,d0		; start block 0-1803
;	move.l	#1056,d1	; number of blocks
;	bsr	Loader
;
;	ILLEGAL
;
;*===========================================================================*
;
SelDF0MotOn:
	or.b	#CIAF_DSKSEL3|CIAF_DSKSEL2|CIAF_DSKSEL1|CIAF_DSKSEL0,ciaprb+_ciab ; Deselect all drives by setting bits to high.
	bclr	#CIAF_DSKMOTOR,ciaprb+_ciab ; Clear bit to switch motor on.
	nop
	nop
	bclr	#CIAF_DSKSEL0,$bfd100 ; Clear bit 3 to select DF0.
	rts
SelDF0MotOff:
	or.b	#CIAF_DSKSEL3|CIAF_DSKSEL2|CIAF_DSKSEL1|CIAF_DSKSEL0,ciaprb+_ciab ; Deselect all drives by setting bits to high.
	bset	#CIAF_DSKMOTOR,ciaprb+_ciab ; Set bit to switch motor off.
	nop
	nop
	bclr	#CIAF_DSKSEL0,$bfd100 ; Clear bit 3 to select DF0.
	rts

;*­---------------------------------------------­*
;
;	*	Control routine.
;
;	*	Start block -> d0
;	*	Number of blocks -> d1
;	*	Destination address -> a0
;
;Loader		Tst.l	d1
;		Beq	ExitLR
;		Bmi	ExitLR
;		Tst.l	d0
;		Bmi	ExitLR			Boundary check.
;		Move.l	d1,d2
;		Add.l	d0,d2
;		Cmp.l	#1804,d2
;		Bgt	ExitLR
;
;		Bsr.s	SelDF0MotOn
;		Divu	#11,d0
;		Move.b	d0,StartTrack(a4)
;		Move.l	d0,d2
;		Swap 	d2
;		Move.b	d2,StartSector(a4)
;		Add.b	d2,d1
;		Divu	#11,d1
;		Move.l	d1,d2
;		Swap 	d2
;		Tst.b	d2
;		Bne.s	EqualTrack
;		Subq.b	#1,d1
;		Move.b	#11,d2
;EqualTrack	Move.b	d1,Tracks(a4)
;		Move.b	d2,EndSector(a4)
;
;		Move.b	d0,d1			Start-track in d0.
;		Move.b	Position(a4),d2
;		Lsr.b	#1,d1
;		Lsr.b	#1,d2
;		Cmp.b	d1,d2
;		Beq.s	RightCyl		No need to move head.
;		Blt.s	MoveHeadIn
;		Sub.b	d1,d2			Moving head outwards.
;		Bsr	MoveOutwards
;		Subq.b	#1,d2
;		Beq.s	RightCyl
;		Subq.b	#1,d2
;		Ext.w	d2
;.MoveHeadOut	Bsr	MoveHead
;		Dbra	d2,.MoveHeadOut
;		Bra.s	RightCyl
;MoveHeadIn	Sub.b	d2,d1			Moving head inwards.
;		Bsr	MoveInwards
;		Subq.b	#1,d1
;		Beq.s	RightCyl
;		Subq.b	#1,d1
;		Ext.w	d1
;.MoveHeadIn	Bsr	MoveHead
;		Dbra	d1,.MoveHeadIn
;RightCyl	Btst	#0,StartTrack(a4)		Time to choose side.
;		Beq.s	.LowerIt
;		Btst	#2,$bfd100
;		Beq.s	RightTrack
;		Bsr	Upper
;		Bra.s	RightTrack
;.LowerIt	Btst	#2,$bfd100
;		Bne.s	RightTrack
;		Bsr	Lower
;RightTrack	Move.b	StartSector(a4),d3	And now, the reading begins.
;		Move.b	Tracks(a4),d2
;		Beq.s	LastTrack
;		Moveq	#11,d4
;		Bsr.s	Read
;NextTrack	Moveq	#0,d3
;		Btst	#2,$bfd100
;		Bne.s	NextSide
;		Bsr	Lower
;		Btst	#1,$bfd100
;		Bne.s	.FirstMoveIn
;		Bsr	MoveHead
;		Bra.s	NextRead
;.FirstMoveIn	Bsr	MoveInwards
;		Bra.s	NextRead
;NextSide	Bsr	Upper
;NextRead	Subq.b	#1,d2
;		Beq.s	LastTrack
;		Bsr.s	Read
;		Bra.s	NextTrack
;LastTrack	Move.b	EndSector(a4),d4
;		Bsr.s	Read
;		Bsr.s	SelDF0MotOff
;ExitLR		Rts
;
;*­-­-­-­-­-­-­-­-­-­-­-­-­-­-­-­-­-­-­-­-­-­-­-­*
;
;
;*­---------------------------------------------­*
;
;Read		Btst	#5,$bfe001		Await Disk ready.
;		Bne.s	Read
;		Move.b	#$91,$bfd400		Timer A low.
;		Move.b	#$29,$bfd500		Timer A hi, and starts timer.
;		Bsr	Timer
;		Move.w	#2,$9c(a5)		Clear Disk Intrequest.
;		Move.l	buf(a4),$20(a5)	DSKPT, MFM-buffer.
;		Move.w	#$8010,$96(a5)		Disk DMA on.
;		Move.w	#$4000,$24(a5)		dsklen
;		Move.w	#$9900,$24(a5)		dsklen, read lenght.
;		Move.w	#$9900,$24(a5)		dsklen
;.DMAwait	Btst	#1,$1f(a5)		DMA transfer done when high.
;		Beq.s	.DMAwait
;		Move.w	#$4000,$24(a5)
;		Move.w	#$0010,$96(a5)		Disk DMA off.
;
;*­---------------------------------------------­*
;	*	Destination address -> a0
;	*	Start sector -> d3
;	*	End sector -> d4
;
;Decode		Move.w	#SyncWord,d5		Sync-word.
;		Move.l	#$55555555,d7		%010101...
;
;FindSector	movea.l	buf(a4),a1		Move Buffer-address.
;SyncSearch	Cmp.w	(a1)+,d5		Check for Sync-word.
;		Bne.s	SyncSearch
;		Cmp.w	(a1),d5			Another Sync-word?
;		Beq.s	SyncSearch
;		Move.l	(a1),d0
;		Move.l	4(a1),d1
;		And.l	d7,d0
;		Asl.l	#1,d0
;		And.l	d7,d1
;		Or.l	d1,d0
;		Ror.l	#8,d0
;		Cmp.b	d3,d0			Correct sector?
;		Beq.s	SectorOK
;		Lea	$43E(a1),a1		Add to next sector.
;		Bra.s	SyncSearch
;
;SectorOK	Addq.b	#1,d3
;		Lea	$38(a1),a1		Skip InfoBytes.
;		Moveq	#$7f,d6
;DeCodeLoop	Move.l	$200(a1),d1
;		Move.l	(a1)+,d0
;		And.l	d7,d0
;		Asl.l	#1,d0
;		And.l	d7,d1
;		Or.l	d1,d0
;		Move.l	d0,(a0)+		Move to Load Address.
;		Dbra	d6,DeCodeLoop
;		Cmp.b	d4,d3
;		Bne.s	FindSector
;		Rts
;
;*­---------------------------------------------­*
;
;GoToTrack00	Btst	#4,$bfe001	Track 00 when low.
;		Beq.s	Pos00
;		Bsr.s	MoveOutwards
;TowardsTrack00	Btst	#4,$bfe001	Track 00 when low.
;		Beq.s	Pos00
;		Bclr	#0,$bfd100	Move head.
;		Nop
;		Nop
;		Bset	#0,$bfd100	Prepare to move head.
;		Move.b	#$69,$bfd400	Timer A low.
;		Move.b	#$0e,$bfd500	Timer A hi, and starts timer.
;		Bsr.s	Timer		5.2ms
;		Bra.s	TowardsTrack00
;Pos00		Clr.b	Position(a4)
;		Rts
;
;*­---------------------------------------------­*
;
;Upper		Bclr	#2,$bfd100	Upper side.
;		Move.b	#$47,$bfd400	Timer A low.
;		Move.b	#$00,$bfd500	Timer A hi, and starts timer.
;		Bra.s	Timer		100µs
;
;*­---------------------------------------------­*
;
;Lower		Bset	#2,$bfd100	Lower side.
;		Move.b	#$47,$bfd400	Timer A low.
;		Move.b	#$00,$bfd500	Timer A hi, and starts timer.
;		Bra.s	Timer		100µs
;
;*­---------------------------------------------­*
;
;MoveOutwards	Bset	#1,$bfd100	Head direction outward.
;		Bclr	#0,$bfd100	Move head.
;		Nop
;		Nop
;		Bset	#0,$bfd100	Prepare to move head.
;		Move.b	#$e1,$bfd400	Timer A low.
;		Move.b	#$31,$bfd500	Timer A hi, and starts timer.
;		Move.b	#-2,Direction(a4)
;		Add.b	#-2,Position(a4)	18ms
;
;*­---------------------------------------------­*
;
;Timer		Move.b	$bfdd00,d0	Await Timer ready.
;		Btst	#0,d0
;		Beq.s	Timer
;		Rts
;
;*­---------------------------------------------­*
;
;MoveInwards	And.b	#$fc,$bfd100	Clear bits 0 and 1,
;		Nop	which results in diskdirec=inwards, head moved.
;		Nop
;		Bset	#0,$bfd100	Prepare to move head.
;		Move.b	#$e1,$bfd400	Timer A low.
;		Move.b	#$31,$bfd500	Timer A hi, and starts timer.
;		Move.b	#2,Direction(a4)
;		Addq.b	#2,Position(a4)
;		Bra.s	Timer		18ms
;
;*­---------------------------------------------­*
;
;MoveHead	Bclr	#0,$bfd100	Move head.
;		Nop
;		Nop
;		Bset	#0,$bfd100	Prepare to move head.
;		Move.b	#$50,$bfd400	Timer A low.
;		Move.b	#$08,$bfd500	Timer A hi, and starts timer.
;		Move.b	Direction(a4),d0
;		Add.b	d0,Position(a4)
;		Bra.s	Timer		3ms
;
;trackbuffer:
;	even
	END
