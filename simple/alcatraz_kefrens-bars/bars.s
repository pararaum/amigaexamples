        INCLUDE "hardware/custom.i"
        INCLUDE "hardware/intbits.i"
        INCLUDE "hardware/dmabits.i"
	include	"own.i"

BPLWIDTH = 320
BPLHEIGHT = 256
BPLNOS = 3
SINUSTABLELENGTH EQU sinustable_end-sinustable
VERTBAREND = 180

	;;; A6 contains the $DFF000 custom chip base.

_start:	jmp	main(pc)
	dc.b	"Alcatraz/Kefrens Bars",10
	dc.b	"Code: Pararaum / T7D",0
	align	4
	cmp.l	#"main",main
	cmp.l	#"seco",setup_copper
	cmp.l	#"vert",do_vertbars
	cmp.l	#"COPL",copper_list
	cmp.l	#"BPLA",bitplane
	cmp.l	#"SINU",sinustable
	align	4
	main:	nop
	moveq	#OWN_libraries|OWN_view|OWN_trap,d0
	jsr	own_machine
	lea.l	$DFF000,a6
	bsr	setup_system
	nop
	moveq	#33,d7
	lea	bitplane,a5
l3$:	nop
	bsr	wait_frame
	bsr	clear_topline
	move.w	#$38<<8,d0
l4$:	move.w	vhposr(a6),d1
	cmp.w	vhposr(a6),d0
	bcc.s	l4$
	bsr	do_vertbars
;#	mulu	#33,d7
;#	add.w	#3,d7
;#	move.w	d7,d0
;#	move.w	d7,d1
;#	and.w	#$7f,d0
;#	lsr.w	#8,d1
;#	eor.b	d1,(a5,d0)
	btst	#6,$bfe001	; Left mouse clicked?
	bne.s	l3$
	jsr	disown_machine
	moveq	#0,d0
	rts
	jmp	_start(pc)

do_vertbars:
	movem.l	d2-d7/a2-a6,-(sp)
	;; A5: pointer to bitplane
	;; A4: pointer to sinustable
	;; D7: current angle1
	;; D6: current angle2
	;;
	lea.l	bitplane,a5
	lea.l	sinustable,a4
	move.w	phase$(pc),d7
	move.w	phase2$(pc),d6
l1$:	move.w	d7,d0
	move.w	d6,d1
	bsr	get_value$
	bsr	paint$
	move.l	vposr(a6),d0
	and.l	#$0003ff00,d0
	add.l	#$00000800,d0
l2$:	cmp.l	vposr(a6),d0
	bcc.s	l2$
	add.w	#5,d7
	add.w	#11,d6
	cmp.w	#VERTBAREND<<8,vhposr(a6)
	bcs.s	l1$
	add.w	#5,phase$
	addq.w	#7,phase2$
	movem.l	(sp)+,d2-d7/a2-a6
	rts
paint$:
	move.w	d0,d2
	lsr.w	#4,d2		; Word position
	lsl.w	#1,d2		; To bytes
	move.w	d0,d3
	and.w	#$f,d3		; Shift
	move.l	mask$,d0
	ror.l	d3,d0		; Rotate the mask
	and.l	d0,0(a5,d2)
	and.l	d0,BPLWIDTH/8(a5,d2)
	and.l	d0,BPLWIDTH/8*2(a5,d2)
	move.l	pat0$,d0
	lsr.l	d3,d0		; Move shift pixels
	or.l	d0,0(a5,d2)
	move.l	pat1$,d0
	lsr.l	d3,d0		; Move shift pixels
	or.l	d0,BPLWIDTH/8(a5,d2)
	move.l	pat2$,d0
	lsr.l	d3,d0		; Move shift pixels
	or.l	d0,BPLWIDTH/8*2(a5,d2)
	rts
;;; D0: angle1, D1: angle2
get_value$:
	and.w	#SINUSTABLELENGTH-2,d0 ; Make even pointer in table
	move.w	(a4,d0),d0	; sin(d0)
	asr.w	#1,d0		; sin(d0)/2
	and.w	#SINUSTABLELENGTH-2,d1
	move.w	(a4,d1),d1	; sin(d1)
	asr.w	#3,d1		; sin(d1)/8
	add.w	d1,d0
	add.w	#150,d0
	;; Now: 150+sin(d0)/2+sin(d1)/8
	rts
	;;       10987654321098765432109876543210
