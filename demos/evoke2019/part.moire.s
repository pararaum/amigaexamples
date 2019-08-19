        INCLUDE "hardware/custom.i"
        INCLUDE "hardware/intbits.i"
        INCLUDE "hardware/dmabits.i"
	INCLUDE	"circallator.i"

	XDEF	_moire_part
	XDEF	wait_one_songposition
	XREF	_inflate

MOIREPATTERN_PNG_WIDTH:	EQU	400
MOIREPATTERN_PNG_HEIGHT:	EQU	400
MOIREPATTERN_STARTLINE:	EQU	25
	;;; A6 contains the $DFF000 custom chip base.

	SECTION	CODE,code
_moire_part:
	movem.l	d2-d7/a2-a6,-(sp)
	jsr	main(pc)
	movem.l	(sp)+,d2-d7/a2-a6
	rts
	dc.b	"Moire Pattern",10
	dc.b	"Code: Pararaum / T7D",0
	align	4
	cmp.l	#"main",main
	align	4
main:	nop
	lea.l	$DFF000,a6
	;; Allocate memory for the moire pattern bitplane.
	move.l	#MOIREPATTERN_PNG_WIDTH*MOIREPATTERN_PNG_HEIGHT/8,d0
	jsr	circalloc
	move.l	a0,bitplaneptr
	;; Uncrunch image.
	move.l	#moirepattern_deflated,-(sp)	; Input data
	move.l	bitplaneptr,-(sp)		; Output Buffer
	jsr	_inflate
	addq.l	#8,sp		; Clean up the stack.
	;; Center the image.
	move.w	#-(MOIREPATTERN_PNG_WIDTH-320)/2,mpos_odd_x
	move.w	#(MOIREPATTERN_PNG_HEIGHT-256)/2,mpos_odd_y
	;; Now set up the copper to display the moire pattern.
	bsr	setup_copper
	move.l	#irq_routine,$308.w
	;; Moire ok, now wait.
	bsr	wait_two_songpositions
	;; For more variety change the colour.
	move.l	#$00000aa2,d0
	move.l	#$033a053f,d1
	jsr	change_colour
	;; Second pattern.
	move.l	#moirepattern2_deflated,-(sp)	; Input data
	move.l	bitplaneptr,-(sp)		; Output Buffer
	jsr	_inflate
	addq.l	#8,sp		; Clean up the stack.
	bsr	wait_one_songposition
	move.l	#$000003aa,d0
	move.l	#$03ff0311,d1
	jsr	change_colour
	;; And the third pattern:
	move.l	#moirepattern3_deflated,-(sp)	; Input data
	move.l	bitplaneptr,-(sp)		; Output Buffer
	jsr	_inflate
	addq.l	#8,sp		; Clean up the stack.
	bsr	wait_two_songpositions
	;; For more variety change the colour.
	move.l	#$00000A3B,d0
	move.l	#$0f3f0414,d1
	jsr	change_colour
	;; And the fourth pattern:
	move.l	#moirepattern4_deflated,-(sp)	; Input data
	move.l	bitplaneptr,-(sp)		; Output Buffer
	jsr	_inflate
	addq.l	#8,sp		; Clean up the stack.
	bsr	wait_one_songposition
	;; Fade out...
	move.l	copperlistptr,a2 ; Copperlist in memory.
l1$:	lea.l	copper_colours-copper_list(a2),a0 ; Colours in chipmem.
	lea.l	copper_colours_end-copper_list(a2),a1 ; Colours end in chipmem.
	jsr	fade_out_copper_list
	bsr	wait_frame
	tst.l	d0
	bne.s	l1$
	;; Stop effect.
	clr.l	$308.w
	rts

wait_one_songposition:
	clr.l	-(sp)
	move.l	pt_SongPosition,d0
	addq.l	#1,d0
	move.l	d0,-(sp)
	jsr	_wait_songposition
	addq.l	#8,sp		; Clean up the stack.
	rts

wait_two_songpositions:
	clr.l	-(sp)
	move.l	pt_SongPosition,d0
	addq.l	#2,d0
	move.l	d0,-(sp)
	jsr	_wait_songposition
	addq.l	#8,sp		; Clean up the stack.
	rts

irq_routine:
	;; Registers are saved elsewhere!
	addq.w	#1,counter$
	move.w	counter$(pc),d1
	and.w	#$ff,d1
	lsl.w	#2,d1		; Multiply by 4.
	lea.l	displacements,a0 ; x&y, 2 bytes per position
	add.w	d1,a0		; Move to the next pair of pos.
	move.w	(a0)+,d0	; X
	add.w	#-(MOIREPATTERN_PNG_WIDTH-320)/2,d0
	move.w	d0,mpos_even_x
	move.w	(a0),d0
	add.w	#(MOIREPATTERN_PNG_HEIGHT-256)/2,d0
	move.w	d0,mpos_even_y
	bsr	do_moire
	rts
counter$:	dc.w	0


do_moire:
	move.w	mpos_even_x,d0
	move.w	mpos_even_y,d1
	move.w	mpos_odd_x,d2
	move.w	mpos_odd_y,d3
	move.l	bitplaneptr,a0
	lea.l	MOIREPATTERN_STARTLINE*MOIREPATTERN_PNG_WIDTH/8(a0),a0
	move.l	bitplaneptr,a1
	lea.l	MOIREPATTERN_STARTLINE*MOIREPATTERN_PNG_WIDTH/8(a1),a1
	;; Calculate the space within the copperlist.
	move.l	copperlistptr,a2
	lea.l	copper_moire_space-copper_list(a2),a2
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
	mulu	#MOIREPATTERN_PNG_WIDTH/8,d1 ; Advance that many lines (result is 32 bits).
	add.l	d1,a0			     ; A0 now contains the line of the odd bitplane.
	move.w	d0,d1		; D1 contains now x displacement.
	and.w	#$FFF0,d1
	asr.w	#3,d1		; Divide by 8 for bytes.
	neg.w	d1		; If moved to the right then we have to start fetching data earlier.
	ext.l	d1
	add.l	d1,a0		; Add the offset to the odd bitplane pointer.
	mulu	#MOIREPATTERN_PNG_WIDTH/8,d3
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



;;; Change colours in the copper list. They will be updated on the next frame. The upper 16 bits of D0 are the color 0 in RGB4, the lower 16 bits contain colour 1.
;;; D0=colour 0,1
;;; D1=colour 2,3
change_colour:
	;; Get address of current copper list.
	move.l	copperlistptr,a0
	;; Adjust pointer to colour MOVE commands.
	lea.l	copper_colours-copper_list(a0),a0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	move.w	d1,14(a0)
	swap	d1
	move.w	d1,10(a0)
	rts

;;; Setup the copper and write the corresponding wait and color instructions.
setup_copper:
	movem.l	d2-d7/a2-a6,-(sp)
	;; A2=pointer to copperlist chipmemory
	;; Allocate memory for copper list
	move.l	#copper_list_end-copper_list,d0
	jsr	circalloc
	move.l	a0,copperlistptr
	move.l	a0,a2
	lea.l	copper_list,a1
	;; Copy data
	move.l	#copper_list_end-copper_list-1,d0
l1$:	move.b	(a1)+,(a0)+
	dbf	d0,l1$
	;; Setup copper pointer.
	move.l	a2,cop1lc(a6)
	clr.w	copjmp1(a6)	 ; Strobe copper
	movem.l	(sp)+,d2-d7/a2-a6
	rts


	SECTION	DATA,data

copper_list:
	;; Copper List
	;; see: http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_2.html
	;; AGA compatible setup?
	dc.w 	fmode,$0000
	;; Setting up display.
	;; see also: http://cyberpingui.free.fr/tuto_graphics.htm
	dc.w	$008e,$2c91,$0090,$2cb1		; DIWSTRT/DIWSTOP
	dc.w	$0092,$0038,$0094,$00d0		; DDFSTRT/DDFSTOP
	;; http://amiga-dev.wikidot.com/hardware:bplcon0
	dc.w	bplcon0,$2200			; 1 Bitplanes, output enabled
	;; http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_4.html
	;; http://www.winnicki.net/amiga/memmap/BPLCON2.html
	;; http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node0159.html
	;; $104          FEDCBA9876543210
	dc.w	bplcon2,%0000000000000000
	;; http://www.winnicki.net/amiga/memmap/BPLCON3.html
	;; done in all_black()	dc.w	bplcon3,$0C00
copper_moire_space:
	dcb.l	5,$01feEAEA	; Copper NOP
	;; Bitplane modulos
copper_bitplane_modulos:
	dc.w	bpl1mod,(MOIREPATTERN_PNG_WIDTH-320)/8
	dc.w	bpl2mod,(MOIREPATTERN_PNG_WIDTH-320)/8
copper_colours:
	dc.w	color+2*0,$0000	;Colour 0
	dc.w	color+2*1,$03aa	;Colour 1
	dc.w	color+2*2,$03ff	;Colour 2
	dc.w	color+2*3,$0311	;Colour 3
