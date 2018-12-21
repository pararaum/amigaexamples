	include "hardware/custom.i"
	include	"own.i"
	
	XDEF	_init_framework
	XDEF	_shutdown_framework
	XDEF	_wait_for_mouse
	XREF	_do_interrupt_warp

SCROLLER_SPARE_LINES	EQU	8

font_pointer:
	dc.l	0
bitplane_pointer:
	dc.l	0
scroller_spare:
	;dc.w	$AAAA
	;dc.w	$5555
	;dc.w	$AAAA
	;dc.w	$5555
	;dc.w	$AAAA
	;dc.w	$5555
	;dc.w	$AAAA
	;dc.w	$5555
	ds.w	SCROLLER_SPARE_LINES

;;; Scroll 8 scan lines to the left.
;;; Input:
;;; Output:
;;; Destroys: A0-A1/D0-D1
scroll_left:
	move.l	bitplane_pointer(pc),a1
	lea.l	scroller_spare(pc),a0
	;; |----------------|
	;;                ^ move pointer here
	lea.l	320/8*128+320/8-2(a1),a1	; End of line 128.
        moveq  #SCROLLER_SPARE_LINES-1,d1		; 8 lines to move.
l2$:    lsl.w   (a0)+		; One pixel to the left in spare.
        moveq   #320/8/2-1,d0	; Remainder of the line.
l1$:    roxl.w  (a1)
	lea     -2(a1),a1
        dbf     d0,l1$
	;; We have to add two times the size of a scanline as we moved
	;; backward from the end and we need to skip to the end of the
	;; current line and move forward to the end of the *next* line.
	lea     2*320/8(a1),a1    ; Move one line forward.
        dbf     d1,l2$
	rts

	
interrupt_autovector:
	movem.l	d0-d7/a0-a6,-(sp)	;Store registers
	lea.l	$DFF000,a6
	move.w	#$0e10,$180(a6)		;Change background
	move.w	vhposr(a6),d7		;First raster line
	lsr.w	#8,d7			;Move 8 bits to the right (vertical position)
	;; 	move.l	#scroll_left,$3fc
	bsr	scroll_left
	move.w	vhposr(a6),d0	;Current raster position
	lsr.w	#8,d0		;Move 8 bits to the right (vertical position)
	sub.w	d7,d0		;Subtract to calculate number of needed scan lines.
	ext.l	d0		;Extent to 32bit.
	;; 	move.l	#interrupt_autovector,$3fc
	move.l	d0,-(sp)	; Push number of scan lines
	pea.l	scroller_spare	; Push address of the scroller spare onto the stack.
	;; Now the C routine can be called.
	jsr	_do_interrupt_warp
	addq	#4+4,a7		       ;Clean up stack.
	move.w	#$0010,$180(a6)		;Change background
	move.w	#(1<<2),$dff000+intreq	;Acknowledge interrupt
	movem.l	(sp)+,d0-d7/a0-a6	;Restore registers
	rte

;;; Initialise using the framework, will set interrupt, etc.
;;; Input
;;; A0 = pointer to the font data
;;; A1 = pointer to the bitplane data
;;; Output:
;;; D0 = pointer to the bitplane space.
_init_framework:
	movem.l	d2-d7/a2-a6,-(sp)
	move.l	a0,font_pointer
	move.l	a1,bitplane_pointer
        moveq   #OWN_libraries|OWN_view|OWN_trap|OWN_interrupt,d0
        jsr     own_machine
	lea.l	$dff000,a6
	move.w	#$0fff,180(a6)
	;; Now set the level 1 autovector (for SOFT interrupt).
	lea.l	interrupt_autovector(pc),a0
	move.l	a0,$64.w
	move.w	#$8000|(1<<14)|(1<<2),intena(a6)
	movem.l	(sp)+,d2-d7/a2-a6
	rts

;;; Restore the system.
_shutdown_framework:
	movem.l	d2-d7/a2-a6,-(sp)
        jsr     disown_machine
	movem.l	(sp)+,d2-d7/a2-a6
	rts

;;; Wait for mouse button.
;;; Destroys: A0
_wait_for_mouse:
	lea	$BFE001,a0		;CIA A
l$:	btst	#6,(a0)
	bne.b	l$
	rts