mask$:	dc.l	%00000000011111111111111111111111
pat0$:	dc.l	%10100010100000000000000000000000
pat1$:	dc.l	%01100011000000000000000000000000
pat2$:	dc.l	%00011100000000000000000000000000
phase$:	dc.w	0
phase2$:	dc.w	0

clear_topline:
	moveq	#(BPLWIDTH*BPLNOS/8/4)-1,d0	; Clear the line
	lea.l	bitplane,a0
l1$:	clr.l	(a0)+
	dbf	d0,l1$
	rts

wait_frame:
l1$:	btst.b	#0,vposr+1(a6)
	beq.s	l1$
l2$:	btst.b	#0,vposr+1(a6)
	bne.s	l2$
	rts


setup_system:
	move.w	#$7fff,dmacon(a6)
	bsr	setup_copper
	move.w	#DMAF_SETCLR|DMAF_BLITTER|DMAF_COPPER|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER,dmacon(a6)
	rts

;;; Setup the copper and write the corresponding wait and color instructions.
setup_copper:
	movem.l	d2-d7/a2-a6,-(sp)
	;; D3: line numner
	;; Setup copper pointer.
	move.l	#copper_list,cop1lc(a6)
	clr.w	copjmp1(a6)	 ; Strobe copper
	move.l	#bitplane,d0	 ; Address of bitplane 0
	moveq	#BPLNOS-1,d1	 ; Number of bitplanes
	lea.l	copper_bplptr,a0 ; Pointer to bitplane pointers in copper list
l1$:	move.w	d0,6(a0)	 ; Lower 16 bits.
	swap	d0
	move.w	d0,2(a0)	 ; Upper 16 bits.
	swap	d0		 ; Restore value
	add.l	#BPLWIDTH/8,d0	 ; Next line for next bitplane
	addq.l	#8,a0		 ; Next bitplane pointer in copper list
	dbf	d1,l1$
	movem.l	(sp)+,d2-d7/a2-a6
	rts

;;; ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
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
	dc.w	bplcon0,$3200			; 3 Bitplanes, output enabled
copper_scrollcon:
	;; http://www.winnicki.net/amiga/memmap/BPLCON1.html, scrolling
	;; Lower nibbles are for scrolling, PF 1 and PF2.
	dc.w	bplcon1,$0000
	;; http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_4.html
	;; http://www.winnicki.net/amiga/memmap/BPLCON2.html
	;; http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node0159.html
	;; $104          FEDCBA9876543210
	dc.w	bplcon2,%0000000000000000
	;; http://www.winnicki.net/amiga/memmap/BPLCON3.html
	dc.w	bplcon3,$0000
	;; Bitplane modulos
copper_bitplane_modulos:
	dc.w	bpl1mod,-(320/8) ; Repeat the line (move back 320 pixels)
	dc.w	bpl2mod,-(320/8) ; Repeat the line (move back 320 pixels)
copper_bplptr:
	dc.w	$00e0,$0000,$00e2,$0000		; Bitplaneptrs
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000
	dc.w	$00f0,$0000,$00f2,$0000
	dc.w	color+2*0,$0000	;Colour 0
	dc.w	color+2*1,$0321	;Colour 1
	dc.w	color+2*2,$0542
	dc.w	color+2*3,$0753
	dc.w	color+2*4,$0974
	dc.w	color+2*5,$0b84
	dc.w	color+2*6,$0da5
	dc.w	color+2*7,$0fc5
	dc.w	$ffdf,$fffe	; End of NTSC.
	dc.w	$0007,$fffe
	dc.w	color,$0fff	; Turn white
	;; End of Copper List
	dc.w	$ffff,$fffe

;;; ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
	SECTION	BSSC,bss_c
bitplane:
	ds.b	BPLWIDTH*BPLHEIGHT/8*BPLNOS

;;; ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	SECTION BSS,bss
debugstorage:
	ds.l	1<<10

;;; ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
	SECTION DATA,data
