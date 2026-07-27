SECTIONS {
 . = STARTADDR;
 LOWCODE : {
 	 *(LOWCODE)
 }
 CODE : {
      *(CODE)
      *(music)
 }
 exec_LVO : {
 	 *(exec_LVO)
 	 *(exec_LVO0)
 	 *(exec_LVO1)
 }
 DATA : {
      *(DATA)
 }
 data : {
      *(data)
 }
 
 BSS  : {
     __BSS_START__ = .;
     *(BSS)
     *(musicbss)
     __BSS_END__ = .;
 }
}
