%header {
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
#include "ml-lexer.h"
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
}

%top {
tmpl_state *tstate = NULL;
}

%prefix Template

[%]HEADER[%] {
    fprintf(tstate->f, "%.*s", (int) tstate->st->header->len,
            tstate->st->header->s);
}

[%]TOP[%] {
    fprintf(tstate->f, "%.*s", (int) tstate->st->top->len, tstate->st->top->s);
}

[%]PREFIX[%] {
    fprintf(tstate->f, "%.*s", (int) tstate->st->prefix->len,
            tstate->st->prefix->s);
}

[%]FASTATES[%] {
    state_t *s;
    trans_t *t;
    int i = 0;
    int is_first = 1;

    for(s = tstate->dfa->first; s != NULL; s = s->next) {
        fprintf(tstate->f, "%s\n {%d, %d, ", is_first ? "" : ",",
                s->done_num, i);
        is_first = 0;
        for(t = s->trans; t != NULL; t = t->next)
            ++i;
        fprintf(tstate->f, "%d}", i);
    }
    fputs("\n", tstate->f);
}

[%]FATRANS[%] {
    state_t *s;
    trans_t *t;
    int is_first = 1, i, j, val;

    for(s = tstate->dfa->first; s != NULL; s = s->next) {
        for(t = s->trans; t != NULL; t = t->next) {
            fprintf(tstate->f, "%s\n { {", is_first ? "" : ",");
            is_first = 0;
            for(i = 0; i < 256; i += 8) {
                val = 0;
                for(j = 0; j < 8; ++j) {
                    if(t->cond[(i*8+j)/ML_UINT_BIT] &
                       (1 << ((i*8+j)%ML_UINT_BIT)))
                    val |= 1 << j;
                }
                fprintf(tstate->f, "%d%s", val, (i < 248) ? "," : "");
            }
            fprintf(tstate->f, "}, %d }", t->dest->id);
        }
    }

    fputs("\n", tstate->f);
}

[%]FASTARTS[%] {
    fa_list_t *l;

    for(l = tstate->start_states; l != NULL; l = l->next)
        fprintf(tstate->f, "%s\n %d", (l == tstate->start_states) ? "" : ",",
                l->state->id);

    fputs("\n", tstate->f);
}

[%]START_STATE_DEFS[%] {
    fa_list_t *l;
    int i = 0;

    for(l = tstate->start_states; l != NULL; l = l->next)
        fprintf(tstate->f, "#define YY_STATE_%.*s %d\n",
                (int) ((len_string *) l->data1)->len,
                ((len_string *) l->data1)->s, i++);

    fprintf(tstate->f, "#define YY_INITSTATE YY_STATE_%.*s\n",
            (int) tstate->st->initstate->len, tstate->st->initstate->s);
}

[%]ACTIONS[%] {
    fa_list_t *l;
    len_string *code;

    for(l = tstate->patterns; l != NULL; l = l->next) {
        code = (len_string *) l->data3;
        fprintf(tstate->f, "case %d: {\n%.*s\n}\n", l->done_num,
                (int) code->len, code->s);
    }
}

. {
    fputc(yytext[0], tstate->f);
}
