	include	"hardware/custom.i"

	XDEF	copper_create_bitplptrs
;;; Create the copperlist entries for the bitplane pointers.
;;; Input: A0=copperlist pointer
;;;	A1=bitplane pointer to first bitplane
;;;	D0.w=number of bitplanes
;;;	D1.w=modulo for the bitplanes
;;; Output: A0=copperlist pointer after last written command
;;; Modifies: D0/D1/A0
copper_create_bitplptrs:
Acopptr$:	equr	A0
Abitplptr$:	equr	A1
Dmodulo$:	equr	D2
Dnumbitpl$:	equr	D3
REGS$:	reg	Dmodulo$/Dnumbitpl$/Abitplptr$
	movem.l	REGS$,-(sp)
	move.w	d0,Dnumbitpl$	; Save the number of bitplanes.
	move.w	d1,Dmodulo$	; Save the bitplane modulo.
	move.w	#bplpt,d1	; Put copper write to bitplane pointer to D1.
	;; This takes care of dbf and having to subtract one from the number of bitplanes.
	bra.s	.lentry
.loop_sbpptr:
	move.l	Abitplptr$,d0
	swap	d0
	move.w	d1,(Acopptr$)+	; High word of bitplane pointer.
	move.w	d0,(Acopptr$)+
	swap	d0
	addq.w	#2,d1
	move.w	d1,(Acopptr$)+	; Low word of bitplane pointer.
	move.w	d0,(Acopptr$)+
	addq.w	#2,d1
	add.w	Dmodulo$,Abitplptr$	; Add modulo to bitplane pointer.
.lentry:
	dbf	Dnumbitpl$,.loop_sbpptr
	movem.l	(sp)+,REGS$
	rts
