;;; Basic Operating System Simulacrum
	include	hardware/custom.i
	include	hardware/dmabits.i

	include boss.memorymanagement.i
	include	boss.io.i

	XREF	boss_memmanage_init
	XREF	boss_io_init

	xref	_ul2hex
	xref	_boss_simprintf
	xref	_testfun

	XDEF	BOSS_MAIN_INIT


	data
testtext:	dc.b	"%x %x %x %x",10,0
	even

	;; **********************************************************************
	;; MAIN
	;; **********************************************************************
	CODE
BOSS_MAIN_INIT:
	lea	$00DFF000,a5	; Custom base in A5.
	move.w	#$7fff,intena(a5) ; Disable interrupts.
	move.w	#$7fff,intreq(a5) ; Disable interrupt requests.
	move.w	#$7fff,dmacon(a5) ; Disable DMA.
	lea	super$(pc),a0
	move.l	a0,$20.w	  ; Set privilege escalation vector.
	stop	#$0200		  ; This is a privileged opcode.
super$:				  ; Supervisor mode with A7=SP at end of memory.
	bsr	boss_memmanage_init
	bsr	boss_io_init
	BossIOWritelnS	"Booting BOSS..."
	bsr	boss_trackloader_init
	BossIOWritelnS	"READY."

	lea.l	$6100,a0
	move.l	#$400,d0
	BossMem	BossMemTrapAllocChipAt

	jmp	*

	move.l	a7,a6
	move.l	a7,d0
	subq.l	#3,d0
	and.l	#$FFFFFFFC,d0
	move.l	d0,a7
	move.l	#$d0e0f000,-(sp)
	move.l	#$90a0b0c0,-(sp)
	move.l	#$50607080,-(sp)
	move.l	#$10203040,-(sp)
	;; 	clr.w	-(sp)
	pea.l	testtext
	bsr	_boss_simprintf
	bsr	_testfun
	move.l	a6,a7
	
	;moveq	#23,d0
	;moveq	#120,d1
	;lea.l	$c50000,a0
	;BossIO	BossIOTrapTrackload
	
	move.l	#"12AB",-(sp)
	bsr	_ul2hex
	lea	4(sp),sp	; Restore stack.
	move.l	d0,a0
	BossIO	BossIOTrapWriteln
	BossIOWritelnS	"A beautiful day."
	move.l	#$1001,d0
	BossMem	BossMemTrapAlloc
	move.l	a0,a2
	move.l	a0,-(sp)
	bsr	_ul2hex
	lea	4(sp),sp	; Restore stack.
	move.l	d0,a0
	BossIO	BossIOTrapWriteln
	move.l	#$107f,d0
	BossMem	BossMemTrapAlloc
	move.l	a0,-(sp)
	bsr	_ul2hex
	lea	4(sp),sp	; Restore stack.
	move.l	d0,a0
	BossIO	BossIOTrapWriteln
	move.l	a2,a0
	BossMem	BossMemTrapFree
	move.l	#$1081,d0
	BossMem	BossMemTrapAlloc
	move.l	a0,-(sp)
	bsr	_ul2hex
	lea	4(sp),sp	; Restore stack.
	move.l	d0,a0
	BossIO	BossIOTrapWriteln
	move.l	#$10,d0
	BossMem	BossMemTrapAlloc
	move.l	a0,-(sp)
	bsr	_ul2hex
	lea	4(sp),sp	; Restore stack.
	move.l	d0,a0
	BossIO	BossIOTrapWriteln
	;;
	move.l	a7,a6
	move.l	#12345678,-(sp)
	bsr	_ul2dec
	move.l	a6,a7
	move.l	d0,a0
	BossIO	BossIOTrapWriteln

	
	jmp	*

