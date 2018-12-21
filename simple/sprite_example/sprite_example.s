;;; Sprite examples for the amiga... Have a look at
	;; http://codetapper.com/amiga/sprite-tricks/
	;; http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_4.html
	
	;; 	incdir	"Sources:include/" "Sources:framework/"
	include "LVO/exec_lib.i"
	include "LVO/graphics_lib.i"
	include "hardware/custom.i"

	xref	sprite_movement


	section main,code
_start:
	moveq	#3,d0
	jsr	own_machine
	nop
	nop
	nop
	jsr	prepare_custom
	jsr	wait_for_mouse
	nop
	nop
	nop
	jsr	disown_machine
	moveq	#0,d0
	rts

prepare_custom:
	; a6 dff000 custom chip base
	lea	$DFF000,a6
	;; Set up the two bitplanes
	lea	bitplane0_data,a0
	lea	copper_bplptr,a1
	;; We are going to have two bitplanes
	moveq	#2-1,d1
.setbitplanes:
	;; move bitplane address into d0
	move.l	a0,d0
	;; Store into the copper list
	move.w	d0,6(a1)
	swap	d0
	move.w	d0,2(a1)
	add.l	#320*256/8,a0	; Pointer to next bitplane in picture-rawdata
	addq.l	#8,a1		; Next Bitplaneptr in copperlist
	dbf	d1,.setbitplanes
	nop
	; Setup sprite pointers
	lea	sprite_data,a0
	lea	copper_spriteptr,a1
	move.l	a0,d0
	move.w	d0,6(a1)
	swap	d0
	move.w	d0,2(a1)
	nop
	;; Set address of new copper list into $dff080.
	;; http://www.winnicki.net/amiga/memmap/COP1LCH.html
	;; http://amiga-dev.wikidot.com/hardware:cop1lch
	move.l	#copper_list,cop1lc(a6)
	nop
	jsr	fillbpl
	nop
	move.w	#320,d0
	move.w	#256,d1
	move.w	#%1111000011110000,d2
	moveq	#4,d3
	lea	bitplane0_data,a0
	jsr fillbpl
	;jsr	make_checkerboard
	move.w	#320,d0
	move.w	#256,d1
	move.w	#%1100110011001100,d2
	moveq	#2,d3
	lea.l	bitplane1_data,a0
	;jsr	make_checkerboard
	nop
	rts

;;; Function to create a checkboard by inversing the pattern
;; every n-th line.
	;; IN
	;; d0 width of line in pixels (divided by 8)
	;; d1 height (number of lines)
	;; d2 pattern
	;; d3 invert patter every n-th line
	;; a0 pointer to memory
	;; OUT
make_checkerboard:
	;; d7 width in bytes
	;; d6 number of lines
	;; a6 target pointer
	movem.l	d2-d7/a2-a6,-(sp)
	move.w	d0,d7
	lsr.w	#4,d7		;Divide by 16
	move.l	a0,a6
	move.w	d1,d6
	mulu.w	d7,d1
	add.l	d1,a0
	subq.w	#1,d7		;dbra loops until -1
	subq.w	#1,d6		;dbra loops until -1
	move.w	d3,d1
.l1:
	move.w	d7,d0
.l2:
	move.w	d2,(a6)+
	dbra	d0,.l2
	subq.w	#1,d1
	bne.s	.no_invert
	eor.w	#$FFFF,d2
	move.w	d3,d1
.no_invert:
	dbra	d6,.l1
	movem.l	(sp)+,d2-d7/a2-a6
	rts
	

fillbpl:
	move.w	#$8002,d2
	move.w	#320*256/16*1,d3
	lea.l	bitplane0_data,a2
.l1:
	;mulu	#73,d2
	;add.w	#739,d2
	move.w	d2,(a2)+
	dbra	d3,.l1
	move.w	#$8001,d2
	move.w	#320*256/16*1,d3
	lea.l	bitplane1_data,a2
.l2:
	;mulu	#73,d2
	;add.w	#739,d2
	move.w	d2,(a2)+
	dbra	d3,.l2
	rts

	moveq	#-1,d2
	move.w	#320*256/16*2,d3
	lea.l	bitplane0_data,a2
.l3:
	;eor.w	d2,(a2)+
	move.w	#0,(a2)+
	dbra	d3,.l3
	rts


wait_for_mouse:
	move.l	.pos,a0			; current position in table
	;lea.l	sprite_movement,a0	; a0=sprite movement data
	;add.w	d0,a0			; add offset
	move.w	(a0)+,d1		; d1=x position
	;asr.w	d1			; divide position by two
	add.w	#$0090,d1		; center
	move.b	d1,sprite_data+1	; move into sprite dma data
	move.w	(a0)+,d1		; d1=y position
	add.w	#$0060,d1		; center
	move.b	d1,sprite_data		; first line of sprite
	add.w	#10,d1			; height is ten lines
	move.b	d1,sprite_data+2	; last line of sprite
	;addq	#4,d0			; next offset
	;cmp.w	#32768,d0		; 8192 * 2 * 2
	cmp.l	#sprite_movement+32768,a0
	bls.s	.norestart
	lea.l	sprite_movement,a0
.norestart:
	move.l	a0,.pos
	;; https://www.reaktor.com/blog/crash-course-to-amiga-assembly-programming/
.tof:
	move.l	$dff000+vposr,d0 ;get beam position
	and.l	#$1ff00,d0	; These are the vertical position bits, only.
	cmp.l	#303<<8,d0	; Precalc and compare.
	bne.s	.tof
	btst #6,$bfe001		; Left mouse clicked?
	bne.b wait_for_mouse	; No, continue loop!
	rts
.pos:	dc.l	sprite_movement

	section bitplanes,bss_c
bitplane0_data:	
	ds.b	320*256/8
bitplane1_data:	
	ds.b	320*256/8


	section chipdata,data_c

sprite_data:
	;; http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node00B9.html
	;;  Vertical and horizontal position, vertical stop
	dc.w	$7f7f,$7f00+$0a00
	;; Sprite data
	dc.w	$1e00,$0000
	dc.w	$3f00,$0000
	dc.w	$6780,$1800
	dc.w	$c3c0,$3c40
	dc.w	$c3c0,$3c40
	dc.w	$e7c0,$1840
	dc.w	$ffc0,$0040
	dc.w	$7f80,$0080
	dc.w	$3f00,$0100
	dc.w	$1e00,$0600
	dc.w	$0000,$0000
	
copper_list:
	;; Copper List
	;; see: http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_2.html
	;; AGA compatible setup?
	dc.w	bplcon3,$0000
	dc.w 	fmode,$0000
	;; Setting up display.
	;; see also: http://cyberpingui.free.fr/tuto_graphics.htm
	dc.w	$008e,$2c81,$0090,$2cc1		; DIWSTRT/DIWSTOP
	dc.w	$0092,$0038,$0094,$00d0		; DDFSTRT/DDFSTOP
	;; http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_4.html
	;; http://www.winnicki.net/amiga/memmap/BPLCON2.html
	;; http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node0159.html
	;; $104          FEDCBA9876543210
	dc.w	bplcon2,%0000000000100100
	dc.w	$0102,$0000
	dc.w	$0106,$0000,$0108,$0000
	dc.w	$010a,$0000

	;; http://amiga-dev.wikidot.com/hardware:bplcon0
;#15 	HIRES 	HIRES = High resolution (640*200/640*400 interlace)
;#mode
;#14-12 	BPUx 	Bit planes use
;#11 	HAM 	Hold and modify mode, now using either 6 or 8 bit
;#planes.
;#10 	DPF 	Double playfield (PF1 = odd & PF2 = even bit planes)
;#now available in all resolutions.
;#(If BPU = 6 and HAM = 0 and DPF = 0 a special mode is
;#defined that allows bitplane 6 to cause an intensity
;#reduction of the other 5 bitplanes. The color
;#register output selected by 5 bitplanes is shifted
;#to half intensity by the 6th bit plane. This is
;#called EXTRA-HALFBRITE Mode.
;#09 	COLOR 	Enables color burst output signal
;#08 	GAUD 	Genlock audio enable. This level appears on the ZD
;#pin on denise during all blanking periods, unless ZDCLK
;#bit is set.
;#07 	UHRES 	Ultrahi res enables the UHRES pointers (for 1k*1k) also
;#needs bits in DMACON (hires chips only).
;#Disables hard stops for vert, horiz display windows.
;#06 	SHRES 	Super hi-res mode (35ns pixel width)
;#05 	BYPASS=0 	Bit planes are scrolled and prioritized normally, but
;#bypass color table and 8 bit wide data appear on R(7:0).
;#04 	BPU3=0 	See above (BPUx)
;#03 	LPEN 	Light pen enable (reset on power up)
;#02 	LACE 	Interlace enable (reset on power up)
;#01 	ERSY 	External resync (HSYNC, VSYNC pads become inputs)
;#(reset on power up)
;#00 	ECSENA=0 	When low (default), the following bits in BPLCON3 are
;#disabled: BRDRBLNK,BRDNTRAN,ZDCLKEN,BRDSPRT, and
;#EXTBLKEN. These 5 bits can always be set by writing
;#to BPLCON3, however there effects are inhibited until
;#ECSENA goes high. This allows rapid context switching
				;#between pre-ECS viewports and new ones.
	;; $0100
	dc.w	bplcon0,$2200			; 2 Bitplanes, output enabled
	
copper_bplptr:
	dc.w	$00e0,$0000,$00e2,$0000		; Bitplaneptrs
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000
	dc.w	$00f0,$0000,$00f2,$0000

	;; Spritepointers...
copper_spriteptr:
	dc.w	$120,0		:Sprite 0
	dc.w	$122,0
				; Clear spriteptrs
	dc.w	$0124,$0000,$0126,$0000
	dc.w	$0128,$0000,$012a,$0000
	dc.w	$012c,$0000,$012e,$0000
	dc.w	$0130,$0000,$0132,$0000
	dc.w	$0134,$0000,$0136,$0000
	dc.w	$0138,$0000,$013a,$0000
	dc.w	$013c,$0000,$013e,$0000

	; Setting up the 4 colors
	;; http://www.winnicki.net/amiga/memmap/COLORx.html
	dc.w	color,$0000	;black
	dc.w	color+2,$0a00	;red
	dc.w	color+4,$00a0	;green
	dc.w	color+6,$000a	;blue
	;; Sprites, colour 16, etc. $180+2*16=$1a0
	dc.w	$01a0,$0fff,$01a2,$0b41,$01a4,$0ad4,$01a6,$0059
	;dc.w	color+2*16,$0fff
	;dc.w	color+2*17,$0ff0
	;dc.w	color+2*18,$0f0f
	;dc.w	color+2*19,$00ff
	

	; amigadev.elowar.com says:
	; WAIT %VVVVVVVVHHHHHHH1, BVVVVVVVHHHHHHH0
	; MOVE %0000000RRRRRRRR0, ????????????????

	dc.w	$1011, $fffe
	dc.w	$0180, $0000
	dc.w	$2021, $fffe
	dc.w	$0180, $000f
	dc.w	$3031, $fffe
	dc.w	$0180, $00f0
	dc.w	$4041, $fffe
	dc.w	$0180, $00ff
	dc.w	$5051, $fffe
	dc.w	$0180, $0f00
	dc.w	$6061, $fffe
	dc.w	$0180, $0f0f
	dc.w	$7071, $fffe
	dc.w	$0180, $0fff
	dc.w	$8081, $fffe
	dc.w	$0180, $0000
	dc.w	$9091, $fffe
	dc.w	$0180, $0f00
	dc.w	$A0A1, $fffe
	dc.w	$0180, $000f


	;; Wait for line 250
	dc.w	$fa01,$ff00
	;; COLOR00
	dc.w	$0180,$0888
	;; Wait for line 251
	dc.w	$fb01,$ff00
	;; COLOR00
	dc.w	$0180,$0fff
	dc.w	$ffff,$fffe


	dc.b	"ChipData"
