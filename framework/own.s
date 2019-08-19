; -*- mode: asm-mode; -*-

	;; 	incdir	"Sources:include/"
	include "LVO/exec_lib.i"
	include "LVO/graphics_lib.i"
        include "hardware/custom.i"
        include "hardware/dmabits.i"
	include "own.i"

	XDEF	own_machine
	XDEF	disown_machine
	XDEF	_own_machine
	XDEF	_disown_machine
	XDEF	_own_supervisor
	XDEF	_disown_supervisor
	XDEF	_gfxbase

COP1LCH	EQU	$dff080
	
	;; Do not define! This will not call forbid! For testing!
	;; deb_noforbid equ 1
	section framework,code
	
;;; Convenience function for C call. Parameters see below and are read from the integer from the stack. Output: D0: _gfxbase
_own_machine:
	move.l	4(a7),d0
	bsr.s	own_machine
	move.l	a0,d0
	rts
;;; This function will open the graphics library and take over the
;	machine. The bits in D0 tell the function which further
;	initialisations should be done.
	;; Bits:
	;; 0: Open libraries (Must be done!)
	;; 1: Clear the View (Loadview with 0)
	;; 2: Get the trap vectors
	;; 3: Get the interrupt vectors
	;; ----
	;; IN
	;; d0: Bits set initialise something
	;; OUT
	;; a0: _gfxbase
own_machine:
	;; d7: stores the initialisation bits.
	;; d6: current bit for actions
	;; a6: gfx or exec
	;; a5: jump table pointer
	movem.l	d2-d7/a2-a6,-(sp)	; Save registers.
	move.l	d0,d7		; Store initialisation bits.
	move.l	d0,initialisation_bits
	move.l	$4.w,a6		; Load Exec to a6.
	lea.l	jump_table,a5	; Jump table pointer is in a5.
	moveq	#0,d6		; We begin with zeroth bit and zeroth element in jump table.
l1$:	btst	d6,d7		; Is the bit set?
	beq	nodo$		; No, do nothing.
	move.l	d6,d0		; Current bit into d0.
	lsl.w	#3,d0		; Bit times eight (Pointer is four bytes, two pointers).
	move.l	(a5,d0),a0	; jump_table + d0 into a0.
	jsr	(a0)		; Jump to where a0 points to.
nodo$:	addq	#1,d6		; Increment current bit.
	cmp	#15,d6		; Maximum reached?
	bne	l1$		; No, loop
	move.l	$4.w,a6
	ifnd	deb_noforbid
	jsr _LVOForbid(a6)	; Forbid
	endif
	move.l	_gfxbase,a0	; GfxBase is returned in A0.
	movem.l	(sp)+,d2-d7/a2-a6	; Restore registers.
	rts

clear_view:
	move.l 	_gfxbase,a6
        move.l  34(a6),oldgfxbaseview
        move.l  38(a6),oldcopperlistptr
	move.l	#0,a1		; No view
	;; http://amigadev.elowar.com/read/ADCD_2.1/Includes_and_Autodocs_2._guide/node0459.html
	jsr	_LVOLoadView(a6)	; LoadView
	jsr	_LVOWaitTOF(a6)	; WaitTOF
	jsr	_LVOWaitTOF(a6)	; WaitTOF
	jsr	_LVOOwnBlitter(a6)
	jsr	_LVOWaitBlit(a6)
	rts

restore_view:
	move.l 	_gfxbase,a6
	move.l  oldcopperlistptr,COP1LCH
	move.l 	oldgfxbaseview,a1	;Old default View
	jsr	_LVOLoadView(a6)	; LoadView
	jsr	_LVOWaitTOF(a6)	; WaitTOF
	jsr	_LVOWaitTOF(a6)	; WaitTOF
	jsr	_LVODisownBlitter(a6)
	rts

_disown_machine:
disown_machine:
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	$4.w,a6
	ifnd	deb_noforbid
	jsr	_LVOPermit(a6)	; Permit
	endif
	move.l	initialisation_bits,d7
	lea.l	jump_table,a5	; Jump table pointer is in a5.
	moveq	#15,d6		; We begin with 15th bit, closing down is reversed...
l1$:	btst	d6,d7		; Is the bit set?
	beq	nodo$		; No, do nothing.
	move.l	d6,d0		; Current bit into d0.
	lsl.w	#3,d0		; Bit times eight (Pointer is four bytes, two pointers).
	move.l	4(a5,d0),a0	; jump_table + d0 + 4 into a0.  D0*4???
	jsr	(a0)		; Jump to where a0 points to.
nodo$:	dbf	d6,l1$		; Decrement, loop
	movem.l	(sp)+,d0-d7/a0-a6
	rts

init_libraries:
	lea	gfxname,a1	; Name of Gfx library.
	moveq	#0,d0		; Version
	jsr	_LVOOpenLibrary(a6) ;Open
	tst.l	d0
	bne.s	ok$
	bsr	kill_program	; Yes, we kill the program!
ok$:	move.l	d0,_gfxbase	    ;Store gfxbase, updates condition codes.
	rts

shutdown_libraries:
	move.l 	_gfxbase,a1
	move.l	$4.w,a6
	jsr	_LVOCloseLibrary(a6)
	rts

kill_program:
	ori.b	#2,CCR	;Set overflow flag
	trapv
	rts

trap15_code:
	move.l	d0,-(sp)
	move.w	#$0f00,d0
l$:	move.w	d0,$dff180
	eor.b	#$ff,d0
	bra.s	l$
	move.l	(sp)+,d0
	rte

trapV_code:
	move.l	d0,-(sp)
	move.l	#$00000f00,d0
l$:	move.w	d0,$dff180
	swap	d0
	bra.s	l$
	move.l	(sp)+,d0
	rte

