	INCLUDE	"hardware/custom.i"
	INCLUDE	"t7d/blitter.i"

	XDEF	_copy_greetings_copperlist
	XDEF	_fire_plasma
	XDEF	_copy_plasma
	XDEF	_scroll_rect
	XDEF	_copy_greetings_colours
	XDEF	_greetings_rainbow

SCROLLERHEIGHT	EQU	8
FIREBLIBSPL	EQU	38	; MOVE per line for fire plasma
FIRELINES	EQU	31
;;; Offset from left.
LEFTOFFSET	EQU	3*4+2	; Left *colour* value

	;; http://users.ece.cmu.edu/~koopman/lfsr/16.txt
LFSR_TERM	equ	$864A

;;; Greetings info structure. Must be in sync with C code!
	RSRESET
greetings_info_linewidth:	rs.w	1
greetings_info_3linewidth:	rs.w	1
greetings_info_fireplasmaptr:	rs.l	1
greetings_info_3rdlineptr:	rs.l	1
greetings_info_bottomlineptr:	rs.l	1
greetings_info_rainbowpos:	rs.w	1
greetings_info_SizeOf:		rs
	ifeq	greetings_info_SizeOf
	FAIL	Info structure is zero!
	endif

;;; Make the rainbow effect for the scroller texts.
;;; Input
;;;	A0=pointer to a greetings_info structure
;;;	A1=pointer to colours
;;; Destroys: D0-D1/A0-A1
_greetings_rainbow:
reg$	reg	a2/a6
	movem.l	reg$,-(sp)
	move.l	a0,a2		; A2=ScrGreetings info struct
	lea.l	$DFF000,a6	; A6=custom base
	WAITBLITA6
	move.w	#$9f0,bltcon0(a6)  ; D=A
	move.w	#$0000,bltcon1(a6) ; ascending mode
	move.w	#$FFFF,bltafwm(a6) ; bltafwm
	move.w	#$FFFF,bltalwm(a6) ; bltalwm
	;; Get correct position of the colours.
	add.w	greetings_info_rainbowpos(a2),a1
	move.l	a1,bltapt(a6)	; Source
	move.l	greetings_info_fireplasmaptr(a2),a0 ; First line of plasma
	add.w	#LEFTOFFSET-4,a0	; minus four as the colour is set before the background colours.
	move.l	a0,bltdpt(a6)	; Destination
	clr.w	bltamod(a6)	; One colour value after the other
	move.w	greetings_info_linewidth(a2),d0
	subq	#2,d0		; Skip rest of line
	move.w	d0,bltdmod(a6)
	;;  H9-H0, W5-W0; width is in words.
	move.w	#(1)|((FIRELINES*3)<<6),bltsize(a6)
	move.w	greetings_info_rainbowpos(a2),d0
	addq	#2,d0
	cmp.w	#255*2,d0
	bcs.s	noreset$
	moveq	#0,d0
noreset$:
	move.w	d0,greetings_info_rainbowpos(a2)
	movem.l	(sp)+,reg$
	rts


;;; Copy out nice greetings colours into the area pointed to by A0.
;;; Input
;;;	A0=pointer to target area (511*2 words)
;;; Destroys: D0-D1/A0-A1
_copy_greetings_colours:
reg$	reg	d2-d7/a2-a6
	movem.l	reg$,-(sp)
	lea.l	rainbow_ilbm_palette+4,a1 ; A1=pointer to colours
	move.l	#4*(5+5),d1		  ; D1=advancement of 20 words or 40 bytes
	moveq	#0,d0			  ; Copy at start
	move.w	#255*2,d2		  ; D2=255 words later
	;; (/ (* 255 2 ) 40)12
	REPT	12
	movem.l	(a1)+,d3-d7/a2-a6
	movem.l	d3-d7/a2-a6,0(a0,d0.w)
	movem.l	d3-d7/a2-a6,0(a0,d2.w)
	add.w	d1,d0
	add.w	d1,d2
	ENDR
	;; Bytes still to copy(- 510 (* 12 40))30
	movem.l	(a1)+,d3-d4/a2-a6	; 7 registers = 28 Bytes
	movem.l	d3-d4/a2-a6,0(a0,d0.w)
	movem.l	d3-d4/a2-a6,0(a0,d2.w)
	add.w	#28,d0
	add.w	#28,d2
	;; 2 Bytes left to copy
	move.w	(a1),0(a0,d0.w)
	move.w	(a1),0(a0,d2.w)
	movem.l	(sp)+,reg$
	rts

