
	XDEF	_deflated_data
	XDEF	_wait_for_mouse

	SECTION CODE,code
;;; Wait for mouse button.
;;; Destroys: A0
_wait_for_mouse:
        lea     $BFE001,a0              ;CIA A
l$:     btst    #6,(a0)
        bne.b   l$
        rts

	SECTION	DATA,data
_deflated_data:
	INCBIN	"serene_scene.deflate"

;;; The scene uses the palette "Endesga-8" [https://lospec.com/palette-list/endesga-8] by Endesga.
