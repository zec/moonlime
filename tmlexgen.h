#ifndef YYML_Template_HEADER
#define YYML_Template_HEADER

/* The default lexical-scanner template for Moonlime. Terms under which the
 * generated code may be distributed, modified, etc. are provided by the
 * lexer-writer below. */


/* A lexer for template .c and .h files.
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms. */

#define ML_TMPL_LEX_H

#ifndef ML_STDIO_H
#define ML_STDIO_H
#include <stdio.h>
#endif

#ifndef ML_UTILS_H
#include "utils.h"
#endif

#ifndef ML_ML_LEXER_H
#include "mllexgen.h"
#endif

#ifndef ML_FA_H
#include "fa.h"
#endif

typedef struct {
    FILE *f;
    lexer_lexer_state *st;
    fa_t *dfa;
    fa_list_t *patterns;
    fa_list_t *start_states;
} tmpl_state;


typedef struct yy_Template_state Template_state;

Template_state * TemplateInit( void * (*alloc)(size_t),
    void (*unalloc)(void *) );
void TemplateDestroy( Template_state *lexer );
int TemplateRead( Template_state *lexer, char *input, size_t len ,  tmpl_state *  data );

#endif
