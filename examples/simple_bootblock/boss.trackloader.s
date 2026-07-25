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
	XDEF	boss_trackload_data
	XDEF	boss_manifest_load

SyncWord	Equ	$4489	; Default sync value.

; Structure for our disk.
	rsreset
rsDiskPosition		rs.w	1 ; Where is the head? Which track?
rsDiskStartTrack	rs.w	1
rsDiskStartSector	rs.w	1
rsDiskEndTrack		rs.w	1 ; End track to reach.
rsDiskEndSector		rs.w	1
rsDiskBuf		rs.l	1 ; Pointer to the Memory for the track buffer, must be in CHIP.
rsDiskStructSize	rs

	BSS
current_diskstruct:	ds.b	rsDiskStructSize
	even

	CODE
boss_manifest_load:
SAFETYBUFFERSIZE$:	equ	$20 ; Just in case the decompression algorithm overruns the buffer...
SECTORSLACK$:	equ	$200 ; We *always* read whole sectors so make enough room for them!
manifestR$:	equr	a6
allocatedR$:	equr	a2	; Here we store the memory of the allocated memory.
	BossMem	BossFindManifestEntry
	move.l	a0,d0
	tst.l	d0
	bne.s	found$
	move.l	d0,a0
	rts
	;;  Part was found, now get the memory.
found$:	move.l	a0,manifestR$		; Manifest pointer in MANIFESTR$.
	move.l	rsManifestMemflags(manifestR$),d1 ; Where to put the data?
	and.l	#$40000000,d1			  ; Is the no alloc bit set?
	beq	allocate$
	move.l	rsManifestMemflags(manifestR$),d1 ; Where to put the data?
	and.l	#$00ffffff,d1			  ; Lowest 24 bits.
	move.l	d1,allocatedR$
	bra	skip_allocation$
allocate$:			; An allocation has to be performed.
	move.l	rsManifestMemflags(manifestR$),d1 ; Where to put the data?
	move.l	rsManifestUnpackedSize(manifestR$),a0
	move.w	#SECTORSLACK$,d0
	lea.l	SAFETYBUFFERSIZE$(a0,d0.w),a0
	move.l	a0,d0
	BossMem	BossMemTrapAllocDeluxe
	move.l	a0,allocatedR$		; Put address into allocatedR$.
	move.l	a0,d0
	tst.l	d0		; Fail?
	beq	end$
skip_allocation$:
	add.l	rsManifestUnpackedSize(manifestR$),a0
	lea.l	SAFETYBUFFERSIZE$(a0),a0
	sub.l	rsManifestPackedSize(manifestR$),a0
	;; Warning! The packed size may be odd and this, of course,
	;; does not work on a 68K! We added a buffer and now we just
	;; clear the lowest bit to make the address even!
	move.l	a0,d0
	bclr	#0,d0		; Now we are even!
	move.l	d0,a3		; Load address into A3 for later use.
	move.l	d0,a0		; Destination address for track loader.
	move.w	rsManifestStartSector(manifestR$),d0
	move.w	rsManifestNumSectors(manifestR$),d1
	BossIO	BossIOTrapTrackload
	move.l	allocatedR$,a1		; Destination
	move.l	a3,a0
	BossMem	BossMemDecompressZX0
end$:	move.l	allocatedR$,a0
	move.l	allocatedR$,d0
	rts

	code
boss_trackloader_init:
	moveq	#0,d0
	lea	$DFF000,a5
	lea	current_diskstruct,a0
	move.w	d0,rsDiskPosition(a0)
	move.w	d0,rsDiskStartTrack(a0)
	move.l	#BOSSSCREENBITPLANE,rsDiskBuf(a0) ; Hard coded for now.
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

	;; We make sure that the head is at track 0 as the structure
	;; above is initialised to this track.
	bsr	SelDF0MotOn
	bsr	go_to_track0
	bsr	SelDF0MotOff
	rts

;;; Modifies: -
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

;;; In:	D0.w = startblock
;	D1.w = number of blocks
;	A4.l = disk information structure
;;; Out: modifies disk information structure, sets start/end track and start/end sector (0..10)
;;; Modifies: d0-d2
trackload_calc_start_end_tracks:
curdisstrptr$ equr A4
	and.l	#$0000ffff,d1	; If there is something in the upper bits remove it!
	and.l	#$0000ffff,d0	; If there is something in the upper bits remove it!
	add.w	d0,d1	      ; Add start sector to number of blocks. This gives us the last block in d1.
	divu	#11,d1
	divu.w	#11,d0	    ; Divide d0 by 11 (no of sectors per track) to get cylinder/track.
	;; D0 = rrrrqqqq, quotient in the lower bits, remainder in the most significant 16 bits.
	move.w	d0,rsDiskStartTrack(curdisstrptr$)
	move.l	d0,d2	    ; Division result/remainder into d2.
	swap 	d2	    ; Remainder aka start sector.
	move.w	d2,rsDiskStartSector(curdisstrptr$)
	move.w	d1,rsDiskEndTrack(curdisstrptr$)
	swap	d1
	move.w	d1,rsDiskEndSector(curdisstrptr$)
	rts

;;; In: d0.w = destination track
;;;	A4.l = curdisstrptr$
;;; Modifies: d0-d3
move_head_to_track:
curdisstrptr$	equr	a4
	move.w	d0,d3		; Keep destination track safe in d3.
	and.w	#$0001,d0	; Only disk side needed.
	move.w	rsDiskPosition(curdisstrptr$),d1
	and.w	#$FFFE,d1	; Remove disk side.
	or.w	d1,d0
	move.w	d0,rsDiskPosition(curdisstrptr$)
