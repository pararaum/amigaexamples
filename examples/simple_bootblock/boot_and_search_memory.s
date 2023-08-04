
	include	hardware/custom.i
	include	hardware/dmabits.i

BOOTCODEADDRESS = $100

	;; The following are added by  xdftool.
	;dc.b	"DOS",0		; Header of a bootable disk.
	;dc.l	0		; Checksum, will be added by xdftool.
	;dc.l	880		; Root block number (default).

;;; Registers:
	;; A5 = $DFF000


BOOTSTART:
	;; In A6 we have the Exec base.
	jsr	_LVOForbid(a6)	  ; No more task switching.
	lea	$DFF000,a5	; Custom base in A5.
	move.w	#$7fff,intena(a5) ; Disable interrupts.
	move.w	#$7fff,intreq(a5) ; Disable interrupt requests.
	move.w	#$7fff,dmacon(a5) ; Disable DMA.
	;; Now we will copy the code and everything to the area at $100 which are "user vectors" and unused(?). This will assure that the copperlist is in chip mem.
	move.w	#$100/4-1,d0	; Number of long words to copy.
	lea.l	bootcode(pc),a0	; Get address of boot code.
	lea.l	BOOTCODEADDRESS.w,a1 ; Destination for the bootcode.
	move.l	a1,$20.w	; Prepare the priviledge violation vector.
.cloop:	move.l	(a0)+,(a1)+
	dbf	d0,.cloop
	lea	BOOTEND(PC),a2	; A2=end of boot code
	stop	#$0200		; Now continue below:

	;; Here we start in supervisor mode.
bootcode:
	lea.l	coplist(pc),a0
	move.l	a0,cop1lc(a5)	; Point copper to the Copperlist.
	;; Enable display and copper.
	move.w	#DMAF_SETCLR|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER,dmacon(a5)
	;; Search for tracks in memory
	move.l	a2,a0
	moveq	#22-1,d2
.bootloop:
	bsr.s	search_track
	move.l	$4.w,$4.w
	and.l	#$00ffff00,d0
	asl.l	#1,d0
	add.l	#$c00000,d0
	move.l	a0,a2
	move.l	d0,a0
	bsr.s	decode_trackA1A0
	move.l	a2,a0
	dbf	d2,.bootloop
	bra	*		; Stay a while! Stay forever!

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

coplist:
	dc.w	$0106,$0000,$01fc,$0000		; AGA compatible
	;; Setting up display.
	;; see also: http://cyberpingui.free.fr/tuto_graphics.htm
	dc.w	diwstrt,$2c81,diwstop,$2cc1	; DIWSTRT/DIWSTOP
	dc.w	ddfstrt, $0038,ddfstop,$00d0	; DDFSTRT/DDFSTOP
	dc.w	bplcon0,$8000|(1<<12)|$200	; HiRes and one bitplane.
	dc.w	bplcon1,$0000,bplcon2,$0000
	dc.w	bplcon3,$0000
	dc.w	bpl1mod,$0000,bpl2mod,$0000
	dc.w	color+0,$012e		  ; Light blue background.
	dc.w	color+2,$0efe		  ; Not quite white foreground.
	dc.w	bplpt,$0000,bplpt+2,$0000 ; Bitplane pointer points to $0.
	dc.l	-2		; Wait forever: $FFFF,$FFFE
	dc.b	"Pararaum/T7D",0
	even
BOOTEND:
	printv	BOOTEND-BOOTSTART

