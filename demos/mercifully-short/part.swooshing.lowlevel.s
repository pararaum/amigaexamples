;;; Lowlevel routines for the swooshing.
	include	"globals.i"
	include	"hardware/custom.i"
	include	"hardware/dmabits.i"

	XDEF	_part_swooshing_copper_list
	XDEF	_part_swooshing_copper_list_end
	XDEF	_part_swooshing_copper_bplptr
	XDEF	_part_swooshing_copper_colours
	XDEF	_part_swooshing_copspace4blit
	XDEF	_part_swooshing_copper_sprpt

BITPLANE_MODULO	equ	(FOR_YOU_width/8*(FOR_YOU_depth-1))

	section	data_c,data_c

_part_swooshing_copper_list:
        dc.w    fmode,$0000
        dc.w    diwstrt,$2c81,diwstop,$2cc1
        dc.w    ddfstrt,$0038,ddfstop,$00d0
        dc.w    bplcon0,$0200
        ;; http://www.winnicki.net/amiga/memmap/BPLCON1.html, scrolling
        ;; Lower nibbles are for scrolling, PF 1 and PF2.
        dc.w    bplcon1,$0000
        ;; http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_4.html
        ;; http://www.winnicki.net/amiga/memmap/BPLCON2.html
        ;; http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node0159.html
	;; Sprites must have priority.
        ;; $24           FEDCBA9876543210
        dc.w    bplcon2,%0000000000100100
        ;; Bitplane modulos
        dc.w    bpl1mod,BITPLANE_MODULO
_part_swooshing_copper_bitplane_modulo1 = *-2
        dc.w    bpl2mod,BITPLANE_MODULO
_part_swooshing_copper_bitplane_modulo2 = *-2
_part_swooshing_copper_bplptr:
        dc.w    $00e0,$0000,$00e2,$0000         ; Bitplaneptrs
        dc.w    $00e4,$0000,$00e6,$0000
        dc.w    $00e8,$0000,$00ea,$0000
        dc.w    $00ec,$0000,$00ee,$0000
        dc.w    $00f0,$0000,$00f2,$0000
_part_swooshing_copper_sprpt:
	dc.w	sprpt,0,sprpt+2,0 ; Sprite 0
	dc.w	sprpt+4,0,sprpt+6,0 ; Sprite 1
	dc.w	sprpt+8,0,sprpt+10,0 ; Sprite 2
	dc.w	sprpt+12,0,sprpt+14,0 ; Sprite 3
	dc.w	sprpt+16,0,sprpt+18,0 ; Sprite 4
	dc.w	sprpt+20,0,sprpt+22,0 ; Sprite 5
	dc.w	sprpt+24,0,sprpt+26,0 ; Sprite 6
	dc.w	sprpt+28,0,sprpt+30,0 ; Sprite 7
	;; Delay display of bitmap.
	dc.w	$4a01,$fffe
        dc.w    bplcon0,$4200
_part_swooshing_copspace4blit:
	dcb.l	20,$01fe01fe	; No-Op
	;;
	dc.w	$4a01+(IMAGE_BACKGROUND_FISH_height<<8),$fffe
	dc.w	bplcon0,$0200
_part_swooshing_copper_colours:
	dcb.l	16,$01fe01fe	; No-Op, 16 colours
	dc.w    $ffdf,$fffe     ; End of NTSC.
	dc.w	$ffff,$fffe
_part_swooshing_copper_list_end:
