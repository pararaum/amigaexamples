;;; Use a privilege escalation to go into supervisor mode, run code in
;	supervisor mode and return to usermode.
	include	"own.i"
	include	"hardware/custom.i"
	
;;; Section is name, section type
	section	text,code

_start:
	jmp	main(pc)
	dc.b	"Supervisor",10
	dc.b	"by Pararaum / T7D",10,0
	even
debug:	dc.l	0
prvesc:	dc.l	0

main:
	move	#OWN_libraries|OWN_trap|OWN_interrupt,d0
	jsr	own_machine
	move.l	$20,prvesc
	move.l	#exception,$20
	lea.l	pcode,a0
	stop	#0
	move.l	prvesc,$20
l2$:	tst.l	debug
	bne	l2$
	jsr	disown_machine
	clr.l	d0
	rts

exception:
	movem.l	d0-d7/a0-a6,-(sp)
	lea.l	15*4(a7),a6	;Original pointer into stack
	move.w	(a6)+,d7	;SR
	move.l	(a6)+,d6	;PC
	move.w	(a6)+,d5	;vector offset (only 68k20+???)
	jsr	(a0)
	;lea.l	15*4(a7),a6	;Original pointer into stack
	;addq.l	#4,2(a6)	;Skip STOP#0 opcode
	addq.l	#4,15*4+2(a7)
	movem.l	(sp)+,d0-d7/a0-a6
	rte

pcode:
	move.l	#$400000,d0
	lea.l	$dff180,a0
l1$:	move.w	d0,(a0)
	subq.l	#1,d0
	bpl.s	l1$
	rts
