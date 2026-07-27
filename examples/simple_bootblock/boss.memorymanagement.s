
	include boss.memorymanagement.i
	include boss.io.i

	XDEF	boss_memmanage_init

	xref	boss_manifest_entries
	xref	boss_manifest_memory

	XDEF	BOSSSCREENBITPLANE
	XDEF	BOSSSCREENCOPPERLIST

;;; Put this at the very beginning of the chip ram just behind the vectors. Vectors from $c0 to $3ff seem to be available.
BOSSSCREENBITPLANE:	equ	$400
;;; We put the copperlist just behind the graphics memory.
BOSSSCREENCOPPERLIST:	equ	BOSSSCREENBITPLANE+640/8*256
;;; This is the first memory available for the allocation code.
BOSSFIRSTCHIP:	equ	BOSSSCREENCOPPERLIST+256

; CHUNK-TABLE MEMORY ALLOCATOR  (Motorola 68000)
; ==============================================
;
; DESIGN
; ------
; 
; The memory pool is divided into fixed-size chunks. Instead of a
; plain free/used bitmap, each chunk has a 16-bit entry in the
; corresponding chunk table:
;
;     entry == 0:        chunk is free
;     entry == $FFFF:    chunk is a continuation of an allocation that
;                        started at an earlier chunk (occupied, but not
;                        the block's start)
;     entry == 1..$FFFE: chunk is the start of an allocation, and the
;                        value is the number of consecutive chunks
;                        (including this one) that belong to it
;
; Ssearch algorithm for allocation
; --------------------------------
; 
; The number of needed chunks N is calculated and the table is walked
; until N consecutive chunks could be found.  As soon as the run
; reaches the number of chunks requested, that run is used making this
; a first-fit algorithm. Any non-zero entry (used or continuation)
; resets the run length back to zero. Nothing more sophisticated is
; used because this is fast and should be good enough.
;
; Freeing
; --------
; 
; The chunk number is calculated and a lookup in the table gets the
; number of allocated chunks for this memory allocation. These chunks
; are freed by setting them to zero in the allocation table.
;
; Notes
; -----
; 
; The chunk table uses WORD entries. As we have different types of
; memory multiple tables are needed.


	RSRESET
rsMEMCHUNK_shift:	rs.w	1 ; log2(chunk size)
rsMEMCHUNK_chunksize:	rs.w	1 ; 1<<above shift
rsMEMCHUNK_memchunknum:	rs.w	1 ; available chunks
rsMEMCHUNK_memstart:	rs.l	1 ; Pointer to the memory
rsMEMCHUNK_memchunks:	rs.w	0 ; Placeholder!
rsMEMCHUNK_rs_size:	rs


;;; \1=memname, \2=shift, \3=start, \4=end
	macro	ChunkStructure
MEMCHUNKSIZE\1	equ	((\4)-\3)

	bss
MEMCHUNK\1:	dcb.b	rsMEMCHUNK_rs_size
	dcb.w	MEMCHUNKSIZE\1/(1<<\2)

	code
init_MEMCHUNK\1:
	lea.l	MEMCHUNK\1,a6
	move.w	#\2,rsMEMCHUNK_shift(a6)
	move.w	#1<<\2,rsMEMCHUNK_chunksize(a6)
	move.w	#MEMCHUNKSIZE\1/(1<<\2),rsMEMCHUNK_memchunknum(a6)
	move.l	#\3,rsMEMCHUNK_memstart(a6)
        lea     rsMEMCHUNK_memchunks(a6),a0 ; a0 = start of chunk list
	move.w  #MEMCHUNKSIZE\1/(1<<\2)-1,d0
	moveq	#0,d1
clear$:
        move.w  d1,(a0)+
        dbra    d0,clear$
	rts
	endm

	;; Chip memory chunks.
	ChunkStructure	CHIP, 7, BOSSFIRSTCHIP, 512<<10
	;; Slow memory chunks. After BOSS (remember to check __BSS_END__!) but leave some space for stack!
	ChunkStructure	SLOW, 9, $c05000, $c7f000
	
CONT_MARKER     equ     $FFFF           ; marks a "continuation" chunk


	CODE
;;; Initialise the whole memory system. This will install the trap15code.
boss_memmanage_init:
regs$:	reg	d2-d7/a2-a6
	movem.l	regs$,-(sp)
	bsr	init_MEMCHUNKSLOW
	bsr	init_MEMCHUNKCHIP
	lea	trap15code(pc),a0
	move.l	a0,$BC.w	; Set vector for TRAP#15.
	movem.l	(sp)+,regs$
        rts

trap15code:
	movem.l	d2-d7/a2-a6,-(sp)
	lsl.w	#2,d7
	jsr	list$(PC,d7.w)
	movem.l	(sp)+,d2-d7/a2-a6
	rte
	;; Using JMP PC relative to make sure that each opcode takes 4 bytes!
list$:	jmp	boss_memmanage_init(pc)
	jmp	boss_memmanage_deluxealloc(pc)
	jmp	boss_memmanage_chipalloc(pc)
	jmp	boss_memmanage_chipfree(pc)
	jmp	boss_memmanage_slowalloc(pc)
	jmp	boss_memmanage_slowfree(pc)
	jmp	boss_memmanage_chipalloc_at(pc)
	jmp	boss_memmanage_slowalloc_at(pc)
	jmp	memcopyword(pc)
	jmp	memclearword(pc)
	jmp	zx0_decompress(pc)
	jmp	find_manifest(pc)

boss_memmanage_deluxealloc:
	tst.l	d1	; Where to put the data?
	bmi	useCHIP$
	beq	useSLOW$
	;; ...or a fixed destination address.
	move.l	d1,a0
	cmp.l	#$800000,d1
	blt	useAbsCHIP$
	BossMem	BossMemTrapAllocSlowAt
	bra	end$
useAbsCHIP$:
	BossMem	BossMemTrapAllocChipAt
	bra	end$
useCHIP$:
	BossMem	BossMemTrapAlloc
	bra	end$
useSLOW$:
	BossMem	BossMemTrapAllocSlow
end$:				; A0 has memory.
	rts


find_manifest:
	move.l	boss_manifest_memory,a0
	move.w	boss_manifest_entries,d1
l1$:
	cmp.l	(a0),d0		; Is this the entry we are looking for?
	beq	found$
	lea.l	rsManifestStructsize(a0),a0 ; Skip to next entry.
	dbeq	d1,l1$
	sub.l	a0,a0		; Clear A0 as nothing was found.
found$:	rts

	include	"zx0decompress.inc"

;;; Copy memory from a0, a1. D0 words are copied.
memcopyword:
	subq.w	#1,d0		; DBF works until -1!
	bmi.s	end$		; Somebody used zero???
l1$	move.w	(a0)+,(a1)+
	dbf	d0,l1$
end$	rts

;;; Clear memory from a0 for d0 words.
memclearword:
	subq.w	#1,d0		; DBF works until -1!
	bmi.s	end$		; Somebody used zero???
l1$:	clr.w	(a0)+
	dbf	d0,l1$
end$	rts


boss_memmanage_chipalloc_at:
	lea.l	MEMCHUNKCHIP,a6
	bra	boss_memmanage_alloc_atA6
boss_memmanage_slowalloc_at:
	lea.l	MEMCHUNKSLOW,a6
	bra	boss_memmanage_alloc_atA6

boss_memmanage_chipalloc:
	lea.l	MEMCHUNKCHIP,a6
	bra	boss_memmanage_allocA6
boss_memmanage_chipfree:
	lea.l	MEMCHUNKCHIP,a6
	bra	boss_memmanage_freeA6

boss_memmanage_slowalloc:
	lea.l	MEMCHUNKSLOW,a6
	bra	boss_memmanage_allocA6
boss_memmanage_slowfree:
	lea.l	MEMCHUNKSLOW,a6
	bra	boss_memmanage_freeA6


;;; Allocate memory at a certain position.
;;; In:	D0.l = number of bytes requested
;;;	A0.l = address requested
;;;	A6.l = pointer to memory structure
;;; Out: a0 = pointer to allocated memory or 0 on failure
boss_memmanage_alloc_atA6:
;;; TODO: check out of bounds! If the start address requested is outside of the memory range then no check should be performed.
chunee$	equr	d4 ; Chunks needed
chunum$	equr	d2 ; Number of first chunk
	;;---- chunks_needed = ceil(size / CHUNK_SIZE) ----
	moveq	#0,d1
        move.w 	rsMEMCHUNK_chunksize(a6),d1 ; d1 = chunksize in L.
	subq.l	#1,d1
	add.l	d0,d1
        move.w	rsMEMCHUNK_shift(a6),d0
	lsr.l	d0,d1		; d1 = number of chunks
        beq     fail$		; size 0 -> nothing to do
        move.l  d1,chunee$		; d4 = chunks needed
	cmp.w	rsMEMCHUNK_memchunknum(a6),d4 ; Check if there are enough chunks!
	bgt	fail$
	move.l	rsMEMCHUNK_memstart(a6),a1 ; Start of memory
	cmpa.l	a1,a0
	blt.s	fail$
	move.l	a0,chunum$		; Put address into data register.
	sub.l	a1,chunum$		; Offset into the memory
        move.w	rsMEMCHUNK_shift(a6),d0
	lsr.l	d0,chunum$	; First chunk number calculated.
	;; Now scan.
	move.l	chunum$,d0	; First chunk number in D0.
	lsl.l	#1,d0		; A word for each chunk.
	move.w	d4,d1
	subq.w	#1,d1
	lea.l	rsMEMCHUNK_memchunks(a6),a0
scanloop$:
	tst.w	0(a0,d0)
	bne	fail$
	addq.l	#2,d0
	dbf	d1,scanloop$
	;; Memory is free, allocate it.
	move.l	chunum$,d0	; First chunk number in D0.
	lsl.l	#1,d0		; A word for each chunk.
	add.l	d0,a0		; Chunk entry in table, a0 is unchanged from above!
	move.w	d4,d1
	move.w	d4,(a0)+	; Allocate the memory.
	subq.w	#1,d1
	beq	onlyone$
	subq.w	#1,d1		; DBF goes to -1.
	moveq	#-1,d0		; $FFFF
fillloop$:
	move.w	d0,(a0)+
	dbf	d1,fillloop$
onlyone$:
	move.w	rsMEMCHUNK_shift(a6),d0	; Multi first chunk number to get offset.
	lsl.l	d0,chunum$
	add.l	rsMEMCHUNK_memstart(a6),chunum$ ; Add beginning of memory.
	;; chunum$ now contains the real start address
	move.l	chunum$,a0		; A0, too.
	rts
fail$:	moveq	#0,d0
	move.l	d0,a0
	rts

;;; Allocate memory, memory information structure in A6
;;; In:	d0.l = number of bytes requested
;;;	a6.l = pointer to memory structure
;;; Out: a0.l  = pointer to allocated memory, or 0 if the request failed
;;; Modifies: d1-d4/a1
boss_memmanage_allocA6:
chunks_needed$:	equr	D4	; WORD value.
start_index$:	equr	D3
freerun_len$:	equr	D2
	;; Calculate the number of chunks needed, aka ceil(size / CHUNK_SIZE) ----
	moveq	#0,d1
	move.w	rsMEMCHUNK_chunksize(a6),d1 ; d1 = chunksize in L.
	subq.l	#1,d1
	add.l	d0,d1		; d1 = number of bytes filled to chunk lenght minus one
	;; Afterwards 0 will be 0 but 1 (a single byte) will occupy at least one chunk.
	move.w	rsMEMCHUNK_shift(a6),d0 ; How many bits to shift for chunk size.
	lsr.l	d0,d1		; d1 = number of chunks
	beq	alloc_fail$	; Size = 0? Yes, nothing to do.
	move.w	d1,chunks_needed$	; chunks_needed$ = chunks needed, this is now a WORD!
	;; Scan table of chunks for a run of chunks_needed$ consecutive zeros.
	lea	rsMEMCHUNK_memchunks(a6),a1	; a1 = table scan pointer
	moveq	#0,freerun_len$			; freerun_len$ = current free-run length
	moveq	#0,start_index$			; start_index$ = start index of run
	moveq	#0,d0				; d0 = current chunk index
scanloop$:
	cmp.w	rsMEMCHUNK_memchunknum(a6),d0 ; End reached?
	bge	alloc_fail$		    ; ran off the end, no room
	;; Memory available?
	tst.w	(a1)
	bne	abort_run$	; Chunk was occupied, we have to abort the current run.
	;; Chunk was free.
	tst.w	freerun_len$	; Is this the first in the run?
	bne	not_first_chunk$
	move.w	d0,start_index$	; Store start index of the free run.
not_first_chunk$:
	addq.l	#1,freerun_len$	; Increment run length.
	cmp.w	chunks_needed$,freerun_len$
	bge	found_space$	; There is enough space available!
	bra	continue_run$
abort_run$:
	moveq	#0,freerun_len$	; Chunk is occupied, start again.
continue_run$:
	addq.l	#1,d0		; Increment chunk index.
	addq.l	#2,a1		; Go to next table entry, remember these are WORDs.
	bra	scanloop$
	;; We have found a run of chunks_needed$ free chunks starting at chunk index start_index$. We need to fill with <length>,$FFFF,$FFFF,...
found_space$:
	lea	rsMEMCHUNK_memchunks(a6),a1
	move.w	start_index$,d0
	lsl.w	#1,d0		; Index to which WORD?
	adda.w	d0,a1		; A1 = pointer to the chunk table-entry.
	move.w	chunks_needed$,(a1)+ ; That many chunks were needed.
	move.w	chunks_needed$,d1
	subq.w	#1,d1		; Number of entries we have to mark with $FFFF, remember that this may be zero!
	beq	calc_and_ret_addr$
	moveq	#1,d0		; D0 = $FFFFFFFF, we need only 16 bits.
l1$:	move.w	d0,(a1)+
	subq.l	#1,d1
	bne	l1$
calc_and_ret_addr$:
	moveq	#0,d0
	move.l	start_index$,d0		; d0 = start index of run, see above.
	move.w	rsMEMCHUNK_shift(a6),d1
	lsl.l	d1,d0			; Calculate byte offset into memory.
	move.l	rsMEMCHUNK_memstart(a6),a0 ; Start address of memory.
	adda.l	d0,a0			 ; a0 = pointer to give caller
	rts
alloc_fail$:
	moveq	#0,d0
	move.l	d0,a0			 ; return NULL
	rts


;;; Free an allocated memory.
;;; In:	a0 = pointer previously returned by mem_alloc
;;;	a6.l = pointer to memory structure
;;; Out: -
;;; Modifies: d0-d2/a0-a1
;
; If a0 does not point to the start of a live allocation (e.g. it
; points into the middle of a block, or the block was already freed),
; the BOSS system will dump registers and stop.
boss_memmanage_freeA6:
	;; ---- chunk index = (a0 - MEM_POOL) / CHUNK_SIZE ----
	move.l	a0,d0
	move.l	rsMEMCHUNK_memstart(a6),a1 ; A1 = memory start.
	sub.l	a1,d0		; d0 = offset of memory in the memory block
	move.w	rsMEMCHUNK_shift(a6),d1
	lsr.l	d1,d0		; d0 = which chunk is it?
	
	lea	rsMEMCHUNK_memchunks(a6),a1
	move.l	d0,d1
	lsl.l	#1,d1		; Table of words, so multiply by 2.
	adda.l	d1,a1		; A1 = points to table entry of chunk.
	;; Check if we have the correct chunk.
	move.w	(a1),d2
	cmp.w	#CONT_MARKER,d2
	beq	bad_free$	; This is in the middle of an allocation, something went wrong.
	tst.w	d2
	beq	bad_free$	; This chunk is free, something went wrong.
	;; Now D2 contains the number of chunks to free (unsigned short).
	moveq	#0,d0		; CLR.L D0
clearloop$:
	move.w	d0,(a1)+
	subq.w	#1,d2
	bne	clearloop$
	rts
bad_free$:
	BossIO	BossIODumpRegisters
	BossIOWritelnS "Memory free failed!"
	move.w	#$0f00,d0
	BossIO	BossIOBackground
	move.w	#$0ff3,d0
	BossIO	BossIOForeground
        bra	*
