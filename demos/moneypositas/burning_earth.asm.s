	INCLUDE "hardware/custom.i"
	INCLUDE "hardware/intbits.i"
	INCLUDE "hardware/dmabits.i"

	XDEF	_copperlist_burning
	XDEF	_coltopoffset
	XDEF	_colbottomoffset

BURNING_WIDTH SET 320
BURNING_BPLNOS SET 5
TEXTPLANE_HEIGHT SET 56
	
;;; Stack: return address, dest, bitplanes, textplane
_copperlist_burning:
reg$	reg	 d2-d7/a2-a6	; 6+5 registers
	movem.l	reg$,-(sp)
	lea.l	cop5bpl,a1
	move.l	(6+5)*4+8(a7),d0	; Bitplanes
	moveq	#BURNING_BPLNOS-1,d1
l1$:	move.w	d0,6(a1)
	swap	d0
	move.w	d0,2(a1)
	swap	d0
	add.l	#320/8,d0
	lea	8(a1),a1
	dbf	d1,l1$
	lea.l	coptext,a1
	move.l	(6+5)*4+12(a7),d0 ; Textplane
	move.w	d0,6(a1)
	swap	d0
	move.w	d0,2(a1)
	move.l	#end_of_copperlist-cop5bpl-1,d0
	lea.l	cop5bpl,a0
	move.l	(6+5)*4+4(a7),a1 ; destination
cpl$:	move.b	(a0)+,(a1)+
	dbf	d0,cpl$
	move.l	(6+5)*4+12(a7),a0 ; Textplane
	bsr	clear
	move.l	#end_of_copperlist-cop5bpl,d0
	movem.l	(sp)+,reg$
	rts

clear:	moveq	#0,d0
	move.w	#(BURNING_WIDTH*TEXTPLANE_HEIGHT/8/4)-1,d1
l1$:	move.l	d0,(a0)+
	dbf	d1,l1$
	rts

	section	data,data

_coltopoffset:	dc.w	col01top-cop5bpl
_colbottomoffset:	dc.w	col01bottom-cop5bpl

cop5bpl:
	dc.w	bplpt+0, 0, bplpt+2, 0
	dc.w	bplpt+4, 0, bplpt+6, 0
	dc.w	bplpt+8, 0, bplpt+10, 0
	dc.w	bplpt+12, 0, bplpt+14, 0
	dc.w	bplpt+16, 0, bplpt+18, 0
	dc.w	$182
col01top:
	dc.w	$0
	dc.w	bpl1mod,BURNING_WIDTH/8*(BURNING_BPLNOS-1);
	dc.w	bpl2mod,BURNING_WIDTH/8*(BURNING_BPLNOS-1);
	dc.w	bplcon0, $5200
	dc.w	$f401, $fffe
coptext:
	dc.w	bplpt, 0, bplpt+2, 0
	dc.w	$182
col01bottom:
	dc.w	$0
	dc.w	bplcon0, $1200
	dc.w	bpl1mod,0
	dc.l	$fffffffe
end_of_copperlist:

