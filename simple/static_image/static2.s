        INCLUDE "hardware/custom.i"
        INCLUDE "hardware/intbits.i"
	include	"own.i"

WIDTH = (1024+320)
HEIGHT = (1024+256)

;;; A6 contains the $DFF000 custom chip base.

_start:	jmp	main(pc)
	dc.b	"Static image 2",10
	dc.b	"Code: Pararaum / T7D",0
	align	4
main:	nop
	moveq	#1|2|4,d0
	jsr	own_machine
	lea.l	$DFF000,a6
	bsr	setup_copper
	jsr	waitsome
	bsr	draw_coordinates
l3$:	btst	#6,$bfe001	; Left mouse clicked?
	bne.s	l3$
	jsr	disown_machine
	;; setup copper
	moveq	#0,d0
	rts

waitsome:
	moveq	#103,d0
l1$:	btst	#0,vposr+1(a6)
	beq.s	l1$
	move.w	d0,color(a6)
l2$:	btst	#0,vposr+1(a6)
	bne.s	l2$
	dbf	d0,l1$
	rts

;;; Draw the coordinate points in the image data.
;;; Every 64 Pixel (h/v) a hexadecimal number is written so that scrolling can be observed.
draw_coordinates:
	movem.l	d0-d7/a0-a6,-(sp)
	;; D2: X coordinate
	;; D3: Y coordinate
	moveq	#0,d2
	moveq	#0,d3
l1$:	move.w	d3,d0		; Current Y in d0
	mulu.w	#WIDTH/8,d0	; This is the line pointer
	move.l	d2,d1		; X in D1
	lsr.w	#3,d1		; Divide by 8 to get bytes
	add.l	d1,d0
	lea.l	image,a0
	add.l	d0,a0		; Points now to the next 64x64 block.
	move.w	#WIDTH/8,d0
	move.w	d2,d1		; X coordinate into d1 lower bits.
	swap.w	d1		; now in upper 16 bits.
	or.w	d3,d1		; Y coordinate for full (x,y) pair.
	jsr	draw_uint32_number
	add.w	#64+8,d2	; Next X coordinate
	cmp.w	#WIDTH-64-8,d2
	bcs.s	l1$
	moveq	#0,d2		; Clear X coordinate
	add.w	#32,d3		; Next Y coordinate
	cmp.w	#HEIGHT-64-8,d3
	bcs.s	l1$
	movem.l	(sp)+,d0-d7/a0-a6
	rts

setup_copper:
	lea	copper_list,a0
	move.l	a0,cop1lc(a6)
	lea	copper_bplptr,a1 ; Pointer to copper list bitplane setup.
	move.l	#image,d0	 ; Move image address into d0
	move.w	d0,6(a1)	 ; Lower 16 bits of address
	swap	d0		 ; Switch words
	move.w	d0,2(a1)	 ; Upper 16 bits of address
	move.l	#onscreen,d0	; On screen display
	move.w	d0,14(a1)	; Lower 16 bits of onscreen display
	swap	d0
	move.w	d0,10(a1)	; Upper 16 bits of onscreen display
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
	dc.w	bplcon0,$1200			; 1 Bitplanes, output enabled
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
	dc.w	bpl1mod,(WIDTH-320)/8 ; 320 Pixels are displayed
	dc.w	bpl2mod,$0000	      ; Onscreen display is only 320 pixel wide.
copper_bplptr:
	dc.w	$00e0,$0000,$00e2,$0000		; Bitplaneptrs
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000
	dc.w	$00f0,$0000,$00f2,$0000
	dc.w	color+2*0,$0000	;Colour 0
	dc.w	color+2*1,$075f
	dc.w	color+2*2,$069d
	dc.w	color+2*3,$09ef
	;; End of Copper List
	dc.w	$ffff,$fffe

	SECTION DATA,data

	SECTION bss_c,bss_c
image:	ds.b	WIDTH*HEIGHT/8
onscreen:
	ds.b	320*256/8
