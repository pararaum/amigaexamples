;;; This code was mostly ripped from alpha one's http://www.flashtro.com/index.php?e=page&c=crack8&id=606. I just streamlined it a little bit and added some comments for my pleasure. Later on this will be a real intro...

;;; Section is name, section type
	section	text,code

main:
	move.l	4.w,a6		; Get base of exec lib
	lea	gfxlib,a1	; Adress of gfxlib string to a1
	moveq	#0,d0		; any version is ok
	jsr	-408(a6)	; Call OpenLibrary()
	tst.l	d0
	bne.s	.libok
	moveq	#-1,d0		; user should know something went wrong
	rts
.libok:	move.l	d0,gfxbase	; Save base of graphics.library
	lea	picture,a0	; Address of picture-rawdata
	lea	bplptr,a1	; Address of bitplaneptrs in copperlist
	moveq	#5-1,d1		; 5 bitplanes to set in copperlist
setbpls:move.l	a0,d0		; Picture-Rawdata address to d0
	move.w	d0,6(a1)	; Insert bitplaneptr into copperlist
	swap	d0		; 
	move.w	d0,2(a1)	;
	add.l	#(320/8)*256,a0	; Pointer to next bitplane in picture-rawdata
	addq.l	#8,a1		; Next Bitplaneptr in copperlist
	dbf	d1,setbpls

	jsr	-132(a6)	; Forbid task switching
	;; see: http://amiga.sourceforge.net/amidevhelp/phpwebdev.php?keyword=Forbid&funcgroup=AmigaOS&action=Search
	move.l #cop,$dff080	; Set new copperlist
mouse:	btst #6,$bfe001		; Left mouse clicked?
	bne.b mouse		; No, continue loop!
	move.l gfxbase,a1	; Base of graphics.library to a1
	move.l 38(a1),$dff080	; Restore old copperlist
	jsr	-138(a6)	; Permit task switching
	;; http://amiga.sourceforge.net/amidevhelp/phpwebdev.php?keyword=Permit&funcgroup=AmigaOS&action=Search
	jsr -414(a6)		; Call CloseLibrary()
	moveq #0,d0		; Status = OK
	rts			; Bye, Bye!


	section vars,data
gfxlib:		dc.b	"graphics.library",0

	
	section data,data_c
	;; Copper List
	;; see: http://www.theflatnet.de/pub/cbm/amiga/AmigaDevDocs/hard_2.html
cop:
	dc.w	$0106,$0000,$01fc,$0000		; AGA compatible
	;; Setting up display.
	;; see also: http://cyberpingui.free.fr/tuto_graphics.htm
	dc.w	$008e,$2c81,$0090,$2cc1		; DIWSTRT/DIWSTOP
	dc.w	$0092,$0038,$0094,$00d0		; DDFSTRT/DDFSTOP
	dc.w	$0102,$0000,$0104,$0000
	dc.w	$0106,$0000,$0108,$0000
	dc.w	$010a,$0000
	dc.w	$0120,$0000,$0122,$0000		; Clear spriteptrs
	dc.w	$0124,$0000,$0126,$0000
	dc.w	$0128,$0000,$012a,$0000
	dc.w	$012c,$0000,$012e,$0000
	dc.w	$0130,$0000,$0132,$0000
	dc.w	$0134,$0000,$0136,$0000
	dc.w	$0138,$0000,$013a,$0000
	dc.w	$013c,$0000,$013e,$0000

	; Setting up the 32 colors

	dc.w	$0180,$0000,$0182,$0012,$0184,$0201,$0186,$0213
	dc.w	$0188,$0223,$018a,$0124,$018c,$0224,$018e,$0326
	dc.w	$0190,$0345,$0192,$0412,$0194,$0525,$0196,$0556
	dc.w	$0198,$0348,$019a,$0438,$019c,$0569,$019e,$056c
	dc.w	$01a0,$078a,$01a2,$0923,$01a4,$0936,$01a6,$0946
	dc.w	$01a8,$0d56,$01aa,$093a,$01ac,$0a59,$01ae,$0a5d
	dc.w	$01b0,$0d69,$01b2,$0d6e,$01b4,$099a,$01b6,$0aac
	dc.w	$01b8,$0bcd,$01ba,$0d8b,$01bc,$0f9e,$01be,$0def

		dc.w	$0100,$5200			; 5 Bitplanes
bplptr:		dc.w	$00e0,$0000,$00e2,$0000		; Bitplaneptrs
		dc.w	$00e4,$0000,$00e6,$0000
		dc.w	$00e8,$0000,$00ea,$0000
		dc.w	$00ec,$0000,$00ee,$0000
		dc.w	$00f0,$0000,$00f2,$0000
	;; Wait for line 250
	dc.w	$fa01,$ff00
	;; COLOR00
	dc.w	$0180,$0fff
	dc.w	$ffff,$fffe

	align	0,4
picture:	incbin	"testpicture.raw"		; picture 32 cols

	section	storage,bss
gfxbase:	ds.l	1
