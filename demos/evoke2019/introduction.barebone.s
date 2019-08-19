;;; Barebone code and data for the Evoke 2019 demo.
        INCLUDE "hardware/custom.i"
        INCLUDE "hardware/intbits.i"

	XDEF	_mod_introspeech
	XDEF	_whole_chipmem
	XDEF	_whole_chipmem_end
	XDEF	_wait_songposition
	XDEF	_get_songposition
	XDEF	_introduction_create_copperlist
	XDEF	_introduction_coppercolours

	XREF	pt_SongPosition

	SECTION CHIP,data_c
_whole_chipmem:
	dc.l	$CAFEBABE
	ALIGN	4
_mod_introspeech:
	incbin	"mod.introspeech"
	ALIGN	4
	include	"fader.t7d.i"
	ALIGN	4
	include	"fader.flamewars.i"
	ALIGN	4
	include	"fader.presents.i"
	ALIGN	4
	include	"fader.minidemo.i"
	ALIGN	4
	include	"evoke.introduction.5planes.i"
	ALIGN	4
introduction_copperlist:
	dcb.l	20,$01feEAEA	; Copper NOP
	dc.w	bplcon0,$5200	; 5 Bitplanes and output.
_introduction_coppercolours:
i$	SET	color
	REPT	32
	dc.w	i$,0
i$	SET	i$+2
	ENDR
	;; (format "%X" (+ #x2c 200))"F4": This is the 200th line of the bitplanes starting from the top of the display window. Wait for the end of the line.
	dc.w	$F3DF,$FFFE
	dc.w	bplcon0,$0200	; Disable bitplanes.
	dc.w	$FFFF,$FFFE	; End of Copperlist
	ALIGN	4
	dc.l	" END"
	;; A chip segment of 434000 bytes (loads up to $7F000?) seems to be loadable but close to the limit. If there is not enough memory a Guru Meditation occurs.
	dcb.b	55067,$EA
_whole_chipmem_end:
	dc.l	-1
	dc.b	$54,$37,$44,$EA

	SECTION CODE,code
;;; int wait_songposition(ULONG songpos, ULONG patternpos);
;;; Wait for a certain song position and pattern position.
;;; Return: Returns either 0 on exact match or one if the position has passed.
_wait_songposition:
	;; d0=songpos
	;; d1=patternpos
	;; http://www.easy68k.com/paulrsm/doc/trick68k.htm
	move.l	1*4(sp),d0
	move.l	2*4(sp),d1
	lsl.l	#4,d1		; Multiply pattern position with 16...
	;;  song pos > d0, d0 < song pos
	cmp.l	pt_SongPosition,d0 ; d0 - songpos -> CC
	bcs.s	passe$
	;; Loop as long song position is smaller than or equal d0
	;; song pos <= d0
	;; Operands are reversed:
	;; d0 >= song pos
l1$:	cmp.l	pt_SongPosition,d0 ; d0 - songpos -> cc
	bhi.s	l1$
	;; Loop as long as pattern position is smaller than D1
	;; pattern pos < D1
	;; Operands are reversed
	;; d1 > pattern pos
l2$:	cmp.l	pt_PatternPosition,d1
	bhi.s	l2$
	clr.l	d0
	rts
passe$:	moveq	#1,d0
	rts


_get_songposition:
	move.l	pt_SongPosition,d0
	rts

;;; UWORD *introduction_create_copperlist(int image_number);
;;; This function will return the corresponding colour list in D0. It will also set the copper list number one.
_introduction_create_copperlist:
	movem.l	d1-d7/a0-a6,-(sp)
;	;; Setup colors
	lea.l	$DFF000,a6
;	lea.l	logo_old_t7d_png_palette,a0
;	lea.l	color(a6),a1
;	moveq	#(1<<logo_old_t7d_png_bitplanes)-1,d0
;l1$:	move.w	(a0)+,(a1)+
;	dbf	d0,l1$
	;; Bitplane pointers
	move.w	#$e0,d2
	move.l	(7+7)*4+4(a7),d3 ; Image number
	lsl.w	#2,d3		 ; Pointers are four bytes.
	move.l	(imageptrs$,pc,d3),d3
	lea.l	introduction_copperlist,a2
	moveq	#fader_t7d_png_bitplanes-1,d0
l2$:	move.w	d2,(a2)+
	addq.l	#2,d2
	swap	d3
	move.w	d3,(a2)+
	swap	d3
	move.w	d2,(a2)+
	addq.l	#2,d2
	move.w	d3,(a2)+
	add.l	#fader_t7d_png_width/8,d3
	dbf	d0,l2$
	move.w	#fader_t7d_png_width*(fader_t7d_png_bitplanes-1)/8,bpl1mod(a6)
	move.w	#fader_t7d_png_width*(fader_t7d_png_bitplanes-1)/8,bpl2mod(a6)
	move.l	#introduction_copperlist,cop1lc(a6)
	move.l	(7+7)*4+4(a7),d0 ; Image number
	lsl.w	#2,d0		 ; Pointers are four bytes.
	move.l	(colourptrs$,pc,d0),d0 ; Get pointer to colours
	movem.l	(sp)+,d1-d7/a0-a6
	rts
imageptrs$:
	dc.l	evoke_introduction_5planes_png
	dc.l	fader_t7d_png
	dc.l	fader_presents_png
	dc.l	fader_flamewars_png
	dc.l	fader_minidemo_png
	dc.l	-1
colourptrs$:
	dc.l	evoke_introduction_5planes_png_palette
	dc.l	fader_t7d_png_palette
	dc.l	fader_presents_png_palette
	dc.l	fader_flamewars_png_palette
	dc.l	fader_minidemo_png_palette
	dc.l	-1
