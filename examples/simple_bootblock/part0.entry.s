        include "t7d/music.i"
        include "hardware/custom.i"
        include "hardware/intbits.i"
	include	"boss.memorymanagement.i"

	BSS
songmem:
	ds.l	1

	section	LOWCODE,CODE
	jmp	_part_init(pc)
	jmp	_main(pc)
	jmp	_part_teardown(pc)
	jmp	part_vbirq(pc)
	;; Use this if nothing to do.
	rts
	nop
	;; or RTS RTS, ...

	CODE
part_vbirq:
	rts
