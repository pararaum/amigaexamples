;;; Play a sample and stop via interrupt.
	include	"own.i"
	include	"hardware/custom.i"
	
;;; Section is name, section type
	section	text,code

_start:
	jmp	main(pc)
	dc.b	"Play sample",10
	dc.b	"by Pararaum / T7D",10,0
	even
debug:	dc.l	0

main:
l2$:	tst.l	debug
	bne	l2$
	move	#OWN_libraries|OWN_trap|OWN_interrupt,d0
	jsr	own_machine
	nop
	bsr	set_audio_irq
	bsr	play_sample
	;; Apparently this has to be done after the sample has started
	;; to play. Otherwise there seems to be always an additional
	;; interrupt. Why?
	move.w	#$7fff,$dff000+intreq	      ;Clear pending interrupts
	move.w	#$8000|(1<<14)|(1<<7),$DFF09a ;And enable the interrupt
l1$:	btst	#6,$bfe001	; Left mouse?
	bne	l1$
	nop
	jsr	disown_machine
	clr.l	d0
	rts

irq_counter:	dc.l	0

set_audio_irq:
	lea	audio_irq_routine(pc),a0
	move.l	a0,$70.w	;Set Level 4 interrupt autovector
	;; Restoration not needed, this is done in framework.
	rts

audio_irq_routine:
	addq.l	#1,irq_counter
	cmp.l	#3,irq_counter
	blt.s	b$
	move.w	#$1,$DFF096	;Disable Audio DMA
	move.w	#$7fff,$dff09a	;Disable interrupts
b$:	move.w	#$7fff,$dff000+intreq ;acknowledge irq
	rte

play_sample:
	lea.l	$DFF000,a6
	lea.l	sample_data,a0
	add.w	#$30,a0			;Skip header (should probably use IFF reader)
	move.l	a0,aud0+ac_ptr(a6)		;Audio 0 channel pointer
	lea.l	sample_data_end,a1
	sub.l	a0,a1		;Calculate length of sample
	move.w	a1,aud0+ac_len(a6)	;Audio 0 length
	move.w	#3579546/10000,aud0+ac_per(a6)	;Audio 0 period
	move.w	#64,aud0+ac_vol(a6)	;Audio 0 volume
	move.w	#$8000|(1<<9)|$1,$96(a6) ;DMACON, enable DMA, enable Audio 0 DMA
	rts

	section	chip,data_c
sample_data:
	incbin	"st-43.deephit.8svx"
sample_data_end:
