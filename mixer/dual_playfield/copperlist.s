	include "hardware/custom.i"

	XDEF	_copperlist
	XDEF	_wait_for_mouse

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
	dc.w	bplpt,0
	dc.w	bplpt+2,0
	dc.w	bplpt+4,0
	dc.w	bplpt+6,0
	dc.w	bplpt+8,0
	dc.w	bplpt+10,0
	dc.w	bplpt+12,0
	dc.w	bplpt+14,0
	dc.w	bplpt+16,0
	dc.w	bplpt+18,0

	dc.l	$FFFFFFFE
