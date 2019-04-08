;;; Sound samples.
	include	"hardware/custom.i"
	include	"hardware/dmabits.i"
	include	"iff.i"

	XDEF	_sound_samples
	XDEF	_play_sample

	SECTION TEXT,code

	;; Play a sample from the sample list
	;; Input
	;; D0.w: number of sample
	;; Output:
	;; D0: Sample address
_play_sample:
	cmp.w	#(_sound_samples_end-_sound_samples)/4,d0
	bcc.s	end$	       ;not(d0<no of sound samples?)
	;; A6: $DFF000
	;; A2: sound sample address (FORM file)
	movem.l	d2-d7/a2-a6,-(sp)
        lea.l   $DFF000,a6
	lsl.l	#2,d0		  ; Multiply by four (ptr is 4 bytes)
	lea.l	_sound_samples,a0 ; Address of sound sample list.
	move.l	(a0,d0.w),a2	  ; A2 now has address of sound sample
	move.l	a2,a0		  ; IFF data
	move.l	#"SSND",d0	  ; Sound data
	jsr	find_iff_chunk
	;; A0=ptr to data, D0=size or -1
	;; Size is in bytes therefore divide by two.
	lsr.w	#1,d0
	move.l  a0,aud0+ac_ptr(a6)	; Audio 0 channel pointer
        move.w  d0,aud0+ac_len(a6)	; Audio 0 length
        move.w  #64,aud0+ac_vol(a6)	; Audio 0 volume
        move.w  #3579546/20000,aud0+ac_per(a6)	;Audio 0 period
	move.l  a0,aud1+ac_ptr(a6)	; Audio 1 channel pointer
        move.w  d0,aud1+ac_len(a6)	; Audio 1 length
        move.w  #64,aud1+ac_vol(a6)	; Audio 1 volume
        move.w  #3579546/20000,aud1+ac_per(a6)  ;Audio 1 period
        move.w  #DMAF_SETCLR|DMAF_MASTER|DMAF_AUD0|DMAF_AUD1,dmacon(a6) ;DMACON, enable DMA, enable Audio 0 & 1 DMA
	movem.l	(sp)+,d2-d7/a2-a6
end$:	rts
	

	SECTION	CHIP,data_c
_sound_samples:
	dc.l	sample0
	dc.l	sample1
	dc.l	sample2
	dc.l	sample3
	dc.l	0
_sound_samples_end:

sample0:
	incbin	"voice.t7d.aiff"
	even
sample1:
	incbin	"voice.presents.aiff"
	even
sample2:
	incbin	"voice.flamewars.aiff"
	even
sample3:
	incbin	"voice.minidemo.aiff"
