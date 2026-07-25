	include	hardware/custom.i
	include	hardware/dmabits.i

	include boss.memorymanagement.i
	include	boss.io.i

	XREF	boss_manifest_load

	XDEF	boss_io_init

LOWEST_SCREEN_ROW:	equ	32

;;; Include a nice font into the data segment.
	DATA
_FONT:	incbin	"Computing 60s Bold.ch8"
	EVEN
;;; Current screen row.
screen_row:	dc.w	0
;;; Current screen column.
screen_col:	dc.w	0

	data
coplist:
	;; Bitplane pointer points to our screen.
	dc.w	bplpt,0,bplpt+2,0	; Filled by code.
	dc.w	$0106,$0000,$01fc,$0000		; AGA compatible
	;; Setting up display.
	;; see also: http://cyberpingui.free.fr/tuto_graphics.htm
	dc.w	diwstrt,$2c71,diwstop,$2cc1	; DIWSTRT/DIWSTOP
	dc.w	ddfstrt, $0038,ddfstop,$00d0	; DDFSTRT/DDFSTOP
	dc.w	bplcon0,$8000|(1<<12)|$200	; HiRes and one bitplane.
	dc.w	bplcon1,$0000,bplcon2,$0000
	dc.w	bplcon3,$0000
	dc.w	bpl1mod,$0000,bpl2mod,$0000
coplist_color00:
	dc.w	color+0,$0172		  ; Dark green background.
coplist_color01:
	dc.w	color+2,$06fb		  ; Light green foreground.
	dc.w	$FFFF,$FFFE		  ; Wait for end.
coplist_end:
;;; This produces an error message: Reference to undefined symbol _SDA_BASE_. Why?
;;; coplist_color00_offset = coplist_end - coplist
coplist_color00_offset:	equ	60
coplist_color01_offset:	equ	62


	code
boss_io_init:
	lea	trap1code(pc),a0
	move.l	a0,$84.w	; Set vector for TRAP#1.
	bsr	init_custom
	bsr	trap1clrscr
	move.w	#21,screen_row	; We start at this row.
	rts


init_custom:
	;; Copy copper list.
	lea.l	coplist(pc),a0
	lea.l	BOSSSCREENCOPPERLIST,a1
	move.l  a1,cop1lc(a5)   ; Point copper to the Copperlist.
	move.l	#BOSSSCREENBITPLANE,d0 ; Put screen address into d0, in order to...
	move.w	d0,6(a0)	       ; ...to put the low word into the copper list and...
	swap	d0
	move.w	d0,2(a0)		; ...do the same with high word.
	moveq	#(coplist_end-coplist)/2,d0 ; Now put length in D0 for trap.
	BossMem	BossMemTrapCopyWords
	;; Enable DMA.
	move.w  #DMAF_SETCLR|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER,dmacon(a5)
	rts


	;; Font/Console/IO functions
trap1code:
	movem.l	d2-d7/a2-a6,-(sp)
	lsl.w	#2,d7
	jsr	list$(PC,d7.w)
	movem.l	(sp)+,d2-d7/a2-a6
	rte
	;; Use JMP because BSR may be optimised to BSR.S!
list$:	jmp	trap1init_custom(pc)
	jmp	trap1putc(pc)
	jmp	trap1write(pc)
	jmp	trap1writeln(pc)
	jmp	trap1home(pc)
	jmp	trap1clrscr(pc)
	jmp	trap1scroll_up(pc)
	jmp	trap1output_hex(pc)
	jmp	trap1foreground(pc)
	jmp	trap1background(pc)
	jmp	trap1dumpregs(pc)
	rept	10
	illegal
	illegal
	endr
	jmp	boss_trackload_data(pc)
	jmp	boss_manifest_load(pc)
	;; If we forget to increase this should be a gentle reminder.
	illegal

trap1init_custom:
	lea	$DFF000,a5
	bsr	init_custom
	lea.l	BOSSSCREENCOPPERLIST,a1
	lea.l	BOSSSCREENBITPLANE,a0
	rts

trap1dumpregs:
	lsr.w	#2,d7		; Restore.
	move.l	a7,oldstack$
	movem.l	d0-a7,-(sp)	; Put *everything* on stack.
	moveq	#0,d6
l1$:	move.l	0(a7,d6.l),-(sp)
	bsr	_ul2hex
	addq.l	#4,sp		; Fix stack
	move.l	d0,a0
	bsr	trap1write
	REPT	2
	moveq	#' ',d0
	bsr	trap1putc
	ENDR
	addq.w	#4,d6
	cmp.w	#16*4,d6
	bne	l1$
	move.l	oldstack$(pc),a7
	rts
	PUSHSECTION
	BSS
oldstack$:	ds.l	1
	POPSECTION

trap1background:
	move.l	d0,BOSSSCREENCOPPERLIST+coplist_color00_offset
	rts

trap1foreground:
	move.l	d0,BOSSSCREENCOPPERLIST+coplist_color01_offset
	rts

trap1output_hex:
	move.l	d0,-(sp)	; Put on stack for C.
	bsr	_ul2hex
	addq.l	#4,sp		; Fix stack
	move.l	d0,a0
	bra	trap1write	; And output, tail recursion.

trap1home:
	moveq	#0,d0
	move.w	d0,screen_row
	move.w	d0,screen_col
	rts

trap1clrscr:
	BossMemClearWords	BOSSSCREENBITPLANE,640*256/8/2
	bra	trap1home

trap1scroll_up:
	lea.l	BOSSSCREENBITPLANE,a1 ; Destination
	lea.l	640/8*8(a1),a0	  ; Source, top left position + one line.
	move.w	#640/8/2*(256-8),d0
	BossMem	BossMemTrapCopyWords
	lea.l	BOSSSCREENBITPLANE+640/8*(256-8),a0 ; Destination
	move.w	#8*640/8/2,d0			; Clear 8 rows.
	BossMem	BossMemTrapClearWords
	rts

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
	lea	BOSSSCREENBITPLANE,a1
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
	addq.w	#1,screen_row	; Move to next row.
	cmp.w	#LOWEST_SCREEN_ROW,screen_row	; Have we left the lowest row?
	blt.s	norowadjust$
	subq.w	#1,screen_row	; We are back on the visible area.
	bsr	trap1scroll_up
norowadjust$:
	moveq	#0,d0		; Move cursor to the left of screen
less80$:
	move.w	d0,screen_col
	rts
charCR$:
	moveq	#0,d0
	move.w	d0,screen_col
	rts
charLF$:
	addq.w	#1,screen_row
	cmp.w	#LOWEST_SCREEN_ROW,screen_row	; Have we left the lowest row?
	blt.s	charCR$
	subq.w	#1,screen_row	; We are back on the visible area.
	bsr	trap1scroll_up
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
