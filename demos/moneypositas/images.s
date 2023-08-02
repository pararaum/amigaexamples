
	XDEF	_get_image
	XDEF	_lz4logo
	XDEF	_lz4logo_end
	XDEF	_one_dollar_png
	XDEF 	_one_dollar_png_width
	XDEF	_one_dollar_png_height
	XDEF	_futurewriter_font
	XDEF	_for_a_fistful_of_dollars
	XDEF	_font16x16
	XDEF	_animation_plus_ccm
	XDEF	_burning_earth
	XDEF	_dollarbackground
	XDEF	_image_kaboom

;;; Get the compressed image data.
;;; Input:
;;; d0.w = which number?
;;; a0 = ptr to where address is written to
;;; Output: d0 = length, zero if no such image.
_get_image:
	cmp.w	#2,d0
	bhi.s	.nope
	lsl.w	#3,d0		; Multiply by 8 (4 for long word, and there are 2).
	lea.l	.table(pc),a1
	move.l	0(a1,d0.w),(a0)	; Get image address.
	move.l	4(a1,d0.w),d0	; Get image size.
	rts
.nope:
	clr.l	d0
	rts
.table:
	dc.l	img1319,img1319_end-img1319
	dc.l	img2258,img2258_end-img2258
	dc.l	img2271,img2271_end-img2271

	SECTION DATA,DATA
	
img1319:
	INCBIN	"image.past.deflated"
img1319_end:

	EVEN
img2258:
	INCBIN	"image.present.deflated"
img2258_end:

	EVEN
img2271:
	INCBIN	"image.future.deflated"
img2271_end:

	EVEN
_lz4logo:
	;; 	INCBIN	"logo.the_7th_division.lz4"
	INCBIN	"logo.the_7th_division.bpl~1.deflated"
_lz4logo_end:

	EVEN
_animation_plus_ccm:
	INCBIN	"animation.bpl~5.deflated"
	
	EVEN
_futurewriter_font:
	INCBIN	"futurewriter.bpl~1.deflated"

	EVEN
_for_a_fistful_of_dollars:
	INCBIN	"pictures/50.ilbm"

	EVEN
_burning_earth:
	INCBIN	"burning_earth.bpl~5.deflated"
	
	EVEN
_image_kaboom:
 	INCBIN	"image.kaboom.bpl~5.deflated"
	
	EVEN
_font16x16:
	INCBIN	"font.16x16.4bpls.deflated"

	EVEN
_dollarbackground:
	INCBIN	"image.dollarbackground.bpl~2.deflated"
	
	SECTION CHIP,DATA_C
	;; lines: 1
	;; two pixels: 2
	;; center dot: 4
	;; background: 6
	;; zackenrand: 9
	;; circle: 11
one_dollar_png_width	EQU	16
one_dollar_png_height	EQU	6
one_dollar_png_bitplanes	EQU	4
	;; 
_one_dollar_png_width:		dc.w	one_dollar_png_width
_one_dollar_png_height:		dc.w	one_dollar_png_height
_one_dollar_png:
	DC.B	$a9, $2a
	DC.B	$56, $d5
	DC.B	$56, $d5
	DC.B	$a9, $2a
	DC.B	$03, $80
	DC.B	$ff, $ff
	DC.B	$fc, $7f
	DC.B	$03, $80
	DC.B	$87, $c9
	DC.B	$7f, $f6
	DC.B	$50, $36
	DC.B	$87, $c1
	DC.B	$46, $cc
	DC.B	$be, $f3
	DC.B	$b9, $33
	DC.B	$06, $c0
	DC.B	$bf, $e9
	DC.B	$47, $d6
	DC.B	$40, $16
	DC.B	$87, $c1
	DC.B	$03, $80
	DC.B	$ff, $ff
	DC.B	$fc, $7f
	DC.B	$03, $80

