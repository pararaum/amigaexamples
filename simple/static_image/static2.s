


_start:	jmp	main(pc)
	dc.b	"Static image 2",10
	dc.b	"Code: Pararaum / T7D",0
	align	4
main:	nop
	moveq	#0,d0
	rts