;;; scroll a rectangle using the blitter
;;; Input: A0=pointer after last line, D0=pixel to scroll
_scroll_rect:
reg$	reg	a6
	movem.l	reg$,-(sp)
	lea.l	$DFF000,a6	; A6=custom base
	subq	#2,a0		; A0=last word of screen area
	ror.w	#4,d0		; Rotate the lower four bits into $X000.
	or.w	#$9f0,d0	; A shift is 2, A&D channel, minterm: D=A
	WAITBLITA6
	move.w	d0,bltcon0(a6)
	move.w	#$0002,bltcon1(a6) ; descending mode
	move.w	#$FFF0,bltafwm(a6) ; bltafwm
	move.w	#$FFFF,bltalwm(a6) ; bltalwm
	move.l	a0,bltapt(a6)
	move.l	a0,bltdpt(a6)
	clr.w	bltamod(a6)
	clr.w	bltdmod(a6)
;*;  /* H9-H0, W5-W0; width is in words. By writing the size into the
;*;     custom chip register the blit begins and continues while the cpu
;*;     is still running. */
	move.w	#(336/8/2)|(SCROLLERHEIGHT<<6),bltsize(a6)
	movem.l	(sp)+,reg$
	rts


;;; Do LFSR step using D6.
;;; Input: D6=old LFSR state
;;; Output: D0=lfsr value, D6=new lfsr state
step_LFSR_in_D6:	
	lsr.w	#1,d6
	bcc.s	no$
	eor.w	#LFSR_TERM,d6
no$:	move.w	d6,d0
	rts

;;; Input: A0=destination pointer, A1=bitplane pointer,
;;;	D0=startline for effect, D1=pointer to info struct
;;; Output: D0.L=actual copperlist size
_copy_greetings_copperlist:
reg$	reg	d2/d7/a2-a3
	movem.l	reg$,-(sp)
	move.l	d0,d7		; D7=startline/current line
	move.l	d1,a3		; A3=pointer to info struct
	move.l	a0,a2		; A2=destination pointer
	move.l	a1,d1		; D1=bitplane pointer
	lea.l	greetings_copperlist,a0 ; A0=source
	move.w	d1,6(a0)	; Change the BPL1PTL
	swap	d1
	move.w	d1,2(a0)	; Change the BPL1PTH
	;; Copy the default portion of the copperlist.
	move.l	#(greetings_copperlist_end-greetings_copperlist)/2-1,d0
	move.l	a2,a1		; Use A1 for copy (A1=A2)
l9$:	move.w	(a0)+,(a1)+
	dbf	d0,l9$
	;; Generate the fire plasma lines.
	move.l	a1,greetings_info_fireplasmaptr(a3)
	bsr	genlines$
	;; Now the line width has been set.
	move.w	greetings_info_linewidth(a3),d0
	mulu	#3,d0
	move.w	d0,greetings_info_3linewidth(a3)
	moveq	#0,d0
	move.w	greetings_info_linewidth(a3),d0
	lsl.w	#2,d0
	add.l	greetings_info_fireplasmaptr(a3),d0
	move.l	d0,greetings_info_3rdlineptr(a3)
	;; Bottom line is actually four from the bottom.
	move.l	#FIRELINES-4,d0
	mulu	greetings_info_3linewidth(a3),d0
	add.l	greetings_info_fireplasmaptr(a3),d0
	move.l	d0,greetings_info_bottomlineptr(a3)
	;; End of Copper list.
	move.l	#$FFFFFFFE,(a1)+
	move.l	a1,d0		; End of copperlist
	sub.l	a2,d0		; Subtract beginning for size.
	movem.l	(sp)+,reg$
	rts
genlines$:
;;; Generate all the lines.
;;; Input: A1=destination pointer
	move.w	#(FIRELINES*3)-1,d2
l95$:	move.l	a1,-(sp)	; Beginning address of line on stack.
	bsr.s	genline$
	move.l	a1,d0		; D0=current address of line
	sub.l	(sp)+,d0	; subtract beginning
	move.w	d0,greetings_info_linewidth(a3) ; Store line length
	addq	#2,d7		; next line (every second line)
	dbf	d2,l95$
	rts
genline$:
;;; Generates a single plasma line, first a WAIT instruction and the the foreground colour is set and then FIREBLIBSPL moves to the background colour are performed. Finally the background is set to black.
;;; Input: D7=line number, A1=target pointer
;;; Modifies: D0,A1
;;; Output: A1=points after last writte copper-list word
	move.w	d7,d0
	cmp.w	#$0100,d0	; PAL/NTSC
	beq.s	l119$
	move.l	#$01feEAEA,(a1)+
	bra.s	l121$
l119$:	move.l	#$ffdffffe,(a1)+
l121$:
	lsl.w	#8,d0		; Lower eight bits are now zero
	btst	#0,d7		; Check d7 for even/odd
	bne.s	l106$
	or.w	#$3f,d0
	bra.s	l108$
