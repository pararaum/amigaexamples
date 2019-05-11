        INCLUDE "hardware/custom.i"
        INCLUDE "hardware/intbits.i"
        INCLUDE "hardware/dmabits.i"
	include	"own.i"

	;;; A6 contains the $DFF000 custom chip base.

	SECTION	CODE,code
_start:	jmp	main(pc)
	dc.b	"Moire Pattern",10
	dc.b	"Code: Pararaum / T7D",0
	align	4
	cmp.l	#"main",main
	align	4
main:	nop
	moveq	#OWN_libraries|OWN_view|OWN_trap|OWN_interrupt,d0
	jsr	own_machine
	lea.l	$DFF000,a6
	bsr	setup_system
	move.w	#-(moirepattern_png_width-320)/2,mpos_odd_x
	move.w	#(moirepattern_png_height-256)/2,mpos_odd_y
l3$:	nop
	bsr	wait_frame
	;; 	move.w	counter$(pc),color+2(a6)
	addq.w	#1,counter$
	move.w	counter$(pc),d0
	lsr.w	#2,d0
	and.w	#$7f,d0
	sub.w	#$40,d0
	add.w	#-(moirepattern_png_width-320)/2,d0
	move.w	d0,mpos_even_x
	move.w	counter$(pc),d0
	lsr.w	#3,d0
	and.w	#$3f,d0
	sub.w	#$20,d0
	add.w	#(moirepattern_png_height-256)/2,d0
	move.w	d0,mpos_even_y
	bsr	do_moire
	btst	#6,$bfe001	; Left mouse clicked?
	bne.s	l3$
	move.w	#$7fff,dmacon(a6)
	move.w	#$7fff,intena(a6)
	jsr	disown_machine
	moveq	#0,d0
	rts
counter$:	dc.w	0
	jmp	_start

setup_system:
	move.w	#$7fff,dmacon(a6)
	move.w	#$7fff,intena(a6)
	bsr	do_moire
	bsr	setup_copper
	move.w	#DMAF_SETCLR|DMAF_BLITTER|DMAF_COPPER|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER,dmacon(a6)
	move.l	#irq_routine,$6c.w ;Vertical blanking
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,intena(a6)
	rts

do_moire:
	move.w	mpos_even_x,d0
	move.w	mpos_even_y,d1
	move.w	mpos_odd_x,d2
	move.w	mpos_odd_y,d3
	lea.l	moirepattern_png,a0
	lea.l	moirepattern_png,a1
	lea.l	copper_moire_space,a2
	bra	move_image
	;; Optimised away: RTS

;;; Position superlarge image using bitplane pointers and copper list setup.
;;; INPUT
;;; D0.w: displacement odd bitplanes X
;;; D1.w: displacement odd bitplanes Y
;;; D2.w: displacement even bitplanes X
;;; D3.w: displacement even bitplanes Y
;;; A0: pointer to odd bitplane
;;; A1: pointer to even bitplane
;;; A2: pointer to copper space (2+2+1=5 commands)
;;; DESTROYS: all of the above.
move_image:
	mulu	#moirepattern_png_width/8,d1 ; Advance that many lines (result is 32 bits).
	add.l	d1,a0			     ; A0 now contains the line of the odd bitplane.
	move.w	d0,d1		; D1 contains now x displacement.
	and.w	#$FFF0,d1
	asr.w	#3,d1		; Divide by 8 for bytes.
	neg.w	d1		; If moved to the right then we have to start fetching data earlier.
	ext.l	d1
	add.l	d1,a0		; Add the offset to the odd bitplane pointer.
	mulu	#moirepattern_png_width/8,d3
	add.l	d3,a1		; A1 now contains the line of the even bitplane.
	move.w	d2,d3
	and.w	#$FFF0,d3
	asr.w	#3,d3
	neg.w	d3
	ext.l	d3
	add.l	d3,a1
	;; http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node0022.html
	;; PF2H?: bits 4-7, PF1H?: bits 0-3
	and.w	#$f,d0		; Displacement lower four bits (odd).
	and.w	#$f,d2		; Displacement lower four bits (even).
	lsl.w	#4,d2		; PF2H?
	or.w	d0,d2		; D2=new value for BPLCON1
	move.l	a0,d0		; d0=odd bitplane pointer
	move.w	#bplpt+2,(a2)+	; lower 16 bits
	move.w	d0,(a2)+
	swap	d0
	move.w	#bplpt,(a2)+	; Upper 16 bits
	move.w	d0,(a2)+
	move.l	a1,d0		; d0=even bitplane pointer
	move.w	#bplpt+6,(a2)+	; lower 16 bits
	move.w	d0,(a2)+
	swap	d0
	move.w	#bplpt+4,(a2)+	; Upper 16 bits
	move.w	d0,(a2)+
	move.w	#bplcon1,(a2)+
	move.w	d2,(a2)+
	rts
	