copper_colours_end:
	;; End of Copper List
	dc.w	copjmp2,0
	dc.w	$ffff,$fffe
copper_list_end:

moirepattern_deflated:
	incbin	"image.moirepattern.deflated"
moirepattern2_deflated:
	incbin	"image.moirepattern2.deflated"
;;; img = PIL.Image.new(mode='1', size=(400,400))
;;; draw=PIL.ImageDraw.Draw(img)
;;; for i in range(1,200,2):
;;;   draw.ellipse((i,i,400-i,400-i), fill=('black' if (i//2&1)!=0 else 'white'))
moirepattern3_deflated:
	incbin	"image.moirepattern3.deflated"
moirepattern4_deflated:
	incbin	"image.moirepattern4.deflated"

	EVEN
displacements:
	dc.w	0,20,1,20,2,20,3,20,4,20,5,20,6,20,7,20,8,20,9,20,9,19,10,19,11,19,12,19,13,19,13,19,14,18,15,18,15,18,16,18,17,18,17,17,18,17,18,17,18,17,19,16,19,16,19,16,20,15,20,15,20,15,20,14,20,14,20,14,20,13,20,13,20,13,19,12,19,12,19,12,18,11,18,11,18,10,17,10,17,9,16,9,15,9,15,8,14,8,13,7,13,7,12,6,11,6,10,5,9,5,9,4,8,4,7,3,6,3,5,2,4,2,3,1,2,1,1,0,0,0,-1,0,-2,-1,-3,-1,-4,-2,-5,-2,-6,-3,-7,-3,-8,-4,-9,-4,-9,-5,-10,-5,-11,-6,-12,-6,-13,-7,-13,-7,-14,-8,-15,-8,-15,-9,-16,-9,-17,-9,-17,-10,-18,-10,-18,-11,-18,-11,-19,-12,-19,-12,-19,-12,-20,-13,-20,-13,-20,-13,-20,-14,-20,-14,-20,-14,-20,-15,-20,-15,-20,-15,-19,-16,-19,-16,-19,-16,-18,-17,-18,-17,-18,-17,-17,-17,-17,-18,-16,-18,-15,-18,-15,-18,-14,-18,-13,-19,-13,-19,-12,-19,-11,-19,-10,-19,-9,-19,-9,-20,-8,-20,-7,-20,-6,-20,-5,-20,-4,-20,-3,-20,-2,-20,-1,-20,0,-20,1,-20,2,-20,3,-20,4,-20,5,-20,6,-20,7,-20,8,-20,9,-20,9,-19,10,-19,11,-19,12,-19,13,-19,13,-19,14,-18,15,-18,15,-18,16,-18,17,-18,17,-17,18,-17,18,-17,18,-17,19,-16,19,-16,19,-16,20,-15,20,-15,20,-15,20,-14,20,-14,20,-14,20,-13,20,-13,20,-13,19,-12,19,-12,19,-12,18,-11,18,-11,18,-10,17,-10,17,-9,16,-9,15,-9,15,-8,14,-8,13,-7,13,-7,12,-6,11,-6,10,-5,9,-5,9,-4,8,-4,7,-3,6,-3,5,-2,4,-2,3,-1,2,-1,1,0,0,0,-1,0,-2,1,-3,1,-4,2,-5,2,-6,3,-7,3,-8,4,-9,4,-9,5,-10,5,-11,6,-12,6,-13,7,-13,7,-14,8,-15,8,-15,9,-16,9,-17,9,-17,10,-18,10,-18,11,-18,11,-19,12,-19,12,-19,12,-20,13,-20,13,-20,13,-20,14,-20,14,-20,14,-20,15,-20,15,-20,15,-19,16,-19,16,-19,16,-18,17,-18,17,-18,17,-17,17,-17,18,-16,18,-15,18,-15,18,-14,18,-13,19,-13,19,-12,19,-11,19,-10,19,-9,19,-9,20,-8,20,-7,20,-6,20,-5,20,-4,20,-3,20,-2,20,-1,20
;;; ghci:
;;; let angles = [i*2*pi/256 | i <- [0..255]]
;;; map round $ foldl (++) [] $ map (\i -> [20 * sin (2*i), 20 * cos i]) angles

	SECTION BSS,bss
mpos_even_x:	ds.w	1
mpos_even_y:	ds.w	1
mpos_odd_x:	ds.w	1
mpos_odd_y:	ds.w	1
bitplaneptr:	ds.l	1	; Pointer to the bitplane chipmemory.
copperlistptr:	ds.l	1	; Pointer to the copperlist chipmemory.
