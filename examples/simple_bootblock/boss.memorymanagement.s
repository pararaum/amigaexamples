
	XDEF	boss_memmanage_init
	XDEF	boss_memmanage_alloc
	XDEF	boss_memmanage_free

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

;;; \1=memname, \2=shift, \3=start, \4=end
	macro	ChunkStructure
	rsreset
rsMEMCHUNK\1_shift:	rs.w	1 ; log2(chunk size)
rsMEMCHUNK\1_chunksize:	rs.w	1 ; 1<<above shift
rsMEMCHUNK\1_memchunknum:	rs.w	1
rsMEMCHUNK\1_memchunks:	rs.w	((\4)-\3)/(1<<\2)
rsMEMCHUNK\1_memstart:	rs.l	1
rsMEMCHUNK\1_rs_size:	rs

	bss
MEMCHUNK\1:	dcb.b	rsMEMCHUNK\1_rs_size

	code
init_MEMCHUNK\1:
	lea.l	MEMCHUNK\1,a6
	move.w	#\2,rsMEMCHUNK\1_shift(a6)
	move.w	#1<<\2,rsMEMCHUNK\1_chunksize(a6)
	move.w	#((\4)-\3)/(1<<\2),rsMEMCHUNK\1_memchunknum(a6)
	move.l	#\3,rsMEMCHUNK\1_memstart(a6)
        lea     rsMEMCHUNK\1_memstart(a6),a0
	move.w  #((\4)-\3)/(1<<\2)-1,d0
	moveq	#0,d1
clear$:
        move.w  d1,(a0)+
        dbra    d0,clear$
	rts
	endm

	ChunkStructure	CHIP, 7, $6000, 512<<10
	ChunkStructure	SLOW, 9, $c10000, $c7f800
	
;-----------------------------------------------------------------------------
; CONSTANTS
;-----------------------------------------------------------------------------
CHUNK_SHIFT     equ     7               ; log2(CHUNK_SIZE), used for fast *//
CHUNK_SIZE      equ     (1<<7)		; bytes per chunk

MEM_START	equ	$6000	; Lowest available memory.
POOL_SIZE       equ     (512<<10)-MEM_START ; 512KB of chip memory.
NUM_CHUNKS      equ     POOL_SIZE/CHUNK_SIZE

CONT_MARKER     equ     $FFFF           ; marks a "continuation" chunk

;-----------------------------------------------------------------------------
; DATA / BSS
;-----------------------------------------------------------------------------
	BSS

        even
CHUNK_TABLE:    ds.w    NUM_CHUNKS      ; one word per chunk (see header)

	DATA
	dc.l	__BSS_START__
	dc.l	__BSS_END__
	dc.b	"END TABLE"
	even

	CODE
;=============================================================================
; Clears the chunk table so every chunk starts out FREE. Call once before
; any mem_alloc/mem_free calls.
;
; In:  -
; Out: NUM_CHUNKS
; Modifies: d0/a0
;=============================================================================
boss_memmanage_init:
	bsr	init_MEMCHUNKSLOW
	bsr	init_MEMCHUNKCHIP
        lea     CHUNK_TABLE,a0
        move.w  #NUM_CHUNKS-1,d0
	moveq	#0,d1
mi_clear:
        move.w  d1,(a0)+
        dbra    d0,mi_clear
	lea	trap15code(pc),a0
	move.l	a0,$BC.w	; Set vector for TRAP#15.
	move.w	#NUM_CHUNKS,d0
        rts

trap15code:
	movem.l	d2-d7/a2-a6,-(sp)
	lsl.w	#2,d7
	jsr	list$(PC,d7.w)
	movem.l	(sp)+,d2-d7/a2-a6
	rte
list$:	jmp	boss_memmanage_init(pc)
	jmp	boss_memmanage_alloc(pc)
	jmp	boss_memmanage_free(pc)


;=============================================================================
; In:  d0.l = number of bytes requested
; Out: a0   = pointer to allocated memory, or 0 if the request failed
;             (no run of free chunks was large enough)
; Modifies: d1-d4/a1
;=============================================================================
boss_memmanage_alloc:
	;;---- chunks_needed = ceil(size / CHUNK_SIZE) ----
        move.l  d0,d1
        addi.l  #CHUNK_SIZE-1,d1
        lsr.l   #CHUNK_SHIFT,d1
        beq     ma_fail                 ; size 0 -> nothing to do
        move.l  d1,d4                   ; d4 = chunks needed

	;;---- scan CHUNK_TABLE for a run of d4 consecutive zeros ----
        lea     CHUNK_TABLE,a1          ; a1 = table scan pointer
        moveq   #0,d2                   ; d2 = current free-run length
        moveq   #0,d3                   ; d3 = start index of run
        moveq   #0,d0                   ; d0 = current chunk index

ma_scan:
        cmp.l   #NUM_CHUNKS,d0
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
        lea     CHUNK_TABLE,a1
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
        move.l  d3,d0
        lsl.l   #CHUNK_SHIFT,d0          ; chunk index -> byte offset
        lea     MEM_START,a0
        adda.l  d0,a0                    ; a0 = pointer to give caller
        rts

ma_fail:
        moveq   #0,d0
        move.l  d0,a0                    ; return NULL
        rts


;=============================================================================
; mem_free
;
; In:  a0 = pointer previously returned by mem_alloc
; Out: -
; Modifies: d0-d2/a0-a1
;
; If a0 does not point to the start of a live allocation (e.g. it points
; into the middle of a block, or the block was already freed), the call
; is a no-op. mf_bad is the spot to extend with real error reporting
; (e.g. return a status code in d0) if you need it.
;=============================================================================
boss_memmanage_free:
	;; ---- chunk index = (a0 - MEM_POOL) / CHUNK_SIZE ----
        move.l  a0,d0
        lea     MEM_START,a1
        sub.l   a1,d0
        lsr.l   #CHUNK_SHIFT,d0
	
        lea     CHUNK_TABLE,a1
        move.l  d0,d1
        add.l   d1,d1                    ; *2 -> byte offset
        adda.l  d1,a1                    ; a1 -> table entry

        move.w  (a1),d2
        cmp.w   #CONT_MARKER,d2
        beq     mf_bad                   ; mid-block pointer, reject
        tst.w   d2
        beq     mf_bad                   ; already free / invalid

	;; ---- d2 = number of chunks to clear ----
        move.w  #0,(a1)+
        subq.w  #1,d2
        beq     mf_done
mf_clear:
        move.w  #0,(a1)+
        subq.w  #1,d2
        bne     mf_clear

mf_done:
        rts

mf_bad:
	;;bad pointer / double free
        rts
