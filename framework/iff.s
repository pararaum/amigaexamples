;;; IFF tools to make it easier to include images in this format. 
;;; See here, too? http://wiki.amigaos.net/wiki/IFF_Source_Code

	XDEF	uncompress_body
	XDEF	find_iff_chunk
	XDEF	copy_cmap_chunk
	XDEF	interpret_bmhd

;;; This will uncompress a body chunk (make sure it is really compressed).
;;; The decompression will create *continous* bitplanes!
;;; This function will change the data in the bitplane pointer array!
;;; Input:
;;; 
uncompress_body_continous:
	movem.l	d2-d7/a2-a6,-(sp)
	;; a4: current pointer in bitplanepointer array
	;; a5: body chunk pointer
	;; A6: bitplanepointer array pointer
	;; d4: current bitplane number
	;; d5: number of bitplanes
	;; d6: width in bytes
	;; d7: height
	ext.l	d7		;Just for good measure.
	subq	#1,d7		;We are using dbf
	ext.l	d6		;Long operation later on, see add to A4
line_in_lines$:
	moveq	#0,d4		;Current bitplane
	move.l	a6,a4
bitplane_in_bitplanes$:
	move.l	(a4),a2		;Current bitplane pointer
	bsr.s	uncompress_line$
	add.l	d6,(a4)+	;Next line next time
	addq	#1,d4		;Next bitplane no.
	cmp.w	d5,d4		;less than number of bitplanes?
	blt.s	bitplane_in_bitplanes$
	dbf	d7,line_in_lines$ ;Do for all lines
	movem.l	(sp)+,d2-d7/a2-a6
	rts
uncompress_line$:
	move.l	a2,a3
	add.w	d6,a3
loop$:	moveq	#0,d0
	move.b	(a5)+,d0
	ext.w	d0
	bpl.s	lit$
	neg.w	d0
	move.b	(a5)+,d1
l36$:	move.b	d1,(a2)+
	dbf	d0,l36$
	bra	end$
lit$:	move.b	(a5)+,(a2)+
	dbf	d0,lit$
end$:	cmp.l	a3,a2
	blt	loop$
	rts


;;; Fast method to find a chunk in an iff file.
	;; Input
	;; A0: Pointer of IFF data.
	;; D0.l: Chunk to find.
	;; Output:
	;; A0: Pointer to chunk data
	;; D0: Number of bytes in chunk or -1 if not found
find_iff_chunk:
	;; a2: pointer to form data
	;; a3: pointer to end of form data
	;; d2: Chunk ID to find.
	movem.l	d2/a2-a3,-(sp)
	cmp.l	#"FORM",(a0)
	beq.s	ok$
	moveq	#-1,d0
out$:	movem.l	(sp)+,d2/a2-a3
	rts
ok$:	move.l	d0,d2		;Put chunk id in D2
	lea	12(a0),a2	;Beginning of data
	; 12 Bytes: FORM <size> Group_ID
	move.l	a0,a3
	add.l	4(a0),a3	;Add length
	move.l	a2,a0
l1$:	cmp.l	(a0),d2
	beq.s	found$
	move.l	4(a0),d0	;Size of Chunk
	lea.l	(8,a0,d0.l*1),a0	;a0=a0+d0+8 (skip chunk)
	;; 8 Bytes: Chunk_ID <size>
	cmp.l	a3,a0
	blt.s	l1$
	moveq	#-1,d0
	bra.s	out$
found$:	lea.l	8(a0),a0	; Points now to data
	move.l	-4(a0),d0	; Number of bytes in chunk
	bra	out$


;;; Copy the CMAP chunk colours in an ILBM image into memory.
;;; Colour map is transformed in $0RGB format (16 bit).
	;; Input:
	;; A0: pointer to image
	;; A1: pointer to target area
	;; D0.w: module added after each copy operation (e.g. 2 if copying into a copper list, zero else).
	;; Output:
	;; D0: 0=OK, -1=Not found
	;; D1: Number of bytes in chunk
	;; Destroys:
	;; A0-A1
copy_cmap_chunk:
	;; D2: number of bytes in CMAP (decremented each loop to account for all colours).
	;; D3: modulo copied from D0
	movem.l	d2/d3,-(sp)
	move.l	d0,d3
	move.l	#"CMAP",d0
	bsr	find_iff_chunk
	tst.l	d0		;Number of bytes in CMAP (-1 = ERROR)
	bmi.s	out$
	move.l	d0,d2		;Number of bytes
l2$:	move.b	(a0)+,d0	;R
	lsl.w	#4,d0
	and.w	#$0f00,d0
	move.w	d0,d1
	move.b	(a0)+,d0	;G
	and.w	#$00f0,d0
	or.w	d0,d1
	move.b	(a0)+,d0	;B
	and.w	#$00ff,d0
	lsr.w	#4,d0
	or.w	d0,d1
	move.w	d1,(A1)+
	add.w	d3,a1		;Add modulo (if any)
	subq	#3,d2
	bpl.s	l2$
out$:	movem.l	(sp)+,d2/d3
	rts


;Interpret an bmhd chunk, this subroutine will get the most important
;information out of a BMHD chunk.
;Input:
;a0: pointer to BMHD data
;d0.l: size of BMHD chunk
;Output:
;d0.l: compression type
;d1.l: number of bitplanes
;d2.l: width in pixels
;d3.l: height in pixels
interpret_bmhd:
	moveq	#0,d0
	move.b	10(a0),d0
	moveq	#0,d1
	move.b	8(a0),d1
	moveq	#0,d2
	move.w	(a0),d2
	moveq	#0,d3
	move.w	2(a0),d3
	rts
