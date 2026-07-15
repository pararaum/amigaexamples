;;; Basic Operating System Simulacrum
	include	hardware/custom.i
	include	hardware/dmabits.i

	include boss.memorymanagement.i
	include	boss.io.i

	XREF	boss_memmanage_init
	XREF	boss_io_init


	XDEF	BOSS_MAIN_INIT


	data
trackloadtext:
	dc.b	"Trackloading %x..%x to %x.",10,0
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
	bsr	boss_memmanage_init
	bsr	boss_io_init
	BossIOWritelnS	"Booting BOSS..."
	bsr	boss_trackloader_init
	BossIOWritelnS	"READY."

mainloop$:
	move.l	(sp)+,d2	; Address.
	bmi	end_of_demo$
	moveq	#9,d0
	move.l	(sp)+,d3	; End sector of part.
	lsr.l	d0,d3
	move.l	(sp)+,d4	; Start sector of part.
	lsr.l	d0,d4
	move.l	a7,a6
	move.l	a7,d0
	and.l	#$FFFFFFFC,d0	; Align to word
	move.l	d0,a7
	move.l	d2,-(sp)
	move.l	d3,-(sp)
	move.l	d4,-(sp)
	pea.l	trackloadtext
	bsr	_boss_simprintf
	move.l	a6,a7		; Restore stack
	move.l	d4,d0
	move.l	d3,d1
	move.l	d2,a0
	BossIO	BossIOTrapTrackload
	move.l	d2,a0		; Get destination address.
	jsr	(a0)		; Call
	bra	mainloop$
end_of_demo$:
	;lea.l	$6100,a0
	;move.l	#$400,d0
	;BossMem	BossMemTrapAllocChipAt
	;
	;jmp	*

	;move.l	a7,a6
	;move.l	a7,d0
	;subq.l	#3,d0
	;and.l	#$FFFFFFFC,d0
	;move.l	d0,a7
	;move.l	#$d0e0f000,-(sp)
	;move.l	#$90a0b0c0,-(sp)
	;move.l	#$50607080,-(sp)
	;move.l	#$10203040,-(sp)
	;;; 	clr.w	-(sp)
	;pea.l	testtext
	;bsr	_boss_simprintf
	;bsr	_testfun
	;move.l	a6,a7
	
	;moveq	#23,d0
	;moveq	#120,d1
	;lea.l	$c50000,a0
	;BossIO	BossIOTrapTrackload
	

	
	jmp	*

