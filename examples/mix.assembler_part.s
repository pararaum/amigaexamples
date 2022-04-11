
;;; Example code to mixing C and Assembler. 
;;;
;;; Links:
;;; http://www.winnicki.net/amiga/memmap/MoreInts.html


	XDEF	_start
	XDEF	_fun2
	XDEF	_fungen
	XDEF	_funreg
	XREF	_printhex

SOFTWARE_INTERRUPT = $64
VBLANK_INTERRUPT = $6C
	

	include "hardware/custom.i"
	include "hardware/dmabits.i"
	include "own.i"

	section	text,code

;;; void funreg(int __reg("d0") i, unsigned long __reg("d1") j, __reg("a0") char * ptr);
_funreg:
	and.l	d0,d1		;Some operation
	moveq	#32-1,d0	;no. of bits
l1$:	lsl.l	d1
	bcs.s	s1$
	move.b	#'0',(a0)+
	bra.s	s2$
s1$:	move.b	#'1',(a0)+
s2$:	dbf	d0,l1$
	clr.b	(a0)
	rts

;;; int fun2(int i, int j);
_fun2:	nop
	;; Parameter where pushed right to left on the stack.
	;;	j
	;;	i
	;; →	return address
	movem.l	d1-d7/a0-a6,-(sp)
	;; Now even more on the stack
	;;	j
	;;	i
	;; 	return address
	;;	reg_0
	;;	reg_i
	;;→	reg_n-1
	move.l	14*4+1*4(a7),d0	;i
	move.l	14*4+2*4(a7),d1	;j
	add.l	d1,d0
	movem.l (sp)+,d1-d7/a0-a6
	;; D0 contains the returnvalue.
	rts

_start:	bra.s	main
	dc.b	"Mixing example",10
	dc.b	"Code: Pararaum / T7D",10
	dc.b	0
	EVEN
	ifd	DEBUG
	dc.l	"MAIN",main
	endif
	EVEN


;;; Function to be called from C. Look at http://sun.hasenbraten.de/vbcc/docs/vbcc_4.html#SEC50 for calling convention.
_fungen:
	lea	_start+2(pc),a0
	move.l	a0,d0
	rts

;;; Assembler 'main' function
main:	nop
	;; Parameters are pushed right to left.
	pea.l	main(pc)	;Push address of main
	pea.l	maintext$	;Push address of text
	jsr	_printhex	;Call C routine
	addq.l	#8,a7		;Clean up stack
	moveq   #OWN_libraries|OWN_trap,d0
        jsr     own_machine
	nop
	lea	$DFF000,a6	;Set custom register base
	moveq	#0,d0
l1$:	move.w	d0,$180(a6)
	dbf	d0,l1$
	nop
	nop
	;; 	trap	#15
	nop
	nop
	jsr     disown_machine
	moveq	#0,d0
	rts
maintext$:
	dc.b	"main",0
