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

#ifndef ML_STRING_H
#define ML_STRING_H
#include <string.h>
#endif

#ifndef ML_ML_LEXER_H
#include "mllexgen.h"
#endif

#ifndef ML_TMPL_LEX_H
#include "tmlexgen.h"
#endif

#ifndef ML_FA_H
#include "fa.h"
#endif

static fa_list_t * mk_regex_list(lexer_lexer_state *s);
static fa_list_t * mk_start_state_list(lexer_lexer_state *s);
static void free_fa_list(fa_list_t *l);
static void run_tmpl(tmpl_state *t, const char *tmpl_name);

int main(int argc, char **argv)
{
    lexer_lexer_state s;
    FILE *f;
    Moonlime_state *lexer;
    char buf[256];
    size_t num_in = 1;
    const char *lexer_name = NULL;
    const char *cout_name = NULL;
    const char *hout_name = NULL;
    char *new_hout_name = NULL;
    const char *ctmpl_name = SHAREDIR "tmpl.c";
    const char *htmpl_name = SHAREDIR "tmpl.h";
    int i, verbose = 0;
    size_t slen;
    fa_list_t *rxl, *stsl;
    fa_t *nfa, *dfa;
    tmpl_state tms;

    for(i = 1; i < argc; ++i) {
        if(!strcmp(argv[i], "-o")) {
            if(++i >= argc) {
                fputs("No output file given after -o\n", stderr);
                return 1;
            }
            cout_name = argv[i];

        } else if(!strcmp(argv[i], "-i")) {
            if(++i >= argc) {
                if(cout_name == NULL)
                    continue;

                slen = strlen(cout_name);
                if(!strcmp(cout_name + slen - 2, ".c")) {
                    if(new_hout_name != NULL)
                        free(new_hout_name);

                    new_hout_name = malloc_or_die(slen + 1, char);
                    strncpy(new_hout_name, cout_name, slen+1);
                    strcpy(new_hout_name + slen - 2, ".h");
                    hout_name = new_hout_name;
                } else {
                    if(new_hout_name != NULL)
                        free(new_hout_name);
                    new_hout_name = NULL;
                    hout_name = "yylex.h";
                }
            } else {
                if(new_hout_name != NULL)
                    free(new_hout_name);
                new_hout_name = NULL;
                hout_name = argv[i];
            }
        } else if(!strcmp(argv[i], "-v"))
            verbose = 1;
        else
            lexer_name = argv[i];
    }

    if(lexer_name == NULL) {
        fputs("No lexer file given\n", stderr);
        return 1;
    }
    if(cout_name == NULL)
        cout_name = "yylex.c";

    /*
     * Right now, we're just trying to check that the lexer-lexer tokenizes the
     * file correctly, not try to do anything with the results, so the
     * following is a little simplified for now.
     */
    init_lexer_lexer_state(&s);
    if(verbose)
        s.verb = stderr;

    if((f = fopen(lexer_name, "r")) == NULL) {
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
            if(!MoonlimeRead(lexer, buf, num_in, &s)) {
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

    if(!MoonlimeRead(lexer, NULL, 0, &s)) {
        fputs("An error occurred during lexing near EOF!\n", stderr);
        MoonlimeDestroy(lexer);
        return 1;
    }

    MoonlimeDestroy(lexer);
    fclose(f);

    if(s.states == NULL) {
        s.initstate = lstring_dupbuf(1, "A");
        s.states = malloc_or_die(1, lstr_list_t);
        s.states->s = s.initstate;
        s.states->next = NULL;
    }

    rxl = mk_regex_list(&s);
    stsl = mk_start_state_list(&s);
    nfa = multi_regex_compile(rxl);

    if(verbose) {
        fputs("--- total NFA:\n", stderr);
        print_fa(stderr, nfa, "nfa");
    }

    dfa = nfas_to_dfas(nfa, rxl, stsl);

    if(verbose) {
        fputs("--- total DFA:\n", stderr);
        print_fa(stderr, dfa, "dfa");
    }

    tms.st = &s;
    tms.dfa = dfa;
    tms.patterns = rxl;
    tms.start_states = stsl;

    if((f = fopen(cout_name, "w")) == NULL) {
        fprintf(stderr, "Can\'t open %s for writing\n", cout_name);
        return 1;
    }

    tms.f = f;
    run_tmpl(&tms, ctmpl_name);
    fclose(f);

    if(hout_name != NULL) {
        if((f = fopen(hout_name, "w")) == NULL) {
            fprintf(stderr, "Can\'t open %s for writing\n", hout_name);
            return 1;
        }

        tms.f = f;
        run_tmpl(&tms, htmpl_name);
        fclose(f);
    }

    free_fa_list(rxl);
    free_fa_list(stsl);
    destroy_fa(nfa);
    destroy_fa(dfa);

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

static fa_list_t * mk_start_state_list(lexer_lexer_state *s)
{
    lstr_list_t *p = s->states;
    fa_list_t *first = NULL, *last = NULL, *curr = NULL;

    while(p != NULL) {
        curr = malloc_or_die(1, fa_list_t);

        if(first == NULL)
            first = curr;
        if(last != NULL)
            last->next = curr;

        curr->state = NULL;
        curr->data1 = p->s;

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

static void run_tmpl(tmpl_state *t, const char *tmpl_name)
{
    FILE *f;
    char buf[1];
    Template_state *lexer;
    size_t num_in = 1;
    int num_tot = 0;

    if((f = fopen(tmpl_name, "r")) == NULL) {
        fprintf(stderr, "Can\'t open %s for reading\n", tmpl_name);
        exit(1);
    }

    if((lexer = TemplateInit(malloc, free)) == NULL) {
        fputs("Error in TemplateInit\n", stderr);
        exit(1);
    }

    while(num_in > 0) {
        num_in = fread(buf, 1, sizeof(buf), f);

        if(num_in != 0) {
            if(!TemplateRead(lexer, buf, num_in, t)) {
                fprintf(stderr, "Error lexing %s (%d-%d)\n", tmpl_name,
                        num_tot, num_tot + (int) num_in);
                TemplateDestroy(lexer);
                exit(1);
            }
        }
        num_tot += num_in;

        if(ferror(f)) {
            fprintf(stderr, "Error reading %s\n", tmpl_name);
            TemplateDestroy(lexer);
            exit(1);
        }
    }

    if(!TemplateRead(lexer, NULL, 0, t)) {
        fprintf(stderr, "Error near the end of %s\n", tmpl_name);
        exit(1);
    }

    TemplateDestroy(lexer);
    fclose(f);
}
