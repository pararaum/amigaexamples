
	include	hardware/custom.i
	include	hardware/dmabits.i

BOOTCODEADDRESS = $100
BOOTSIZE=1024
;;; Here we put the decoded data in the correct order.
DESTINATIONDECODEBUFFER=$c7E000
DESTINATIONBOSS=$C00000	

BOOTSTART:
	dc.b	"DOS",0		; Header of a bootable disk.
	dc.l	0		; Checksum, will be added later.
	dc.l	880		; Root block number (default).

;;; Registers:
	;; A5 = $DFF000

	;; In A6 we have the Exec base.
	jsr	_LVOForbid(a6)	  ; No more task switching.
	lea	$DFF000,a5	; Custom base in A5.
	move.w	#$7fff,intena(a5) ; Disable interrupts.
	move.w	#$7fff,intreq(a5) ; Disable interrupt requests.
	move.w	#$7fff,dmacon(a5) ; Disable DMA.

bootcode:
	lea	BOOTEND(PC),a2	; A2=end of boot code
	move.l	a2,a0
	moveq	#11-1,d2
.bootloop:
	bsr.s	search_track
	move.l	$4.w,$4.w	; Special form to be used with memory watchpoints: "w 1 4 4 W". Every write (long) to address 4 will trigger a watchpoint.
	and.l	#$00ffff00,d0	; Mask out $00TTSS00, aka track and sector.
	asl.l	#1,d0		; Multiply by two (T=0, probably) and S=[0..11], as it is already at bit 8-15 multiplying by 2 conveniently skips another 512 bytes.
	add.l	#DESTINATIONDECODEBUFFER,d0
	move.l	a0,a2
	move.l	d0,a0
	bsr.s	decode_trackA1A0
	move.l	a2,a0
	cmp.l	#$800000,a0
	dbhi	d2,.bootloop	; if A0>$800000 is false (if true leave loop) then D2-=1, loop if D2 >= 0!

	move.w	#$00f0,color(a5)
	movea.l	#zx0data-BOOTSTART+DESTINATIONDECODEBUFFER,a0
	lea.l	DESTINATIONBOSS,a1
	bsr	zx0_decompress
	move.w	#$00a0,color(a5)

	jmp	DESTINATIONBOSS

;;; Decode a track
;;; Input: A0=destination to write decoded data to, A1=source MFM data
;;; Output: -
;;; Modifies: D0-D1,A0-A1
decode_trackA1A0:
.src:		equr	A1
.dest:		equr	A0
.counter:	equr	D2
.oddmfm:	equr	A3
.regs:	reg	.counter/.oddmfm
	movem.l	.regs,-(sp)
	lea.l	512(.src),.oddmfm
	move.w	#$100-1,d2
	move.l	#$55555555,d0
.loop:	move.l	(.src)+,d1
	and.l	d0,d1
	asl.l	#1,d1
	move.l	d1,(.dest)
	move.l	(.oddmfm)+,d1
	and.l	d0,d1
	or.l	d1,(.dest)+
	dbf	d2,.loop
	movem.l	(sp)+,.regs
	rts
	
;;; Search a track (mfm encoded) in memory.
;;; Input: A0=memory pointer
;;; Output: A0=memory pointer *after* sector, A1=pointer to mfm encoded sector data, D0=$FFTTSSkk (T=track, S=sector, k=skip to end of track)
;;; Modifies: A0,A1,D0,D1
search_track:
	cmp.w	#$AAAA,(a0)+	; Find the MFM encoding of a the gap (zero bytes).
	bne.s	search_track
	cmp.w	#$4489,(a0)	; First sync mark.
	bne.s	search_track
	cmp.w	#$4489,2(a0)	; Second sync mark.
	bne.s	search_track
	lea.l	4(a0),a0	; Skip syncs.
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	and.l	#$55555555,d0
	and.l	#$55555555,d1
	lsl.l	#1,d0
	or.l	d1,d0
	lea.l	48(a0),a1	; Beginning of MFM sector data.
	lea.l	1024(a1),a0	; Skip sector data.
	rts

	dc.b	"Pararaum/T7D",0
	even


;  unzx0_68000.s - ZX0 decompressor for 68000 - 88 bytes
;
;  in:  a0 = start of compressed data
;       a1 = start of decompression buffer
;
;  Copyright (C) 2021 Emmanuel Marty
;  ZX0 compression (c) 2021 Einar Saukas, https://github.com/einar-saukas/ZX0
;
;  This software is provided 'as-is', without any express or implied
;  warranty.  In no event will the authors be held liable for any damages
;  arising from the use of this software.
;
;  Permission is granted to anyone to use this software for any purpose,
;  including commercial applications, and to alter it and redistribute it
;  freely, subject to the following restrictions:
;
;  1. The origin of this software must not be misrepresented; you must not
;     claim that you wrote the original software. If you use this software
;     in a product, an acknowledgment in the product documentation would be
;     appreciated but is not required.
;  2. Altered source versions must be plainly marked as such, and must not be
;     misrepresented as being the original software.
;  3. This notice may not be removed or altered from any source distribution.

zx0_decompress:
               movem.l a2/d2,-(sp)  ; preserve registers
               moveq #-128,d1       ; initialize empty bit queue
                                    ; plus bit to roll into carry
               moveq #-1,d2         ; initialize rep-offset to 1

.literals:     bsr.s .get_elias     ; read number of literals to copy
               subq.l #1,d0         ; dbf will loop until d0 is -1, not 0
.copy_lits:    move.b (a0)+,(a1)+   ; copy literal byte
               dbf d0,.copy_lits    ; loop for all literal bytes
               
               add.b d1,d1          ; read 'match or rep-match' bit
               bcs.s .get_offset    ; if 1: read offset, if 0: rep-match

.rep_match:    bsr.s .get_elias     ; read match length (starts at 1)
.do_copy:      subq.l #1,d0         ; dbf will loop until d0 is -1, not 0
.do_copy_offs: move.l a1,a2         ; calculate backreference address
               add.l d2,a2          ; (dest + negative match offset)               
.copy_match:   move.b (a2)+,(a1)+   ; copy matched byte
               dbf d0,.copy_match   ; loop for all matched bytes

               add.b d1,d1          ; read 'literal or match' bit
               bcc.s .literals      ; if 0: go copy literals

.get_offset:   moveq #-2,d0         ; initialize value to $fe
               bsr.s .elias_loop    ; read high byte of match offset
               addq.b #1,d0         ; obtain negative offset high byte
               beq.s .done          ; exit if EOD marker
               move.w d0,d2         ; transfer negative high byte into d2
               lsl.w #8,d2          ; shift it to make room for low byte

               moveq #1,d0          ; initialize length value to 1
               move.b (a0)+,d2      ; read low byte of offset + 1 bit of len
               asr.l #1,d2          ; shift len bit into carry/offset in place
               bcs.s .do_copy_offs  ; if len bit is set, no need for more
               bsr.s .elias_bt      ; read rest of elias-encoded match length
               bra.s .do_copy_offs  ; go copy match

.get_elias:    moveq #1,d0          ; initialize value to 1
.elias_loop:   add.b d1,d1          ; shift bit queue, high bit into carry
               bne.s .got_bit       ; queue not empty, bits remain
               move.b (a0)+,d1      ; read 8 new bits
               addx.b d1,d1         ; shift bit queue, high bit into carry
                                    ; and shift 1 from carry into bit queue

.got_bit:      bcs.s .got_elias     ; done if control bit is 1
.elias_bt:     add.b d1,d1          ; read data bit
               addx.l d0,d0         ; shift data bit into value in d0
               bra.s .elias_loop    ; keep reading

.done:         movem.l (sp)+,a2/d2  ; restore preserved registers
.got_elias:    rts


BOOTEND:
	printt "BOOTEND-BOOTSTART"
	printv	BOOTEND-BOOTSTART
	;; Skip till end.
	dcb.b	BOOTSIZE-(BOOTEND-BOOTSTART)

zx0data:
	incbin	"boss.zx0"
	even
