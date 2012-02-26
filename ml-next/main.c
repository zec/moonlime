/*
 * main.c: Entry point for Moonlime.
 *
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms.
 */

/*
 * The following idiom comes from John Lakos, "Large-Scale C++ Software
 * Design". The idea is that if we've already read in the header file, a
 * simple #include will require the whole header file to be read and parsed
 * *again*, even if it has no net effect. So ML_UTILS_H is #define'd inside
 * utils.h, and we check to see if it's already been #define'd so we don't have
 * to parse the header again unnecessarily. It's a touch wordy, but quickly
 * chunkable. Of course, I doubt Moonlime will ever count as 'large-scale',
 * but it's the *principle* of the thing...
 */
#ifndef ML_UTILS_H
#include "utils.h"
#endif

/* This is the version of the idiom for external headers. */
#ifndef ML_STDIO_H
#define ML_STDIO_H
#include <stdio.h>
#endif

#ifndef ML_STDLIB_H
#define ML_STDLIB_H
#include <stdlib.h>
#endif

#ifndef ML_ML_LEXER_H
#include "ml-lexer.h"
#endif

int main(int argc, char **argv)
{
    lexer_lexer_state s;
    FILE *f;
    void *lexer;
    char buf[256];
    size_t num_in = 1;

    /*
     * Right now, we're just trying to check that the lexer-lexer tokenizes the
     * file correctly, not try to do anything with the results, so the
     * following is a little simplified for now.
     */
    s.regex_nest_depth = 0;
    file_state = &s;

    if((f = fopen(argv[1], "r")) == NULL) {
        fprintf(stderr, "Couldn\'t open file \'%s\'\n", argv[1]);
        return 1;
    }

    if((lexer = MoonlimeInit(malloc, free)) == NULL) {
        fputs("Couldn\'t initialize lexer\n", stderr);
        return 1;
    }

    while(num_in > 0) {
        num_in = fread(buf, 1, sizeof(buf), f);

        if(num_in != 0) {
            if(!MoonlimeRead(lexer, buf, num_in)) {
                fputs("An error occurred during lexing!\n", stderr);
                MoonlimeDestroy(lexer);
                return 1;
            }
        }

        if(ferror(f)) {
            fputs("An error occurred during reading!\n", stderr);
            MoonlimeDestroy(lexer);
            return 1;
        }
    }

    if(!MoonlimeRead(lexer, NULL, 0)) {
        fputs("An error occurred during lexing near EOF!\n", stderr);
        MoonlimeDestroy(lexer);
        return 1;
    }

    MoonlimeDestroy(lexer);
    return 0;
}
