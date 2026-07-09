SECTIONS {
 . = 0xc00000;
 CODE : {
      *(CODE)
 }
 exec_LVO : {
 	 *(exec_LVO)
 	 *(exec_LVO0)
 	 *(exec_LVO1)
 }
 DATA : {
      *(DATA)
 }
}
