	include "hardware/custom.i"
	include	"own.i"
	
	XDEF	_init_framework
	XDEF	_shutdown_framework
	XDEF	_wait_for_mouse
	XDEF	_fade_rasterbars
	XREF	_do_interrupt_warp

RASTERBARLINES	equ	($d6-$30)

;;; Fade the rasterbars, a pointer to the wait instruction is given.
;;; Input
;;; A0: pointer to copper list wait instruction
_fade_rasterbars:
	movem.l	d2-d3,-(sp)
	;; d2: rasterbarlines to fade
	;; d3: register to build up target colour
	;; Advance pointer to colour value
	addq.l	#6,a0
	move.w	#RASTERBARLINES,d2
l1$:	moveq	#0,d3		;Clear target colour register
	move.w	(a0),d0		;get colour value
	move.w	d0,d1		;store original colour in D1
	and.w	#$000f,d0	;B
	sub.w	#$0001,d0	;reduce
	bmi.s	noB$
	or.w	d0,d3
noB$:	move.w	d1,d0		;original colour, again
	and.w	#$00f0,d0	;G
	sub.w	#$0010,d0	;reduce
	bmi.s	noG$
	or.w	d0,d3
noG$:	move.w	d1,d0		;original colour, again
	and.w	#$0f00,d0	;R
	sub.w	#$0100,d0	;reduce
	bmi.s	noR$
	or.w	d0,d3
noR$:	move.w	d3,(a0)		;Write into copper list
	addq	#8,a0		;Advance to next colour value
	dbf	d2,l1$
	movem.l	(sp)+,d2-d3
	rts

font_pointer:
	ds.l	1
bitplane_pointer:
	ds.l	1

interrupt_autovector:
	movem.l	d0-d7/a0-a6,-(sp)	;Store registers
	IFND	NDEBUG
	lea.l	$DFF000,a6
	move.w	#$0e10,$180(a6)		;Change background
	ENDIF
	;; Now the C routine can be called.
	jsr	_do_interrupt_warp
	IFND	NDEBUG
	move.w	#$007D,$180(a6)		;Change background
	ENDIF
	jsr	pt_PlayMusic
	IFND	NDEBUG
	move.w	#$0010,$180(a6)		;Change background
	ENDIF
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
	lea.l	tracker_song_data,a0
	jsr	pt_InitMusic
	movem.l	(sp)+,d2-d7/a2-a6
	rts

;;; Restore the system.
_shutdown_framework:
	movem.l	d2-d7/a2-a6,-(sp)
        jsr     disown_machine
	jsr	pt_StopMusic
	movem.l	(sp)+,d2-d7/a2-a6
	rts

;;; Wait for mouse button.
;;; Destroys: A0
_wait_for_mouse:
	lea	$BFE001,a0		;CIA A
l$:	btst	#6,(a0)
	bne.b	l$
	rts

