;;; Very primitive font subroutines.

	XDEF	draw_string
	XDEF	draw_character
	XDEF	draw_uint32_number

	section	framework,code
;;; Draw an uint32 into a single bitplane.
;;; Input
;;; A0: bitplane pointer
;;; D0.w: bitplane width
;;; D1.l: Number
draw_uint32_number:
	;; D7: copy of uint32 number
	;; D6: nibble number
	;; D5: bitplane width in bytes
	;; A6: old stack pointer
	movem.l	d5-d7/a6,-(sp)
	link	a6,#-10
	move.l	a0,a1		;Store bitplane pointer into A1 (for string draw function).
	move.l	d1,d7		;Save number into D7
	move.l	d0,d5		;Store bitplane width in d5.
	moveq	#8-1,d6		;8 nibbles to calculate
l54$:	move.l	d7,d0		;Copy current value into D0
	and.w	#$0f,d0		;Mask lowest nibble
	add.w	#'0',d0		;0 to '0', 1 to '1', etc.
	cmp.w	#'9',d0		;Larger then a '9'?
	ble.s	nbr$		;No
	add.w	#'A'-'9'-1,d0	;Yes, make 10 to an 'A', 11 to a 'B', etc.
nbr$:	move.b	d0,(a7,d6.w*1)	;Store nibble character into string space.
	lsr.l	#4,d7		;Move used nibble out.
	dbf	d6,l54$		;Loop until all nibbles converted.
	move.b	#$00,8(a7)	;Add a zero (for string end).
	;; A1 has bitplane pointer
	move.w	d5,d0		;Width of bitplane in bytes
	move.l	a7,a0		;Pointer to string.
	bsr	draw_string
	unlk	a6
	movem.l	(sp)+,d5-d7/a6
	rts


;;; Draw a string into a single bitplane.
;;; Input:
;;; A0: pointer to the string (null terminated)
;;; A1: pointer to the bitplane byte where the string will be displayed.
;;; d0.w: width of bitplane in bytes
draw_string:
	;; A2: String pointer
	;; A3: bitplane byte
	movem.l	a2-a3,-(sp)
	move.l	a0,a2
	move.l	a1,a3
	move.w	d0,d1		;Move width into D1, user by draw character
loop$:	move.b	(a2)+,d0	;Get next chracter
	beq.s	out$		;Null? Then exit.
	move.l	a3,a0		;Bitplane pointer to write character to.
	bsr	draw_character
	addq.l	#1,a3		;Move one byte further to the right.
	bra.s	loop$
out$:	movem.l	(sp)+,a2-a3
	rts


;;; ------------------------------------------------------------------
;;; Draw a character into a single bitplane.
;;; Input:
;;; A0: pointer to the bitplane byte where the character will be displayed.
;;; D0.b: character
;;; D1.w: width in bytes
;;; Output: None
;;; Destroys: A0,A1,D0;
;;; D1 is left intact!
draw_character:
	lea.l	small_font_data(pc),a1
	and.w	#$00ff,d0
	sub.w	#$20,d0
	mulu	#13,d0		;multiply by Font height
	add.l	d0,a1		;Now points to the first byte of the character
	moveq	#13-1,d0
l1$:	move.b	(a1)+,(a0)
	add.w	d1,a0
	dbf	d0,l1$
	rts

	;; We keep it in the same segment so that relative addressing works.
