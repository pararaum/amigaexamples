
	XDEF	_decrunch_muzak
	XREF	inflate

	SECTION	CODE,CODE

;;; Decrunch the musik into a buffer. Warning! No security whatsoever!
;;; Input:
;;; A0 = output buffer
_decrunch_muzak:
	move.l	a0,a4
	lea.l	muzak_data,a5
	jsr	inflate
	clr.l	d0
	rts

	SECTION	DATA,DATA
muzak_data:
	;; 	INCBIN	"MOD.timewarped.deflated"
	INCBIN	"umwelt.mod.deflated"
	EVEN
	dc.l	"MUZK"
