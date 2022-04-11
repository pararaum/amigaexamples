
	include	hardware/custom.i
	include	hardware/dmabits.i
	
	;dc.b	"DOS",0		; Header of a bootable disk.
	;dc.l	0		; Checksum, will be added by xdftool.
	;dc.l	880		; Root block number (default).

;;; Registers:
	;; A5 = $DFF000

	;; In A6 we have the Exec base.
	; jsr	_LVOForbid(a6)	  ; No more task switching.
	lea	$DFF000,a5	; Custom base in A5.
	move.w	#$7fff,intena(a5) ; Disable interrupts
	move.w	#$7fff,intreq(a5) ; Disable interrupt requests
	move.w	#$7fff,dmacon(a5) ; Disable DMA.

	move.w	#$012e,color(a5) ; Light blue background.
	move.w	#$0efe,color+2(a5) ; No quite white foreground.

	lea.l	coplist(pc),a0
	lea.l	$100.w,a1
	moveq	#$100/4,d1
.l1:	move.l	(a0)+,(a1)+
	dbf	d1,.l1
	lea.l	$100.w,a0
	move.l	a0,cop1lc(a5)	; Point copper to the Copperlist.
	;; Enable display and copper.
	move.w	#DMAF_SETCLR|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER,dmacon(a5)
	bra	*		; Stay a while! Stay forever!

	dc.l	"END"
coplist:
        dc.w    $0106,$0000,$01fc,$0000         ; AGA compatible
        ;; Setting up display.
        ;; see also: http://cyberpingui.free.fr/tuto_graphics.htm
        dc.w	diwstrt,$2c81,diwstop,$2cc1         ; DIWSTRT/DIWSTOP
        dc.w	ddfstrt, $0038,ddfstop,$00d0         ; DDFSTRT/DDFSTOP
	dc.w	bplcon0,$8000|(1<<12)|$200	     ; HiRes and one bitplane.
        dc.w    $0102,$0000,$0104,$0000
        dc.w    $0106,$0000
	dc.w	bpl1mod,$0000
        dc.w    bpl2mod,$0000
	dc.w	bplpt,$0000,bplpt+2,$0000 ; Bitplane pointer points to $0.
	dc.l	-2		; Wait forever: $FFFF,$FFFE
	dc.b	"Pararaum/T7D",0
	even
