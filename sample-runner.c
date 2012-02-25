/*
 * sample-runner.c: Driver for the sample lexers.
 *
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms.
 */

#include <stdio.h>
#include <stdlib.h>

extern void * SampleInit( void * (*alloc)(size_t), void (*unalloc)(void *) );
extern void SampleDestroy( void *lexer );
extern int SampleRead( void *lexer, char *input, size_t len );

int main(int argc, char **argv)
{
    void *lexer = SampleInit(malloc, free);
    char buf[256];
    size_t num_in = 1;

    if(lexer == NULL) {
        fputs("Unable to initialize lexer!\n", stderr);
        return 1;
    }

    /* n_in will only be zero in the case of EOF or a file error */
    while(num_in != 0) {
        num_in = fread(buf, 1, sizeof(buf), stdin);

        if(num_in != 0) {
            if(!SampleRead(lexer, buf, num_in)) {
                fputs("An error occurred during lexing!\n", stderr);
                SampleDestroy(lexer);
                return 1;
            }
        }

        if(ferror(stdin)) {
            fputs("An error occurred during reading!\n", stderr);
            SampleDestroy(lexer);
            return 1;
        }
    }

    if(!SampleRead(lexer, NULL, 0)) {
        fputs("An error occurred during lexing near EOF!\n", stderr);
        SampleDestroy(lexer);
        return 1;
    }

    SampleDestroy(lexer);
    return 0;
}
