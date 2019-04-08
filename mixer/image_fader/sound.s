;;; Sound samples.
	include	"hardware/custom.i"
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
	;; A6: $DFF000
	;; A2: sound sample address (FORM file)
	movem.l	d2-d7/a2-a6,-(sp)
        lea.l   $DFF000,a6
	lsl.l	#2,d0		  ; Multiply by four
	lea.l	_sound_samples,a0 ; Address of sound sample list.
	move.l	(a0,d0.w),a2	  ; A2 now has address of sound sample
	move.l	a2,a0		  ; IFF data
	move.l	"SSND",d0	  ; Sound data
	jsr	find_iff_chunk
	;; A0=ptr to data, D0=size or -1
	move.l  a0,aud0+ac_ptr(a6) ; Audio 0 channel pointer
        move.w  d0,aud0+ac_len(a6)      ;Audio 0 length
        move.w  #3579546/20000,aud0+ac_per(a6)  ;Audio 0 period
        move.w  #64,aud0+ac_vol(a6)     ;Audio 0 volume
        move.w  #$8000|(1<<9)|$1,dmacon(a6) ;DMACON, enable DMA, enable Audio 0 DMA
	movem.l	(sp)+,d2-d7/a2-a6
        rts
	

	SECTION	CHIP,data_c
_sound_samples:
	dc.l	sample0
	dc.l	sample1
	dc.l	sample2
	dc.l	sample3
	dc.l	0

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
