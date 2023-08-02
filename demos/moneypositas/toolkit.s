
	XDEF	_copy_modulo_cpu

;;; Copy block with modulo from src to dest.
;;; Input
;;;  * +0 PTR destination
;;;  * +4 PTR source
;;;  * +8 destination width in words
;;;  * +12 source width in words
;;;  * +16 number of lines
_copy_modulo_cpu:
	movem.l	d2-d3,-(sp)
	;; Stack Return address + register * 4 + input offset
	move.l	(1+2)*4+0(a7),a1	; Destination
	move.l	(1+2)*4+4(a7),a0	; Source
	move.l	(1+2)*4+16(a7),d0	; Lines
	subq	#1,d0		; For dbf
	move.l	(1+2)*4+12(a7),d3
	subq	#1,d3		; D3 = source width -1 (for dbf)
	move.l	(1+2)*4+8(a7),d2
	sub.l	(1+2)*4+12(a7),d2	; D2 = modulo to add
	lsl.w	#1,d2		; Word to Bytes
outer$:	move.w	d3,d1		; Source width
l1$	move.w	(a0)+,(a1)+	; COPY
	dbf	d1,l1$
	add.w	d2,a1		; Skip modulo in dest.
	dbf	d0,outer$
	movem.l	(sp)+,d2-d3
	rts
