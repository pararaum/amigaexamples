        INCLUDE "hardware/custom.i"
        INCLUDE "hardware/intbits.i"
        INCLUDE "hardware/dmabits.i"
	include	"own.i"

PLASMA_WIDTH = 256
PLASMA_HEIGHT = 128
PLASMA_COPPER_MPL = 256/8
PLASMA_TOPLINE = $30

	;;; A6 contains the $DFF000 custom chip base.

	_start:	jmp	main(pc)
	dc.b	"Plasma Two",10
	dc.b	"Code: Pararaum / T7D",0
	align	4
	cmp.l	#"main",main
	cmp.l	#"seco",setup_copper
	cmp.l	#"plas",do_plasma
	cmp.l	#"COPL",copper_list
	cmp.l	#"CPLS",copper_plasma_space
	cmp.l	#"COLR",colour_area_r
	cmp.l	#"COLG",colour_area_g
	cmp.l	#"COLB",colour_area_b
	cmp.l	#"COLE",colour_area_end
	align	4
main:	nop
	moveq	#OWN_libraries|OWN_view|OWN_trap|OWN_interrupt,d0
	jsr	own_machine
	lea.l	$DFF000,a6
	bsr	setup_system
l3$:	nop
	bsr	wait_frame
	move.w	#$b5b,color+2(a6)
	bsr	do_plasma
	move.w	#$bb5,color+2(a6)
	bsr	blit_plasma
	move.w	#$55c,color+2(a6)
	btst	#6,$bfe001	; Left mouse clicked?
	bne.s	l3$
	jsr	disown_machine
	moveq	#0,d0
	rts
	jmp	_start

;;; Blit the plasma lines
blit_plasma:
	movem.l	d2-d7/a0-a6,-(sp)
	;; WAITBLIT
wb1$:	btst.b	#6,dmaconr(a6)
	bne.s	wb1$
	bsr	init_blitter$
	;; A2: pointer to red
	;; A3: pointer to green
	;; A4: pointer to blue
	;; A5: copper are target
	;; D7: line counter
	lea.l	colour_area_r,a2
	lea.l	colour_area_g,a3
	lea.l	colour_area_b,a4
	lea.l	copper_plasma_space,a5
	move.w	#PLASMA_HEIGHT-1,d7	   ; -1 as using dbf
wb2$:	btst.b	#6,dmaconr(a6)
	bne.s	wb2$
	lea.l	PLASMA_COPPER_MPL*2-2(a2),a0 ; End of current line for r
	move.l	a0,bltapt(a6)
	lea.l	PLASMA_COPPER_MPL*2-2(a3),a0 ; End of current line for g
	move.l	a0,bltbpt(a6)
	lea.l	PLASMA_COPPER_MPL*2-2(a4),a0 ; End of current line for b
	move.l	a0,bltcpt(a6)
	lea.l	2+PLASMA_COPPER_MPL*4(a5),a0 ; Last move for this line in copper list.
	move.l	a0,bltdpt(a6)
	;; H9-H0, W5-W0 width is in words. By writing the size into the custom chip register the blit begins and continues while the cpu is still running.
	move.w	#(PLASMA_COPPER_MPL<<6)|(1),bltsize(a6)
	;; Advance one line
	lea.l	PLASMA_COPPER_MPL*2(a2),a2
	lea.l	PLASMA_COPPER_MPL*2(a3),a3
	lea.l	PLASMA_COPPER_MPL*2(a4),a4
	;; Move to the line in copper commands. +4 for first wait, +4 for MOVE black at right side.
	lea.l	4+4+PLASMA_COPPER_MPL*4(a5),a5
	dbf	d7,wb2$
	movem.l	(sp)+,d2-d7/a0-a6
	rts
init_blitter$:
	;; Now prepare the blitter
	;; ShiftA=8, useA-D
	;; Minterms: d=a+b+c
	;; d=a(b+B)(c+C) + (a+A)b(c+C) + (a+A)(b+B)c
	;; d=(ab+aB)(c+C) + (ab+Ab)(c+C) + (ab+aB+Ab+AB)c
	;; d=abc+abC+aBc+aBC + abc+abC+Abc+AbC + abc+aBc+Abc+ABc
	;; d=abc+abC+aBc+aBC + Abc+AbC + ABc
	move.w	#$8Ffe,bltcon0(a6)
	;; Descending mode, ShiftB=4
	move.w	#$4002,bltcon1(a6)
	;; Now set up first and last blitmask
	moveq	#-1,d0		; All bits set
	move.w	d0,bltafwm(a6)
	move.w	d0,bltalwm(a6)
	clr.w	bltamod(a6)	; No modulos here
	clr.w	bltbmod(a6)
	clr.w	bltcmod(a6)
	move.w	#2,bltdmod(a6)	;Skip every second word (one word copper command, one word for value)
	rts

