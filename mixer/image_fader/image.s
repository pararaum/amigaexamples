;;; Image data

	XDEF	_image_pointers
	
	SECTION	DATA,data

_image_pointers:
	dc.l	image1
	dc.l	0

	EVEN
image1:	INCBIN	"static_image.ilbm"

