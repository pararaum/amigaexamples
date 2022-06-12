;;; -*- mode: asm -*-

;;; Create the copperlist entries for the bitplane pointers.
;;; Input: A0=copperlist pointer
;;;	A1=bitplane pointer to first bitplane
;;;	D1.w=modulo for the bitplanes
;;;	D0.w=number of bitplanes
;;; Output: A0=copperlist pointer after last written command
	XREF	copper_create_bitplptrs
