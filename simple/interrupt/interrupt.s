;;; Example code to handle interrupts.
;;;
;;; Links:
;;; http://www.winnicki.net/amiga/memmap/MoreInts.html

SOFTWARE_INTERRUPT = $64
VBLANK_INTERRUPT = $6C

	include "hardware/custom.i"
	include "hardware/dmabits.i"
	include "own.i"

	section	text,code

_start:	bra.s	main
	dc.b	"Interrupt example",10
	dc.b	"Code: Pararaum / T7D",10
	EVEN
	ifd	DEBUG
	dc.l	"MAIN",main
	endif
	EVEN

main:	nop
	moveq   #OWN_libraries|OWN_view|OWN_interrupt,d0
        jsr     own_machine
	nop
	lea	$DFF000,a6	;Set custom register base
	lea.l	irq_handler,a0	;Set up own handler
	move.l	a0,VBLANK_INTERRUPT
	move.l	#softirq_handler,SOFTWARE_INTERRUPT		 ;Set own handler for software interrupt
	move.w	#$8000|(1<<14)|(1<<5)|(1<<2),intena(a6) ;Enable!
	nop
	bsr	setup_copper
	nop			;wait for mouse
	nop			;clean up
	nop
	move.l	#$4e8076,d0	;Random number
l1$:	move.w	d0,some_data
	subq.l	#1,d0
	bpl.s	l1$
	nop
	move.w	#$7fff,intena(a6)		   ;Disable interrupts before cleanup.
	nop
	jsr     disown_machine
	moveq	#0,d0
	rts

;;; Setup the copper
;;; Input: a6=$DFF000
;;; Destroys: a0
setup_copper:
	lea.l	copper_list,a0
	move.l	a0,cop1lc(a6)
	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER,dmacon(a6) ;Enable DMA.
	rts

softirq_handler:
	move.w	#$888,$180(a6)	;gray background
	move.w	#1<<2,intreq(a6) ;Acknowledge interrupt
	rte

some_data:	dc.l	-1
irq_handler:
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	some_data+2(pc),d0
	addq	#1,d0
	move.w	d0,some_data+2
	and.w	#$0FFF,d0
	move.w	d0,$180(a6)	;Make sure A6 is right otherwise BOOOM.
	move.w	#1<<5,intreq(a6) ;Ackowledge interrupt
	movem.l	(sp)+,d0-d7/a0-a6
	rte
	ifd	DEBUG
	dc.b	"irq_handler",0
	even
	bra	irq_handler
	endif

;;; Disable interrupts and save registers
;;; Input: A6=$DFF000
;;; Destroys: D0-D1, A0
disable_interrupts:
	lea.l	intspace(pc),a0	 ;Space to save registers
	move.w	#$8000,d1	 ;Preload set/clear bit
	move.w	dmaconr(a6),d0
	or.w	d1,d0
	move.w	d0,(a0)+
	move.w	adkconr(a6),d0
	or.w	d1,d0
	move.w	d0,(a0)+
	move.l	intenar(a6),d0	;INTENAR and INTREQR
	or.l	#$80008000,d0
	move.l	d0,(a0)+
	move.l	#$7fff3fff,intena(a6) ;Disable interrupts (INTENA) and remove pending (INTREQ)
	move.w	#$7fff,adkcon(a6)     ;Disable Audio, Disk, Control
	move.w	#$07ff,dmacon(a6)     ;Disable all DMA via DMA control
	rts
intspace:
	ds.w	4
	;; DMACON, ADKCON, INTENA, INTREQ

;;; Input: A6=$DFF000
enable_interrupts:
	move.l	#$7fff3fff,intena(a6)	;Kill INTENA and INTREQ
	move.w	#$7fff,adkcon(a6)	;Kill ADKCON
	move.w	#$07ff,dmacon(a6)	;Kill DMACON
	lea.l	intspace(PC),a0
	move.w	(a0)+,dmacon(a6)
	move.w	(a0)+,adkcon(a6)
	move.l	(a0)+,intena(a6)
	rts


	section chipdata,data_c
copper_list:
	dc.w	$4001,$fffe
	dc.w	$180,0
	dc.w	$a071,$fffe	;Wait H=$a0, vertical $70
	;; http://amiga-dev.wikidot.com/hardware:intreqr
	;; Software Interrupt! Not the usual copper interrupt. We use this interrupt vector so that two different interrupt vectors are used and we do not have to read the INTREQR register to distinguish between them. This is not the canonical form to do this!
	dc.w	intreq,$8000|(1<<2)
	dc.w	$c001,$fffe
	dc.w	$180,$333
	dc.w	$FFFF,$FFFE	;End of List

	section	bssc,bss_c
bitplane:
	ds.b	320*256/8	;Single bitplane 320 X 256


	section	bss,bss
level3_autovector:
	ds.l	1
level2_autovector:
	ds.l	1
