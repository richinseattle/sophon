#include <unistd.h>
#include <stdio.h>
#include <sys/mman.h>

int main(int argc, char * argv[]) {
    FILE * fh = fopen(argv[1], "rb");

    fseek(fh, 0, SEEK_END);
    size_t filesize = ftell(fh);
    fseek(fh, 0, SEEK_SET);

    if (filesize & 0xfff) {
        filesize += 0x1000;
        filesize &= 0xfffff000;
    }

    void * mem = mmap(0,
                      filesize,
                      PROT_READ | PROT_WRITE | PROT_EXEC,
                      MAP_ANONYMOUS | MAP_PRIVATE,
                      -1,
                      0);
    
    fread(mem, 1, filesize, fh);
    fclose(fh);

    ((void (*)(int, int)) mem)(0xdead, 0xbeef);

    return 0;
}