;;; Basic Operating System Simulacrum
	include	hardware/custom.i
	include	hardware/dmabits.i

	include boss.memorymanagement.i
	include	boss.io.i

	XREF	boss_memmanage_init
	XREF	boss_io_init

	xref	_ul2hex

	XDEF	BOSS_MAIN_INIT


	data
	dc.b	"DATA begins here."
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
	BossIOWritelnS	"...I am ready for you."
	
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
	
	jmp	*

