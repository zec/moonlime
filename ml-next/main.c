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

#ifndef ML_FA_H
#include "fa.h"
#endif

static fa_list_t * mk_regex_list(lexer_lexer_state *s);
static void free_fa_list(fa_list_t *l);

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
    init_lexer_lexer_state(&s);
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

    if(0) {
        pat_entry_t *p;
        fa_t *fa;
        state_t *initstate;
        int i = 0;

        for(p = s.phead; p != NULL; p = p->next) {
            fa = single_regex_compile(p->rx, &initstate);
            printf("--- NFA %d:\n", ++i);
            print_fa(stdout, fa, initstate);
            destroy_fa(fa);
        }
    }

    {
        fa_list_t *l = mk_regex_list(&s);
        fa_t *fa = multi_regex_compile(l);

        free_fa_list(l);
        printf("--- total NFA:\n");
        print_fa(stdout, fa, NULL);
        destroy_fa(fa);
    }

    return 0;
}

static fa_list_t * mk_regex_list(lexer_lexer_state *s)
{
    pat_entry_t *p = s->phead;
    fa_list_t *first = NULL, *last = NULL, *curr = NULL;

    while(p != NULL) {
        curr = malloc_or_die(1, fa_list_t);

        if(first == NULL)
            first = curr;
        if(last != NULL)
            last->next = curr;

        curr->state = NULL;
        curr->data1 = p->rx;
        curr->data2 = p->states;
        curr->data3 = p->code;

        last = curr;
        p = p->next;
    }

    if(curr != NULL)
        curr->next = NULL;

    return first;
}

static void free_fa_list(fa_list_t *l)
{
    fa_list_t *next;

    while(l != NULL) {
        next = l->next;
        free(l);
        l = next;
    }
}
