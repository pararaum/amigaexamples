SECTIONS {
 . = 0xc00000;
 CODE : {
     __CODE_START__ = .;
      *(CODE)
     __CODE_END__ = .;
 }
 exec_LVO : {
 	 *(exec_LVO)
 	 *(exec_LVO0)
 	 *(exec_LVO1)
 }
 romhunks : {
 	  *(romhunks)
 }
 DATA : {
     __DATA_START__ = .;
      *(data)
      *(DATA)
     __DATA_END__ = .;
 }
 BSS (NOLOAD) : {
     __BSS_START__ = .;
     *(BSS)
     __BSS_END__ = .;
 }
}
