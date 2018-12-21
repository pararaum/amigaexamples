; forbid task switching and wait for mouse

_LVOForbid EQU -132
_LVOPermit EQU -138

 	section	task,code

main:	move.l	4.w,a6		; Get base of exec lib
	jsr	_LVOForbid(a6)	; Forbid Multitasking
.wfm:	btst	#6,$bfe001	; Left mouse clicked ?
	bne.b	.wfm 		; keep waiting
	bsr.s	get_data	; get some values
	;we get nasty here
	move.l	$80,trpvec	; save TRAP#0 vector
	lea.l	thetrp(pc),a0	; our trap
	move.l	a0,$80
	trap	#0		; TRAP!
	move.l	trpvec,$80	; restore trap vector
	jsr	_LVOPermit(a6)	; Permit Multitasking
	moveq	#0,d0		; status ok
	rts			; quit

get_data:	move.l	$80,a0
	move.l	$84,a1
	move.l	$88,a2
	lea.l	$80,a5
	movem.l	(a5)+,d0-d7
	rts

thetrp:	movem.l d0-d3/a0-a3,-(sp)
	moveq	#$5A,d0
	move.w	d0,d1
	lea.l	$dff000,a0
	lea.l	$180(a0),a1
.l1	move.w	d0,(a1)
	dbra	d0,.l1
	dbra	d1,.l1
	movem.l (sp)+,d0-d3/a0-a3
	rte

	section udata,bss
trpvec:	ds.l	1

