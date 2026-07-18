;;; Basic Operating System Simulacrum
	include	hardware/custom.i
	include	hardware/dmabits.i

	include boss.memorymanagement.i
	include	boss.io.i

	XREF	boss_memmanage_init
	XREF	boss_io_init


	XDEF	BOSS_MAIN_INIT
	xdef	boss_manifest_entries
	xdef	boss_manifest_memory

	data
trackloadtext:
	dc.b	"Trackloading %x..%x to %x.",10,0
	even

	bss
;;; This stores the number of available manifest entries.
boss_manifest_entries:	ds.w	1
boss_manifest_memory:	ds.l	1
	;; **********************************************************************
	;; MAIN
	;; **********************************************************************
	CODE
BOSS_MAIN_INIT:
	lea	$00DFF000,a5	; Custom base in A5.
	move.w	#$7fff,intena(a5) ; Disable interrupts.
	move.w	#$7fff,intreq(a5) ; Disable interrupt requests.
	move.w	#$7fff,dmacon(a5) ; Disable DMA.
	move.l	d0,-(sp)	  ; Put first part onto the stack.
	;; Copy manifest.
	sub.w	#1024,sp	  ; Make space for the list on the stack.
	move.l	sp,a1
	move.l	(a0)+,d0	; Number of entries.
	move.w	d0,boss_manifest_entries
	mulu.w	#rsManifestStructsize,d0
	subq.l	#1,d0
manifestcopyloop$:
	move.b	(a0)+,(a1)+
	dbf	d0,manifestcopyloop$
	bsr	boss_memmanage_init
	bsr	boss_io_init
	BossIOWritelnS	"Booting BOSS..."
	bsr	boss_trackloader_init
	;; Now copy manifest at designated memory.
	move.w	boss_manifest_entries,d0
	mulu.w	#rsManifestStructsize,d0
	BossMem	BossMemTrapAllocSlow
	move.l	a0,boss_manifest_memory
	;; TODO: add check?
	move.w	boss_manifest_entries,d0
	mulu.w	#rsManifestStructsize,d0
	lsr.l	#1,d0		; We need number of words.
	move.l	sp,a0
	move.l	boss_manifest_memory,a1
	BossMem	BossMemTrapCopyWords
	BossIOWritelnS	"READY."
	add.w	#1024,sp	; Restore old stack.
	move.l	(sp)+,d0	; First part from stack.
	;; Now load.
	BossIO	BossManifestLoad
	tst.l	d0
	bne.s	found$
	BossIOWritelnS "Finding of first part failed!"
	bra	*
	;;  Part was found, now get the memory.
found$:	jmp	(a0)
