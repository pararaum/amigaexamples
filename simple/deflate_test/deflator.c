#include <stdio.h>
#include <hardware/custom.h>
#include <hardware/dmabits.h>

/*
 * This is an example of how to use the inflate.asm code from
 * https://github.com/keirf/Amiga-Stuff. A file can be generated quiet
 * easily with gzip.
 */

/* Custom chip registers. */
extern struct Custom custom;
extern void inflate(void *output_buffer, void *input_stream);
extern unsigned char deflated_data[];
extern void *own_machine(ULONG __reg("d0") initbits);
extern void disown_machine(void);
extern void wait_for_mouse(void);

/* Excerpt from RFC 1952:
 
   2.3. Member format

      Each member has the following structure:

         +---+---+---+---+---+---+---+---+---+---+
         |ID1|ID2|CM |FLG|     MTIME     |XFL|OS | (more-->)
         +---+---+---+---+---+---+---+---+---+---+

      (if FLG.FEXTRA set)

         +---+---+=================================+
         | XLEN  |...XLEN bytes of "extra field"...| (more-->)
         +---+---+=================================+

      (if FLG.FNAME set)

         +=========================================+
         |...original file name, zero-terminated...| (more-->)
         +=========================================+

      (if FLG.FCOMMENT set)

         +===================================+
         |...file comment, zero-terminated...| (more-->)
         +===================================+

      (if FLG.FHCRC set)

         +---+---+
         | CRC16 |
         +---+---+

         +=======================+
         |...compressed blocks...| (more-->)
         +=======================+

           0   1   2   3   4   5   6   7
         +---+---+---+---+---+---+---+---+
         |     CRC32     |     ISIZE     |
         +---+---+---+---+---+---+---+---+

      2.3.1. Member header and trailer

         ID1 (IDentification 1)
         ID2 (IDentification 2)
            These have the fixed values ID1 = 31 (0x1f, \037), ID2 = 139
            (0x8b, \213), to identify the file as being in gzip format.

         CM (Compression Method)
            This identifies the compression method used in the file.  CM
            = 0-7 are reserved.  CM = 8 denotes the "deflate"
            compression method, which is the one customarily used by
            gzip and which is documented elsewhere.

         FLG (FLaGs)
            This flag byte is divided into individual bits as follows:

               bit 0   FTEXT
               bit 1   FHCRC
               bit 2   FEXTRA
               bit 3   FNAME
               bit 4   FCOMMENT
               bit 5   reserved
               bit 6   reserved
               bit 7   reserved

            If FTEXT is set, the file is probably ASCII text.  This is
            an optional indication, which the compressor may set by
            checking a small amount of the input data to see whether any
            non-ASCII characters are present.  In case of doubt, FTEXT
            is cleared, indicating binary data. For systems which have
            different file formats for ascii text and binary data, the
            decompressor can use FTEXT to choose the appropriate format.
            We deliberately do not specify the algorithm used to set
            this bit, since a compressor always has the option of
            leaving it cleared and a decompressor always has the option
            of ignoring it and letting some other program handle issues
            of data conversion.

            If FHCRC is set, a CRC16 for the gzip header is present,
            immediately before the compressed data. The CRC16 consists
            of the two least significant bytes of the CRC32 for all
            bytes of the gzip header up to and not including the CRC16.
            [The FHCRC bit was never set by versions of gzip up to
            1.2.4, even though it was documented with a different
            meaning in gzip 1.2.4.]

            If FEXTRA is set, optional extra fields are present, as
            described in a following section.

            If FNAME is set, an original file name is present,
            terminated by a zero byte.  The name must consist of ISO
            8859-1 (LATIN-1) characters; on operating systems using
            EBCDIC or any other character set for file names, the name
            must be translated to the ISO LATIN-1 character set.  This
            is the original name of the file being compressed, with any
            directory components removed, and, if the file being
            compressed is on a file system with case insensitive names,
            forced to lower case. There is no original file name if the
            data was compressed from a source other than a named file;
            for example, if the source was stdin on a Unix system, there
            is no file name.

            If FCOMMENT is set, a zero-terminated file comment is
            present.  This comment is not interpreted; it is only
            intended for human consumption.  The comment must consist of
            ISO 8859-1 (LATIN-1) characters.  Line breaks should be
            denoted by a single line feed character (10 decimal).

            Reserved FLG bits must be zero.

         MTIME (Modification TIME)
            This gives the most recent modification time of the original
            file being compressed.  The time is in Unix format, i.e.,
            seconds since 00:00:00 GMT, Jan.  1, 1970.  (Note that this
            may cause problems for MS-DOS and other systems that use
            local rather than Universal time.)  If the compressed data
            did not come from a file, MTIME is set to the time at which
            compression started.  MTIME = 0 means no time stamp is
            available.

         XFL (eXtra FLags)
            These flags are available for use by specific compression
            methods.  The "deflate" method (CM = 8) sets these flags as
            follows:

               XFL = 2 - compressor used maximum compression,
                         slowest algorithm
               XFL = 4 - compressor used fastest algorithm

         OS (Operating System)
            This identifies the type of file system on which compression
            took place.  This may be useful in determining end-of-line
            convention for text files.  The currently defined values are
            as follows:

                 0 - FAT filesystem (MS-DOS, OS/2, NT/Win32)
                 1 - Amiga
                 2 - VMS (or OpenVMS)
                 3 - Unix
                 4 - VM/CMS
                 5 - Atari TOS
                 6 - HPFS filesystem (OS/2, NT)
                 7 - Macintosh
                 8 - Z-System
                 9 - CP/M
                10 - TOPS-20
                11 - NTFS filesystem (NT)
                12 - QDOS
                13 - Acorn RISCOS
               255 - unknown

[https://tools.ietf.org/html/rfc1952]
*/

 /*
  * The following was generated with gzip, the first ten bytes are the
  * header (see description above.
  */
