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

;;; CIA B is used, and there we are going to use timer A.
	XREF _ciab

	XDEF	boss_trackloader_init

SyncWord	Equ	$4489	; Default sync value.

; Structure for our disk.
	rsreset
rsDiskPosition		rs.b	1 ; Where is the head?
rsDiskDirection		rs.b	1
rsDiskStartTrack	rs.b	1
rsDiskStartSector	rs.b	1
rsDiskTracks		rs.b	1 ; Tracks to load.
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
	move.l	#$500,rsDiskBuf(a0) ; Hard coded for now.
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
	;; Outmode=toggle, runmode=1 is one-shot, spmode=1 is output on serial(?), load=0 means every write in hi latches the value into the timer, inmode=0 is 716 kHz mode.
	move.b	#CIACRAF_OUTMODE|CIACRAF_RUNMODE|CIACRAF_SPMODE,_ciab+ciacra

	bsr	SelDF0MotOn
	bsr	GoToTrack00
	bsr	SelDF0MotOff

	moveq	#0,d0
	moveq	#120,d1
	lea.l	$c50000,a0
	bsr	trackload_data
	unlk	a6
	rts


SelDF0MotOn:
	or.b	#CIAF_DSKSEL3|CIAF_DSKSEL2|CIAF_DSKSEL1|CIAF_DSKSEL0,ciaprb+_ciab ; Deselect all drives by setting bits to high.
	bclr	#CIAB_DSKMOTOR,ciaprb+_ciab ; Clear bit to switch motor on.
	nop
	nop
	bclr	#CIAB_DSKSEL0,$bfd100 ; Clear bit 3 to select DF0.
	rts
SelDF0MotOff:
	or.b	#CIAF_DSKSEL3|CIAF_DSKSEL2|CIAF_DSKSEL1|CIAF_DSKSEL0,ciaprb+_ciab ; Deselect all drives by setting bits to high.
	bset	#CIAB_DSKMOTOR,ciaprb+_ciab ; Set bit to switch motor off.
	nop
	nop
	bclr	#CIAB_DSKSEL0,$bfd100 ; Clear bit 3 to select DF0.
	rts

;;; Trackload data (sectors) into memory
;;; In: D0.w = startblock
;;;	D1.w = number of blocks
;;;	A0.l = destination address
;;; Modifies: d0-d2,a0
trackload_data:
curdisstrptr$	equr	a4
	tst.w	d1		; Sanity check number of blocks to read.
	beq	exit$
	bmi	exit$
	tst.w	d0		; Negative start block?
	bmi	exit$
	move.w	d1,d2
	add.w	d0,d2
	cmp.l	#1804,d2
	bgt	exit$

	lea.l	current_diskstruct,curdisstrptr$ ; Get pointer
	bsr	SelDF0MotOn ; Start the motor.
	divu	#11,d0	    ; Divide d0 by 11 (no of sectors per track) to get cylinder/track.
	move.b	d0,rsDiskStartTrack(curdisstrptr$)
	move.l	d0,d2	    ; Division result/remainder into d2.
	swap 	d2	    ; Remainder aka start sector.
	move.b	d2,rsDiskStartSector(curdisstrptr$)
	add.w	d2,d1	      ; Add start sector to number of blocks(?).
	divu	#11,d1
	move.l	d1,d2		; track in result/sector in remainder
	swap 	d2		; D2 = track
	tst.b	d2
	bne.s	equaltrack$
	subq.b	#1,d1
	move.b	#11,d2
equaltrack$:
	move.b	d1,rsDiskTracks(a4)
	move.b	d2,rsDiskEndSector(a4)
	move.w	d0,d1			Start-track in d0.
	move.b	rsDiskPosition(a4),d2
	lsr.b	#1,d1
	lsr.b	#1,d2
	cmp.b	d1,d2
	beq.s	rightcyl$	; The cylinder is right.
	blt.s	moveheadin$
	sub.b	d1,d2	       ; How many cylinders outward?
	bsr	move_outwards
	subq.b	#1,d2
	beq.s	rightcyl$
	subq.b	#1,d2
	ext.w	d2
moveheadout$:
	bsr	move_outwards
	dbra	d2,moveheadout$
	bra.s	rightcyl$
moveheadin$:
	sub.b	d2,d1		; How many cylinders inward?
	bsr	move_inwards
	subq.b	#1,d1
	beq.s	rightcyl$
	subq.b	#1,d1
	ext.w	d1
movefurtherin$:
	bsr	move_inwards
	dbra	d1,movefurtherin$
rightcyl$:
	btst	#0,rsDiskStartTrack(a4) ; Getting the side (upper/lower) bit.
	beq.s	lower_side$
	bsr	select_upper_side
	bra.s	already_right_track$
lower_side$:
	bsr	select_lower_side
already_right_track$:
	move.b	rsDiskStartSector(a4),d3 ; Read the sectors.
	move.b	rsDiskTracks(a4),d2
	beq.s	lasttrack$
	moveq	#11,d4
	bsr.s	read_and_decode
