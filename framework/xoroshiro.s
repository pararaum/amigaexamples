;;; Very simple random number generator.
;;; This is a quite fast and sufficiently fast generator.
;;;
;;; Links
;;;  * https://github.com/ZiCog/xoroshiro/blob/master/src/main/c/xoroshiro.h
;;;  * http://vigna.di.unimi.it/xorshift/xoroshiro128plus.c
;;;  * http://xoshiro.di.unimi.it/
	
	XDEF	_xoroshiro32plusplus
	XDEF	_seed_xoroshiro32plusplus

XORO32a:	EQU	13
XORO32b:	EQU	5
XORO32c:	EQU	10
XORO32d:	EQU	9

;;; Call the Xoroshiro32++ RNG which yields a 16 bit number.
;;; Output:
;;; D0.w: next random number (16 bit)
;;; Destroys:
;;; D0, D1, A0, A1
_xoroshiro32plusplus:
	;; A0=result
	;; A1=used as a temporary
	move.w	x32pps0(pc),d0	; result = rol(s0 + s1, d) + s0
	add.w	x32pps1(pc),d0
	moveq	#XORO32d,d1
	rol.w	d1,d0
	add.w	x32pps0(pc),d0
	move.w	d0,a0		; Temporarily store result.
	move.w	x32pps0(pc),d0	; s1 ^= s0
	eor.w	d0,x32pps1
	move.w	x32pps0(pc),d0	; s0 = rol(s0, a ) ^ s1 ^ (s1 << b);
	moveq	#XORO32a,d1	;	# rol(s0,a)
	rol.w	d1,d0
	move.w	x32pps1(pc),d1	;	# ^ s1
	eor.w	d1,d0
	move.w	x32pps1(pc),d1	;	# (s1 << b)
	lsl.w	#XORO32b,d1
	eor.w	d1,d0
	move.w	d0,x32pps0
	move.w	x32pps1(pc),d0	; s1 = rol(s1, c)
	moveq	#XORO32c,d1
	rol.w	d1,d0
	move.w	d0,x32pps1
	move.w	a0,d0
	rts
	;; These are the default values.
x32pps0:	dc.w	1
x32pps1:	dc.w	0

_seed_xoroshiro32plusplus:
	tst.l	d0
	beq.s	default$
	move.l	d0,x32pps0
	rts
default$:
	move.l	#$00010000,x32pps0
	rts
