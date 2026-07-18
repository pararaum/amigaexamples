#ifndef __CUSTOMCHIPS_H_20220430__
#define __CUSTOMCHIPS_H_20220430__

// Offsets from custom base.

#define BLTDDAT     0x000
#define DMACONR     0x002
#define VPOSR	    0x004
#define VHPOSR	    0x006
#define DSKDATR     0x008
#define JOY0DAT     0x00A
#define JOY1DAT     0x00C
#define CLXDAT	    0x00E

#define ADKCONR     0x010
#define POT0DAT     0x012
#define POT1DAT     0x014
#define POTINP	    0x016
#define SERDATR     0x018
#define DSKBYTR     0x01A
#define INTENAR     0x01C
#define INTREQR     0x01E

#define DSKPT	    0x020
#define DSKLEN	    0x024
#define DSKDAT	    0x026
#define REFPTR	    0x028
#define VPOSW	    0x02A
#define VHPOSW	    0x02C
#define COPCON	    0x02E
#define SERDAT	    0x030
#define SERPER	    0x032
#define POTGO	    0x034
#define JOYTEST     0x036
#define STREQU	    0x038
#define STRVBL	    0x03A
#define STRHOR	    0x03C
#define STRLONG     0x03E

#define BLTCON0     0x040
#define BLTCON1     0x042
#define BLTAFWM     0x044
#define BLTALWM     0x046
#define BLTCPT	    0x048
#define BLTBPT	    0x04C
#define BLTAPT	    0x050
#define BLTDPT	    0x054
#define BLTSIZE     0x058
#define BLTCON0L    0x05B		// note: byte access only
#define BLTSIZV     0x05C
#define BLTSIZH     0x05E

#define BLTCMOD     0x060
#define BLTBMOD     0x062
#define BLTAMOD     0x064
#define BLTDMOD     0x066

#define BLTCDAT     0x070
#define BLTBDAT     0x072
#define BLTADAT     0x074

#define DENISEID    0x07C
#define DSKSYNC     0x07E

#define COP1LC	    0x080
#define COP2LC	    0x084
#define COPJMP1     0x088
#define COPJMP2     0x08A
#define COPINS	    0x08C
#define DIWSTRT     0x08E
#define DIWSTOP     0x090
#define DDFSTRT     0x092
#define DDFSTOP     0x094
#define DMACON	    0x096
#define CLXCON	    0x098
#define INTENA	    0x09A
#define INTREQ	    0x09C
#define ADKCON	    0x09E

#define AUD	    0x0A0
#define AUD0	    0x0A0
#define AUD1	    0x0B0
#define AUD2	    0x0C0
#define AUD3	    0x0D0

// AudChannel
#define AC_PTR	    0x00	; ptr to start of waveform data
#define AC_LEN	    0x04	; length of waveform in words
#define AC_PER	    0x06	; sample period
#define AC_VOL	    0x08	; volume
#define AC_DAT	    0x0A	; sample pair
#define AC_SIZEOF   0x10

#define BPLPT	    0x0E0

#define BPLCON0     0x100
#define BPLCON1     0x102
#define BPLCON2     0x104
#define BPLCON3     0x106
#define BPL1MOD     0x108
#define BPL2MOD     0x10A
#define BPLCON4     0x10C
#define CLXCON2     0x10E

#define BPLDAT	    0x110

#define SPRPT	    0x120

#define SPR	    0x140

//* SpriteDef
#define SD_POS	    0x00
#define SD_CTL	    0x02
#define SD_DATAA    0x04
#define SD_DATAB    0x06
#define SD_SIZEOF   0x08

#define COLOR00	    0x180
#define COLOR(x)    (0x180+x*2)

#define HTOTAL	    0x1C0
#define HSSTOP	    0x1C2
#define HBSTRT	    0x1C4
#define HBSTOP	    0x1C6
#define VTOTAL	    0x1C8
#define VSSTOP	    0x1CA
#define VBSTRT	    0x1CC
#define VBSTOP	    0x1CE
#define SPRHSTRT    0x1D0
#define SPRHSTOP    0x1D2
#define BPLHSTRT    0x1D4
#define BPLHSTOP    0x1D6
#define HHPOSW	    0x1D8
#define HHPOSR	    0x1DA
#define BEAMCON0    0x1DC
#define HSSTRT	    0x1DE
#define VSSTRT	    0x1E0
#define HCENTER     0x1E2
#define DIWHIGH     0x1E4
#define FMODE	    0x1FC
#define CNOOP	    0x1FE

#endif