unsigned char lorem_bin[] = {
  0x1f, 0x8b, 0x08, 0x00, 0x4e, 0x03, 0xb2, 0x5c, 0x02, 0x03, 0x65, 0x91,
  0x4b, 0x52, 0x83, 0x31, 0x0c, 0x83, 0xf7, 0x9c, 0x42, 0x07, 0xe8, 0x70,
  0x0a, 0x96, 0x6c, 0x39, 0x40, 0x9a, 0x98, 0x1f, 0xcf, 0x24, 0x71, 0x48,
  0xec, 0xf2, 0x38, 0x3d, 0xca, 0xb4, 0x85, 0x05, 0xbb, 0xbc, 0xe4, 0x4f,
  0x52, 0x9e, 0x6d, 0x4a, 0x83, 0x8e, 0x15, 0x0d, 0xc5, 0xaa, 0x4d, 0x2c,
  0x75, 0xa4, 0x26, 0x7e, 0x42, 0xb6, 0xbe, 0x24, 0xbb, 0x78, 0xc8, 0x44,
  0x2a, 0x3a, 0x74, 0x65, 0xed, 0x07, 0xa4, 0x2a, 0x6f, 0x97, 0x14, 0x14,
  0xa5, 0xb8, 0x5b, 0x8f, 0xd6, 0xbe, 0xd0, 0xf5, 0xfc, 0x06, 0x09, 0x5d,
  0xcd, 0x0a, 0x5c, 0x7b, 0xd6, 0x12, 0xdd, 0x11, 0x8e, 0x9a, 0xf2, 0x14,
  0xf1, 0x2b, 0x40, 0xd0, 0xd2, 0xd1, 0x13, 0x52, 0xd5, 0x23, 0x52, 0x83,
  0xcc, 0xe4, 0xb8, 0x58, 0x0d, 0x1f, 0xc9, 0x1f, 0xf1, 0xe2, 0xf8, 0xd0,
  0xa5, 0x0b, 0xd2, 0xb5, 0x91, 0x8a, 0xa6, 0x7b, 0x71, 0xe1, 0x36, 0xb5,
  0x13, 0xde, 0x39, 0x9f, 0xc4, 0xe5, 0x33, 0x0a, 0xe4, 0x53, 0x66, 0x56,
  0x78, 0xb8, 0x5a, 0x47, 0xd4, 0xca, 0x71, 0xd9, 0xe6, 0xa0, 0xdd, 0x15,
  0xf4, 0x3a, 0x18, 0xa5, 0xda, 0xd9, 0xa6, 0x6f, 0x11, 0xa7, 0x6e, 0x33,
  0xe4, 0x72, 0xc8, 0xa0, 0x18, 0x92, 0xf8, 0xbc, 0xd1, 0xae, 0x5d, 0xb3,
  0xbe, 0xc7, 0x76, 0xf0, 0xb4, 0x11, 0x2e, 0x78, 0x95, 0x38, 0x14, 0xaf,
  0x29, 0x6b, 0xa5, 0xf4, 0x76, 0x9e, 0xc2, 0xe5, 0xde, 0x94, 0x76, 0xbc,
  0x49, 0x2f, 0x53, 0x26, 0x39, 0xdc, 0x5c, 0xa2, 0x8e, 0xf0, 0x44, 0xe9,
  0x65, 0x57, 0x04, 0x59, 0x8b, 0x61, 0xad, 0xca, 0x72, 0x95, 0x3f, 0xc2,
  0x69, 0x5f, 0x43, 0x6b, 0xbd, 0x57, 0x2e, 0x6c, 0xed, 0x4a, 0x63, 0x13,
  0x7d, 0xc7, 0xf8, 0xa5, 0x12, 0xc8, 0x72, 0x64, 0x1a, 0x6b, 0x32, 0x76,
  0x42, 0xfb, 0x39, 0x47, 0x5b, 0xa9, 0xef, 0xb5, 0xc6, 0x72, 0x83, 0x15,
  0x35, 0xfe, 0xc4, 0xc1, 0x80, 0x8b, 0x4d, 0x31, 0x1c, 0xce, 0x35, 0xf5,
  0x42, 0x07, 0x63, 0x26, 0x59, 0xc2, 0x4f, 0xa8, 0x31, 0x68, 0x8c, 0xc0,
  0xef, 0xef, 0xa9, 0x15, 0x45, 0x2a, 0xfb, 0xe4, 0xb0, 0xc0, 0x11, 0x82,
  0xb2, 0x93, 0xdd, 0xac, 0xdc, 0x82, 0xff, 0x73, 0xf2, 0xf8, 0xf0, 0x03,
  0x95, 0xbe, 0xec, 0xd0, 0x2b, 0x02, 0x00, 0x00
};
unsigned int lorem_bin_len = 332;
UWORD __chip buffer[320*200/sizeof(UWORD)+1024];
UWORD __chip copper_list[] = {
  /* Bitplane pointer. */
  0xe0, 0,
  0xe2, 0,
  0xe4, 0,
  0xe6, 0,
  0xe8, 0,
  0xea, 0,
  /* NOP */
  0x1fe, 0,
  /* End of List */
  0xFFFF, 0xFFFE
};

void init_copper(UWORD *image) {
  int i;
  int planes = image[2];
  int colors = (1 << planes);
  ULONG address = (ULONG)image + 16 +  colors * 2;

  /* Set up copper list */
  custom.cop1lc = (ULONG)copper_list;
  custom.dmacon = DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER;
  custom.diwstrt = 0x2c81;
  custom.diwstop = 0x2cc1;
  custom.ddfstrt = 0x0038;
  custom.ddfstop = 0x00d0;
  custom.bplcon0 = 0x0200 | 0x1000 * planes; /* colour burst */
  custom.bplcon1 = 0;
  custom.bplcon2 = 0x0024;
  custom.bplcon3 = 0;
  custom.bpl1mod = 320/8*(planes-1);
  custom.bpl2mod = 320/8*(planes-1);
  custom.fmode = 0;
  copper_list[1] = address >> 16;
  copper_list[3] = address & 0xFFFF;
  copper_list[5] = (address+320/8) >> 16;
  copper_list[7] = (address+320/8) & 0xFFFF;
  copper_list[9] = (address+320/8*2) >> 16;
  copper_list[11] = (address+320/8*2) & 0xFFFF;
  for(i = 0; i < colors; ++i) {
    custom.color[i] = image[8 + i];
  }
}

int main(int argc, char **argv) {
  printf("inflate=$%08lX\n", (unsigned long)&inflate);
  printf("buffer=$%08lX\n", (unsigned long)&buffer);
  printf("init_copper=$%08lx\n", (unsigned long)&init_copper);
  puts("Deflating data...");
  inflate(buffer, &lorem_bin[10]);
  printf("DATA\n%s\nDATA END\n", (char*)buffer);
  inflate(buffer, deflated_data);
  printf("%hu\t%hu\t%hu\n", buffer[0], buffer[1], buffer[2]);
  own_machine(0x3);
  init_copper(buffer);
  wait_for_mouse();
  disown_machine();
  return 0;
}
