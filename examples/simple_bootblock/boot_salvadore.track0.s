
	include	hardware/custom.i
	include	hardware/dmabits.i

BOOTCODEADDRESS = $100
BOOTSIZE=1024
;;; Here we put the decoded data in the correct order.
DESTINATIONDECODEBUFFER=$c7E000
DESTINATIONBOSS=$C00000	

BOOTSTART:
	dc.b	"DOS",0		; Header of a bootable disk.
	dc.l	0		; Checksum, will be added later.
	dc.l	880		; Root block number (default).

;;; Registers:
	;; A5 = $DFF000

	;; In A6 we have the Exec base.
	jsr	_LVOForbid(a6)	  ; No more task switching.
	lea	$DFF000,a5	; Custom base in A5.
	move.w	#$7fff,intena(a5) ; Disable interrupts.
	move.w	#$7fff,intreq(a5) ; Disable interrupt requests.
	move.w	#$7fff,dmacon(a5) ; Disable DMA.
	;; And switch directly to super user mode.
	lea	super$(pc),a0
	move.l	a0,$20.w	  ; Set privilege escalation vector.
	stop	#$0200		  ; This is a privileged opcode.
super$:				  ; Supervisor mode with A7=SP at end of memory.
	lea	BOOTEND(PC),a2	; A2=end of boot code
	move.l	a2,a0
	moveq	#11-1,d2
.bootloop:
	bsr.s	search_track
	move.l	$4.w,$4.w	; Special form to be used with memory watchpoints: "w 1 4 4 W". Every write (long) to address 4 will trigger a watchpoint.
	and.l	#$00ffff00,d0	; Mask out $00TTSS00, aka track and sector.
	asl.l	#1,d0		; Multiply by two (T=0, probably) and S=[0..11], as it is already at bit 8-15 multiplying by 2 conveniently skips another 512 bytes.
	add.l	#DESTINATIONDECODEBUFFER,d0
	move.l	a0,a2
	move.l	d0,a0
	bsr.s	decode_trackA1A0
	move.l	a2,a0
	cmp.l	#$800000,a0
	dbhi	d2,.bootloop	; if A0>$800000 is false (if true leave loop) then D2-=1, loop if D2 >= 0!

	move.w	#$00f0,color(a5)
	movea.l	#zx0data-BOOTSTART+DESTINATIONDECODEBUFFER,a0
	lea.l	DESTINATIONBOSS,a1
	bsr	zx0_decompress
	move.w	#$00a0,color(a5)

	moveq	#-1,d0
	move.l	d0,-(sp)	; End.
	move.l	#part0,-(sp)
	move.l	#part0_end,-(sp)
	move.l	#$c60000,-(sp)
	jmp	DESTINATIONBOSS

	
;;; Search a track (mfm encoded) in memory.
;;; Input: A0=memory pointer
;;; Output: A0=memory pointer *after* sector, A1=pointer to mfm encoded sector data, D0=$FFTTSSkk (T=track, S=sector, k=skip to end of track)
;;; Modifies: A0,A1,D0,D1
search_track:
	cmp.w	#$AAAA,(a0)+	; Find the MFM encoding of a the gap (zero bytes).
	bne.s	search_track
	cmp.w	#$4489,(a0)	; First sync mark.
	bne.s	search_track
	cmp.w	#$4489,2(a0)	; Second sync mark.
	bne.s	search_track
	lea.l	4(a0),a0	; Skip syncs.
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	and.l	#$55555555,d0
	and.l	#$55555555,d1
	lsl.l	#1,d0
	or.l	d1,d0
	lea.l	48(a0),a1	; Beginning of MFM sector data.
	lea.l	1024(a1),a0	; Skip sector data.
	rts

;;; Decode a track
;;; Input: A0=destination to write decoded data to, A1=source MFM data
;;; Output: -
;;; Modifies: D0-D1,A0-A1
decode_trackA1A0:
.src:		equr	A1
.dest:		equr	A0
.counter:	equr	D2
.oddmfm:	equr	A3
.regs:	reg	.counter/.oddmfm
	movem.l	.regs,-(sp)
	lea.l	512(.src),.oddmfm
	move.w	#$100-1,d2
	move.l	#$55555555,d0
.loop:	move.l	(.src)+,d1
	and.l	d0,d1
	asl.l	#1,d1
	move.l	d1,(.dest)
	move.l	(.oddmfm)+,d1
	and.l	d0,d1
	or.l	d1,(.dest)+
	dbf	d2,.loop
	movem.l	(sp)+,.regs
	rts

	dc.b	"Pararaum/T7D",0
	even

	include	zx0decompress.inc


BOOTEND:
	printt "BOOTEND-BOOTSTART"
	printv	BOOTEND-BOOTSTART
	;; Skip till end.
	;; 	dcb.b	BOOTSIZE-(BOOTEND-BOOTSTART)
	ALIGN	9

zx0data:
	incbin	"boss.zx0"
zx0data_end:
	even
	align	9
	dc.b	"After the bootblock."
	even
	dc.l	zx0data,zx0data_end
	rept	32
	dc.l	*
	endr

	align	9
	printt "Part0"
	printv *,*/512

part0:
	incbin	"part0"
part0_end:
	even