head_position_loop$:
	move.w	d3,d1			; Destination track in d1.
	move.w	rsDiskPosition(a4),d2	; Current position in d2.
	lsr.w	#1,d1			; Calculate the actual cylinder!
	lsr.w	#1,d2
	cmp.w	d1,d2
	beq.s	rightcyl$	; The cylinder is right.
	blt.s	moveheadin$
	;; Move the head out.
	bsr	move_outwards
	subq.w	#2,rsDiskPosition(curdisstrptr$)
	bra.s	head_position_loop$
moveheadin$:			; Move head in increasing the cylinder.
	bsr	move_inwards
	addq.w	#2,rsDiskPosition(curdisstrptr$)
	bra	head_position_loop$
rightcyl$:
	rts
	
	
;;; Trackload data (sectors) into memory
;;; In: D0.w = startblock
;;;	D1.w = number of blocks
;;;	A0.l = destination address
;;; Modifies: d0-d2,d7,a0
boss_trackload_data:
curdisstrptr$	equr	a4
;;; This contains the current track in the loader loop.
curtralooR$	equr	d7	
	tst.w	d1		; Sanity check number of blocks to read.
	beq	exit$
	bmi	exit$
	tst.w	d0		; Negative start block?
	bmi	exit$
	move.w	d1,d2
	add.w	d0,d2	       ; d2 contains sum of startblock and number of blocks to read.
	cmp.w	#1804,d2	;Maximum is 82 tracks: (* 11 2 82) 1804
	bgt	exit$

	bsr	SelDF0MotOn ; Start the motor.
	lea.l	current_diskstruct,curdisstrptr$ ; Get pointer
	bsr	trackload_calc_start_end_tracks
	move.w	rsDiskStartTrack(a4),curtralooR$ ; Start track in d7.
head_position_loop$:
	move.w	curtralooR$,d0
	bsr	move_head_to_track
	move.w	rsDiskPosition(a4),d0 ; Getting the side (upper/lower) bit.
	;btst.l	#0,d0
	;beq.s	lower_side$
	lsr.w	#1,d0
	bcc.s	lower_side$
	bsr	select_upper_side
	bra.s	disk_position_reached$
lower_side$:
	bsr	select_lower_side
disk_position_reached$:
	moveq	#0,d3		; Read from the beginning of the track.
	moveq	#11-1,d4	; Read until the end of the track.
	;; Check if on first or last track to adjust first and last sector.
	move.w	rsDiskPosition(curdisstrptr$),d0
	cmp.w	rsDiskStartTrack(curdisstrptr$),d0
	bne.s	no_start_track$
	move.w	rsDiskStartSector(curdisstrptr$),d3
no_start_track$:
	;; 	move.w	rsDiskPosition(curdisstrptr$)
	cmp.w	rsDiskEndTrack(curdisstrptr$),d0
	bne.s	no_end_track$
	move.w	rsDiskEndSector(curdisstrptr$),d4
no_end_track$:
	bsr.s	read_and_decode
	move.w	rsDiskPosition(curdisstrptr$),d0
	cmp.w	rsDiskEndTrack(curdisstrptr$),d0
	beq.s	finished$
	addq.w	#1,curtralooR$
	bra	head_position_loop$
finished$:
	bsr	SelDF0MotOff
exit$:	rts


;;; Read the current track and decode the sectors.
;;; In: d3.w = start sector
;;;	d4.w = end sector
;;;	a4.l = current dist structure
read_and_decode:
	lea	$dff000,a5
	btst	#5,$bfe001	; Await Disk ready.
	bne.s	read_and_decode
	move.w	#$2991,d0
	bsr	timer_wait
	move.w	#2,intreq(a5)	; Clear Disk Intrequest.
	move.l	rsDiskBuf(a4),dskpt(a5) ; Set MFM buffer.
	move.w	#$8010,dmacon(a5)	; Disk DMA on.
	move.w	#$9900,dsklen(a5)
	move.w	#$9900,dsklen(a5)
dmawait$:
	btst	#1,$1f(a5)		DMA transfer done when high.
	beq.s	dmawait$
	move.w	#$4000,$24(a5)
	move.w	#$0010,$96(a5)		Disk DMA off.
	clr.w	dsklen(a5)

;;; Decode MFM track.
;;; In:	a0 = destination address
;;; 	d3 = start sector
;;; 	d4 = end sector
;;; 	a4 = current disk structure
;;; Modifies: d0-d4,d0-a1
;;; TODO: Return or check if the track was right.
decode_mfm:
syncwordR$	equr	d5
clockpatR$	equr	d7
REGS$:	REG	syncwordR$/clockpatR$
	movem.l	REGS$,-(sp)
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
	lea	$38(a1),a1	; Skip header bytes.
	moveq	#$7f,d6		; $80-1 long words.
decodeloop$:
	move.l	$200(a1),d1
	move.l	(a1)+,d0
	and.l	d7,d0
	asl.l	#1,d0
	and.l	d7,d1
	or.l	d1,d0
	move.l	d0,(a0)+	; Move to destination buffer.
	dbra	d6,decodeloop$
	cmp.b	d4,d3		; Is this the end?
	beq.s	exit$
	addq.w	#1,d3
	bra.s	findsector$
exit$:	movem.l	(sp)+,REGS$
	rts


go_to_track0:
	btst	#CIAF_DSKTRACK0,$bfe001 ; Bit 4: track 0 when low.
	beq.s	pos00$
	bsr.s	move_outwards
	bra.s	go_to_track0
pos00$:	rts


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
	;; 	bra.s	move_head
	;; Fall through to move_head and add a NOP for small delay in order to give the hardware some time.
	nop

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
