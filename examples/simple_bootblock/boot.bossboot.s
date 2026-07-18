
	include	hardware/custom.i
	include	hardware/dmabits.i
	include	exec/io.i
	include	exec/memory.i
	include	boss.memorymanagement.i

BOOTCODEADDRESS = $100
BOOTSIZE=1024
DESTINATIONBOSS=$C00000	

BOSSONDISK=$600
BOSSMARGIN=$2000		; We need some margin other decompression could overwrite...
BOSSDISKSIZE=$3000+BOSSMARGIN

BOOTSTART:
;;; Registers:
CUSTOM:	equr	a5
MEMADDR:	equr	a4	; Address of allocated memory block.
CUSTOMADDRES:	equ	$DFF000

	move.l	a1,a3		; Save IO request address.
	;; In A6 we have the Exec base.
	jsr	_LVOForbid(a6)	  ; No more task switching.
	lea	CUSTOMADDRES,CUSTOM	; Custom base in A5.
	move.w	#$00ff,color(CUSTOM)
	move.l	#BOSSDISKSIZE,d0	      ; Memory size
	moveq	#MEMF_CHIP,d1		      ; We *must* use chip memory.
	jsr	_LVOAllocMem(a6)
	move.l	d0,MEMADDR
	tst.l	d0
	beq	boot_fail
	;; Read BOSS.
	move.l  #BOSSONDISK,d3	  ; byte offset into disk
	move.l  #BOSSDISKSIZE,d4      ; length in bytes
	move.l	MEMADDR,d0
	add.l	#BOSSMARGIN,d0
	move.l	a3,a1		; Restore IO request.
	move.l  d0,IO_DATA(a1)
	move.l  d4,IO_LENGTH(a1)
	move.l  d3,IO_OFFSET(a1)
	move.w  #CMD_READ,IO_COMMAND(a1)
	jsr     _LVODoIO(a6)          ; a6 = exec base, available at boot time
	tst.l   d0
	bne     boot_fail
	;; Read manifest.
	move.l  #$200,d3	  ; byte offset into disk
	move.l  #$400,d4      ; length in bytes
	move.l	MEMADDR,d0
	move.l  d0,IO_DATA(a1)
	move.l  d4,IO_LENGTH(a1)
	move.l  d3,IO_OFFSET(a1)
	move.w  #CMD_READ,IO_COMMAND(a1)
	jsr     _LVODoIO(a6)          ; a6 = exec base, available at boot time
	tst.l   d0
	bne     boot_fail
	move.w	#$000f,color(CUSTOM)
	move.w	#$7fff,intena(CUSTOM) ; Disable interrupts.
	move.w	#$7fff,intreq(CUSTOM) ; Disable interrupt requests.
	move.w	#$7fff,dmacon(CUSTOM) ; Disable DMA.
	;; And switch directly to super user mode.
	lea	super$(pc),a0
	move.l	a0,$20.w	  ; Set privilege escalation vector.
	stop	#$0200		  ; This is a privileged opcode.
super$:				  ; Supervisor mode with A7=SP at end of memory.
	move.l	MEMADDR,a0
	add.l	#BOSSMARGIN,a0
	lea.l	DESTINATIONBOSS,a1
	bsr	zx0_decompress
	move.w	#$000a,color(CUSTOM)
	;; Init the BOSS.
	move.l	MEMADDR,a0
	move.l	#"RESI",d0
	jmp	DESTINATIONBOSS
	
	include	zx0decompress.inc

boot_fail:
	move.l	#$0f00,color(a5)
	bra	*
	dc.l	"T7D "


BOOTEND:
	printt "BOOTEND-BOOTSTART"
	printv	BOOTEND-BOOTSTART
