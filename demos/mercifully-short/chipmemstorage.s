	include	"hardware/custom.i"
	INCLUDE	globals.i

	xdef	_chip_gfx_memory
	XDEF	_image_2022_04_17_20_37_59_png
	XDEF	image_2022_04_17_20_37_59_png
	XDEF	image_2022_04_17_20_37_59_png_palette
	XDEF	_make_colour_copperlist_background
	XDEF	_image_mercifully

_image_2022_04_17_20_37_59_png = image_2022_04_17_20_37_59_png

	section	data_c,data_c
	include	"image_2022-04-17_20-37-59.inc"

_image_mercifully:
	incbin	"image.mercifully_short.raw"
image_mercifully_end:
	if	image_mercifully_end-_image_mercifully>CHIPMEMSTORAGE_height*CHIPMEMSTORAGE_width*CHIPMEMSTORAGE_depth/8
	fail	Chipmem not big enough!
	endif

	section	bss_c,bss_c
_chip_gfx_memory:
	ds.b	CHIPMEMSTORAGE_width*CHIPMEMSTORAGE_height*CHIPMEMSTORAGE_depth/8

	TEXT

;;; Input: A1=pointer to copperlist space
_make_colour_copperlist_background:
	moveq	#(1<<FOR_YOU_depth)-1,d0	; 16 colours
	move.w	#color,d1	; Colour custom chip address
	lea	image_2022_04_17_20_37_59_png_palette,a0 ; Image colours
.loop_copcol:
	move.w	d1,(a1)+	; Move register into copperlist.
	move.w	(a0)+,(a1)+	; Copy the colour value.
	addq.w	#2,d1		; Next colour register.
	dbf	d0,.loop_copcol
	rts
