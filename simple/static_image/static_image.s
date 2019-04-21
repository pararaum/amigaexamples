;;; Display a static image which will be later on greater than the whole screen.

	include "hardware/custom.i"
	include	"iff.i"
	include "own.i"

	section	static_image,code

_start:	jmp	main$(pc)
	dc.b	"Static Image",10
	dc.b	"Code: Pararaum / T7D",10
	dc.b	"Gfx: Pararaum / T7D",10
	dc.b	"Muzak: JackBeatmaster / T7D",10
	ALIGN	4		; Next 16 Byte boundry.
	;; For debugging.
	cmp.l	#"TAIL",copper_TAIL
	cmp.l	#"CIBP",copper_information_bitplane_pointer
	cmp.l	#"ipl0",im0pl0
	cmp.l	#"ipl1",im0pl1
	cmp.l	#"ipl2",im0pl2
	cmp.l	#"infb",information_bitplane
	cmp.l	#"SONG",tracker_song_data
	trap	#15
	jmp	pt_InitMusic
	bra	prepare_scroll_around
	bra	scroll_around
	bra	display_current_frame_no
	bra	setup_copper
	bra	wait_tof
	ALIGN	4
main$:	nop
	moveq	#OWN_libraries|OWN_view|OWN_trap,d0
	jsr	own_machine
	nop
	lea.l	_start(pc),a0			; Get address of _start
	moveq	#320/8,d0			; Bitplane width
	move.l	a0,d1				; The number is _start
	lea.l	information_bitplane+320/8*13+0,a0	; Bitplane pointer
	jsr	draw_uint32_number
	nop
	lea.l	tracker_song_data,a0
	jsr	pt_InitMusic
	nop
	bsr	setup_copper
	bsr	action_list_manager
	jsr	pt_StopMusic
	nop
	jsr	disown_machine
	nop
	moveq	#0,d0
	rts

;;; Handle the action list with action per frame.
action_list_manager:
	;; A6: action list pointer
	;; A5: current action subroutine, called each frame
	;; D7: current frame number
	;; D6: frame number at which next action will happen
	movem.l	d0-d7/a0-a6,-(sp)
	lea.l	action_list,a6
	moveq	#0,d7		;Clear frame number
	;; Now initialise (first) action.
	bsr	next_action$
loop$:	jsr	wait_tof	;Wait for next frame
	cmp.l	d6,d7		;Next action reached?
	bne.s	no_new$
premature$:
	add.w	#3*4,a6		;Skip to next action in list.
	bsr	next_action$	;Initialise again...
no_new$:
	move.l	a5,d0		;TST A0
	beq.s	noframe$
	move.l	d7,d0		;Frame number in D0.
	jsr	(a5)		;Do action per frame.
	tst.w	d0		;Action did end prematurely?
	beq.s	premature$
noframe$:
	bsr	display_current_frame_no
	lea.l	$dff000,a0
l69$:	move.l	vposr(a0),d0
	and.l   #$1ff00,d0
	cmp.l	#263<<8,d0
	bne.s	l69$
	move.w	#$0f55,$180(a0)
	jsr	pt_PlayMusic
	lea.l	$dff000,a0
	clr.w	$180(a0)
	
	lea.l	information_bitplane+0,a0 ; Bitplane pointer
	moveq	#320/8,d0	    ; Bitplane width
	move.l	pt_PatternPosition,d1		    ; Number
	jsr	draw_uint32_number
	lea.l	information_bitplane+8,a0 ; Bitplane pointer
	moveq	#320/8,d0	    ; Bitplane width
	move.l	pt_SongPosition,d1		    ; Number
	jsr	draw_uint32_number
	lea.l	information_bitplane+16,a0 ; Bitplane pointer
	moveq	#320/8,d0	    ; Bitplane width
	move.l	pt_audchan3temp+40,d1		    ; Number
	jsr	draw_uint32_number

	addq.l	#1,d7		; Next frame number
	btst	#6,$bfe001	; Left mouse clicked?
	bne	loop$		; Continue loop
	movem.l	(sp)+,d0-d7/a0-a6 ;Finished, now restore
	rts			; And return.
next_action$:
	move.l	d7,d6		;Current frame into D6, see after no_jump$.
jump$:	move.l	(a6),d0		;Get length of action in D0.
	bne.s	no_jump$	;We have a length, therefore no jump.
	move.l	8(a6),a6	;Do the jump.
	addq	#1,d6		;Next frame
	bra.s	jump$
no_jump$:
	add.l	d0,d6		;Set frame number for next action
	move.l	4(a6),a0	;Get address of initialise action
	move.l	8(a6),a5	;Per frame action subroutine.
	move.l	a0,d0		;Actually test A0
	beq.s	noinit$
	jmp	(a0)		;call initialise action
noinit$:	rts

display_current_frame_no:
	;; Display the current frame number in the bottem right.
	;lea.l	im0pl0+(255-13)*320/8+32,a0 ; Bitplane pointer
	lea.l	information_bitplane+13*320/8+32,a0 ; Bitplane pointer
	moveq	#320/8,d0	    ; Bitplane width
	move.l	d7,d1		    ; Number
	jsr	draw_uint32_number
	lea.l	information_bitplane+13*320/8+24,a0 ; Bitplane pointer
	moveq	#320/8,d0	    ; Bitplane width
	move.l	d6,d1		    ; Number
	jsr	draw_uint32_number
	rts


prepare_1st_image:
	movem.l	d2-d7/a2-a6,-(sp)
	sub.w	#3*4,sp		;I need some space on the stack.
	lea.l	ilbm_image,a0	;Pointer to image
	move.l	#"BODY",d0	;BODY chunk
	jsr	find_iff_chunk
	tst.l	d0
	bpl.s	ok$
kill$:	trap	#15		;Kill loop for debugging.
ok$:	move.l	a0,a5		;Pointer to body chunk data
	move.l	#im0pl0,(a7)	;Pointer array is in stack.
	move.l	#im0pl1,4(a7)
	move.l	#im0pl2,8(a7)
	move.l	a7,a6		;Bitplane pointer array
	move.w	#320/8,d6	;Width in bytes
	move.w	#200,d7		;Height in lines
	moveq	#3,d5		;Number of bitplanes
	jsr	uncompress_body_continous
	lea.l	ilbm_image,a0	;Pointer to image.
	lea.l	colour_space,a1 ;Here the colour values are copied to.
	moveq	#0,d0		;No skip.
	jsr	copy_cmap_chunk
	add.w	#3*4,sp
	movem.l	(sp)+,d2-d7/a2-a6
	rts


prepare_2nd_image:
	movem.l	d2-d7/a2-a6,-(sp)
	sub.w	#3*4,sp		;I need some space on the stack.
	lea.l	panorama_image,a0	;Pointer to image
	move.l	#"BODY",d0	;BODY chunk
	jsr	find_iff_chunk
	tst.l	d0
	bpl.s	ok$
kill$:	trap	#15		;Kill loop for debugging.
ok$:	move.l	a0,a5		;Pointer to body chunk data
	move.l	#im0pl0,(a7)	;Pointer array is in stack.
	move.l	#im0pl1,4(a7)
	move.l	#im0pl2,8(a7)
	move.l	a7,a6		;Bitplane pointer array
	move.w	#1280/8,d6	;Width in bytes
	move.w	#200,d7		;Height in lines
	moveq	#3,d5		;Number of bitplanes
	jsr	uncompress_body_continous
	lea.l	panorama_image,a0	;Pointer to image.
	lea.l	colour_space,a1 ;Here the colour values are copied to.
	moveq	#0,d0		;No skip.
	jsr	copy_cmap_chunk
	move.w	#$0030,copper_diswin+10	   ;DDFSTRT (make screen wider for scrolling)
	lea.l	copper_bitplane_modulos,a0 ;Copper list entries for modulos.
	move.w	#(1280-320)/8-2,d0	   ;Modulo (-2 is because of the change of DDFSTRT)
	move.w	d0,2(a0)	; ...and store!
	move.w	d0,6(a0)
	move.l	#im0pl0-2,d0	;Set the copper bitplane pointers appropriately.
	move.l	#im0pl1-2,d1	;-2 because of the change in DDFSTRT
	move.l	#im0pl2-2,d2
	lea.l	copper_bplptr,a0
	bsr	set_copper_bitplanepointer
	add.w	#3*4,sp
	movem.l	(sp)+,d2-d7/a2-a6
	rts


fade_in_colours:
	and.w	#$0007,d0	;D0 has frame number.
	bne.s	skip$
	lea.l	colour_space,a0
	lea.l	copper_colours,a1
	moveq	#8,d0
	jsr	fade_copper_list_to
skip$:	moveq	#1,d0
	rts


;;; Fill the colour_space with a value.
	;; Input:
	;; D0: Colour to fill.
	;; Destroys:
	;; A0,D1
fill_colours:
	lea.l	colour_space,a0
	moveq	#32-1,d1
l1$:	move.w	d0,(a0)+
	dbf	d1,l1$
	rts

;;; Turn all colours in the colour space to black.
kill_colours:
	lea.l	colour_space,a0
	moveq	#32-1,d0
l1$:	clr.w	(a0)+
	dbf	d0,l1$
	move.w	#$0fff,colour_space+2
	rts

fade_out_colours:
	and.w	#$0007,d0	;D0 has frame number.
	bne.s	skip$
	lea.l	colour_space,a0
	lea.l	copper_colours,a1
	moveq	#8,d0
	jsr	fade_copper_list_to
skip$:
	rts


prepare_scroll_around:
	move.l	#im0pl0,d0
	move.l	#im0pl1,d1
	move.l	#im0pl2,d2
	lea.l	copper_bplptr,a0
	bsr	set_copper_bitplanepointer
	moveq	#$0000,d0
	move.l	d0,scroll_offset
	move.w	#$00ff,d0
	move.w	d0,copper_scrollcon+2 ;Copper will write this to BPLCON1
	rts

scroll_around:
	move.w	copper_scrollcon+2,d0 ; Move scroll position into d0
	sub.w	#$0011,d0	      ; Move to the left.
	bmi.s	add_bitp_ptr$	      ; Less than 0 so scrolling has to be done using bitplane pointer.
	move.w	d0,copper_scrollcon+2
	moveq	#1,d0
	rts
add_bitp_ptr$:
	move.l	scroll_offset,d3
	addq.l	#2,d3
	cmp.l	#(1280-320)/8-2,d3
	bgt.s	finish$
	move.l	d3,scroll_offset
	move.l	#im0pl0,d0
	add.l	d3,d0
	move.l	#im0pl1,d1
	add.l	d3,d1
	move.l	#im0pl2,d2
	add.l	d3,d2
	lea.l	copper_bplptr,a0
	bsr	set_copper_bitplanepointer
	move.w	#$00ff,d0
	move.w	d0,copper_scrollcon+2
	moveq	#1,d0
	rts
finish$:
	bsr	prepare_scroll_around
	moveq	#1,d0
	rts

prepare_scroll_left:
	move.w	#$00ff,d0
	move.w	d0,copper_scrollcon+2
	move.l	#im0pl0,d0
	move.l	#im0pl1,d1
	move.l	#im0pl2,d2
	lea.l	copper_bplptr,a0
	bsr	set_copper_bitplanepointer
	move.w	d0,copper_scrollcon+2
	move.l	#0,scroll_offset
	rts


scroll_left:
	move.w	copper_scrollcon+2,d0
	sub.w	#$0011,d0
	bmi.s	end$
	move.w	d0,copper_scrollcon+2
	moveq	#1,d0
	rts
end$:	addq.l	#2,scroll_offset
	lea.l	copper_bplptr,a0
	move.l	scroll_offset,d0
	;; 
	move.l	#im0pl1,d1
	add.l	d0,d1
	move.l	#im0pl2,d2
	add.l	d0,d2
	add.l	#im0pl0,d0
	bsr	set_copper_bitplanepointer
	;;
	move.l	scroll_offset,d0
	cmp.l	#(1280-320)/8-2,d0 ;-2, see changes of DDFSTRT
	bge.s	finish$
	move.w	#$00ff,copper_scrollcon+2
	moveq	#1,d0
	rts
finish$:
	moveq	#0,d0
	rts

;;; Write three bitplanepointers to copper list bitplane pointer.
	;; Input
	;; D0-D2: bitplane pointers
	;; A0: copper list with bitplane pointers.
	;; Destroys:
	;; D0-D2
set_copper_bitplanepointer:	
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	move.w	d1,14(a0)
	swap	d1
	move.w	d1,10(a0)
	move.w	d2,22(a0)
	swap	d2
	move.w	d2,18(a0)
	rts


prepare_scroll_right:
	move.w	#$0000,copper_scrollcon+2
	rts
scroll_right:
	move.w	copper_scrollcon+2,d0
	add.w	#$0011,d0
	cmp.w	#$0100,d0
	bge.s	end$
	move.w	d0,copper_scrollcon+2
	moveq	#1,d0
	rts
end$:	subq.l	#2,scroll_offset ;
	beq	finish$
	move.w	#0,copper_scrollcon+2
	lea.l	copper_bplptr,a0
	move.l	scroll_offset,d0
	move.l	#im0pl1,d1
	add.l	d0,d1
	move.l	#im0pl2,d2
	add.l	d0,d2
	add.l	#im0pl0,d0
	lea.l	copper_bplptr,a0
	bsr	set_copper_bitplanepointer
	moveq	#1,d0
	rts
finish$:	moveq	#0,d0
	rts


;;; Fade a copper colour list to a value. This function will iterate through a copper list and add/subtract to/from the red, green, and blue components until the target colour is reached. It will return the number of changed colours.
;; a0: pointer to list of target colours
;; a1: pointer to colour copper list begin
;; D0: number of colours
;; Destroys: a0, a1, d0, d1
;; Output: D0: number of changed colour components
fade_copper_list_to:
	;; D2: current target color
	;; D3: current copper value
	;; D4: Colour mask
	;; D5: Number of non-zero values.
	;; D6: number of colours.
	movem.l	d2-d6,-(sp)
	move.w	d0,d6		; Save number of colours.
	subq	#1,d6		; DBF!
	addq	#2,A1		;Points to the first colour value in copper list.
	moveq	#0,d5		; number of non-zero values.
next_colour$:
	move.w	(A0)+,d2	; Target colour value into d2.
	move.w	(A1),d3		; Current copper colour in d3.
	move.w	#$0f00,d4	; Set colour mask
next_colcom$:
	move.w	d2,d0
	move.w	d3,d1
	and.w	d4,d0		; d0 has one component of target colour
	and.w	d4,d1		; d1 has one component of copper colour
	cmp.w	d0,d1		; are the colours equal?
	beq.s	equal$
	blt.s	incr$
	;; decrement otherwise
	move.w	#$0111,d0	; This value
	and.w	d4,d0		; and'ed with the colour mask
	sub.w	d0,d3		; is subtracted from the copper colour.
	bra.s	do_change$
incr$:	move.w	#$0111,d0	; This value
	and.w	d4,d0		; and'ed with the colour mask
	add.w	d0,d3		; is added to the copper colour.
do_change$:
 	addq	#1,d5		; Something changed...
	move.w	d3,(A1)		; Write colour back.
equal$:
	lsr.w	#4,d4		; Next colour mask
	bne.s	next_colcom$
	addq	#4,A1		; Go to the next copper colour code, a0 is incremented already.
	dbf	d6,next_colour$
	move.l	d5,d0		; Set return value.
	movem.l	(sp)+,d2-d6
	rts



;;; Wait for the Top Of Frame
;;; Destroys: D0
wait_tof:
	move.l	$dff000+vposr,d0 ;get beam position
	and.l	#$1ff00,d0	; These are the vertical position bits, only.
	tst.l	d0		; Wait for position 0.
	bne.s	wait_tof
	rts


;;; Setup the copper list for proper operation.
setup_copper:
	lea.l	copper_bplptr,a1 ;Where to put this data
	lea.l	im0pl0,a0	;First bitplane
	bsr.s	set$
	lea.l	im0pl1,a0	;Second bitplane
	bsr.s	set$
	lea.l	im0pl2,a0	;Third bitplane
	bsr.s	set$
	;; Now the information bitplane
	lea.l	information_bitplane,a0
	lea.l	copper_information_bitplane_pointer,a1
	bsr	set$
	;; Initialise all colours with black.
	lea.l	copper_colours+2,a0 ; Pointer to copper list (colour value).
	move.w	#$180,d0	; Colour register.
l1$:	clr.w	(a0)		; Clear the colour.
	addq.w	#2,d0		; Next colour register.
	lea.l	4(a0),a0	; Skip to next colour value in copper list.
	cmp.w	#$180+8*2,d0
	bne.s	l1$
	bsr.s	clear_sprites$
	move.l	#copper_list,$dff080 ;Write copper list pointer
	rts
set$:	move.l	a0,d0
	move.w	d0,6(a1)
	swap	d0
	move.w	d0,2(a1)
	addq.l	#8,a1
	rts
clear_sprites$:		;; Clear sprites...
	lea.l	copper_spriteptr,a0 ; Where to put the copper sprite list.
	move.l	#sprite_empty,d0    ; Address of the "empty" sprite.
	move.l	d0,d1
	swap	d1		; High part of address.
	move.w	#$0120,d2	; Custom register sprite pointer.
	moveq	#8-1,d3		; For DBF loop.
l2$:	move.w	d2,(a0)+	; SPRxPTH
	addq.w	#2,d2
	move.w	d1,(a0)+	; High
	move.w	d2,(a0)+	; SPRxPTL
	addq.w	#2,d2
	move.w	d0,(a0)+
	dbf	d3,l2$
	rts

	section	staimg~data,data_c
copper_list:
	;; Copper List
	;; see: http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_2.html
	;; AGA compatible setup?
	dc.w	bplcon3,$0000
	dc.w 	fmode,$0000
	;; Setting up display.
	;; see also: http://cyberpingui.free.fr/tuto_graphics.htm
copper_diswin:
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
	dc.w	bplcon2,%0000000000100100
	;; http://www.winnicki.net/amiga/memmap/BPLCON3.html
	dc.w	bplcon3,$0000
	;; Bitplane modulos
copper_bitplane_modulos:
	dc.w	$0108,$0000
	dc.w	$010a,$0000
copper_bplptr:
	dc.w	$00e0,$0000,$00e2,$0000		; Bitplaneptrs
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
copper_colours:
	dc.w	$180+2*0,$0000	;Colour 0
	dc.w	$180+2*1,$0222
	dc.w	$180+2*2,$0444
	dc.w	$180+2*3,$0666
	dc.w	$180+2*4,$0888
	dc.w	$180+2*5,$0AAA
	dc.w	$180+2*6,$0CCC
	dc.w	$180+2*7,$0EEE	;Colour 7
copper_spriteptr:
	;; Copper NOP as space for filling via program.
	dcb.l	8*2,$01fe0000	;8 sprites, two copper commands (HI/LO)
;copper_TEST:
;	dc.w	$8001,$ff00
;	;; 	dc.w	diwstrt,$2c91
;	dc.w	ddfstrt,$0030
;	dc.w	$0108,(1280-320)/8-2
;	dc.w	$010a,(1280-320)/8-2
copper_TAIL:
	; amigadev.elowar.com says:
	; WAIT %VVVVVVVVHHHHHHH1, BVVVVVVVHHHHHHH0
	; MOVE %0000000RRRRRRRR0, ????????????????
	dc.w	$f501,$fffe
	dc.w	$0180,$0000

	dc.w	$fe01,$fffe
	dc.w	$0180,$00ff

	dc.w	$ff01,$fffe
	dc.w	$0180,$0fff
	;; http://eab.abime.net/showthread.php?t=80874
	;; http://ada.untergrund.net/?p=boardthread&id=29#msg5672
	dc.w	$ffdf,$fffe	;(0,255)?
	dc.w	$0041,$ff00
	dc.w	$0180,$0f00

	dc.w	$0151,$fffe
	dc.w	$0180,$00f0

	dc.w	$02f1,$fffe
	dc.w	$0180,$000f
copper_information_bitplane_pointer:
	dc.w	$00e0,$0000,$00e2,$0000	; Bitplaneptrs
	dc.w	bplcon0,$1200		; 1 Bitplanes, output enabled
	dc.w	$0108,$0000		; Bitplane modulo to zero
	dc.w	$010a,$0000
	dc.w	ddfstrt,$0038
	dc.w	ddfstop,$00d0
	dc.w	bplcon1,$0000		; Here no scrolling.


	dc.w	$0601,$fffe
	dc.w	$0180,$0000
	;; End of Copper List
	dc.w	$ffff,$fffe

sprite_empty:
	;; http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node00B9.html
	;; http://jvaltane.kapsi.fi/amiga/howtocode/startupandexit.html
	dc.w	0,0		;VSTART, HSTART
	dc.w	0,0		;VSTOP, control
	dc.w	0,0		; Transparent line.
	dc.l	0		; End
	dc.l	0
	
	section staimg~bc,bss_c

	CNOP	0,4
im0pl0:	ds.b	1280*256/8
im0pl1:	ds.b	1280*256/8
im0pl2:	ds.b	1280*256/8

information_bitplane:
	;; This will be displayed in the lower part of the screen.
	ds.b	320*60/8	;60 scan lines with 320 pixel width.

	section	staimg~b,bss
	ALIGN	2
	;; Colour space is the space where the colour information is copied to. It will be only read by the CPU so need for chip memory.
colour_space:
	ds.w	32		; Space for maximum number of colours.

	section	staimg~d,data
ilbm_image:
	incbin	"static_image.ilbm"
panorama_image:
	incbin	"panorama_image.ilbm"

	ALIGN	2
scroll_offset:
	dc.l	0		; Scroll offset via bitplane pointer.

	clrso
lab1:	so.w	1
lab2:	so.l	3


	dc.b	"Action Table"
	CNOP	0,4
action_list:
	dc.l	50*7,prepare_1st_image,fade_in_colours
	dc.l	-1,kill_colours,fade_out_colours
	dc.l	50*1,prepare_2nd_image,0
	dc.l	50*5,0,fade_in_colours
	dc.l	50*1,0,0
	dc.l	-1,prepare_scroll_left,scroll_left
	dc.l	50*1,0,0
	dc.l	-1,prepare_scroll_right,scroll_right
	dc.l	50*1,0,0
action_list_jump:
	dc.l	-1,prepare_scroll_around,scroll_around
	dc.l	0,0,action_list_jump

	dc.b	"End Of Data"
