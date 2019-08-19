        INCLUDE "hardware/custom.i"
        INCLUDE "hardware/intbits.i"
        INCLUDE "hardware/dmabits.i"
	INCLUDE	"circallator.i"

	XDEF	_vertical_bars_part
	XREF	_framecounter
	XREF	wait_one_songposition ; From moire part.

BPLWIDTH = 320
BPLHEIGHT = 256
BPLNOS = 3
SINUSTABLELENGTH EQU sinustable_end-sinustable
VERTBAREND = 230

	;;; A6 contains the $DFF000 custom chip base.

_vertical_bars_part:	jmp	main(pc)
	dc.b	"Alcatraz/Kefrens Bars",10
	dc.b	"Code: Pararaum / T7D",0
	align	4
bitplaneptr:	ds.l	1	; Pointer to the bitplane chipmemory.
copperlistptr:	ds.l	1	; Pointer to the copperlist chipmemory.
	cmp.l	#"main",main
	cmp.l	#"seco",setup_copper
	cmp.l	#"vert",do_vertbars
	cmp.l	#"COPL",copper_list
	cmp.l	#"SINU",sinustable
	cmp.l	#"ctop",clear_topline
	align	4
main:	nop
	lea.l	$DFF000,a6
	;; Allocate memory for the bars bitplane.
	move.l	#BPLWIDTH*BPLHEIGHT/8,d0
	jsr	circalloc
	lea.l	BPLWIDTH/8*BPLNOS(a0),a0 ; Jump ahead to "next" bitplane.
	move.l	a0,bitplaneptr
	;; Allocate memory for the copper list.
	move.l	#copper_list_end-copper_list,d0
	jsr	circalloc
	move.l	a0,copperlistptr
	;; And copy the list.
	lea.l	copper_list,a1
	move.l	#copper_list_end-copper_list-1,d0
lc$:	move.b	(a1)+,(a0)+
	dbf	d0,lc$
	;; Setup the system (and copper).
	bsr	setup_system
	;; Bars!
	move.l	#irq_routine,$308.w
	jsr	wait_one_songposition
	clr.l	$308.w
	rts

irq_routine:
	lea.l	$DFF000,a6
	move.w	#$38<<8,d0
l4$:	cmp.w	vhposr(a6),d0
	bcc.s	l4$
	bsr	do_vertbars
	btst.b	#0,_framecounter+3 ; Even or odd plane?
	beq.s	b1$
	sub.l	#BPLWIDTH/8*BPLNOS,bitplaneptr ; Previous
	bra.s	b2$
b1$:	add.l	#BPLWIDTH/8*BPLNOS,bitplaneptr ; Next
b2$:	bsr	clear_topline
	bsr	setup_copper
	rts

do_vertbars:
reg$:	reg	d6-d7/a3-a6
	movem.l	reg$,-(sp)
	;; A5: pointer to bitplane
	;; A4: pointer to sinustable
	;; A3: vhposr custom chip address
	;; D7: current angle1
	;; D6: current angle2
	;;
	move.l	bitplaneptr,a5
	lea.l	sinustable,a4
	lea.l	vhposr(a6),a3
	move.w	phase$(pc),d7
	move.w	phase2$(pc),d6
l1$:	move.w	d7,d0
	move.w	d6,d1
	bsr	get_value$
	bsr	paint$
	add.w	#5,d7		; Advance to next position.
	add.w	#31,d6
	move.w	(a3),d0
	add.w	#$0300,d0
	and.w	#$ff00,d0
l2$:	cmp.w	(a3),d0
	bcc.s	l2$
	cmp.w	#VERTBAREND<<8,(a3)
	bcs.s	l1$
	add.w	#5,phase$
	addq.w	#7,phase2$
	movem.l	(sp)+,reg$
	rts
paint$:
	;; A0=bitplaneptr from A5, plus word position.
	move.w	d0,d2
	lsr.w	#4,d2		; Word position
	lsl.w	#1,d2		; To bytes
	move.l	a5,a0		; Move bitplanepointer to A0.
	add.w	d2,a0		; Precalculate the correct position.
	move.w	d0,d3
	and.w	#$f,d3		; Shift
	move.l	mask$,d0
	ror.l	d3,d0		; Rotate the mask
	and.l	d0,0(a0)
	and.l	d0,BPLWIDTH/8(a0)
	and.l	d0,BPLWIDTH/8*2(a0)
	move.l	pat0$,d0
	lsr.l	d3,d0		; Move shift pixels
	or.l	d0,0(a0)
	move.l	pat1$,d0
	lsr.l	d3,d0		; Move shift pixels
	or.l	d0,BPLWIDTH/8(a0)
	move.l	pat2$,d0
	lsr.l	d3,d0		; Move shift pixels
	or.l	d0,BPLWIDTH/8*2(a0)
	rts
;;; D0: angle1, D1: angle2
get_value$:
	and.w	#SINUSTABLELENGTH-2,d0 ; Make even pointer in table
	move.w	(a4,d0),d0	; sin(d0)
	asr.w	#1,d0		; sin(d0)/2
	and.w	#SINUSTABLELENGTH-2,d1
	move.w	(a4,d1),d1	; sin(d1)
	asr.w	#3,d1		; sin(d1)/8
	add.w	d1,d0
	add.w	#153,d0
	;; Now: 150+sin(d0)/2+sin(d1)/8
	rts
	;;       10987654321098765432109876543210
mask$:	dc.l	%00000000011111111111111111111111
pat0$:	dc.l	%01101011000000000000000000000000
pat1$:	dc.l	%11011101100000000000000000000000
pat2$:	dc.l	%00111110000000000000000000000000
phase$:	dc.w	0
phase2$:	dc.w	0

clear_topline:
	moveq	#(BPLWIDTH*BPLNOS/8/4)-1,d0	; Clear the line
	move.l	bitplaneptr,a0
l1$:	clr.l	(a0)+
	dbf	d0,l1$
	rts


setup_system:
	move.w	#$7fff,dmacon(a6)
	bsr	setup_copper
	move.l	copperlistptr,cop1lc(a6)
	clr.w	copjmp1(a6)	 ; Strobe copper
	move.w	#DMAF_SETCLR|DMAF_BLITTER|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER,dmacon(a6)
	rts

;;; Setup the copper and write bitplane pointer.
setup_copper:
	;; Setup copper pointer.
	move.l	bitplaneptr,d0	 ; Address of bitplane 0
	moveq	#BPLNOS-1,d1	 ; Number of bitplanes
	move.l	copperlistptr,a0 ; Get pointer to copper list.
	lea.l	copper_bplptr-copper_list(a0),a0 ; Pointer to bitplane pointers in copper list
l1$:	move.w	d0,6(a0)	 ; Lower 16 bits.
	swap	d0
	move.w	d0,2(a0)	 ; Upper 16 bits.
	swap	d0		 ; Restore value
	add.l	#BPLWIDTH/8,d0	 ; Next line for next bitplane
	addq.l	#8,a0		 ; Next bitplane pointer in copper list
	dbf	d1,l1$
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
	dc.w	copjmp2,0
	dc.w	$ffdf,$fffe	; End of NTSC.
	
	;; End of Copper List
	dc.w	$ffff,$fffe
copper_list_end:

;;; ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	SECTION DATA,data
;;; Generated via python: ", ".join("%d" % int(math.sin(i/512.0*2*math.pi)*240) for i in range(512))
sinustable:
	dc.w	0, 2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 43, 46, 49, 52, 55, 58, 61, 64, 66, 69, 72, 75, 78, 80, 83, 86, 89, 91, 94, 97, 99, 102, 105, 107, 110, 113, 115, 118, 120, 123, 125, 128, 130, 133, 135, 138, 140, 142, 145, 147, 149, 152, 154, 156, 158, 161, 163, 165, 167, 169, 171, 173, 175, 177, 179, 181, 183, 185, 187, 189, 191, 192, 194, 196, 197, 199, 201, 202, 204, 205, 207, 208, 210, 211, 213, 214, 215, 216, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 232, 233, 234, 234, 235, 235, 236, 236, 237, 237, 238, 238, 238, 239, 239, 239, 239, 239, 239, 239, 240, 239, 239, 239, 239, 239, 239, 239, 238, 238, 238, 237, 237, 236, 236, 235, 235, 234, 234, 233, 232, 232, 231, 230, 229, 228, 227, 226, 225, 224, 223, 222, 221, 220, 219, 218, 216, 215, 214, 213, 211, 210, 208, 207, 205, 204, 202, 201, 199, 197, 196, 194, 192, 191, 189, 187, 185, 183, 181, 179, 177, 175, 173, 171, 169, 167, 165, 163, 161, 158, 156, 154, 152, 149, 147, 145, 142, 140, 138, 135, 133, 130, 128, 125, 123, 120, 118, 115, 113, 110, 107, 105, 102, 99, 97, 94, 91, 89, 86, 83, 80, 78, 75, 72, 69, 66, 64, 61, 58, 55, 52, 49, 46, 43, 41, 38, 35, 32, 29, 26, 23, 20, 17, 14, 11, 8, 5, 2, 0, -2, -5, -8, -11, -14, -17, -20, -23, -26, -29, -32, -35, -38, -41, -43, -46, -49, -52, -55, -58, -61, -64, -66, -69, -72, -75, -78, -80, -83, -86, -89, -91, -94, -97, -99, -102, -105, -107, -110, -113, -115, -118, -120, -123, -125, -128, -130, -133, -135, -138, -140, -142, -145, -147, -149, -152, -154, -156, -158, -161, -163, -165, -167, -169, -171, -173, -175, -177, -179, -181, -183, -185, -187, -189, -191, -192, -194, -196, -197, -199, -201, -202, -204, -205, -207, -208, -210, -211, -213, -214, -215, -216, -218, -219, -220, -221, -222, -223, -224, -225, -226, -227, -228, -229, -230, -231, -232, -232, -233, -234, -234, -235, -235, -236, -236, -237, -237, -238, -238, -238, -239, -239, -239, -239, -239, -239, -239, -240, -239, -239, -239, -239, -239, -239, -239, -238, -238, -238, -237, -237, -236, -236, -235, -235, -234, -234, -233, -232, -232, -231, -230, -229, -228, -227, -226, -225, -224, -223, -222, -221, -220, -219, -218, -216, -215, -214, -213, -211, -210, -208, -207, -205, -204, -202, -201, -199, -197, -196, -194, -192, -191, -189, -187, -185, -183, -181, -179, -177, -175, -173, -171, -169, -167, -165, -163, -161, -158, -156, -154, -152, -149, -147, -145, -142, -140, -138, -135, -133, -130, -128, -125, -123, -120, -118, -115, -113, -110, -107, -105, -102, -99, -97, -94, -91, -89, -86, -83, -80, -78, -75, -72, -69, -66, -64, -61, -58, -55, -52, -49, -46, -43, -41, -38, -35, -32, -29, -26, -23, -20, -17, -14, -11, -8, -5, -2
sinustable_end:
