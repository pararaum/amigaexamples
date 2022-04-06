#include <stdio.h>
/* Include appropiate header*/
#include <proto/intuition.h>
#include <intuition/screens.h>
#include <clib/dos_protos.h>
#include <clib/exec_protos.h>

/* 
 * http://www.pjhutchison.org/tutorial/amiga_c.html
 */

/* First declare a pointer to the IntuitionBase structure */
struct IntuitionBase *IntuitionBase;

struct Screen *get_screen(void) {
  struct NewScreen Screen1 = {
    0,0,320,220,4, /* Screen of 320 x 220 of depth 4 (2^4 = 16 colours)    */
    DETAILPEN, BLOCKPEN,
    0,                     /* see graphics/view.h for view modes */
    PUBLICSCREEN,              /* Screen types */
    NULL,                      /* Text attributes (use defaults) */
    "My New Screen", 
    NULL,
    NULL
  };
  struct Screen *myScreen;
  myScreen = OpenScreen(&Screen1);
  return myScreen;
}

int main(int argc, char **argc) {
  struct Screen *myscreen;
  struct BitMap *bitmap;
  unsigned short int i;
  
  puts("Hello World!");
  /* Now open the library for Intuition */
  IntuitionBase = (struct IntuitionBase *)OpenLibrary("intuition.library", 34);
  printf("IntuitionBase = %08lX\n", (unsigned long)(IntuitionBase));
  myscreen = get_screen();
  printf("myscreen = $%08lX\n", (unsigned long)(myscreen));
  if(myscreen) {
    Delay(200);
    CloseScreen(myscreen);
  }
  printf("ActiveScreen = $%08lX\n", (unsigned long)(IntuitionBase->ActiveScreen));
  myscreen = IntuitionBase->ActiveScreen;
  bitmap = &(myscreen->BitMap);
  printf("bitmap = $%08lX\n", (unsigned long)bitmap);
  printf("bytesperrow=%u rows=%u\n",
	 bitmap->BytesPerRow,
	 bitmap->Rows
	 );
  for(i = 0; i < 8; ++i) {
    printf("planeptr=$%08lx\n", (unsigned long)(bitmap->Planes[i]));
  }
  for(i = 0; i < 320/8*100; ++i) {
    ((unsigned char *)(bitmap->Planes[0]))[i] = 0xAA;
  }
  if (IntuitionBase) CloseLibrary( (struct IntuitionBase *)IntuitionBase);
  return 0;
}