small_font_data:
	dc.b   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	dc.b   $ff, $ff, $ff, $df, $df, $df, $df, $df, $df, $df, $ff, $df
	dc.b   $ff, $ff, $ff, $ff, $af, $af, $af, $ff, $ff, $ff, $ff, $ff
	dc.b   $ff, $ff, $ff, $ff, $ff, $ff, $af, $af, $07, $af, $07, $af
	dc.b   $af, $ff, $ff, $ff, $ff, $ff, $df, $87, $5f, $5f, $8f, $d7
	dc.b   $d7, $0f, $df, $ff, $ff, $ff, $ff, $b7, $57, $af, $ef, $df
	dc.b   $bf, $af, $57, $6f, $ff, $ff, $ff, $ff, $bf, $5f, $5f, $bf
	dc.b   $5f, $67, $6f, $97, $ff, $ff, $ff, $ff, $ff, $cf, $df, $bf
	dc.b   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ef, $df
	dc.b   $df, $bf, $bf, $bf, $df, $df, $ef, $ff, $ff, $ff, $ff, $bf
	dc.b   $df, $df, $ef, $ef, $ef, $df, $df, $bf, $ff, $ff, $ff, $ff
	dc.b   $ff, $df, $57, $07, $8f, $07, $57, $df, $ff, $ff, $ff, $ff
	dc.b   $ff, $ff, $ff, $df, $df, $07, $df, $df, $ff, $ff, $ff, $ff
	dc.b   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $cf, $df, $bf
	dc.b   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $07, $ff, $ff, $ff, $ff
	dc.b   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $df
	dc.b   $8f, $df, $ff, $ff, $ff, $f7, $f7, $ef, $ef, $df, $bf, $bf
	dc.b   $7f, $7f, $ff, $ff, $ff, $ff, $df, $af, $77, $77, $77, $77
	dc.b   $77, $af, $df, $ff, $ff, $ff, $ff, $df, $9f, $5f, $df, $df
	dc.b   $df, $df, $df, $07, $ff, $ff, $ff, $ff, $8f, $77, $77, $f7
	dc.b   $ef, $df, $bf, $7f, $07, $ff, $ff, $ff, $ff, $07, $f7, $ef
	dc.b   $df, $8f, $f7, $f7, $77, $8f, $ff, $ff, $ff, $ff, $ef, $ef
	dc.b   $cf, $af, $af, $6f, $07, $ef, $ef, $ff, $ff, $ff, $ff, $07
	dc.b   $7f, $7f, $4f, $37, $f7, $f7, $77, $8f, $ff, $ff, $ff, $ff
	dc.b   $8f, $77, $7f, $7f, $0f, $77, $77, $77, $8f, $ff, $ff, $ff
	dc.b   $ff, $07, $f7, $ef, $ef, $df, $df, $bf, $bf, $bf, $ff, $ff
	dc.b   $ff, $ff, $8f, $77, $77, $77, $8f, $77, $77, $77, $8f, $ff
	dc.b   $ff, $ff, $ff, $8f, $77, $77, $77, $87, $f7, $f7, $77, $8f
	dc.b   $ff, $ff, $ff, $ff, $ff, $ff, $df, $8f, $df, $ff, $ff, $df
	dc.b   $8f, $df, $ff, $ff, $ff, $ff, $ff, $df, $8f, $df, $ff, $ff
	dc.b   $cf, $df, $bf, $ff, $ff, $ff, $f7, $ef, $df, $bf, $7f, $bf
	dc.b   $df, $ef, $f7, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $07, $ff
	dc.b   $ff, $07, $ff, $ff, $ff, $ff, $ff, $ff, $7f, $bf, $df, $ef
	dc.b   $f7, $ef, $df, $bf, $7f, $ff, $ff, $ff, $ff, $8f, $77, $77
	dc.b   $f7, $ef, $df, $df, $ff, $df, $ff, $ff, $ff, $ff, $8f, $77
	dc.b   $77, $67, $57, $57, $4f, $7f, $87, $ff, $ff, $ff, $ff, $df
	dc.b   $af, $77, $77, $77, $07, $77, $77, $77, $ff, $ff, $ff, $ff
	dc.b   $0f, $b7, $b7, $b7, $8f, $b7, $b7, $b7, $0f, $ff, $ff, $ff
	dc.b   $ff, $8f, $77, $7f, $7f, $7f, $7f, $7f, $77, $8f, $ff, $ff
	dc.b   $ff, $ff, $0f, $b7, $b7, $b7, $b7, $b7, $b7, $b7, $0f, $ff
	dc.b   $ff, $ff, $ff, $07, $7f, $7f, $7f, $0f, $7f, $7f, $7f, $07
	dc.b   $ff, $ff, $ff, $ff, $07, $7f, $7f, $7f, $0f, $7f, $7f, $7f
	dc.b   $7f, $ff, $ff, $ff, $ff, $8f, $77, $7f, $7f, $7f, $67, $77
	dc.b   $77, $8f, $ff, $ff, $ff, $ff, $77, $77, $77, $77, $07, $77
	dc.b   $77, $77, $77, $ff, $ff, $ff, $ff, $8f, $df, $df, $df, $df
	dc.b   $df, $df, $df, $8f, $ff, $ff, $ff, $ff, $c7, $ef, $ef, $ef
	dc.b   $ef, $ef, $ef, $6f, $9f, $ff, $ff, $ff, $ff, $77, $77, $6f
	dc.b   $5f, $3f, $5f, $6f, $77, $77, $ff, $ff, $ff, $ff, $7f, $7f
	dc.b   $7f, $7f, $7f, $7f, $7f, $7f, $07, $ff, $ff, $ff, $ff, $77
	dc.b   $77, $27, $57, $57, $77, $77, $77, $77, $ff, $ff, $ff, $ff
	dc.b   $77, $37, $37, $57, $57, $67, $67, $77, $77, $ff, $ff, $ff
	dc.b   $ff, $8f, $77, $77, $77, $77, $77, $77, $77, $8f, $ff, $ff
	dc.b   $ff, $ff, $0f, $77, $77, $77, $0f, $7f, $7f, $7f, $7f, $ff
	dc.b   $ff, $ff, $ff, $8f, $77, $77, $77, $77, $77, $77, $57, $8f
	dc.b   $f7, $ff, $ff, $ff, $0f, $77, $77, $77, $0f, $5f, $6f, $77
	dc.b   $77, $ff, $ff, $ff, $ff, $8f, $77, $7f, $7f, $8f, $f7, $f7
	dc.b   $77, $8f, $ff, $ff, $ff, $ff, $07, $df, $df, $df, $df, $df
	dc.b   $df, $df, $df, $ff, $ff, $ff, $ff, $77, $77, $77, $77, $77
	dc.b   $77, $77, $77, $8f, $ff, $ff, $ff, $ff, $77, $77, $77, $77
	dc.b   $af, $af, $af, $df, $df, $ff, $ff, $ff, $ff, $77, $77, $77
	dc.b   $77, $57, $57, $57, $27, $77, $ff, $ff, $ff, $ff, $77, $77
	dc.b   $af, $af, $df, $af, $af, $77, $77, $ff, $ff, $ff, $ff, $77
	dc.b   $77, $af, $af, $df, $df, $df, $df, $df, $ff, $ff, $ff, $ff
	dc.b   $07, $f7, $ef, $ef, $df, $bf, $bf, $7f, $07, $ff, $ff, $ff
	dc.b   $ff, $8f, $bf, $bf, $bf, $bf, $bf, $bf, $bf, $8f, $ff, $ff
	dc.b   $ff, $ff, $7f, $7f, $bf, $bf, $df, $ef, $ef, $f7, $f7, $ff
	dc.b   $ff, $ff, $ff, $8f, $ef, $ef, $ef, $ef, $ef, $ef, $ef, $8f
	dc.b   $ff, $ff, $ff, $ff, $df, $af, $77, $ff, $ff, $ff, $ff, $ff
	dc.b   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	dc.b   $ff, $ff, $07, $ff, $ff, $ff, $cf, $ef, $f7, $ff, $ff, $ff
	dc.b   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $8f, $f7
	dc.b   $87, $77, $77, $87, $ff, $ff, $ff, $ff, $7f, $7f, $7f, $0f
	dc.b   $77, $77, $77, $77, $0f, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	dc.b   $8f, $77, $7f, $7f, $77, $8f, $ff, $ff, $ff, $ff, $f7, $f7
	dc.b   $f7, $87, $77, $77, $77, $77, $87, $ff, $ff, $ff, $ff, $ff
	dc.b   $ff, $ff, $8f, $77, $07, $7f, $77, $8f, $ff, $ff, $ff, $ff
	dc.b   $cf, $b7, $bf, $bf, $0f, $bf, $bf, $bf, $bf, $ff, $ff, $ff
	dc.b   $ff, $ff, $ff, $ff, $8f, $77, $77, $77, $87, $f7, $77, $8f
	dc.b   $ff, $ff, $7f, $7f, $7f, $4f, $37, $77, $77, $77, $77, $ff
	dc.b   $ff, $ff, $ff, $ff, $df, $ff, $9f, $df, $df, $df, $df, $8f
	dc.b   $ff, $ff, $ff, $ff, $ff, $ef, $ff, $cf, $ef, $ef, $ef, $ef
	dc.b   $6f, $6f, $9f, $ff, $ff, $7f, $7f, $7f, $6f, $5f, $3f, $5f
	dc.b   $6f, $77, $ff, $ff, $ff, $ff, $9f, $df, $df, $df, $df, $df
	dc.b   $df, $df, $8f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $2f, $57
	dc.b   $57, $57, $57, $77, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $4f
	dc.b   $37, $77, $77, $77, $77, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	dc.b   $8f, $77, $77, $77, $77, $8f, $ff, $ff, $ff, $ff, $ff, $ff
	dc.b   $ff, $0f, $77, $77, $77, $0f, $7f, $7f, $7f, $ff, $ff, $ff
	dc.b   $ff, $ff, $87, $77, $77, $77, $87, $f7, $f7, $f7, $ff, $ff
	dc.b   $ff, $ff, $ff, $4f, $37, $7f, $7f, $7f, $7f, $ff, $ff, $ff
	dc.b   $ff, $ff, $ff, $ff, $8f, $77, $9f, $ef, $77, $8f, $ff, $ff
	dc.b   $ff, $ff, $ff, $bf, $bf, $0f, $bf, $bf, $bf, $b7, $cf, $ff
	dc.b   $ff, $ff, $ff, $ff, $ff, $ff, $77, $77, $77, $77, $67, $97
	dc.b   $ff, $ff, $ff, $ff, $ff, $ff, $ff, $77, $77, $77, $af, $af
	dc.b   $df, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $77, $77, $57, $57
	dc.b   $57, $af, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $77, $af, $df
	dc.b   $df, $af, $77, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $77, $77
	dc.b   $77, $67, $97, $f7, $77, $8f, $ff, $ff, $ff, $ff, $ff, $07
	dc.b   $ef, $df, $bf, $7f, $07, $ff, $ff, $ff, $ff, $e7, $df, $df
	dc.b   $df, $3f, $df, $df, $df, $e7, $ff, $ff, $ff, $ff, $df, $df
	dc.b   $df, $df, $df, $df, $df, $df, $df, $ff, $ff, $ff, $ff, $3f
	dc.b   $df, $df, $df, $e7, $df, $df, $df, $3f, $ff, $ff, $ff, $ff
	dc.b   $b7, $57, $6f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $0a


