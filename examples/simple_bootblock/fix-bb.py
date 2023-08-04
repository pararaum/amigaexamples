#! /usr/bin/env python

import sys
import struct

def main(fname):
    with open(fname, 'rb+') as fin:
        data = fin.read()
        assert len(data) == 880 * 512 * 2
	chksum = 0x444f5300
	for w in range(8, 1024, 4):
	    chksum += struct.unpack('>I', data[w:w + 4])[0]
	    if chksum > 0xffffffff:
		chksum = (chksum + 1) & 0xffffffff
	chksum = (~chksum) & 0xffffffff
        fin.seek(4)
        fin.write(struct.pack('>I', chksum))
    print("Checksum = $%08X" % chksum)

if __name__ == "__main__":
    if len(sys.argv) == 2:
	main(sys.argv[1])
    else:
	sys.stderr.write('fix-bb <filename>\n')
