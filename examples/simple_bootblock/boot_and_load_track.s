
	include	hardware/custom.i
	include	hardware/dmabits.i
	include	hardware/intbits.i
	include	hardware/cia.i

BOOTCODEADDRESS = $100
CIAF_DSKSELx	EQU	(CIAF_DSKSEL3|CIAF_DSKSEL2|CIAF_DSKSEL1|CIAF_DSKSEL0)

	;; The following are added by  xdftool.
	;dc.b	"DOS",0		; Header of a bootable disk.
	;dc.l	0		; Checksum, will be added by xdftool.
	;dc.l	880		; Root block number (default).

;;; Registers:
	;; A5 = $DFF000
	;; A4 = CIA-B $BFD100
	;; A3 = CIA-A $BFE001

	;; In A6 we have the Exec base.
	jsr	_LVOForbid(a6)	  ; No more task switching.
	lea.l	$DFF000,a5	; Custom base in A5.
	lea.l	$BFD100,a4
	lea.l	$BFE001,a3
	move.w	#$7fff,intena(a5) ; Disable interrupts.
	move.w	#$7fff,intreq(a5) ; Disable interrupt requests.
	move.w	#$7fff,dmacon(a5) ; Disable DMA.
	;; Now we will copy the code and everything to the area at $100 which are "user vectors" and unused(?). This will assure that the copperlist is in chip mem.
	move.w	#$100/4-1,d0	; Number of long words to copy.
	lea.l	bootcode(pc),a0
	lea.l	BOOTCODEADDRESS.w,a1
.cloop:	move.l	(a0)+,(a1)+
	dbf	d0,.cloop
	jmp	BOOTCODEADDRESS.w ; Now continue below:

bootcode:
	;; Turn display on.
	lea.l	coplist(pc),a0
	move.l	a0,cop1lc(a5)	; Point copper to the Copperlist.
	;; Enable display and copper.
	move.w	#DMAF_SETCLR|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER,dmacon(a5)
	;; Now activate vblank interrupt.
	lea.l	vblank_handler(pc),a0
	move.l	a0,$6c.w	; Level 3 interrupt.
	; Enable vblank interrupt.
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,intena(a5)
	moveq	#120,d0		; Wait
	bsr	waitframes
	;; Check if on track zero otherwise: kaputt!
	;; http://cyberpingui.free.fr/tuto_trackloader.htm
	;; Bit 4 = TRACK0
	btst	#4,(a3)
	bne.s	.OK
	illegal
.OK:	
	;; Turn Motor on.
	or.b	#CIAF_DSKSELx,(a4)	; deselect all drives
	bclr.b	#CIAB_DSKMOTOR,(a4)
	bclr.b	#CIAB_DSKSEL0,(a4)	; select drive 0
	move	#500/20,d0		; Wait 500 ms.
	bsr	waitframes
	bra	*		; Stay a while! Stay forever!

;;; Input: d0=frames to wait.
waitframes:
	lea.l	framecounter(pc),a0
	move.w	d0,(a0)
.l1:	tst.w	(a0)
	bpl	.l1
	rts

vblank_handler:
	movem.l	d0-a6,-(sp)
	lea	$Dff000,a5
	lea.l	framecounter(pc),a0
	subq.w	#1,(a0)
	move	framecounter(pc),color(a5)
	move.w	#INTF_VERTB,intreq(a5) ; Acknowledge interrupt.
	movem.l	(sp)+,d0-a6
	rte


	dc.l	"####"
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
framecounter:	dc.w	0