wait_frame:
l1$:	btst.b	#0,vposr+1(a6)
	beq.s	l1$
l2$:	btst.b	#0,vposr+1(a6)
	bne.s	l2$
	rts


irq_routine:
	movem.l	d0-d7/a0-a6,-(sp)
	NOP
	move.w	#INTF_VERTB,intreq(a6) ;Acknowledge interrupt
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;;; Setup the copper and write the corresponding wait and color instructions.
setup_copper:
	movem.l	d2-d7/a2-a6,-(sp)
	;; D3: line numner
	;; Setup copper pointer.
	move.l	#copper_list,cop1lc(a6)
	clr.w	copjmp1(a6)	 ; Strobe copper
	movem.l	(sp)+,d2-d7/a2-a6
	rts


	SECTION	DATA,data

	SECTION	CHIP,data_c
copper_list:
	;; Copper List
	;; see: http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_2.html
	;; AGA compatible setup?
	dc.w 	fmode,$0000
	;; Setting up display.
	;; see also: http://cyberpingui.free.fr/tuto_graphics.htm
	dc.w	$008e,$2c81,$0090,$2cc1		; DIWSTRT/DIWSTOP
	dc.w	$0092,$0038,$0094,$00d0		; DDFSTRT/DDFSTOP
	;; http://amiga-dev.wikidot.com/hardware:bplcon0
	dc.w	bplcon0,$2200			; 1 Bitplanes, output enabled
	;; http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_4.html
	;; http://www.winnicki.net/amiga/memmap/BPLCON2.html
	;; http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node0159.html
	;; $104          FEDCBA9876543210
	dc.w	bplcon2,%0000000000000000
	;; http://www.winnicki.net/amiga/memmap/BPLCON3.html
	dc.w	bplcon3,$0000
copper_moire_space:
	dcb.l	5,$01feEAEA	; Copper NOP
	;; Bitplane modulos
copper_bitplane_modulos:
	dc.w	bpl1mod,(moirepattern_png_width-320)/8
	dc.w	bpl2mod,(moirepattern_png_width-320)/8
	dc.w	color+2*0,$0000	;Colour 0
	dc.w	color+2*1,$0aaa	;Colour 1
	dc.w	color+2*2,$0666	;Colour 2
	dc.w	color+2*3,$0fff	;Colour 3

	dc.w	$ffdf,$fffe	; End of NTSC.
	dc.w	$0107,$fffe	;Wait for line 257.
	;; Marker for easy spottin.
	dc.w	color,$003
	;; End of Copper List
	dc.w	$ffff,$fffe

bitplane:
	REPT	255
	dc.w	$F731
	dcb.b	(320-16)/8
	ENDR
	dcb.b	(320-16)/8
	dc.w	$8CEF

	include	"moirepattern.asm"

	SECTION BSS,bss
mpos_even_x:	ds.w	1
mpos_even_y:	ds.w	1
mpos_odd_x:	ds.w	1
mpos_odd_y:	ds.w	1
