#ifndef YYML_Template_HEADER
#define YYML_Template_HEADER


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

extern tmpl_state *tstate;



void * TemplateInit( void * (*alloc)(size_t), void (*unalloc)(void *) );
void TemplateDestroy( void *lexer );
int TemplateRead( void *lexer, char *input, size_t len );

#endif
