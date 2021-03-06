        INCLUDE "hardware/custom.i"
        INCLUDE "hardware/intbits.i"

	XREF	_long_sinusdat
	XDEF	_set_irq
	XDEF	_liberation_single_column_png
	XDEF	_draw_vline_fast
	XDEF	_full_sinus_scroll

	;; These must be the same es in the C-CODE
BPLWIDTH	EQU 320
BPLHEIGHT	EQU 256
BPLNO		EQU 1


	rsreset			; Define a structure
bplinfo_bitplanedata:	rs.l	2
bplinfo_bplidx:	rs.w	1
bplinfo_row_addresses_0:	rs.l	BPLHEIGHT
bplinfo_row_addresses_1:	rs.l	BPLHEIGHT
bplinfo_SIZEOF:	rs

	SECTION TEXT

;;; Set vertical blank.
;;; INPUT
;;; A0=pointer to function
_set_irq:
	movem.l	d0-a6,-(sp)
	move.l	a0,funcptr	; Store function to call.
	lea.l	$DFF000,a6	; Custom base
	lea.l	irqroutine(pc),a0
	move.l	a0,$6c.w	; Vertical blank
	move.w  #INTF_SETCLR|INTF_INTEN|INTF_VERTB,intena(a6)
	movem.l	(sp)+,d0-a6
	rts

irqroutine:
	movem.l	d0-a6,-(sp)
	move.l	funcptr(pc),a0
	jsr	(a0)
	;; Acknowledge interrupt!
	move.w  #INTF_VERTB,$DFF000+intreq
	movem.l	(sp)+,d0-a6
	rte

funcptr:	dc.l	-1

;;; Draw the vertical line but fast...
;;; Input
;;; A0=pointer to the Bitplaneinfo structure
;;; A1.w=pattern
;;; D0=x1
;;; D1=y1
_draw_vline_fast:
	movem.l	a6,-(sp)
	lea.l	$DFF000,a6	; Custom base
	move.w	a1,bltbdat(a6)	; Store the pattern.
	lea.l	bplinfo_row_addresses_0(a0),a1 ; Put row address pointer into A1
	tst.w	bplinfo_bplidx(a0) ; Are we in the 0th or 1st bitplane?
	beq.s	l1$
	lea.l	bplinfo_row_addresses_1(a0),a1 ; Advance to the secondary plane.
l1$:
	lsl.w	#2,d1		; Get index into the row table.
	move.l	(a1,d1.w),a1	; Get address into A1
	;; D1 now free
	move.w	d0,d1	      ; D1=x
	lsr.w	#3,d1		; Divide X-position by 8 to get the byte
	and.w	#$FFFE,d1	; Must be even.
	add.w	d1,a1		; Adjust plane pointer
	move.l	a1,bltcpt(a6)
	move.l	a1,bltdpt(a6)
	move.w	#$8000,bltadat(a6)
	ror.w	#4,d0		; Four right is equivalent to 12 left.
	and.w	#$F000,d0	; If the lower bits are removed.
	or.w	#$0bca,d0	; Channels and use an OR.
	move.w	d0,bltcon0(a6)
	move.w	#15*64+66,bltsize(a6) ; Start the blit.
	movem.l	(sp)+,a6
	rts

;;; Draw the sinus scroll -- but fast...
;;; Input
;;; A0=pointer to the Bitplaneinfo structure
;;; A1=pointer to the source area (this can even be in FAST RAM)
_full_sinus_scroll:
	;; A6=$DFF000
	;; A5=bitplaneinfo
	;; A4=sinus data ptr
	;; A3=source data ptr
	;; A2=row address array (ptr)
	;; D7=X coordinate (or running index)
	lea.l	$DFF000,a6
reg$:	REG	d2-d6/a2-a6
	movem.l	reg$,-(sp)
	moveq	#0,d7		; First column, set X to zero.
	move.l	a0,a5		; Save bitplaneinfo into A5
	lea.l	_long_sinusdat,a4
	lea.l	(a1),a3
	lea.l	bplinfo_row_addresses_0(a5),a2 ; Put row address pointer into A1
	tst.w	bplinfo_bplidx(a5) ; Are we in the 0th or 1st bitplane?
	beq.s	l1$
	lea.l	bplinfo_row_addresses_1(a5),a2 ; Advance to the secondary plane.
