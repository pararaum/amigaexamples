;;; Basic Operating System Simulacrum
	include	hardware/custom.i
	include	hardware/dmabits.i

SCREENCOPLIST=$400
SCREENBITPLANE=$480

	data
	dc.b	"DATA begins here."
	EVEN
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
	dc.w	color+0,$0172		  ; Dark green background.
	dc.w	color+2,$06fb		  ; Light green foreground.
	;; Bitplane pointer points to our screen.
	dc.w	bplpt,SCREENBITPLANE>>16,bplpt+2,SCREENBITPLANE&$FFFF
	dc.w	$FFFF,$FFFE		  ; Wait for end.
coplist_end:


	code
	lea	$DFF000,a5	; Custom base in A5.
	move.w	#$7fff,intena(a5) ; Disable interrupts.
	move.w	#$7fff,intreq(a5) ; Disable interrupt requests.
	move.w	#$7fff,dmacon(a5) ; Disable DMA.
	lea	trap0code(pc),a0
	move.l	a0,$80.w	; Set vector for TRAP#0.
	lea.l	coplist,a0
	lea.l	SCREENCOPLIST,a1
	moveq	#coplist_end-coplist,d0
	trap	#0
	jmp	*

trap0code:
l1$	move.w	(a0)+,(a1)+
	dbf	d0,l1$
	rte
