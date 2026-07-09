;;; Basic Operating System Simulacrum
	include	hardware/custom.i
	include	hardware/dmabits.i

SCREENCOPLIST=$400
;;; The screen bitplane is 640/8*256=20480 bytes large.
SCREENBITPLANE=$480

	data
	dc.b	"DATA begins here."
	even

welcome_text:	dc.b	"Booting BOSS...",0
welcome_text2:	dc.b	"...I am ready for you.",0
	even
	
_FONT:	incbin	"Computing 60s Bold.ch8"
	EVEN
screen_row:	dc.w	0
screen_col:	dc.w	0

coplist:
	dc.w	$0106,$0000,$01fc,$0000		; AGA compatible
	;; Setting up display.
	;; see also: http://cyberpingui.free.fr/tuto_graphics.htm
	dc.w	diwstrt,$2c71,diwstop,$2cc1	; DIWSTRT/DIWSTOP
	dc.w	ddfstrt, $0038,ddfstop,$00d0	; DDFSTRT/DDFSTOP
	dc.w	bplcon0,$8000|(1<<12)|$200	; HiRes and one bitplane.
	dc.w	bplcon1,$0000,bplcon2,$0000
	dc.w	bplcon3,$0000
	dc.w	bpl1mod,$0000,bpl2mod,$0000
	dc.w	color+0,$0172		  ; Dark green background.
	dc.w	color+2,$06fb		  ; Light green foreground.
	;; Bitplane pointer points to our screen.
	dc.w	bplpt,SCREENBITPLANE>>16,bplpt+2,SCREENBITPLANE&$FFFF
	dc.w	$FFFF,$FFFE		  ; Wait for end.
coplist_end:

	;; **********************************************************************
	;; MAIN
	;; **********************************************************************
	CODE
	lea	$DFF000,a5	; Custom base in A5.
	move.w	#$7fff,intena(a5) ; Disable interrupts.
	move.w	#$7fff,intreq(a5) ; Disable interrupt requests.
	move.w	#$7fff,dmacon(a5) ; Disable DMA.
	bsr	init_traps
	bsr	init_custom

	lea.l	SCREENBITPLANE,a0
	move.w	#640*256/8/2,d0
	moveq	#1,d7		; CLEAR
	trap	#0

	lea.l	welcome_text,a0
	moveq	#2,d7
	trap	#1
	lea.l	welcome_text2,a0
	moveq	#2,d7
	trap	#1
	jmp	*

init_traps:
	lea	trap0code(pc),a0
	move.l	a0,$80.w	; Set vector for TRAP#0.
	lea	trap1code(pc),a0
	move.l	a0,$84.w	; Set vector for TRAP#1.
	rts

init_custom:
	;; Copy copper list.
	lea.l	coplist(pc),a0
	lea.l	SCREENCOPLIST,a1
	move.l  a1,cop1lc(a5)   ; Point copper to the Copperlist.
	moveq	#coplist_end-coplist,d0
	moveq	#0,d7		; COPY
	trap	#0
	;; Enable DMA.
	move.w  #DMAF_SETCLR|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER,dmacon(a5)
	rts

trap0code:
	move.l	a6,-(sp)
	lsl.w	#2,d7
	move.l	list$(PC,d7.w),a6
	jsr	(a6)
	move.l	(sp)+,a6
	rte

list$:	dc.l	trap0copy
	dc.l	trap0clear
	
trap0copy:
l1$	move.w	(a0)+,(a1)+
	dbf	d0,l1$
	rts
trap0clear:
l1$:	clr.w	(a0)+
	dbf	d0,l1$
	rts


	;; Font functions
trap1code:
	movem.l	d2-d7/a2-a6,-(sp)
	lsl.w	#2,d7
	jsr	list$(PC,d7.w)
	movem.l	(sp)+,d2-d7/a2-a6
	rte
list$:	jmp	trap1putc(pc)
	jmp	trap1write(pc)
	jmp	trap1writeln(pc)

;;; D0=char
trap1putc:
	lea	_FONT(pc),a0
	cmp.w	#10,d0
	beq.s	charLF$
	cmp.w	#13,d0
	beq.s	charCR$
	sub.w	#32,d0		; Characters start with space.
	lsl.w	#3,d0		; ASCII code * 8.
	adda.w	d0,a0		; Points to character.
	move.w	screen_row,d0
	mulu	#640/8*8,d0	; 640 pixel per row, char is eight raster lines.
	lea	SCREENBITPLANE,a1
	adda.w	d0,a1
	add.w	screen_col,a1
	moveq	#8-1,d0
l1$:	move.b	(a0)+,(a1)
	lea.l	640/8(a1),a1
	dbf	d0,l1$
	;; Now advance cursor.
	move.w	screen_col,d0	; Column into d0.
	addq.w	#1,d0		; Advance to next column.
	cmp.w	#80,d0		; Right border reached?
	blt.s	less80$		; No, every thing is OK.
	moveq	#0,d0		; Move cursor to the left of screen
	addq.w	#1,screen_row	; Move to next row.
	;; TODO: Implement scrolling.
less80$:move.w	d0,screen_col
	rts
charCR$:
	moveq	#0,d0
	move.w	d0,screen_col
	rts
charLF$:
	addq.w	#1,screen_row
	bra.s	charCR$

trap1write:
	move.l	a0,a2
	moveq	#0,d0
l1$:	move.b	(a2)+,d0
	beq	out$
	bsr	trap1putc
	bra.s	l1$
out$:	rts

trap1writeln:
	bsr	trap1write
	moveq	#10,d0
	bsr	trap1putc
	rts
