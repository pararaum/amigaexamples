        include "t7d/music.i"
        include "hardware/custom.i"
        include "hardware/intbits.i"
	include	"boss.memorymanagement.i"

	section	LOWCODE,CODE
	jmp	_part_init(pc)
	jmp	_main(pc)
	jmp	_part_teardown(pc)
	jmp	_part_vbirq(pc)
	;; Use this if nothing to do.
	rts
	nop
	;; or RTS RTS, ...
