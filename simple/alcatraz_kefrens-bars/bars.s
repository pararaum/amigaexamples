        INCLUDE "hardware/custom.i"
        INCLUDE "hardware/intbits.i"
        INCLUDE "hardware/dmabits.i"
	include	"own.i"

BPLWIDTH = 320
BPLHEIGHT = 256
BPLNOS = 3

	;;; A6 contains the $DFF000 custom chip base.

_start:	jmp	main(pc)
	dc.b	"Alcatraz/Kefrens Bars",10
	dc.b	"Code: Pararaum / T7D",0
	align	4
	cmp.l	#"main",main
	cmp.l	#"seco",setup_copper
	cmp.l	#"vert",do_vertbars
	cmp.l	#"COPL",copper_list
	cmp.l	#"BPLA",bitplane
	align	4
	main:	nop
	moveq	#OWN_libraries|OWN_view|OWN_trap,d0
	jsr	own_machine
	lea.l	$DFF000,a6
	bsr	setup_system
	nop
	moveq	#33,d7
	lea	bitplane,a5
l3$:	nop
	bsr	wait_frame
	move.w	#$b5b,color(a6)
	bsr	do_vertbars
;#	mulu	#33,d7
;#	add.w	#3,d7
;#	move.w	d7,d0
;#	move.w	d7,d1
;#	and.w	#$7f,d0
;#	lsr.w	#8,d1
;#	eor.b	d1,(a5,d0)
	move.w	#$5b5,color(a6)
	btst	#6,$bfe001	; Left mouse clicked?
	bne.s	l3$
	jsr	disown_machine
	moveq	#0,d0
	rts
	jmp	_start(pc)

do_vertbars:
	movem.l	d2-d7/a2-a6,-(sp)
	bsr	clear_topline
	;;
	lea.l	bitplane,a5
	move.w	phase$(pc),d0
	bsr	paint$
l1$:	move.l	vposr(a6),d0
	and.l	#$0003ff00,d0
	cmp.l	#$00005500,d0
	bne.s	l1$
	move.w	phase2$(pc),d0
	bsr	paint$
	addq.w	#1,phase$
	and.w	#$1ff,phase$
	addq.w	#5,phase2$
	and.w	#$1ff,phase2$
	movem.l	(sp)+,d2-d7/a2-a6
	rts
paint$:
	move.w	d0,d2
	lsr.w	#4,d2		; Word position
	lsl.w	#1,d2		; To bytes
	move.w	d0,d3
	and.w	#$f,d3		; Shift
	move.l	mask$,d0
	ror.l	d3,d0		; Rotate the mask
	and.l	d0,0(a5,d2)
	and.l	d0,BPLWIDTH/8(a5,d2)
	and.l	d0,BPLWIDTH/8*2(a5,d2)
	move.l	pat0$,d0
	lsr.l	d3,d0		; Move shift pixels
	or.l	d0,0(a5,d2)
	move.l	pat1$,d0
	lsr.l	d3,d0		; Move shift pixels
	or.l	d0,BPLWIDTH/8(a5,d2)
	move.l	pat2$,d0
	lsr.l	d3,d0		; Move shift pixels
	or.l	d0,BPLWIDTH/8*2(a5,d2)
	rts
	;;       10987654321098765432109876543210
mask$:	dc.l	%00000000011111111111111111111111
pat0$:	dc.l	%10100010100000000000000000000000
pat1$:	dc.l	%01100011000000000000000000000000
pat2$:	dc.l	%00011100000000000000000000000000
phase$:	dc.w	0
phase2$:	dc.w	0

clear_topline:
	moveq	#(BPLWIDTH*BPLNOS/8/4)-1,d0	; Clear the line
	lea.l	bitplane,a0
l1$:	clr.l	(a0)+
	dbf	d0,l1$
	rts

wait_frame:
l1$:	btst.b	#0,vposr+1(a6)
	beq.s	l1$
l2$:	btst.b	#0,vposr+1(a6)
	bne.s	l2$
	rts


setup_system:
	move.w	#$7fff,dmacon(a6)
	bsr	setup_copper
	move.w	#DMAF_SETCLR|DMAF_BLITTER|DMAF_COPPER|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER,dmacon(a6)
	rts

;;; Setup the copper and write the corresponding wait and color instructions.
setup_copper:
	movem.l	d2-d7/a2-a6,-(sp)
	;; D3: line numner
	;; Setup copper pointer.
	move.l	#copper_list,cop1lc(a6)
	clr.w	copjmp1(a6)	 ; Strobe copper
	move.l	#bitplane,d0	 ; Address of bitplane 0
	moveq	#BPLNOS-1,d1	 ; Number of bitplanes
	lea.l	copper_bplptr,a0 ; Pointer to bitplane pointers in copper list
l1$:	move.w	d0,6(a0)	 ; Lower 16 bits.
	swap	d0
	move.w	d0,2(a0)	 ; Upper 16 bits.
	swap	d0		 ; Restore value
	add.l	#BPLWIDTH/8,d0	 ; Next line for next bitplane
	addq.l	#8,a0		 ; Next bitplane pointer in copper list
	dbf	d1,l1$
	movem.l	(sp)+,d2-d7/a2-a6
	rts

;;; ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
	SECTION	CHIP,data_c
copper_list:
	;; Copper List
	;; see: http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_2.html
	;; AGA compatible setup?
	dc.w 	fmode,$0000
	;; Setting up display.
	;; see also: http://cyberpingui.free.fr/tuto_graphics.htm
	dc.w	$008e,$2c81,$0090,$2cc1		; DIWSTRT/DIWSTOP
	dc.w	$0092,$0038,$0094,$00d0		; DDFSTRT/DDFSTOP
	;; http://amiga-dev.wikidot.com/hardware:bplcon0
	dc.w	bplcon0,$3200			; 3 Bitplanes, output enabled
copper_scrollcon:
	;; http://www.winnicki.net/amiga/memmap/BPLCON1.html, scrolling
	;; Lower nibbles are for scrolling, PF 1 and PF2.
	dc.w	bplcon1,$0000
	;; http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_4.html
	;; http://www.winnicki.net/amiga/memmap/BPLCON2.html
	;; http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node0159.html
	;; $104          FEDCBA9876543210
	dc.w	bplcon2,%0000000000000000
	;; http://www.winnicki.net/amiga/memmap/BPLCON3.html
	dc.w	bplcon3,$0000
	;; Bitplane modulos
copper_bitplane_modulos:
	dc.w	bpl1mod,-(320/8) ; Repeat the line (move back 320 pixels)
	dc.w	bpl2mod,-(320/8) ; Repeat the line (move back 320 pixels)
copper_bplptr:
	dc.w	$00e0,$0000,$00e2,$0000		; Bitplaneptrs
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000
	dc.w	$00f0,$0000,$00f2,$0000
	dc.w	color+2*0,$0000	;Colour 0
	dc.w	color+2*1,$0321	;Colour 1
	dc.w	color+2*2,$0542
	dc.w	color+2*3,$0753
	dc.w	color+2*4,$0974
	dc.w	color+2*5,$0b84
	dc.w	color+2*6,$0da5
	dc.w	color+2*7,$0fc5
	dc.w	$ffdf,$fffe	; End of NTSC.
	dc.w	$0007,$fffe
	dc.w	color,$0fff	; Turn white
	;; End of Copper List
	dc.w	$ffff,$fffe

;;; ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
	SECTION	BSSC,bss_c
bitplane:
	ds.b	BPLWIDTH*BPLHEIGHT/8*BPLNOS

;;; ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	SECTION BSS,bss
debugstorage:
	ds.l	1<<10
