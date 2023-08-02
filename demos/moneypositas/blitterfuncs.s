	INCLUDE "hardware/custom.i"
	INCLUDE "hardware/intbits.i"
	INCLUDE "hardware/dmabits.i"
	INCLUDE "t7d/blitter.i"

	XDEF	_blit_single_plane
	XDEF	_blit_with_cc
; Blit a single plane with cookie cut
;
; Blit a single plane from the animation into the target plane. The
; cookie-cut mask is taken from the cookie pointer. No Masking is
; done.
;
; It is assumed that there are four bitplanes.
;
; INPUT
; A0 target pointer to the target area
; A1 src
; A2 cookie cut mask pointer
; D0.w animation width in bytes
; D1.w screen bitplane width in bytes
; D2.w animation height in bytes
_blit_single_plane:
	movem.l	d5-d6/a6,-(sp)
	move.w	d0,d5		; D5 animation width
	moveq	#0,d6		; D6 is ZERO
	lea.l	$DFF000,a6	; Custom base
	WAITBLITA6
	;; Four channels, D=AB+¬AC.
	move.w	#$0FCA,bltcon0(a6)
	;; No line drawing or other specialities.
	move.w	d6,bltcon1(a6)
	;; No masks.
	moveq	#-1,d0
	move.w	d0,bltafwm(a6)
	move.w	d0,bltalwm(a6)
	move.l	a2,bltapt(a6)
	move.l	a1,bltbpt(a6)
	move.l	a0,bltcpt(a6)
	move.l	a0,bltdpt(a6)
	move.l	d6,bltamod(a6)
	moveq	#3,d0
	mulu	d5,d0
	move.w	d0,bltbmod(a6)	; = animation width * 3
	;; (BPLWIDTH-ANMWIDTH) + BPLWIDTH*3;
	moveq	#3,d0
	mulu	d1,d0		; = bitplane width * 3
	add.w	d1,d0
	sub.w	d5,d0
	move.w	d0,bltcmod(a6)
	move.w	d0,bltdmod(a6)
	move.w	d5,d0
	lsr.w	#1,d0		; Animation width in words
	move.w	d2,d1
	lsl.w	#6,d1
	or.w	d1,d0
	move.w	d0,bltsize(a6)
	movem.l (sp)+,d5-d6/a6
	rts

; Blit a single plane with cookie cut, interleaved
;
; Blit a single plane from the animation into the destination plane. The
; cookie-cut mask is taken from the cookie pointer. No Masking is
; done.
;
; It is assumed that there are four bitplanes.
;
; INPUT
; A0 destination pointer to the destination area
; A1 src (last and additional bitplane is cookie-cut mask!)
; D0.w animation width in bytes
; D1.w screen bitplane width in bytes
; D2.w animation height in rows
; D3.w number of bitplanes (without cookie-cut mask)
_blit_with_cc:
	movem.l	d4-d6/a2/a6,-(sp)
	move.w	d1,d4		; D4 = destinatin screen width in bytes
	move.w	d0,d5		; D5 = animation width
	move.w	d0,d6
	mulu	d3,d6		; D6 = animation width * bitplanes (w/o ccm)
	move.l	a1,a2
	add.w	d6,a2		; A2 = cookie cut mask
	lea.l	$DFF000,a6	; Custom base
w1$:	btst.b	#6,dmaconr(a6)	; WAITBLIT
	bne.s	w1$
	;; Four channels, D=AB+¬AC.
	move.w	#$0FCA,bltcon0(a6)
	;; No line drawing or other specialities.
	clr.w	bltcon1(a6)
	;; No FW/LW masks.
	moveq	#-1,d0
	move.w	d0,bltafwm(a6)
	move.w	d0,bltalwm(a6)
	move.w	d6,bltamod(a6)
	move.w	d6,bltbmod(a6)
	;; (BPLWIDTH-ANMWIDTH) + BPLWIDTH*(NO of BPLS w/o cookie cut mask)
	move.w	d3,d0		; D0 = number of bitplanes
	mulu	d4,d0		; = bitplane width * (no bitplanes w/o ccm)
	sub.w	d5,d0
	move.w	d0,bltcmod(a6)
	move.w	d0,bltdmod(a6)
	move.w	d5,d0
	lsr.w	#1,d0		; Animation width in words
	move.w	d2,d1
	lsl.w	#6,d1
	or.w	d1,d0		; D0 = size of blitter operation
	move.w	d3,d1
	subq	#1,d1		; D1 = No of bitplanes to blit - 1
l1$:	btst.b	#6,dmaconr(a6)	; WAITBLIT
	bne.s	l1$
	move.l	a2,bltapt(a6)
	move.l	a1,bltbpt(a6)
	move.l	a0,bltcpt(a6)
	move.l	a0,bltdpt(a6)
	move.w	d0,bltsize(a6)
	add.w	d4,a0
	add.w	d5,a1
	dbf	d1,l1$
	movem.l (sp)+,d4-d6/a2/a6
	rts

;;;