;;; Store the pointers for the trap functions
store_trap_pointer:
	lea.l	$0080.w,a0
	lea.l	trap_pointers,a1
	moveq	#16-1,d0
l$:	move.l	(a0)+,(a1)+
	dbf	d0,l$
	move.l	$01c.w,(a1)+	;TRAPV
	;; Now set the 15 trap vectors.
	lea.l	trap15_code(pc),a0 ; Address of trap code
	lea.l	$0080.w,a1	   ; target instruction vector
	moveq	#16-1,d0	   ; 16 vectors
l1$:	move.l	a0,(a1)+
	dbf	d0,l1$
	move.l	#trapV_code,$1c.w
	rts
	
retrieve_trap_pointer:
	lea.l	$0080.w,a0
	lea.l	trap_pointers,a1
	moveq	#16-1,d0
l$:	move.l	(a1)+,(a0)+
	dbf	d0,l$
	move.l	(a1)+,$01c.w	;TRAPV
	rts

;;; Store and disable interrupts.
;;; Destroys: D0-D1, A0-A1
store_interrupt_autovector:
	lea.l	$60.w,a0
	lea.l	autovector_pointers,a1
	moveq	#8-1,d0
l$:	move.l	(a0)+,(a1)+
	dbf	d0,l$
	lea.l	$DFF000,a6
	lea.l   interrupt_custom,a0  ;Space to save registers
        move.l  #$80008000,d1	;Preload set/clear bit
        move.w  dmaconr(a6),d0
        or.w    d1,d0
        move.w  d0,(a0)+
        move.w  adkconr(a6),d0
        or.w    d1,d0
        move.w  d0,(a0)+
        move.l  intenar(a6),d0  ;INTENAR and INTREQR
        or.l    d1,d0
        move.l  d0,(a0)+
        move.l  #$7fff3fff,intena(a6) ;Disable interrupts (INTENA) and remove pending (INTREQ)
        move.w  #$7fff,adkcon(a6)     ;Disable Audio, Disk, Control
        move.w  #$07ff,dmacon(a6)     ;Disable all DMA via DMA control
	rts

retrieve_interrupt_autovector:
	lea.l	$DFF000,a6
	move.l	#$7fff3fff,intena(a6)	;Kill INTENA and INTREQ
	move.w	#$7fff,adkcon(a6)	;Kill ADKCON
	move.w	#$07ff,dmacon(a6)	;Kill DMACON
	lea	autovector_pointers,a0
	lea.l	$60.w,a1
	moveq	#8-1,d0
l$:	move.l	(a0)+,(a1)+
	dbf	d0,l$
	;; Restore old interrupt conditions.
	lea.l	interrupt_custom,a0
	move.w	(a0)+,dmacon(a6)
	move.w	(a0)+,adkcon(a6)
	move.l	(a0)+,intena(a6)
	rts

;;; This function will set the CPU into supervisor mode and it will
;	store the current stack frame. A function pointer has to be
;	pushed onto the stack (void *(void) function). This function
;	is called and must return via RTS.
;;; Input: function pointer on stack
;;; Output: -
;;; Destroys: D0-D1/A0-A1
_own_supervisor:
	move.l	4(a7),a0		;Move function pointer into A0
	link	a1,#-4			;Get space on stack
	move.l	$20.w,(a7)		;Store old exception vector (privilege escalation)
	move.l	#exception$,$20.w	;Set new exception vector
	stop	#0			;Privilege escalation
	;illegal				;Never reached
return$:
	move.l	(a7),$20.w
	unlk	a1
	rts
exception$:
	movem.l	d0-d7/a0-a6,-(sp) ;Store registers
	move.l	#return$,15*4+2(a7) ;Adjust return address
	move.l	a7,own_supervisor_excp_frame
	jsr	(a0)		    ;Call function pointer
	movem.l	(sp)+,d0-d7/a0-a6 ;Restore registers
	rte

;;; Return from supervisor mode at exactly the same position we
;	entered it. See _own_supervisor subroutine.
;;; WARNING! This function does not return to the calling function
_disown_supervisor:
	move.l	own_supervisor_excp_frame,a7
	movem.l	(sp)+,d0-d7/a0-a6 ;Restore registers
	rte



	section framework_data,data
jump_table:
	dc.l	init_libraries, shutdown_libraries ; OWN_libraries
	dc.l	clear_view, restore_view	   ; OWN_view
	dc.l	store_trap_pointer, retrieve_trap_pointer	   ; OWN_trap
	dc.l	store_interrupt_autovector, retrieve_interrupt_autovector
	dc.l	kill_program, kill_program
	dc.l	kill_program, kill_program
	dc.l	kill_program, kill_program
	dc.l	kill_program, kill_program
	dc.l	kill_program, kill_program
	dc.l	kill_program, kill_program
	dc.l	kill_program, kill_program
	dc.l	kill_program, kill_program
	dc.l	kill_program, kill_program
	dc.l	kill_program, kill_program
	dc.l	kill_program, kill_program
	dc.l	kill_program, kill_program

gfxname:
	dc.b	"graphics.library",0
	even
	dc.l	"ZERO"

	section framework_bss,bss
_gfxbase:	ds.l	1
oldcopperlistptr:	ds.l	1
oldgfxbaseview:		ds.l	1
registerspace:	ds.w	4
trap_pointers:	ds.l	16+1	; Pointer to trap exception.
	;; Interrupt autovectors.
autovector_pointers:	ds.l	8
	;; Interrupt custom chip storage.
interrupt_custom:	ds.w	4
initialisation_bits:	ds.l	1
	;; Here we store the exception stack frame for easy return into user mode.
own_supervisor_excp_frame:	ds.l	1
