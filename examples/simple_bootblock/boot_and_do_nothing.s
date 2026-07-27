
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
	stop	#$0200		; Now continue below:

bootcode:
	lea.l	coplist(pc),a0
	move.l	a0,cop1lc(a5)	; Point copper to the Copperlist.
	;; Enable display and copper.
	move.w	#DMAF_SETCLR|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER,dmacon(a5)
	bra	*		; Stay a while! Stay forever!

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
BOOTEND:
	printv	BOOTEND-BOOTSTART
