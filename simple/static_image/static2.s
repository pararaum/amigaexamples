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
	moveq	#100,d0
l1$:	btst	#0,vposr+1(a6)
	beq.s	l1$
l2$:	btst	#0,vposr+1(a6)
	bne.s	l2$
	dbf	d0,l1$
	jsr	disown_machine
	;; setup copper
	moveq	#0,d0
	rts

setup_copper:
	lea	copper_list,a0
	move.l	a0,cop1lc(a6)
	lea	copper_bplptr,a1 ; Pointer to copper list bitplane setup.
	move.l	#image,d0	 ; Move image address into d0
	move.w	d0,6(a1)	 ; Lower 16 bit of address
	swap	d0		 ; Switch words
	move.w	d0,2(a1)	 ; Upper 16 bit of address
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
	dc.w	bplcon0,$1200			; 3 Bitplanes, output enabled
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
	dc.w	color+2*1,$075f
	dc.w	color+2*2,$069d
	dc.w	color+2*3,$09ef
	;; End of Copper List
	dc.w	$ffff,$fffe

	SECTION bss_c,bss_c
image:	ds.b	WIDTH*HEIGHT/8
onscreen:
	ds.b	320*256/8
