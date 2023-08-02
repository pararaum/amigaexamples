;;; Circulatory Allocator

;;; A very simple allocator which will allocate memory in a buffer
;	from beginning to the end and if the end is reached the allocator
;	starts to use the memory at the beginning. Advantage is that
;	you do not need to free memory. The disadvantage is that
;	allocating to much memory will produce strange behaviour or
;	the universe may come to an end. And beware of allocating more
;	bytes then there are available...

	XDEF	circinit
	XDEF	_circinit
	XDEF	circalloc
	XDEF	_circalloc
	XDEF	circfreeze
	XDEF	_circfreeze
	XDEF	circfreeall
	XDEF	_circfreeall

	SECTION CODE

;;; Inititalise the circulatory allocator.
;;; Input
;;; A0: pointer to the beginning of the memory
;;; A1: pointer to the end+1 of the memory
circinit:
	move.l	a0,circmemstart
	move.l	a0,circmemcurrent
	move.l	a0,circmemfreeze
	move.l	a1,circmemstop
	rts
;;; circinit(void *begin, void *end)
_circinit:
	move.l	8(sp),a1
	move.l	4(sp),a0
	bsr.s	circinit
	clr.l	d0
	rts


;;; Allocate memory
;;; Input: D0: number of bytes
;;; Output: A0: address of memory
circalloc:
	or.w	#15,d0			; At least 16 bytes are used. OR.W is sufficient as only the lowest 4 bits are affected.
	addq.l	#1,d0			; At least 16 bytes and at a 16 byte boundry.
	move.l	circmemcurrent(pc),a0	; Get current address.
	move.l	a0,a1			; Copy into temporary register
	add.l	d0,a1			; New end address.
	cmp.l	circmemstop(pc),a1	; Still smaller? a1-circmemstop->CC
	bcs.s	l1$			; Yes, smaller, as borrow must occur.
	move.l	circmemfreeze(pc),a0	; Get beginning as start address.
	move.l	a0,a1			; Copy to a1
	add.l	d0,a1			; End address in a1.
l1$:	move.l	a1,circmemcurrent	; Set new address.
	;; A0 sill containes the old current address which is the beginning of the memory the caller wants.
	rts
_circalloc:
	move.l	4(sp),d0
	bsr.s	circalloc
	move.l	a0,d0
	rts

_circfreeze:
circfreeze:
	move.l	circmemcurrent(pc),circmemfreeze
	rts

;;; Frees all allocations by resetting the memstart pointer. This will also release any freezes.
_circfreeall:
circfreeall:
	move.l	circmemstart(pc),a0
	move.l	a0,circmemfreeze
	move.l	a0,circmemcurrent
	rts

circmemstart:	dc.l	0
circmemstop:	dc.l	0
circmemcurrent:	dc.l	0
circmemfreeze:	dc.l	0
