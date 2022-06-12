	include	"hardware/custom.i"
	include	"hardware/dmabits.i"
	include	"globals.i"

	xdef	_init_swinging
	xdef	_swinging_display
	xdef	_swinging_disable_slot

	xref	_custom
	XREF	_irqcounter

COPSLOTCMD = 16		; Number of commands per slot.

	section	data_c,data_c
copper_list:
        ;; Copper List
        ;; see: http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_2.html
        ;; AGA compatible setup?
        dc.w    fmode,$0000
        ;; Setting up display.
        ;; see also: http://cyberpingui.free.fr/tuto_graphics.htm
        dc.w    diwstrt,$2c81,diwstop,$2cc1
	;; Start fetching earlier for scroll. $30 instead od $38.
        dc.w    ddfstrt,$0030,ddfstop,$00d0
        ;; http://amiga-dev.wikidot.com/hardware:bplcon0
        dc.w    bplcon0,$200|(SWINGING_depth<<12)                   ; 1 Bitplanes, output enabled
copper_scrollcon:
        ;; http://www.winnicki.net/amiga/memmap/BPLCON1.html, scrolling
        ;; Lower nibbles are for scrolling, PF 1 and PF2.
;;;	dc.w    bplcon1,$0000
        ;; http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_4.html
        ;; http://www.winnicki.net/amiga/memmap/BPLCON2.html
        ;; http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node0159.html
        ;; $104          FEDCBA9876543210
        dc.w    bplcon2,%0000000000000000
        ;; Bitplane modulos
copper_bitplane_modulos:
        dc.w    bpl1mod,(640/8)-2
        dc.w    bpl2mod,(640/8)-2
copper_bplptr:
        dc.w    $00e0,$0000,$00e2,$0000         ; Bitplaneptrs, actually unused
        dc.w    $00e4,$0000,$00e6,$0000
        dc.w    $00e8,$0000,$00ea,$0000
        dc.w    $00ec,$0000,$00ee,$0000
        dc.w    $00f0,$0000,$00f2,$0000
        dc.w    color+2*0,$0fef ;Colour 0
        dc.w    color+2*1,$0321 ;Colour 1
        dc.w    bplcon0,$0000                   ; 0 Bitplanes, output disabled!
	;; Setup finished, now the effect:
copper_effect:
	REPT	8*COPSLOTCMD	; Eight slots for 16 commands
	dc.l	$01fe01fe	; NOP
	ENDR
	;; Finish COPPER off...
        dc.w    $ffdf,$fffe     ; End of NTSC.
	dc.w	$ffff,$fffe

	section	code

;;; Setup a copper slot
;;; Input: D0.l=effect number,D1.l=raster position,D2.w=scroll,A0.l=bitplaneptr
;;; Modifies: D0-D1/A0-A1
setup_slot:
Acoplst$:	equr	A2 ; Pointer to copper effect table
Drastpos$:	equr	D3 ; Raster position for effect
REGS$:	REG	Acoplst$/Drastpos$/D2
	movem.l	REGS$,-(a7)
	lea.l	copper_effect,Acoplst$
	move.w	d1,Drastpos$
	lsl.w	#6,d0		; 16 commands=32 words=64 bytes
	add.l	d0,Acoplst$
	lsl.w	#8,d1		; Move raster position to bits 8-15.
	or.w	#1,d1
	move.w	d1,(Acoplst$)+	; Store WAIT.
	move.w	#$fffe,(Acoplst$)+
	move.w	#bplpt+2,(Acoplst$)+ ; Low word of bitplane.
	move.w	a0,(Acoplst$)+
	move.l	a0,d0
	swap.w	d0
	move.w	#bplpt,(Acoplst$)+ ; Hi word of bitplane.
	move.w	d0,(Acoplst$)+
	move.w	d2,d0		; Scroll register value into d2
	lsl.w	#4,d0
	or.w	d2,d0
	move.w	#bplcon1,(Acoplst$)+
	move.w	d0,(Acoplst$)+
	move.l	#bplcon0<<16|$1200,(Acoplst$)+
	;; 	move.l	#$01800aaf,(Acoplst$)+
	move.w	Drastpos$,d0
	lsl.w	#8,d0
	add.w	#$0801,d0
	move.w	d0,(Acoplst$)+	; Store WAIT.
	move.w	#$fffe,(Acoplst$)+
	move.l	#bplcon0<<16|$0000,(Acoplst$)+
	;; 	move.l	#$01800fff,(Acoplst$)+
	movem.l	(a7)+,REGS$
	rts

;;; Inititalise the swinging display.
;;;
;;; This will initialise just the copper, the rest is done in the copper list. As there are initially no enabled rasters, a blank screen is displayed.
_init_swinging:
Acustom$:	equr	a5
regs$:	equr	Acustom$
	movem.l	regs$,-(sp)
	lea.l	_custom,a5
	move.l	#copper_list,cop1lc(a5)
	move.w	#DMAF_SETCLR|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER,dmacon(a5)
	movem.l	(sp)+,regs$
	rts

;;; Input: D0.w=number of slot...
	ifnd	NDEBUG
	dc.b	"t7d: disable"
	even
	endif
_swinging_disable_slot:
Acopptr$:	equr	A0
	lea.l	copper_effect,a0
	mulu.w	#COPSLOTCMD*4,d0
	add.w	d0,a0
	move.l	#$01fe0000,d0	; NoOp
	moveq	#COPSLOTCMD,d1
l$	move.l	d0,(a0)+
	dbf	d1,l$
	rts

;;; Input: extern void swinging_display(int effect, int raster, int offset, char *bitmap);
_swinging_display:
regs$:	reg	d2
	cargs	#4+4,effect$.l,raster$.l,offset$.l,bitmapptr$.l
	movem.l	regs$,-(sp)
	ifnd	NDEBUG
	bra	.jump
	dc.b	"T7D: swinging display"
	even
	.jump:
	endif
	;; Get the current bitplane pointer.
	move.l	bitmapptr$(sp),a0
	move.l	offset$(sp),d0	; Offset into the memory.
	lsr.w	#4,d0		; Which Byte?
	;; 	bclr	#0,d0		; Always even.
	add.l	d0,d0
	add.w	d0,a0		; Add to bitplane pointer.
	move.l	offset$(sp),d2	; Offset into the memory.
	and.w	#15,d2		; Only scroll bits.
	sub.w	#15,d2		; Do 15-D2
	neg.w	d2
	move.l	effect$(sp),d0
	move.l	raster$(sp),d1
	bsr	setup_slot
	movem.l	(sp)+,regs$
	rts

 
