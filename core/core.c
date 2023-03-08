#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


int _start(int a, int b) {
    unsigned int i;

    printf("I was called with 0x%x 0x%x\n", a, b);

    for (i = 0; i < 10; i++) {
        printf("Hello %u\n", i);
    }

    char * buf = malloc(128);

    printf("malloc returned %p\n", buf);

    strcpy(buf, "This is a test string\n");

    puts(buf);

    return 0;
}