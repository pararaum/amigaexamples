;;; This code was partly ripped from alpha one's http://www.flashtro.com/index.php?e=page&c=crack8&id=606.
	include	"copper_fade.i"

picheight = 240
IMAGE_COLOURS = 32
VPOSR = $4
	
	section	text,code

main:	bra	main$
	dc.b	"Scroller and image demostration code by Pararaum / T7D."
	even
	cmp.l	#"COPC",copcol
	cmp.l	#"fade",fade_in_copper_list
	cmp.l	#"dofa",do_fade_in
	illegal
main$:	move.l	4.w,a6		; Get base of exec lib
	lea	gfxlib,a1	; Adress of gfxlib string to a1
	moveq	#0,d0		; any version is ok
	jsr	-408(a6)	; Call OpenLibrary()
	tst.l	d0
	bne.s	libok$
	moveq	#-1,d0		; user should know something went wrong
	rts
libok$:	move.l	d0,gfxbase	; Save base of graphics.library
	move.w	#picheight,d0
	lea.l	copdiw,a0
	bsr	setup_diw
	lea	picture,a0	; Address of picture-rawdata
	lea	bplptr,a1	; Address of bitplaneptrs in copperlist
	moveq	#5-1,d1		; 5 bitplanes to set in copperlist
setbpls:move.l	a0,d0		; Picture-Rawdata address to d0
	move.w	d0,6(a1)	; Insert bitplaneptr into copperlist
	swap	d0		; 
	move.w	d0,2(a1)	;
	add.l	#(320/8)*picheight,a0	; Pointer to next bitplane in picture-rawdata
	addq.l	#8,a1		; Next Bitplaneptr in copperlist
	dbf	d1,setbpls
	lea	copcol,a0
	moveq	#IMAGE_COLOURS,d0		;32 colours
	moveq	#$0,d1
	jsr	make_copper_list

	jsr	-132(a6)	; Forbid task switching

	;; see: http://amiga.sourceforge.net/amidevhelp/phpwebdev.php?keyword=Forbid&funcgroup=AmigaOS&action=Search
	move.l #cop,$dff080	; Set new copperlist
	bsr	do_fade_in
	bsr	do_the_scroll
	lea.l	copcol,a0
	moveq	#IMAGE_COLOURS,d0
	bsr	fade_color
	move.l gfxbase,a1	; Base of graphics.library to a1
	move.l 38(a1),$dff080	; Restore old copperlist
	jsr	-138(a6)	; Permit task switching
	;; http://amiga.sourceforge.net/amidevhelp/phpwebdev.php?keyword=Permit&funcgroup=AmigaOS&action=Search
	jsr -414(a6)		; Call CloseLibrary()
	moveq #0,d0		; Status = OK
	rts			; Bye, Bye!

do_fade_in:
	movem.l	d0-d7/a0-a5,-(sp) ;save registers
	link	a6,#-IMAGE_COLOURS*4*2 ;three words per colour
	movem.l	d0-d1/a0,-(sp)	       ;save registers, again
	moveq	#0,d0		       ;clear
	moveq	#IMAGE_COLOURS*2-1,d1  ;4 words per colour (is easier to calculate)
	move.l	a7,a0		       ;address of spare area
l1$:	move.l	d0,(a0)+	       ;clear
	dbf	d1,l1$
	movem.l	(sp)+,d0-d1/a0	;restore
	moveq	#16-1,d2	;16 steps
	lea.l	copcol,a1	;copper colour area
	move.l	a7,a2		;spare address
l49$:	moveq	#IMAGE_COLOURS,d0 ;number of colours
	lea.l	image_colour_list,a0 ;pointer to colour list
	jsr	fade_in_copper_list ;do one fade
	bsr	wait_4_vblank	    ;wait
	bsr	wait_4_vblank
	bsr	wait_4_vblank
	bsr	wait_4_vblank
	bsr	wait_4_vblank
	bsr	wait_4_vblank
	dbf	d2,l49$		;16 times
	unlk	a6		;free spare area
	movem.l	(sp)+,d0-d7/a0-a5 ;restore registers
	rts

