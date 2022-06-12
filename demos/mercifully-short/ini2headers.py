#! /usr/bin/env python3

"""Generate global include files

Generate the global include files for assembler and C. Assembler
include files will not contain strings and the C header files will put
parenthesis around the defines as this could be some definition of an
expression. The section names will be prepended.

"""

import configparser
import sys
import re

DOLLARRX = re.compile(r"\$[0-9a-fA-F]+")

def replace_dollar(astr):
    """Replace $<hex> with the decimal value

    Decimal was chosen as both C and ASM can be catered.

    @param astr: string to modify
    @return: modified string with every $<hex> replaced by its decimal value
    """
    while True:
        match = DOLLARRX.search(astr)
        if not match:
            break
        beg, end = match.span()
        substr = astr[beg:end]
        astr = "%s%d%s" % (astr[:beg], int(astr[beg+1:end], 16), astr[end:])
    return astr
    

def output_include(outf, kvpairs):
    """Write include file

    @param outf: output file
    @param kvpairs: dictionary with data
    """
    for key in sorted(kvpairs.keys()):
        val = kvpairs[key]
        if val[0] == '"':
            # It is a string.
            print("#define %s %s" % (key, val), file=outf)
        else:
            try:
                print("#define %s %d" % (key, int(val)), file=outf)
            except ValueError:
                print("#define %s (%s)" % (key, val), file=outf)

    
def output_asminc(outf, kvpairs):
    for key in sorted(kvpairs.keys()):
        val = kvpairs[key]
        if val[0] != '"':
            # No strings in assembler includes.
            try:
                print("%s EQU %d" % (key, int(val)), file=outf)
            except ValueError:
                print("%s EQU %s" % (key, val), file=outf)
    
def main(files):
    conpar = configparser.ConfigParser(delimiters=('=', ':', '≔'))
    kvpairs = {}
    for fnam in files:
        print("Reading %s..." % fnam)
        conpar.read(fnam)
    for sect, proxy in conpar.items():
        sect = sect.replace(" ", "_")
        for key, val in proxy.items():
            key = key.replace(" ", "_")
            kvpairs[sect + '_' + key] = replace_dollar(val)
    print(kvpairs)
    with open("globals.h", "w") as out:
        output_include(out, kvpairs)
    with open("globals.i", "w") as out:
        output_asminc(out, kvpairs)

if __name__ == "__main__":
    main(sys.argv[1:])
