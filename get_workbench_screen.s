;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
	
	incdir Sources:include/
	include LVO/exec_lib.i
	include LVO/graphics_lib.i
	include LVO/intuition_lib.i
	include intuition/screens.i

	section text,code
main:
	nop
	move.l	$4.w,a6		; Load Exec to a6.
	lea	intuitionname,a1	; Name of Gfx library.
	moveq	#0,d0		; Version
	jsr	_LVOOpenLibrary(a6) ;Open
	move.l	d0,intuitionbase
	beq	end

	move.l	d0,a6		; Intuition to a6
	moveq	#0,d0
	move.l	d0,a0
	jsr	_LVOLockPubScreen(a6)
	move.l	d0,wbscreen
	beq	.nowb

	move.l	d0,a5		;Screen
	lea.l	sc_BitMap(a5),a4 ;Bitmap
	;; http://amigadev.elowar.com/read/ADCD_2.1/Includes_and_Autodocs_2._guide/node00A6.html#line47
	move.l	a4,wbbitmap
	illegal

.nowb:	nop
	move	wbscreen,a0
	jsr	_LVOUnlockPubScreen(a6)


	move.l	a6,a1		; Store GfxBase in A1
	move.l	$4,a6		; Exec to a6
	jsr	_LVOCloseLibrary(a6) ;Close

end:	rts


	section data,data

intuitionname:
	dc.b	"intuition.library",0
intuitionbase:
	dc.l	0
wbscreen:
	dc.l	0
wbbitmap:
	dc.l	0