;;; Fade in (and generate the copperlist).
	;; A0: colour list of target colours
	;; A1: pointer to where the copper list should be generated
	;; A2: spare area
	;; D0: number of colours
	;; Destroys: D0-D1
fade_in_copper_list:
	;; D2: Number of colours (copied from D0) - 1
	;; D3: colour register number
	movem.l	a0-a2/d2-d3,-(sp)
	move.w	#$180,d3
	move.w	d0,d2
	bra.s	in$		;Jump into loop -- this work even if d0==0
l1$:	move.w	(a0)+,d1	;Get next colour
	move.w	d1,d0		;Only blue
	and.w	#$000f,d0
	add.w	d0,(A2)+
	lsr.w	#4,d1
	move.w	d1,d0		;Only green
	and.w	#$000f,d0
	add.w	d0,(A2)+
	lsr.w	#4,d1
	and.w	#$000f,d0
	move.w	d1,d0		;Only red
	add.w	d0,(A2)+
	move.w	-2(a2),d0	;Get red
	lsr.w	#4,d0		;divide by 16
	lsl.w	#8,d0		;move to position $0x00
	move.w	d0,d1
	move.w	-4(a2),d0	;Get green
	lsr.w	#4,d0		;divide by 16
	lsl.w	#4,d0		;move to position $00x0
	or.w	d0,d1
	move.w	-6(a2),d0	;Get blue
	lsr.w	#4,d0		;divide by 16
	or.w	d0,d1
	move.w	d3,(a1)+	;Colour register (copper MOVE)
	addq	#2,d3		;Next register
	move.w	d1,(a1)+
in$:	dbf	d2,l1$
	movem.l	(sp)+,a0-a2/d2-d3
	rts


setup_diw:
	;; a0: pointer to copper list
	;; d0.w: number of lines
	;; return a0: pointer after last written word.
	movem.l	d6/d7,-(sp)
	moveq	#$2c,d7
	move.w	d7,d6
	lsl.w	#8,d6
	or.w	#$81,d6
	move.w	#$008e,(a0)+
	move.w	d6,(a0)+
	add.w	d0,d7
	move.w	d7,d6
	lsl.w	#8,d6
	or.w	#$00c1,d6
	move.w	#$0090,(a0)+
	move.w	d6,(a0)+
	movem.l	(sp)+,d6/d7
	rts


	;; a0: pointer to colour copper list begin
	;; d0.w: number of colours
fade_color:
	movem.l	d2-d7/a2-a6,-(sp)
	link	a5,#-32		; http://68k.hax.com/LINK
	;; A5 contains now the old SP, A7 points 32 bytes lower.
copbeg$ SET 0
copend$ SET 4
	move.l	a0,copbeg$(A7)	; Store begin of copper list.
	mulu.w	#4,d0
	add.l	d0,a0
	move.l	a0,copend$(A7)	; After end of copper list.
	lea.l	$DFF000,a4
l1$	move.l	copbeg$(A7),a0
	move.l	copend$(A7),a1
	jsr	fade_out_copper_list
	tst.l	d0
	beq	out$
	bsr	wait_4_vblank
	bsr	wait_4_vblank
	bsr	wait_4_vblank
	bsr	wait_4_vblank
	bra.s	l1$
out$:	nop
	;; Restore old stack pointer.
	unlk	a5
	movem.l	(sp)+,d2-d7/a2-a6
	rts


;;; Wait for the vertical blank.
;;; Destroys: A0
wait_4_vblank:
	lea.l	$dff000,a0
	lea	VPOSR+1(a0),a0	; Point to lower part of VPOSR
vblk1$:	btst	#0,(a0)		; V8
	bne.s	vblk1$
vblk2$:	btst	#0,(a0)		; V8
	beq.s	vblk2$
	rts

;;; Wait for a raster line:
;;; I: D0.w	raster line
wait_for_line:
	lea	$DFF000,a0
	and.l	#$1ff,d0	;Make sure to be within the first 512 lines.
	lsl.l	#8,d0		;V? is in the upper bits.
	;; See http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node0044.html.
l$:	move.l	VPOSR(a0),d1	;Vertical position can be read as a 32bit quantity.
	and.l	#$1ff00,d1	;Mask out everything but vertical position.
	cmp.l	d0,d1
	bne.s	l$
	rts

do_the_scroll:
	lea	$DFF000,a4
mouse$:	nop
	;; bsr	wait_4_vblank
	move.w	#190,d0
	bsr.s	wait_for_line
	nop
	move.w	#$fff,$180(a4)	; Background white.
	lea	picture-2,a1	; The word before the picture.
	move.w	#20-1,d1	; 20 lines to move.
l2$:	lea	320/8(a1),a1	; Move one line forward.
	move.l	a1,a0		; A0 points to the last word in the line.
	lsl.w	(a0)		; One pixel to the left.
	moveq	#38/2-1,d0	; Remainder of the line.
l1$:	lea	-2(a0),a0
	roxl.w	(a0)
	dbf	d0,l1$
	dbf	d1,l2$
	move.w	copcol+2,$180(a4)	; Background original colour.
	nop
	btst	#6,$bfe001	; Left mouse clicked?
	bne.b	mouse$		; No, continue loop!
	rts

	even
image_colour_list:
	;; These are the 32 colours of the image.
	dc.w	$0a78,$0a78,$0978,$0a9a
	dc.w	$0c9a,$0ecc,$0cbc,$0bad
	dc.w	$0a9c,$098a,$0979,$087a
	dc.w	$0769,$0868,$0d88,$0867
	dc.w	$0b88,$0658,$0fb9,$0fea
	dc.w	$0547,$0534,$0843,$0e97
	dc.w	$0224,$0112,$0211,$0422
	dc.w	$0322,$0001,$0000,$0110


	section vars,data
gfxlib:		dc.b	"graphics.library",0


	section data,data_c
	;; Copper List
	;; see: http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_2.html
	align	0,4
cop:
	dc.w	$0106,$0000,$01fc,$0000		; AGA compatible
	;; Setting up display.
	;; see also: http://cyberpingui.free.fr/tuto_graphics.htm
copdiw:	dc.w	$008e,$2c81,$0090,$2cc1		; DIWSTRT/DIWSTOP
	dc.w	$0092,$0038,$0094,$00d0		; DDFSTRT/DDFSTOP
	dc.w	$0102,$0000,$0104,$0000
	dc.w	$0106,$0000,$0108,$0000
	dc.w	$010a,$0000
	dc.w	$0120,$0000,$0122,$0000		; Clear spriteptrs
	dc.w	$0124,$0000,$0126,$0000
	dc.w	$0128,$0000,$012a,$0000
	dc.w	$012c,$0000,$012e,$0000
	dc.w	$0130,$0000,$0132,$0000
	dc.w	$0134,$0000,$0136,$0000
	dc.w	$0138,$0000,$013a,$0000
	dc.w	$013c,$0000,$013e,$0000

copcol:	
	; Setting up the 32 colors
	;; IFFTrasher nicely gives this.
	include "CIMG3486.ilbm.CMAP"

		dc.w	$0100,$5200			; 5 Bitplanes
bplptr:		dc.w	$00e0,$0000,$00e2,$0000		; Bitplaneptrs
		dc.w	$00e4,$0000,$00e6,$0000
		dc.w	$00e8,$0000,$00ea,$0000
		dc.w	$00ec,$0000,$00ee,$0000
		dc.w	$00f0,$0000,$00f2,$0000
	;; Wait for line 250
	dc.w	$fa01,$ff00
	;; COLOR00
	dc.w	$0180,$0fff
	dc.w	$ffff,$fffe

	align	0,4
picture:	incbin	"CIMG3486.ilbm.RAW"

	section	storage,bss
gfxbase:	ds.l	1