do_plasma:
	lea	colour_area_r,a2
	lea	colour_area_g,a3
	lea	colour_area_b,a4
	move.l	a2,a0
	bsr	inc$
	move.l	a3,a0
	bsr	inc$
	move.l	a4,a0
	bsr	inc$
	lea	2(a2),a0
	bsr	inc$
	lea	4(a3),a0
	bsr	inc$
	lea	6(a4),a0
	bsr	inc$
	lea	8(a2),a0
	bsr	inc$
	lea	8(a3),a0
	bsr	inc$
	bsr	inc$
	lea	8(a4),a0
	bsr	inc$
	bsr	inc$
	bsr	inc$
	rts
inc$:	move.w	(a0),d0
	addq.w	#1,d0
	and.w	#$f,d0
	move.w	d0,(a0)
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
	move.l	#bitplane,d0	 ; Address of bitplane
	move.w	d0,copper_bplptr+6 ; Lower 16 bits.
	swap	d0
	move.w	d0,copper_bplptr+2 ; Upper 16 bits.
	;; Plasma is W*H "Pixels".
	;; D3: line
	moveq	#0,d3		; Line
	lea.l	copper_plasma_space,a2 ; Space to where the data should be generated.
l2$:	move.w	d3,d0		       ; Current line
	add.w	#PLASMA_TOPLINE,d0     ; Current scanline
	lsl.w	#8,d0		       ; VPOS is bit 9-15
	or.w	#$51,d0		       ; or x-position (odd!)
	move.w	d0,(a2)+
	move.w	#$FFFE,(a2)+	; Mask for WAIT
	moveq	#PLASMA_COPPER_MPL-1,d0 ;MOVEs per line
	move.l	#$01800000,d1
l1$:	move.l	d1,(a2)+
	addq.w	#1,d1
	dbf	d0,l1$
	addq.w	#1,d3		; Next line.
	move.l	#$01800000,(a2)+ ; Turn to black again.
	cmp.w	#PLASMA_HEIGHT,d3
	bcs.s	l2$
	movem.l	(sp)+,d2-d7/a2-a6
	rts

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
	dc.w	bplcon0,$1200			; 1 Bitplane, output enabled
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
	dc.w	bpl1mod,$0000
	dc.w	bpl2mod,$0000
copper_bplptr:
	dc.w	$00e0,$0000,$00e2,$0000		; Bitplaneptrs
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000
	dc.w	$00f0,$0000,$00f2,$0000
	dc.w	color+2*0,$0000	;Colour 0
	dc.w	color+2*1,$05f5	;Colour 1
copper_plasma_space:
	;; +1 for the wait command, +1 for the black at the end.
	dcb.l	PLASMA_HEIGHT*(PLASMA_COPPER_MPL+1+1),$01feEAEA

	dc.w	$ffdf,$fffe	; End of NTSC.
	dc.w	$0107,$fffe	;Wait for line 257.
	;; White marker for easy spottin.
	dc.w	color,$fff
	;; End of Copper List
	dc.w	$ffff,$fffe

bitplane:
	REPT	255
	dc.w	$F731
	dcb.b	(320-16)/8
	ENDR
	dcb.b	(320-16)/8
	dc.w	$8CEF

	dc.b	"COLOUR AREA"
	EVEN
	;; A word for every RGB colour
colour_area_r:
	dcb.w	PLASMA_HEIGHT*PLASMA_COPPER_MPL
colour_area_g:
	dcb.w	PLASMA_HEIGHT*PLASMA_COPPER_MPL
colour_area_b:
	dcb.w	PLASMA_HEIGHT*PLASMA_COPPER_MPL
	dc.b	"COLOUR AREA ENDS"
	EVEN
colour_area_end:
	illegal


	SECTION BSS,bss
debugstorage:
	ds.l	1<<10
