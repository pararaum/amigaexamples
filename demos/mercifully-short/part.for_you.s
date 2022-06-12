	include	"hardware/custom.i"
	include	"hardware/dmabits.i"
	include "t7d/blitter.i"
	include	"globals.i"
	include "chipmemstorage.i"
	XREF	_custom

	XDEF	_part_for_you_copper_bplptr
	XDEF	_part_for_you_copper_list
	XDEF	_init_for_you
	XDEF	_for_you_blit_it_is
	XDEF	_for_you_unblit_it_is

BITPLANE_MODULO	equ	(FOR_YOU_width/8*(FOR_YOU_depth-1))

	section	data_c,data_c
image_it_is:
	incbin	"image.it_is.raw"
image_it_is_end:
	if	image_it_is_end-image_it_is>CHIPMEMSTORAGE_height*CHIPMEMSTORAGE_width*CHIPMEMSTORAGE_depth/8
	fail	Chipmem not big enough!
	endif

_part_for_you_copper_list:
        dc.w    fmode,$0000
        dc.w    diwstrt,$2c81,diwstop,$2cc1
        dc.w    ddfstrt,$0038,ddfstop,$00d0
        dc.w    bplcon0,$0200
copper_scrollcon:
        ;; http://www.winnicki.net/amiga/memmap/BPLCON1.html, scrolling
        ;; Lower nibbles are for scrolling, PF 1 and PF2.
        dc.w    bplcon1,$0000
        ;; http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_4.html
        ;; http://www.winnicki.net/amiga/memmap/BPLCON2.html
        ;; http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node0159.html
        ;; $104          FEDCBA9876543210
        dc.w    bplcon2,%0000000000000000
        ;; Bitplane modulos
copper_bitplane_modulos:
        dc.w    bpl1mod,BITPLANE_MODULO
        dc.w    bpl2mod,BITPLANE_MODULO
_part_for_you_copper_bplptr:
        dc.w    $00e0,$0000,$00e2,$0000         ; Bitplaneptrs
        dc.w    $00e4,$0000,$00e6,$0000
        dc.w    $00e8,$0000,$00ea,$0000
        dc.w    $00ec,$0000,$00ee,$0000
        dc.w    $00f0,$0000,$00f2,$0000
copper_colours:
	dcb.l	32,$01fe01fe	; No-Op, 32 colours
	;; Wait a little
	dc.w	$4a01,$fffe
        dc.w    bplcon0,$4200	; Enable bitplanes
	;; Wait for end.
	dc.w	$4a01+(IMAGE_BACKGROUND_FISH_height<<8),$fffe
        dc.w    bplcon0,$0200	; Disable again to hide garbage.
	dc.w    $ffdf,$fffe     ; End of NTSC.
	dc.w	$ffff,$fffe

	section	code
;;; Initialise the "for you" part.
;;; Input: A0=bitplane pointer to where the image will be displayed (chip).
_init_for_you:
Abitmapmem$:	equr	a2
regs$:	reg	d2-d7/a2-a6
	movem.l	regs$,-(sp)
	move.l	a0,Abitmapmem$
	lea	_custom,a5
	move.w	#DMAF_COPPER|DMAF_RASTER,dmacon(a5) ; Turn off copper and raster.
	;; Now blit the image into the display area.
	lea.l	image_2022_04_17_20_37_59_png,a0
	move.l	Abitmapmem$,a1
	move.w	#FOR_YOU_width/8,d0
	move.w	#FOR_YOU_height*FOR_YOU_depth,d1
	jsr	_blitter_linear_copy
	;; Set bitplane pointers.
	lea	_part_for_you_copper_bplptr,a0
	lea	(Abitmapmem$),a1
	moveq	#FOR_YOU_depth,d0
	move.w	#FOR_YOU_width/8,d1
	jsr	copper_create_bitplptrs
	;; Copy colours.
	lea	copper_colours,a1	; Colour registers copper-space into A1.
	jsr	_make_colour_copperlist_background
	;; Enable copperlist.
	move.l	#_part_for_you_copper_list,cop1lc(a5)
	move.w	#DMAF_SETCLR|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER,dmacon(a5)
	movem.l	(sp)+,regs$
	rts

	ifnd	NDEBUG
	dc.b	"T7D:fillegal"
	align	4
