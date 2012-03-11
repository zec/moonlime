#ifndef YYML_Moonlime_HEADER
#define YYML_Moonlime_HEADER

/* The default lexical-scanner template for Moonlime. Terms under which the
 * generated code may be distributed, modified, etc. are provided by the
 * lexer-writer below. */


/* A lexer for Moonlime lexers.
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms. */

#define ML_ML_LEXER_H

#ifndef ML_UTILS_H
#include "utils.h"
#endif

#ifndef ML_REGEX_H
#include "regex.h"
#endif

typedef enum {
    D_NONE,
    D_TOP,
    D_HEADER,
    D_STATE,
    D_INITSTATE,
    D_PREFIX
} directive_kind;

struct pattern_entry {
    regex_t *rx;
    len_string *code;
    lstr_list_t *states;
    struct pattern_entry *next;
};

typedef struct pattern_entry pat_entry_t;

typedef struct {
    directive_kind dir;   /* Current type of directive being parsed */
    int c_nest_depth;     /* Current brace-nesting depth in C code */
    int regex_nest_depth; /* Current parenthesis-nesting depth in regex */
    len_string *code;     /* The current chunk of C code */

    regex_t *curr_rx; /* Current regular-expression fragment being worked on */
    regex_t *rx_stack; /* Stack of regular-expression fragments -- only
                        * types R_CONCAT, R_OPTION, and R_PAREN should be on
                        * the stack! */

    lstr_list_t *curr_st; /* List of start states for current fragment */

    pat_entry_t *phead; /* First element in the list of regular expression/
                         * code action pairs */
    pat_entry_t *ptail; /* Final element in the list so far */
    size_t npats;       /* Number of elements in the list */

    len_string *header; /* Code to appear both in any generated header file and
                         * the top of the generated lexer */
    len_string *top;    /* Code to appear at the top of the lexer, after the
                         * header */

    lstr_list_t *states;   /* The list of states */
    len_string *initstate; /* Initial start state */

    len_string *prefix; /* A prefix to use for names in the generated lexer. */

    FILE *verb; /* An optional file to print verbose information */
} lexer_lexer_state;

void init_lexer_lexer_state(lexer_lexer_state *st);

extern lexer_lexer_state *file_state;


typedef struct yy_Moonlime_state Moonlime_state;

Moonlime_state * MoonlimeInit( void * (*alloc)(size_t),
    void (*unalloc)(void *) );
void MoonlimeDestroy( Moonlime_state *lexer );
int MoonlimeRead( Moonlime_state *lexer, char *input, size_t len );

#endif