l1$:	
	move.l	a5,a0
	move.w	#$ffff,a1
	;; Calculate the sinus
	move.w	d7,d1		; D1=X
	lsl.w	#1,d1		; D1*=2
	add.w	phase$(pc),d1	; Add phase
	and.w	#4096-1,d1	; Length of table, DANGER!
	move.b	(a4,d1.w),d1	; sin()
	ext.w	d1		; Extend the sinus (in byte) to a word.
	add.w	#75,d1		; Center the sinus, now D1=Y
	move.w	(a3)+,bltbdat(a6)	; Store the pattern.
	lsl.w	#2,d1		; Get index into the row table.
	move.l	(a2,d1.w),a1	; Get address into A1
	move.w	d7,d1		; D1=x
	lsr.w	#3,d1		; Divide X-position by 8 to get the byte
	and.w	#$FFFE,d1	; Must be even.
	add.w	d1,a1		; Adjust plane pointer
	move.l	a1,bltcpt(a6)
	move.l	a1,bltdpt(a6)
	move.w	#$8000,bltadat(a6)
	move.w	d7,d0		; D0=X
	ror.w	#4,d0		; Four right is equivalent to 12 left.
	and.w	#$F000,d0	; If the lower bits are removed.
	or.w	#$0bca,d0	; Channels and use an OR.
	move.w	d0,bltcon0(a6)
	move.w	#15*64+66,bltsize(a6) ; Start the blit.
	addq	#1,d7
	cmp.w	#319,d7
	ble.s	l1$
	add.w	#17,phase$
	movem.l	(sp)+,reg$
	rts
phase$:	dc.w	0


	SECTION DATA,DATA
_liberation_single_column_png:
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$67, $fe
	DC.B	$60, $1e
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $7c
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $04
	DC.B	$00, $7c
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$02, $20
	DC.B	$7e, $20
	DC.B	$03, $f0
	DC.B	$02, $2e
	DC.B	$02, $20
	DC.B	$7e, $20
	DC.B	$03, $f0
	DC.B	$02, $2e
	DC.B	$02, $20
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$38, $10
	DC.B	$60, $7c
	DC.B	$40, $e6
	DC.B	$40, $c2
	DC.B	$ff, $ff
	DC.B	$41, $82
	DC.B	$63, $82
	DC.B	$3f, $0e
	DC.B	$0c, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $7c
	DC.B	$00, $7e
	DC.B	$00, $82
	DC.B	$40, $82
	DC.B	$30, $c6
	DC.B	$08, $7c
	DC.B	$06, $00
	DC.B	$01, $00
	DC.B	$00, $c0
	DC.B	$3e, $20
	DC.B	$73, $18
	DC.B	$40, $86
	DC.B	$40, $82
	DC.B	$61, $80
	DC.B	$3f, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$1e, $00
	DC.B	$3f, $00
	DC.B	$61, $3c
	DC.B	$40, $fe
	DC.B	$40, $c2
	DC.B	$41, $c2
	DC.B	$43, $42
	DC.B	$46, $3e
	DC.B	$2c, $1c
	DC.B	$18, $00
	DC.B	$3e, $00
	DC.B	$63, $80
	DC.B	$40, $80
	DC.B	$40, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $1c
	DC.B	$00, $7c
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$07, $f0
	DC.B	$3f, $fc
	DC.B	$70, $06
	DC.B	$80, $01
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$80, $01
	DC.B	$60, $02
	DC.B	$3f, $fe
	DC.B	$0f, $f8
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$06, $60
	DC.B	$06, $60
	DC.B	$02, $c0
	DC.B	$01, $80
	DC.B	$1f, $f8
	DC.B	$1f, $f8
	DC.B	$01, $80
	DC.B	$03, $c0
	DC.B	$06, $60
	DC.B	$06, $60
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$01, $00
	DC.B	$01, $00
	DC.B	$01, $00
	DC.B	$01, $00
	DC.B	$1f, $f0
	DC.B	$03, $00
	DC.B	$01, $00
	DC.B	$01, $00
	DC.B	$01, $00
	DC.B	$01, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$98, $00
	DC.B	$78, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$03, $00
	DC.B	$03, $00
	DC.B	$03, $00
	DC.B	$03, $00
	DC.B	$03, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$18, $00
	DC.B	$18, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $00
	DC.B	$38, $00
	DC.B	$07, $00
	DC.B	$00, $e0
	DC.B	$00, $1c
	DC.B	$00, $02
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$0f, $f0
	DC.B	$3f, $fc
	DC.B	$60, $06
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$38, $0c
	DC.B	$1f, $f8
	DC.B	$07, $f0
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $08
	DC.B	$40, $04
	DC.B	$40, $04
	DC.B	$7f, $fe
	DC.B	$40, $00
	DC.B	$40, $00
	DC.B	$40, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$60, $00
	DC.B	$70, $06
	DC.B	$68, $02
	DC.B	$6c, $02
	DC.B	$66, $02
	DC.B	$63, $06
	DC.B	$61, $fc
	DC.B	$60, $78
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$30, $00
	DC.B	$60, $06
	DC.B	$40, $02
	DC.B	$40, $82
	DC.B	$40, $82
	DC.B	$40, $c2
	DC.B	$21, $7c
	DC.B	$3f, $38
	DC.B	$0c, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$0c, $00
	DC.B	$0b, $00
	DC.B	$08, $80
	DC.B	$08, $60
	DC.B	$08, $10
	DC.B	$1c, $8c
	DC.B	$7f, $fe
	DC.B	$08, $00
	DC.B	$08, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$60, $fe
	DC.B	$40, $86
	DC.B	$40, $86
	DC.B	$40, $86
	DC.B	$40, $86
	DC.B	$21, $86
	DC.B	$3f, $02
	DC.B	$04, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$07, $e0
	DC.B	$1f, $f8
	DC.B	$30, $0c
	DC.B	$40, $42
	DC.B	$40, $42
	DC.B	$40, $42
	DC.B	$60, $c2
	DC.B	$3f, $86
	DC.B	$0f, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $06
	DC.B	$60, $06
	DC.B	$38, $06
	DC.B	$06, $06
	DC.B	$01, $86
	DC.B	$00, $66
	DC.B	$00, $1e
	DC.B	$00, $02
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$1e, $00
	DC.B	$3f, $7c
	DC.B	$41, $c6
	DC.B	$40, $82
	DC.B	$40, $82
	DC.B	$40, $82
	DC.B	$61, $fe
	DC.B	$3f, $3c
	DC.B	$0c, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$20, $78
	DC.B	$60, $fc
	DC.B	$41, $86
	DC.B	$41, $02
	DC.B	$41, $02
	DC.B	$61, $02
	DC.B	$3d, $9c
	DC.B	$1f, $f8
	DC.B	$00, $80
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$18, $18
	DC.B	$18, $18
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$98, $18
	DC.B	$78, $18
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$03, $00
	DC.B	$03, $00
	DC.B	$04, $80
	DC.B	$04, $80
	DC.B	$08, $40
	DC.B	$08, $60
	DC.B	$10, $20
	DC.B	$10, $10
	DC.B	$20, $10
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$04, $40
	DC.B	$04, $40
	DC.B	$04, $40
	DC.B	$04, $40
	DC.B	$04, $40
	DC.B	$04, $40
	DC.B	$04, $40
	DC.B	$04, $40
	DC.B	$04, $40
	DC.B	$04, $40
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$20, $10
	DC.B	$10, $10
	DC.B	$10, $20
	DC.B	$08, $60
	DC.B	$08, $40
	DC.B	$04, $80
	DC.B	$04, $80
	DC.B	$03, $00
	DC.B	$03, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $0c
	DC.B	$00, $02
	DC.B	$60, $02
	DC.B	$67, $02
	DC.B	$00, $82
	DC.B	$00, $ce
	DC.B	$00, $7c
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$07, $c0
	DC.B	$1c, $30
	DC.B	$20, $0c
	DC.B	$20, $02
	DC.B	$47, $e2
	DC.B	$44, $11
	DC.B	$42, $09
	DC.B	$47, $09
	DC.B	$44, $f9
	DC.B	$24, $01
	DC.B	$02, $01
	DC.B	$01, $02
	DC.B	$00, $fc
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $00
	DC.B	$60, $00
	DC.B	$5c, $00
	DC.B	$43, $80
	DC.B	$02, $70
	DC.B	$02, $0e
	DC.B	$02, $0e
	DC.B	$02, $7e
	DC.B	$43, $f0
	DC.B	$5f, $80
	DC.B	$7c, $00
	DC.B	$60, $00
	DC.B	$40, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$7f, $fe
	DC.B	$40, $82
	DC.B	$40, $82
	DC.B	$40, $82
	DC.B	$40, $82
	DC.B	$40, $82
	DC.B	$41, $e6
	DC.B	$33, $7c
	DC.B	$3f, $18
	DC.B	$0c, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$07, $e0
	DC.B	$1f, $f8
	DC.B	$38, $1c
	DC.B	$20, $04
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$60, $06
	DC.B	$30, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$7f, $fe
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $06
	DC.B	$20, $0c
	DC.B	$38, $1c
	DC.B	$1f, $f8
	DC.B	$07, $e0
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$7f, $fe
	DC.B	$40, $82
	DC.B	$40, $82
	DC.B	$40, $82
	DC.B	$40, $82
	DC.B	$43, $c2
	DC.B	$40, $02
	DC.B	$60, $0e
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$7f, $fe
	DC.B	$41, $02
	DC.B	$41, $02
	DC.B	$01, $02
	DC.B	$01, $02
	DC.B	$03, $82
	DC.B	$00, $02
	DC.B	$00, $0e
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$07, $e0
	DC.B	$1f, $f8
	DC.B	$38, $1c
	DC.B	$20, $04
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$42, $02
	DC.B	$3e, $06
	DC.B	$3e, $0c
	DC.B	$02, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$7f, $fe
	DC.B	$40, $82
	DC.B	$40, $82
	DC.B	$00, $80
	DC.B	$00, $80
	DC.B	$00, $80
	DC.B	$40, $82
	DC.B	$40, $82
	DC.B	$7f, $fe
	DC.B	$7f, $fe
	DC.B	$40, $02
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$7f, $fe
	DC.B	$7f, $fe
	DC.B	$40, $02
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$60, $00
	DC.B	$40, $00
	DC.B	$40, $02
	DC.B	$3f, $fe
	DC.B	$1f, $fe
	DC.B	$00, $02
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$7f, $fe
	DC.B	$43, $02
	DC.B	$41, $82
	DC.B	$00, $c0
	DC.B	$03, $e0
	DC.B	$07, $30
	DC.B	$0e, $08
	DC.B	$38, $06
	DC.B	$70, $02
	DC.B	$60, $02
	DC.B	$40, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$7f, $fe
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $00
	DC.B	$40, $00
	DC.B	$40, $00
	DC.B	$40, $00
	DC.B	$70, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$7f, $fe
	DC.B	$40, $1e
	DC.B	$00, $f8
	DC.B	$03, $e0
	DC.B	$1f, $00
	DC.B	$7c, $00
	DC.B	$18, $00
	DC.B	$06, $00
	DC.B	$01, $c0
	DC.B	$00, $30
	DC.B	$40, $0c
	DC.B	$7f, $fe
	DC.B	$7f, $fe
	DC.B	$40, $02
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$7f, $fe
	DC.B	$40, $0e
	DC.B	$00, $1c
	DC.B	$00, $78
	DC.B	$00, $e0
	DC.B	$03, $80
	DC.B	$0f, $00
	DC.B	$1c, $02
	DC.B	$7c, $02
	DC.B	$7f, $fe
	DC.B	$00, $02
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$07, $e0
	DC.B	$1f, $f8
	DC.B	$38, $1c
	DC.B	$20, $04
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$20, $04
	DC.B	$38, $1c
	DC.B	$1f, $f8
	DC.B	$07, $e0
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$7f, $fe
	DC.B	$42, $02
	DC.B	$42, $02
	DC.B	$02, $02
	DC.B	$03, $02
	DC.B	$01, $8c
	DC.B	$01, $fc
	DC.B	$00, $70
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$07, $e0
	DC.B	$1f, $f8
	DC.B	$38, $1c
	DC.B	$20, $04
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$48, $02
	DC.B	$58, $02
	DC.B	$f0, $02
	DC.B	$e0, $04
	DC.B	$b8, $1c
	DC.B	$9f, $f8
	DC.B	$47, $e0
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$7f, $fe
	DC.B	$41, $02
	DC.B	$41, $02
	DC.B	$01, $02
	DC.B	$03, $02
	DC.B	$0f, $86
	DC.B	$1c, $fc
	DC.B	$70, $7c
	DC.B	$60, $00
	DC.B	$40, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$70, $7c
	DC.B	$40, $e4
	DC.B	$40, $c2
	DC.B	$41, $c2
	DC.B	$41, $82
	DC.B	$41, $82
	DC.B	$37, $06
	DC.B	$1e, $0c
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $06
	DC.B	$00, $02
	DC.B	$00, $02
	DC.B	$40, $02
	DC.B	$7f, $fe
	DC.B	$7f, $fe
	DC.B	$40, $02
	DC.B	$40, $02
	DC.B	$00, $02
	DC.B	$00, $02
	DC.B	$00, $0e
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $02
	DC.B	$07, $fe
	DC.B	$1f, $fe
	DC.B	$30, $02
	DC.B	$60, $02
	DC.B	$40, $00
	DC.B	$40, $00
	DC.B	$40, $00
	DC.B	$40, $00
	DC.B	$20, $02
	DC.B	$38, $02
	DC.B	$0f, $fe
	DC.B	$00, $02
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $02
	DC.B	$00, $06
	DC.B	$00, $1e
	DC.B	$00, $fa
	DC.B	$03, $e2
	DC.B	$1f, $00
	DC.B	$7c, $00
	DC.B	$18, $00
	DC.B	$07, $00
	DC.B	$00, $c0
	DC.B	$00, $3a
	DC.B	$00, $06
	DC.B	$00, $02
	DC.B	$00, $02
	DC.B	$00, $00
	DC.B	$00, $1e
	DC.B	$00, $fe
	DC.B	$07, $e2
	DC.B	$3f, $00
	DC.B	$78, $00
	DC.B	$0e, $00
	DC.B	$01, $c0
	DC.B	$00, $70
	DC.B	$00, $7c
	DC.B	$03, $e0
	DC.B	$1f, $00
	DC.B	$7c, $00
	DC.B	$1c, $00
	DC.B	$03, $c2
	DC.B	$00, $7a
	DC.B	$00, $06
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $00
	DC.B	$40, $02
	DC.B	$70, $06
	DC.B	$58, $0e
	DC.B	$04, $3e
	DC.B	$03, $f0
	DC.B	$01, $c0
	DC.B	$07, $e0
	DC.B	$4e, $30
	DC.B	$7c, $0e
	DC.B	$70, $06
	DC.B	$40, $02
	DC.B	$40, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $02
	DC.B	$00, $06
	DC.B	$00, $0e
	DC.B	$00, $3e
	DC.B	$40, $f2
	DC.B	$41, $c0
	DC.B	$7f, $80
	DC.B	$7f, $00
	DC.B	$40, $c0
	DC.B	$00, $32
	DC.B	$00, $0e
	DC.B	$00, $02
	DC.B	$00, $02
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$40, $00
	DC.B	$70, $0e
	DC.B	$7c, $02
	DC.B	$4e, $02
	DC.B	$47, $82
	DC.B	$41, $e2
	DC.B	$40, $72
	DC.B	$40, $3e
	DC.B	$40, $0e
	DC.B	$70, $02
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$7f, $ff
	DC.B	$c0, $01
	DC.B	$80, $01
	DC.B	$00, $01
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $02
	DC.B	$00, $1c
	DC.B	$00, $e0
	DC.B	$07, $00
	DC.B	$38, $00
	DC.B	$40, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $01
	DC.B	$80, $01
	DC.B	$80, $01
	DC.B	$ff, $ff
	DC.B	$7f, $ff
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$01, $80
	DC.B	$00, $f0
	DC.B	$00, $0c
	DC.B	$00, $03
	DC.B	$00, $03
	DC.B	$00, $0c
	DC.B	$00, $70
	DC.B	$01, $80
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$80, $00
	DC.B	$c0, $00
	DC.B	$c0, $00
	DC.B	$c0, $00
	DC.B	$c0, $00
	DC.B	$c0, $00
	DC.B	$c0, $00
	DC.B	$c0, $00
	DC.B	$c0, $00
	DC.B	$80, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$03, $80
	DC.B	$00, $c0
	DC.B	$00, $40
	DC.B	$00, $c0
	DC.B	$01, $80
	DC.B	$01, $00
	DC.B	$02, $00
	DC.B	$02, $00
	DC.B	$01, $80
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
	DC.B	$00, $00