fillegal:
something$:	equr	d7
	.something: equr	d6
	clrfo
	.val1:	fo.l	1
	.val2:	fo.w	1
	.val3:	fo.w	1
	.val4:	fo.w	1
	.val5:	fo.w	1
	printv	__FO
	link	a6,#__FO
	clr.l	.val1(a6)
	clr.w	.val5(a6)
	unlk	a6
	printv	.val1
	printv	.val2
	printv	.val3
	printv	.val4
	printv	.val5
	cargs	#0,sym1$.l,sym2$.w,sym3$.l
	printv	sym1$,sym2$,sym3$
	illegal
	illegal
	illegal
	illegal
	illegal
	illegal
	illegal
	illegal
	nop
	nop
	nop
	nop
	dc.b	"This demo is for you!"
	even
	trap	#9
	clr.l	something$
	clr.l	.something
	illegal
	endif

	ifnd	NDEBUG
	dc.b	"t7d:blit"
	even
	endif
;;; Blit a single bitplane while ORing with the old contents.
;;; Input: D0=which bitplane to affect in the target
;;;	A0=target bitplane
_for_you_blit_it_is:
Acustom$:	equr	a5
Ait_is$:	equr	a2
Atarget$:	equr	a3
Asrc$:		equr	a4
regs$:	reg	Acustom$/Ait_is$/Atarget$/Asrc$
	movem.l	regs$,-(sp)
	move.l	a0,Atarget$
	lea	_custom,Acustom$	; Custom base into A5
	lea	image_it_is,Ait_is$	; Start address of overlay text
	lea.l	image_2022_04_17_20_37_59_png,Asrc$
	;; Test: skip some lines.
	add.w	#IMAGE_IT_IS_width/8*10,Ait_is$
	mulu.w	#FOR_YOU_width/8,d0
	add.w	d0,Atarget$
	add.w	d0,Asrc$
	WAITBLITA5
	;; http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node011D.html
	;; D = A + B       $FC
	move.w	#$0dFC,bltcon0(Acustom$)
	clr.w	bltcon1(Acustom$)
	move.w	#$FFFF,bltafwm(Acustom$)
	move.w	#$FFFF,bltalwm(Acustom$)
	move.l	Ait_is$,bltapt(Acustom$)
	move.l	Asrc$,bltbpt(Acustom$)
	move.l	Atarget$,bltdpt(Acustom$)
	clr.w	bltamod(Acustom$)
	move.w	#BITPLANE_MODULO,bltbmod(Acustom$)
	move.w	#BITPLANE_MODULO,bltdmod(Acustom$)
	;; http://www.winnicki.net/amiga/memmap/BLTSIZE.html
	move.w	#(FOR_YOU_height<<6)|(FOR_YOU_width/8/2),bltsize(Acustom$)
	movem.l	(sp)+,regs$
	rts

;;; Blit a single bitplane from the original picture into the destination
;;; Input: D0=which bitplane to affect in the destination
;;;	A0=target bitplane
_for_you_unblit_it_is:
Acustom$:	equr	a5
Adest$:	equr	a3
Asrc$:		equr	a4
regs$:	reg	Acustom$/Adest$/Asrc$
	movem.l	regs$,-(sp)
	move.l	a0,Adest$
	lea	_custom,Acustom$	; Custom base into A5
	lea.l	image_2022_04_17_20_37_59_png,Asrc$
	mulu.w	#FOR_YOU_width/8,d0
	add.w	d0,Adest$
	add.w	d0,Asrc$
	WAITBLITA5
	;; http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node011D.html
	;; D = A
	move.w	#$09F0,bltcon0(Acustom$)
	clr.w	bltcon1(Acustom$)
	move.w	#$FFFF,bltafwm(Acustom$)
	move.w	#$FFFF,bltalwm(Acustom$)
	move.l	Asrc$,bltapt(Acustom$)
	move.l	Adest$,bltdpt(Acustom$)
	clr.w	bltamod(Acustom$)
	move.w	#BITPLANE_MODULO,bltamod(Acustom$)
	move.w	#BITPLANE_MODULO,bltdmod(Acustom$)
	;; http://www.winnicki.net/amiga/memmap/BLTSIZE.html
	move.w	#(FOR_YOU_height<<6)|(FOR_YOU_width/8/2),bltsize(Acustom$)
	movem.l	(sp)+,regs$
	rts
