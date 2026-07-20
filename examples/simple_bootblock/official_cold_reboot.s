;	https://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node02E3.html
;
; coldboot.asm
;
; Here is a source code listing of the only supported reboot code:
;

*   NAME
*       ColdReboot - Official code to reset any Amiga (Version 2)
*
*   SYNOPSIS
*       ColdReboot()
*       void ColdReboot(void);
*
*   FUNCTION
*       Reboot the machine.  All external memory and peripherals will be
*       RESET, and the machine will start its power up diagnostics.
*
*       Rebooting an Amiga in software is very tricky.  Differing memory
*       configurations and processor cards require careful treatment.  This
*       code represents the best available general purpose reset.  The
*       MagicResetCode must be used exactly as specified here. The code
*       _must_ be longword aligned.  Failure to duplicate the code EXACTLY
*       may result in improper operation under certain system configurations.
*
*   RESULT
*	This function never returns.

                    INCLUDE "exec/types.i"
                    INCLUDE "exec/libraries.i"

                    XDEF    _ColdReboot
                    XREF    _LVOSupervisor

ABSEXECBASE         EQU 4           ;Pointer to the Exec library base
MAGIC_ROMEND        EQU $01000000   ;End of Kickstart ROM
MAGIC_SIZEOFFSET    EQU -$14        ;Offset from end of ROM to Kickstart size
V36_EXEC            EQU 36          ;Exec with the ColdReboot() function
TEMP_ColdReboot     EQU -726        ;Offset of the V36 ColdReboot function

_ColdReboot:    move.l  ABSEXECBASE,a6
                cmp.w   #V36_EXEC,LIB_VERSION(a6)
                blt.s   old_exec
                jmp     TEMP_ColdReboot(a6)     ;Let Exec do it...
                ;NOTE: Control flow never returns to here

;---- manually reset the Amiga ---------------------------------------------
old_exec:       lea.l   GoAway(pc),a5           ;address of code to execute
                jsr     _LVOSupervisor(a6)      ;trap to code at (a5)...
                ;NOTE: Control flow never returns to here

;-------------- MagicResetCode ---------DO NOT CHANGE-----------------------
                CNOP    0,4                     ;IMPORTANT! Longword align!
GoAway:         lea.l   MAGIC_ROMEND,a0         ;(end of ROM)
                sub.l   MAGIC_SIZEOFFSET(a0),a0 ;(end of ROM)-(ROM size)=PC
                move.l  4(a0),a0                ;Get Initial Program Counter
                subq.l  #2,a0                   ;now points to second RESET
                reset                           ;first RESET instruction
                jmp     (a0)                    ;CPU Prefetch executes this
                ;NOTE: the RESET and JMP instructions must share a longword!
;---------------------------------------DO NOT CHANGE-----------------------
                END

