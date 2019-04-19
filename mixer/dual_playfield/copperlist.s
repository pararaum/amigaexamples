	include "hardware/custom.i"

	XDEF	_copperlist
	XDEF	_copperlist_colors
	XDEF	_copperlist_blit_a_ptr
	XDEF	_copperlist_blit_d_ptr
	XDEF	_copperlist_blit_modulos
	XDEF	_copperlist_blit_size
	XDEF	_wait_for_mouse

	MACRO	COPPERNOP
	dc.w	$01FE,"no"
	ENDM

	SECTION CODE,code
;;; Wait for mouse button.
;;; Destroys: A0
_wait_for_mouse:
        lea     $BFE001,a0              ;CIA A
l$:     btst    #6,(a0)
        bne.b   l$
        rts

	SECTION	CHIP,data_c

_copperlist:
	;; First odd then even bitplanes.
	;; ODD
	dc.w	bplpt,0
	dc.w	bplpt+2,0
	dc.w	bplpt+8,0
	dc.w	bplpt+10,0
	dc.w	bplpt+16,0
	dc.w	bplpt+18,0
	;; EVEN
	dc.w	bplpt+4,0
	dc.w	bplpt+6,0
	dc.w	bplpt+12,0
	dc.w	bplpt+14,0
	COPPERNOP
_copperlist_bplcon_top:
	dc.w	bplcon0,(1<<9)|(1<<10)|$5000
_copperlist_colors:
	dc.w	color+0,$0000
	dc.w	color+2,$0010
	dc.w	color+4,$0020
	dc.w	color+6,$0030
	dc.w	color+8,$0040
	dc.w	color+$a,$0050
	dc.w	color+$c,$0060
	dc.w	color+$e,$0070
	dc.w	color+$10,$0080	; Playfield 2 transparent
	dc.w	color+$12,$0AAA
	dc.w	color+$14,$0DDD
	dc.w	color+$16,$0FEF
	dc.w	color+$18,$00c0
	dc.w	color+$1a,$00d0
	dc.w	color+$1c,$00e0
	dc.w	color+$1e,$00f0
	;; Wait for blitter!
	dc.w	$0007,$7ffe
	;; Blitter activity!
	dc.w	bltcon0,$39f0
	dc.w	bltcon1,$0002
	dc.w	bltafwm,$ffff	;First word mask
	dc.w	bltalwm,$ffff	;Last word mask
_copperlist_blit_a_ptr:
	dc.w	bltapt,0
	dc.w	bltapt+2,0
_copperlist_blit_d_ptr:
	dc.w	bltdpt,0
	dc.w	bltdpt+2,0
_copperlist_blit_modulos:
	dc.w	bltamod,0
	dc.w	bltdmod,0
_copperlist_blit_size:
	;; H9-H0, W5-W0. Width is in words.
	dc.w	bltsize,((2*200)<<6)|(320/16)
	;; Wait for blitter!.
	dc.w	$0007,$7ffe
	;; The display window starts at $2c and we have got 200 lines. Therefore the end of the bitplanes should be at ❨(format "$%x" (+ #x2c 200))"$f4"❩ line $f4.
	dc.w	$f401,$fffe
	;; Disable bitplane dma
	dc.w	bplcon0,(1<<9)
	dc.l	$FFFFFFFE
