        INCLUDE "hardware/custom.i"

	XDEF	_generate_scroller_copperlist
	XDEF	_sentinel_font_deflated
	XDEF	_performance_muzak

	SECTION	CODE,code
;;; Generate the copperlist for the scroller, if D0 is zero return the needed size instead.
;;; D0=pointer to the copperlist area
;;; A0=pointer to the scroller bitplane
_generate_scroller_copperlist:
	;; A6=copperlist area
	tst.l	d0
	bne	copy$
	move.l	#4+scroller_coplist_end-scroller_coplist,d0
	rts
copy$:	movem.l	d0-d7/a0-a6,-(sp)
	move.l	d0,a6		; Safe copper list area pointer.
	move.l	a0,d0		; Pointer to the bitplane now in d0.
	moveq	#4-1,d1		; Four bitplanes.
	move.w	#$e0,d2		; BPL1PT (high)
	lea.l	scroller_coplist_bitplpt,a0 ; Spare area for bitplane pointers.
l2$:	swap	d0
	move.w	d2,(a0)+
	addq.w	#2,d2
	move.w	d0,(a0)+
	swap	d0
	move.w	d2,(a0)+
	addq.w	#2,d2
	move.w	d0,(a0)+
	add.l	#(320+32)/8,d0
	dbf	d1,l2$
	move.w	#(scroller_coplist_end-scroller_coplist)/4,d0
	lea.l	scroller_coplist,a1
l1$:	move.l	(a1)+,(a6)+
	dbf	d0,l1$
	movem.l	(sp)+,d0-d7/a0-a6
	rts

	SECTION	DATA,data
;;; convert Charset-DNS_Sentinel.png +gravity -crop 32x32 tile.%02x.png
;;; montage tile.* -tile 1x -geometry +0+0 dns_sentinel.png
;;; convert_img2raw -h dns_sentinel.png
;;; convert_img2raw -O raw -B4 -b dns_sentinel.png |gzip -9 | tail -c +11 > dns_sentinel.deflated
;;; convert_img2raw -B4 -p dns_sentinel.png
;;;
;;; (* (/ 32 8) 2240 4)35840 bytes...
;;;

	; Filename 'dns_sentinel.png'
dns_sentinel_png_width	EQU	32
dns_sentinel_png_height	EQU	2240
dns_sentinel_png_bitplanes	EQU	4
	XDEF	dns_sentinel_png_width
	XDEF	dns_sentinel_png_height
	XDEF	dns_sentinel_png_bitplanes
_sentinel_font_deflated:
	INCBIN	"dns_sentinel.deflated"
	even

_performance_muzak:
	INCBIN	"only_amiga.mod.deflated"
	even

scroller_coplist:
	dc.w	$FFDF,$FFFE
	dc.w	bplcon0,$0200
scroller_coplist_bitplpt:
	REPT	4
	dc.w	$1fe,0		; Upper 16 bits...
	dc.w	$1fe,0		; Lower 16 bits of bitplane pointer.
	ENDR
	dc.w	diwstrt,$2c81;
	dc.w	diwstop,$2cc1;
;;; 320px + 32px (plane1) (line0) O
;;; 320px + 32px (plane2) (line0) E
;;; 320px + 32px (plane3) (line0) O
;;; 320px + 32px (plane4) (line0) E
;;; 320px + 32px (plane1) (line1) O
;;; 320px + 32px (plane2) (line2) E
;;; 320px + 32px (plane3) (line3) O
;;; 320px + 32px (plane4) (line4) E
;;; Display 320 pixels 
	dc.w	bpl1mod,((320+32)*(4-1)+32)/8
	dc.w	bpl2mod,((320+32)*(4-1)+32)/8
	dc.w	$0107,$FFFE
	dc.w	bplcon0,$4200
	dc.w	bplcon1,0
	dc.w	bplcon2,0
	DC.W	color+2*00,$0000
	DC.W	color+2*01,$0420
	DC.W	color+2*02,$0640
	DC.W	color+2*03,$0971
	DC.W	color+2*04,$0ba3
	DC.W	color+2*05,$0ee4
	DC.W	color+2*06,$0eca
	DC.W	color+2*07,$037d
	DC.W	color+2*08,$049d
	DC.W	color+2*09,$026c
	DC.W	color+2*10,$015b
	DC.W	color+2*11,$003b
	DC.W	color+2*12,$05ae
	DC.W	color+2*13,$07df
	DC.W	color+2*14,$0fff
	DC.W	color+2*15,$099b
	;; (format "%02x" (+ 1 32))"21"
	dc.w	$2101,$FFFE
	;; "Mirror" effect. TODO: reduce colour brightness?
;;; 320px have been displayed, so 320 pixels back and go back four bitplanes.
	dc.w	bpl1mod,-((320+32)*(4)+320)/8
	dc.w	bpl2mod,-((320+32)*(4)+320)/8
	dc.w	color,$0001
	dc.w	$2201,$FFFE
	dc.w	bplcon1,$0011
	dc.w	color,$0002
	dc.w	$2301,$FFFE
	dc.w	bplcon1,$0033
	dc.w	color,$0004
	dc.w	$2401,$FFFE
	dc.w	bplcon1,$0055
	dc.w	color,$0006
	dc.w	$2501,$FFFE
	dc.w	bplcon1,$0077
	dc.w	color,$0008
	dc.w	$2601,$FFFE
	dc.w	bplcon1,$0099
	dc.w	color,$000a
	dc.w	$2701,$FFFE
	dc.w	bplcon1,$00bb
	dc.w	color,$001c
	dc.w	$2801,$FFFE
	dc.w	bplcon1,$00dd
	dc.w	color,$002e
	dc.w	$2901,$FFFE
	dc.w	bplcon1,$00ff
	dc.w	color,$004f
	dc.w	$2a01,$FFFE
	dc.w	bplcon0,$0200
	dc.w	$FFFF,$FFFE
scroller_coplist_end:
