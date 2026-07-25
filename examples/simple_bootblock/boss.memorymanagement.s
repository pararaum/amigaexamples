
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

;=============================================================================
; CHUNK-TABLE MEMORY ALLOCATOR  (Motorola 68000)
;=============================================================================
;
; DESIGN
; ------
; The memory pool is divided into fixed-size chunks (CHUNK_SIZE bytes each,
; 128 by default). Instead of a plain free/used *bitmap*, each chunk has a
; 16-bit entry in CHUNK_TABLE:
;
;     entry == 0        -> chunk is FREE
;     entry == $FFFF     -> chunk is a CONTINUATION of an allocation that
;                           started at an earlier chunk (occupied, but not
;                           the block's start)
;     entry == 1..$FFFE  -> chunk is the START of an allocation, and the
;                           value is the number of consecutive chunks
;                           (including this one) that belong to it
;
; SEARCH ALGORITHM (mem_alloc)
; -----------------------------
; Same idea as scanning a free-bitmap for N consecutive free bits: walk the
; table from the start, counting a run of consecutive zero (free) entries.
; As soon as the run reaches the number of chunks requested, that run is
; used (first-fit). Any non-zero entry (used or continuation) resets the
; run length back to zero.
;
; FREEING (mem_free)
; -------------------
; Because the block's *size* is stored right there at its start entry, no
; header/footer needs to live in the user's memory and no block list needs
; to be walked: look up the chunk index for the pointer, read the count,
; and zero that many table entries. Adjacent free runs need no explicit
; coalescing -- the scanner in mem_alloc already treats consecutive zero
; entries as one contiguous free run regardless of how they became free.
;
; NOTES
; ---------------------------------------
; - CHUNK_TABLE uses WORD entries (max 65535 chunks per single allocation).
;
;=============================================================================
	
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

;=============================================================================
;;; In:	d0.l = number of bytes requested
;;;	a6.l = pointer to memory structure
; Out: a0   = pointer to allocated memory, or 0 if the request failed
;             (no run of free chunks was large enough)
; Modifies: d1-d4/a1
;=============================================================================
boss_memmanage_allocA6:
	;;---- chunks_needed = ceil(size / CHUNK_SIZE) ----
	moveq	#0,d1
        move.w 	rsMEMCHUNK_chunksize(a6),d1 ; d1 = chunksize in L.
	subq.l	#1,d1
	add.l	d0,d1
	;; Afterwards 0 will be 0 but 1 (a single byte) will occupy at least one chunk.
        move.w	rsMEMCHUNK_shift(a6),d0
	lsr.l	d0,d1		; d1 = number of chunks
        beq     ma_fail                 ; size 0 -> nothing to do
        move.l  d1,d4                   ; d4 = chunks needed

	;;---- scan CHUNK_TABLE for a run of d4 consecutive zeros ----
        lea     rsMEMCHUNK_memchunks(a6),a1	; a1 = table scan pointer
        moveq   #0,d2                   	; d2 = current free-run length
        moveq   #0,d3                   	; d3 = start index of run
        moveq   #0,d0                   	; d0 = current chunk index

ma_scan:
        cmp.l   rsMEMCHUNK_memchunknum(a6),d0
        bge     ma_fail                 ; ran off the end, no room

        tst.w   (a1)
        bne     ma_broken                ; non-zero -> run resets

	;;this chunk is free
        tst.l   d2
        bne     ma_grow
        move.l  d0,d3                    ; first free chunk of a new run
ma_grow:
        addq.l  #1,d2
        cmp.l   d4,d2
        bge     ma_found                 ; run is now big enough
        bra     ma_next

ma_broken:
        moveq   #0,d2                    ; run interrupted, start over

ma_next:
        addq.l  #1,d0
        addq.l  #2,a1                    ; word-sized entries
        bra     ma_scan

	;; ---- found a run of d4 free chunks starting at chunk index d3 ----
ma_found:
        lea     rsMEMCHUNK_memchunks(a6),a1
        move.l  d3,d0
        add.l   d0,d0                    ; *2 -> byte offset into table
        adda.l  d0,a1                    ; a1 -> table entry of start

        move.w  d4,(a1)+                 ; store block size at start
        move.l  d4,d1
        subq.l  #1,d1                    ; remaining entries to mark
        beq     ma_addr
ma_markcont:
        move.w  #CONT_MARKER,(a1)+
        subq.l  #1,d1
        bne     ma_markcont

ma_addr:
        move.l  d3,d0		; d0 = start index of run, see above.
	move.w	rsMEMCHUNK_shift(a6),d1
        lsl.l   d1,d0          ; chunk index -> byte offset
        move.l	rsMEMCHUNK_memstart(a6),a0 ; Start address of memory.
        adda.l  d0,a0                    ; a0 = pointer to give caller
        rts

ma_fail:
        moveq   #0,d0
        move.l  d0,a0                    ; return NULL
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
	BossIO	BossIOBackground
        bra	*
