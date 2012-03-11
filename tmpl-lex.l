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
}

%userdata { tmpl_state * }

%prefix Template

[%]HEADER[%] {
    if(yydata->st->header != NULL)
        fprintf(yydata->f, "%.*s", (int) yydata->st->header->len,
                yydata->st->header->s);
}

[%]TOP[%] {
    if(yydata->st->top != NULL)
        fprintf(yydata->f, "%.*s", (int) yydata->st->top->len,
                yydata->st->top->s);
}

[%]PREFIX[%] {
    if(yydata->st->prefix != NULL)
        fprintf(yydata->f, "%.*s", (int) yydata->st->prefix->len,
                yydata->st->prefix->s);
    else
        fputs("Lexer", yydata->f);
}

[%]FASTATES[%] {
    state_t *s;
    trans_t *t;
    int i = 0;
    int is_first = 1;

    for(s = yydata->dfa->first; s != NULL; s = s->next) {
        fprintf(yydata->f, "%s\n {%d, %d, ", is_first ? "" : ",",
                s->done_num, i);
        is_first = 0;
        for(t = s->trans; t != NULL; t = t->next)
            ++i;
        fprintf(yydata->f, "%d}", i);
    }
    fputs("\n", yydata->f);
}

[%]FATRANS[%] {
    state_t *s;
    trans_t *t;
    int is_first = 1, i, j, val;

    for(s = yydata->dfa->first; s != NULL; s = s->next) {
        for(t = s->trans; t != NULL; t = t->next) {
            fprintf(yydata->f, "%s\n { {", is_first ? "" : ",");
            is_first = 0;
            for(i = 0; i < 256; i += 8) {
                val = 0;
                for(j = 0; j < 8; ++j) {
                    if(t->cond[(i+j)/ML_UINT_BIT] &
                       (1 << ((i+j)%ML_UINT_BIT)))
                    val |= 1 << j;
                }
                fprintf(yydata->f, "%d%s", val, (i < 248) ? "," : "");
            }
            fprintf(yydata->f, "}, %d }", t->dest->id);
        }
    }

    fputs("\n", yydata->f);
}

[%]FASTARTS[%] {
    fa_list_t *l;

    for(l = yydata->start_states; l != NULL; l = l->next)
        fprintf(yydata->f, "%s\n %d", (l == yydata->start_states) ? "" : ",",
                l->state->id);

    fputs("\n", yydata->f);
}

[%]START_STATE_DEFS[%] {
    fa_list_t *l;
    int i = 0;

    for(l = yydata->start_states; l != NULL; l = l->next)
        fprintf(yydata->f, "#define YY_STATE_%.*s %d\n",
                (int) ((len_string *) l->data1)->len,
                ((len_string *) l->data1)->s, i++);

    fprintf(yydata->f, "#define YY_MAXSTATE %d\n", i-1);
    fprintf(yydata->f, "#define YY_INITSTATE YY_STATE_%.*s\n",
            (int) yydata->st->initstate->len, yydata->st->initstate->s);
}

[%]ACTIONS[%] {
    fa_list_t *l;
    len_string *code;

    for(l = yydata->patterns; l != NULL; l = l->next) {
        code = (len_string *) l->data3;
        fprintf(yydata->f, "case %d: {\n%.*s\n} break;\n", l->done_num,
                (int) code->len, code->s);
    }
}

[%]UPARAM[%] {
    len_string *p = yydata->st->ustate_type;
    if(p != NULL)
        fprintf(yydata->f, ", %.*s data", (int) p->len, p->s);
}

[%]UDATA[%] {
    if(yydata->st->ustate_type != NULL)
        fputs(", data", yydata->f);
}

[%]YYUPARAM[%] {
    len_string *p = yydata->st->ustate_type;
    if(p != NULL)
        fprintf(yydata->f, ", %.*s yydata", (int) p->len, p->s);
}

.|\n {
    fputc(yytext[0], yydata->f);
}