l106$:	or.w	#$41,d0
l108$:	move.w	d0,(a1)+	; WAIT
	move.w	#$fffe,(a1)+	; WAIT waiting mask
	move.l	#$01820fd5,(a1)+ ; foreground
	moveq	#FIREBLIBSPL-1,d0
l110$:	move.l	#$01800000,(a1)+ ; blue background
	dbf	d0,l110$
	move.l	#$01800000,(a1)+ ; black background
	rts

;;; Input: A0=pointer to greetings info, D0=nonzero if skip another line
_copy_plasma:
reg$	reg	d5-d7/a2-a3/a6
	movem.l	reg$,-(sp)
	move.l	a0,a6		; A6=info struct
	move.w	greetings_info_3linewidth(a6),d5 ; D5=three lines
	move.l	greetings_info_fireplasmaptr(a6),a3 ; A3=top left chunky
	move.l	a3,a2
	move.w	greetings_info_linewidth(a6),a0
	add.w	a0,a0
	add.w	a0,a2		; Plasma line
	tst.l	d0
	beq.s	s59$
	add.w	greetings_info_linewidth(a6),a3
s59$:
	;; Skip left area with WAIT, etc.
	lea.l	LEFTOFFSET(a3),a3
	lea.l	LEFTOFFSET(a2),a2
	move.l	#FIRELINES-2,d7	; D7=row counter
l2$:	moveq	#FIREBLIBSPL-1,d6	; D6=X coordinates to calculate
	move.l	a2,a0		; Set current line pointer
	move.l	a3,a1		; Set current line pointer
l1$:	move.l	(a0)+,(a1)+
	dbf	d6,l1$
	add.w	d5,a2	; Next line
	add.w	d5,a3	; Next line
 	dbf	d7,l2$
	;; 	move.w	d7,$dff180
	movem.l	(sp)+,reg$
	rts

;;; Input: A0=pointer to copperlist, A1=pointer to info struct
_fire_plasma:
reg$	reg	d3-d4/d6-d7/a2-a3/a6
	;;      X	x = (1+2+3+4)*(27/32)
	;;     123
	;;      4
	movem.l	reg$,-(sp)
	move.l	a1,a6		; A6=pointer to info struct
	bsr.s	heat$
	bsr	plasma$
	movem.l	(sp)+,reg$
	rts
heat$:
	move.l	greetings_info_bottomlineptr(a6),a1
	move.w	greetings_info_linewidth(a6),d0
	add.w	d0,d0
	add.w	d0,a1
	move.w	#$0013,d7	; D7=$000F or brightest colour
	move.w	lfsr$(pc),d6	; D6=LFSR
	move.w	greetings_info_3linewidth(a6),a3 ; a3=three lines width
	;;
	MACRO	HEAT
	 jsr	step_LFSR_in_D6
	 and.w	#32-1,d0
	 lsl.w	#2,d0
	 move.w	D7,8+LEFTOFFSET+0(a1,d0)
	 move.w	D7,8+LEFTOFFSET-4(a1,d0)
	 move.w	D7,8+LEFTOFFSET+4(a1,d0)
	 add.l	a3,d0
	 move.w	D7,8+LEFTOFFSET+0(a1,d0)
	ENDM
	HEAT
	HEAT
	HEAT
	HEAT
	move.w	d6,lfsr$	; put current lfsr state into memory
	rts
plasma$:
	moveq	#FIRELINES-3,d4	; D4=row counter
	move.l	greetings_info_fireplasmaptr(a6),a3
	move.w	greetings_info_linewidth(a6),d0
	add.w	d0,d0
	add.w	d0,a3
	move.w	greetings_info_3linewidth(a6),d7 ; D7=distance between two plasma lines
	lea.l	LEFTOFFSET+4(a3),a3	; 8 skip foreground and one plasma blib
l2$:	move.l	a3,a2
	lea.l	0(a2,d7.w),a1		; Set next line pointer
	;; Loop unrolling for speed!
	REPT	FIREBLIBSPL-2-1	; ⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊⇊
	move.w	-4(a1),d3		; d3 will be sum
	add.w	(a1),d3
	add.w	+4(a1),d3
	add.w	0(a1,d7.w),d3
	lsr.w	#2,d3		; Average four values.
	move.w	d3,(a2)
	lea.l	4(a2),a2	; Pixel to the right
	lea.l	4(a1),a1	; Next line, pixel to the right.
	ENDR			; ⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈⇈
	add.w	d7,a3		; next plasma line
 	dbf	d4,l2$
	;; 	move.w	#$733,$dff180
	rts
lfsr$:	dc.w	$77d


	SECTION DATA,DATA
;;; If prearranged use "vasm -Fraw" and compress...
greetings_copperlist:
	dc.w	$e0,0
	dc.w	$e2,0
	;; COPPER NO-OP
	dc.w	$1fe,0
greetings_copperlist_end:

	INCLUDE	"rainbow.i"
