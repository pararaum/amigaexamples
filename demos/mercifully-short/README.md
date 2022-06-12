# Mercifully Short #

This is a simple demo in three small parts which is for everybody who
does not like long and boring(?) demos. It should be snappy.

## Credits ##

Code: Pararaum
Font: DamienG
Graphics: ipok / VCC

# Parts #

The main code resides in mshort.c and is written in C. Some small
routines are written in Assembler.

## Part 1 ##

This is a swinging text routine which swings text from left to right
until it is centered. The chip memory in the BSS segment is used and
interpreted as a 960 times 200 screen. Every SWINGING_step lines a
text line is centered on the central 320*200 screen which will be
visible finally. Datafetch is started early so that we do get
artifacts when swinging the text using the scroll register and
bitplane pointers. All the action happens in the copper list, no
actual copying of the text happens.

After the swinging is finished all the texts are deactivated in a
revers sequence one after the other. This is simply done by over
writing the slots alloted in the copperlist with copper no-ops.

## Part 2 ##

The screen is switched to a colour screen with 320*200 pixels and four
bitplanes (16 colours). The a fade in of sorts is performed by using
the blitter to "or" a single bitplane with the text "it is" with the
four bitplanes in the background graphics. This will change the
colours where the text is until all bits are set in the bitplanes. The
colour with the index 15 is black so the text will be visible nicely.

After some seconds the bitplanes will be restored one after the other
to have a reverse fading type effect until the original graphics can
be seen again.

## Part 3 ##

Swooshing effect...
