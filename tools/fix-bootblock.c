#include <stdio.h>
#include <string.h>
#include <inttypes.h>

#define DISKSIZE (880UL*2*512)

unsigned char filebuf[DISKSIZE];

int main(int argc, char **argv) {
  FILE *file;
  size_t bytes_read;
  uint64_t checksum = 0;

  if(argc != 2) {
    fprintf(stderr, "usage: fix-bootblock <filename>\n");
    return 1;
  }
  if(!(file = fopen(argv[1], "rb+"))) {
    perror("error while opening input");
    return 10;
  }
  bytes_read = fread(filebuf, 1, DISKSIZE, file);
  if(ferror(file) != 0) {
    perror("erro while reading");
    return 10;
  }
  if(bytes_read < 1024) {
    fprintf(stderr, "Error! Could read only %ld bytes.\n", (unsigned long)bytes_read);
    return 10;
  }
  if(strcmp((char*)filebuf, "DOS") != 0) {
    fprintf(stderr, "Error! Not an Amiga DOS image.\n");
    return 10;
  }    
  // Clear old checksum.
  filebuf[4] = 0;
  filebuf[5] = 0;
  filebuf[6] = 0;
  filebuf[7] = 0;
  for(int i = 0; i < 1024; i += 4) {
    uint64_t val = ((uint64_t)filebuf[i] << 24) | ((uint64_t)filebuf[i + 1] << 16) | ((uint64_t)filebuf[i + 2] << 8) | (uint64_t)filebuf[i + 3];
    checksum += val;
    printf("%4d %08lx %09lx\n", i, (unsigned long)val, (unsigned long)checksum);
    if(checksum > 0xFFFFFFFFULL) {
      checksum = (checksum + 1) & 0xFFFFFFFFUL;
    }
  }
  checksum ^= 0xFFFFFFFFUL;
  fseek(file, 4, SEEK_SET);
  fputc((checksum >> 24) & 0xFF, file);
  fputc((checksum >> 16) & 0xFF, file);
  fputc((checksum >> 8) & 0xFF, file);
  fputc((checksum) & 0xFF, file);
  fclose(file);
  printf("Checksum = $%08lX\n", (unsigned long)checksum);
  return 0;
}
