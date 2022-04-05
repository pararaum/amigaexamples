
	XDEF main
	INCLUDE	"exec/exec.i"
	
	section	text,code

main:	nop
	jsr	output
	moveq	#-1,d0
	moveq	#87,d1
	lea.l	$DFF000,a0
l1$:
	move.w	d0,$180(a0)
	dbf	d0,l1$
	dbf	d1,l1$
	moveq #0,d0
	rts

	
output:	lea	DosName,A1	;dos.library name string
	moveq	#36,D0		;minimum required version (36 = Kick 2.0)
	movea.l	$4.w,a6
	jsr	_LVOOpenLibrary(A6)
	movea.l	d0,A6		;moving DOSBase to A6
	tst.l	d0		;zero if OpenLibrary() failed
	beq.s	l1$		;if failed, skip to exit
	lea.l	mytext$(pc),a0
	move.l	a0,d1		;string to print
	move.l	#mytext$,d1
	jsr	_LVOPutStr(A6)	;PutStr
	movea.l	a6,a1		;DOSBase, library to close
	movea.l	$4.w,A6
	jsr	_LVOCloseLibrary(A6)
l1$:	clr.l	D0
	rts
mytext$:	CNOP	0,4
	dc.b	"Hello World!",10,0
	CNOP	0,4
DosName:	dc.b	"dos.library",0