nexttrack$:
	moveq	#0,d3
	btst	#2,$bfd100
	bne.s	nextside_up$
	bsr	select_lower_side
	btst	#1,$bfd100
	bne.s	firstmovein$
	bsr	move_inwards
	bra.s	nextread$
firstmovein$:
	bsr	move_inwards
	bra.s	nextread$
nextside_up$:
	bsr	select_upper_side
nextread$:
	subq.b	#1,d2
	beq.s	lasttrack$
	bsr.s	read_and_decode
	bra.s	nexttrack$
lasttrack$:
	move.b	rsDiskEndSector(a4),d4
	bsr.s	read_and_decode
	bsr	SelDF0MotOff
exit$:	rts



read_and_decode:
	btst	#5,$bfe001	; Await Disk ready.
	bne.s	read_and_decode
	move.w	#$2991,d0
	bsr	timer_wait
	move.w	#2,intreq(a5)	; Clear Disk Intrequest.
	move.l	rsDiskBuf(a4),dskpt(a5) ; Set MFM buffer.
	move.w	#$8010,dmacon(a5)	; Disk DMA on.
	move.w	#$4000,dsklen(a5)
	move.w	#$9900,dsklen(a5)
	move.w	#$9900,dsklen(a5)
dmawait$:
	btst	#1,$1f(a5)		DMA transfer done when high.
	beq.s	dmawait$
	move.w	#$4000,$24(a5)
	move.w	#$0010,$96(a5)		Disk DMA off.

;;; Decode MFM track.
;;; In:	a0 = destination address
;;; 	d3 = start sector
;;; 	d4 = end sector
decode_mfm:
	move.w	#SyncWord,d5	; Put synchornisation word into d5.
	move.l	#$55555555,d7	; Clock pattern in d7.

findsector$:
	movea.l	rsDiskBuf(a4),a1 ; Address of mfm buffer into a1.
syncsearch$:
	cmp.w	(a1)+,d5	; Check for Sync-word.
	bne.s	syncsearch$
	cmp.w	(a1),d5		; Are there two sync words in a row?
	beq.s	syncsearch$
	move.l	(a1),d0		; Movel two MFM encoded longwords into d0 and d1.
	move.l	4(a1),d1
	and.l	d7,d0
	asl.l	#1,d0
	and.l	d7,d1
	or.l	d1,d0
	ror.l	#8,d0
	cmp.b	d3,d0		; Is this the correct sector?
	beq.s	sectorok$
	lea	$43E(a1),a1	; Skip to next sector.
	bra.s	syncsearch$
sectorok$:
	addq.b	#1,d3
	lea	$38(a1),a1	; Skip header bytes.
	moveq	#$7f,d6
decodeloop$:
	move.l	$200(a1),d1
	move.l	(a1)+,d0
	and.l	d7,d0
	asl.l	#1,d0
	and.l	d7,d1
	or.l	d1,d0
	move.l	d0,(a0)+	; Move to destination buffer.
	dbra	d6,decodeloop$
	cmp.b	d4,d3
	bne.s	findsector$
	rts


GoToTrack00:
	btst	#CIAF_DSKTRACK0,$bfe001 ; Bit 4: track 0 when low.
	beq.s	pos00$
	bsr.s	move_outwards
istrack00$:
	btst	#CIAB_DSKTRACK0,$bfe001 ; Test again if track 0 was reached.
	beq.s	pos00$
	bsr	move_outwards
;		Bclr	#0,$bfd100	Move head.
;		Nop
;		Nop
;		Bset	#0,$bfd100	Prepare to move head.
;		Move.b	#$69,$bfd400	Timer A low.
;		Move.b	#$0e,$bfd500	Timer A hi, and starts timer.
;		Bsr.s	Timer		5.2ms
	bra.s	istrack00$
pos00$:
	;; 	clr.b	Position(a4); TODO?
	rts


;;; In: d0.w = timer value to use
;;; Modifies: d0
timer_wait:
	move.b	d0,ciatalo+_ciab
	lsr.w	#8,d0
	move.b	d0,ciatahi+_ciab
	bset	#CIACRAB_START,_ciab+ciacra
	nop
waittimer$:
	btst	#CIACRAB_START,_ciab+ciacra
	bne	waittimer$
	rts

;;; Modifies: d0
move_outwards:
	bset.b	#CIAB_DSKDIREC,ciaprb+_ciab
	nop
	bra.s	move_head

;;; Modifies: d0
move_inwards:
	bclr.b	#CIAB_DSKDIREC,ciaprb+_ciab
	nop
	bra.s	move_head

;;; Modifies: d0
move_head:
	bset	#CIAB_DSKSTEP,ciaprb+_ciab
	nop
	nop
	bclr	#CIAB_DSKSTEP,ciaprb+_ciab
	nop
	nop
	bset	#CIAB_DSKSTEP,ciaprb+_ciab
	move.w	#$31e1,d0
	bra	timer_wait

select_upper_side:
	bclr	#2,$bfd100	; Upper side.
	move.w	#$0047,d0
	bra	timer_wait

select_lower_side:
	bset	#2,$bfd100	; Lower side.
	move.w	#$0047,d0
	bra	timer_wait

	END