;;; Generated via python: ", ".join("%d" % int(math.sin(i/512.0*2*math.pi)*256) for i in range(512))
sinustable:
	dc.w	0, 3, 6, 9, 12, 15, 18, 21, 25, 28, 31, 34, 37, 40, 43, 46
	dc.w	49, 53, 56, 59, 62, 65, 68, 71, 74, 77, 80, 83, 86, 89, 92, 95
	dc.w	97, 100, 103, 106, 109, 112, 115, 117, 120, 123, 126, 128, 131, 134, 136, 139
	dc.w	142, 144, 147, 149, 152, 155, 157, 159, 162, 164, 167, 169, 171, 174, 176, 178
	dc.w	181, 183, 185, 187, 189, 191, 193, 195, 197, 199, 201, 203, 205, 207, 209, 211
	dc.w	212, 214, 216, 217, 219, 221, 222, 224, 225, 227, 228, 230, 231, 232, 234, 235
	dc.w	236, 237, 238, 239, 241, 242, 243, 244, 244, 245, 246, 247, 248, 249, 249, 250
	dc.w	251, 251, 252, 252, 253, 253, 254, 254, 254, 255, 255, 255, 255, 255, 255, 255
	dc.w	256, 255, 255, 255, 255, 255, 255, 255, 254, 254, 254, 253, 253, 252, 252, 251
	dc.w	251, 250, 249, 249, 248, 247, 246, 245, 244, 244, 243, 242, 241, 239, 238, 237
	dc.w	236, 235, 234, 232, 231, 230, 228, 227, 225, 224, 222, 221, 219, 217, 216, 214
	dc.w	212, 211, 209, 207, 205, 203, 201, 199, 197, 195, 193, 191, 189, 187, 185, 183
	dc.w	181, 178, 176, 174, 171, 169, 167, 164, 162, 159, 157, 155, 152, 149, 147, 144
	dc.w	142, 139, 136, 134, 131, 128, 126, 123, 120, 117, 115, 112, 109, 106, 103, 100
	dc.w	97, 95, 92, 89, 86, 83, 80, 77, 74, 71, 68, 65, 62, 59, 56, 53
	dc.w	49, 46, 43, 40, 37, 34, 31, 28, 25, 21, 18, 15, 12, 9, 6, 3
	dc.w	0, -3, -6, -9, -12, -15, -18, -21, -25, -28, -31, -34, -37, -40, -43, -46
	dc.w	-49, -53, -56, -59, -62, -65, -68, -71, -74, -77, -80, -83, -86, -89, -92, -95
	dc.w	-97, -100, -103, -106, -109, -112, -115, -117, -120, -123, -126, -128, -131, -134, -136, -139
	dc.w	-142, -144, -147, -149, -152, -155, -157, -159, -162, -164, -167, -169, -171, -174, -176, -178
	dc.w	-181, -183, -185, -187, -189, -191, -193, -195, -197, -199, -201, -203, -205, -207, -209, -211
	dc.w	-212, -214, -216, -217, -219, -221, -222, -224, -225, -227, -228, -230, -231, -232, -234, -235
	dc.w	-236, -237, -238, -239, -241, -242, -243, -244, -244, -245, -246, -247, -248, -249, -249, -250
	dc.w	-251, -251, -252, -252, -253, -253, -254, -254, -254, -255, -255, -255, -255, -255, -255, -255
	dc.w	-256, -255, -255, -255, -255, -255, -255, -255, -254, -254, -254, -253, -253, -252, -252, -251
	dc.w	-251, -250, -249, -249, -248, -247, -246, -245, -244, -244, -243, -242, -241, -239, -238, -237
	dc.w	-236, -235, -234, -232, -231, -230, -228, -227, -225, -224, -222, -221, -219, -217, -216, -214
	dc.w	-212, -211, -209, -207, -205, -203, -201, -199, -197, -195, -193, -191, -189, -187, -185, -183
	dc.w	-181, -178, -176, -174, -171, -169, -167, -164, -162, -159, -157, -155, -152, -149, -147, -144
	dc.w	-142, -139, -136, -134, -131, -128, -126, -123, -120, -117, -115, -112, -109, -106, -103, -100
	dc.w	-97, -95, -92, -89, -86, -83, -80, -77, -74, -71, -68, -65, -62, -59, -56, -53
	dc.w	-49, -46, -43, -40, -37, -34, -31, -28, -25, -21, -18, -15, -12, -9, -6, -3
sinustable_end:
