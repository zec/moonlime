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

extern tmpl_state *tstate;



tmpl_state *tstate = NULL;


#include <stdlib.h>

typedef struct {
  int done_num;
  int trans_start;
  int trans_end;
} yyml_fa;

typedef struct {
  unsigned char transset[32];
  int dest_state;
} yyml_trans;

typedef struct yy_Template_state {
  int is_in_error;
  int curr_state; /* state of the DFA */
  int curr_start_state; /* which DFA to use... */
  int last_done_num;
  int last_done_len;
  size_t string_len;
  size_t curr_buf_size;
  void * (*alloc)(size_t);
  void (*unalloc)(void *);
  char *buf;
  char start_buf[64];
} yyml_state;

typedef struct yy_Template_state Template_state;

static yyml_fa yy_x[] = {

 {0, 0, 2},
 {9, 2, 2},
 {9, 2, 8},
 {0, 8, 9},
 {0, 9, 10},
 {0, 10, 11},
 {0, 11, 12},
 {0, 12, 13},
 {0, 13, 14},
 {0, 14, 15},
 {8, 15, 15},
 {0, 15, 16},
 {0, 16, 18},
 {0, 18, 19},
 {0, 19, 20},
 {0, 20, 22},
 {0, 22, 23},
 {0, 23, 24},
 {0, 24, 25},
 {6, 25, 25},
 {0, 25, 26},
 {0, 26, 27},
 {0, 27, 28},
 {4, 28, 28},
 {0, 28, 29},
 {0, 29, 30},
 {0, 30, 31},
 {0, 31, 32},
 {0, 32, 33},
 {5, 33, 33},
 {0, 33, 34},
 {0, 34, 35},
 {0, 35, 36},
 {0, 36, 37},
 {0, 37, 38},
 {0, 38, 39},
 {1, 39, 39},
 {0, 39, 40},
 {0, 40, 41},
 {0, 41, 42},
 {0, 42, 43},
 {0, 43, 44},
 {0, 44, 45},
 {3, 45, 45},
 {0, 45, 46},
 {0, 46, 47},
 {0, 47, 48},
 {0, 48, 49},
 {0, 49, 50},
 {0, 50, 51},
 {0, 51, 52},
 {0, 52, 53},
 {0, 53, 54},
 {0, 54, 55},
 {0, 55, 56},
 {0, 56, 57},
 {0, 57, 58},
 {0, 58, 59},
 {0, 59, 60},
 {0, 60, 61},
 {7, 61, 61},
 {0, 61, 62},
 {0, 62, 63},
 {0, 63, 64},
 {2, 64, 64}

};

static yyml_trans yy_y[] = {

 { {0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 2 },
 { {255,255,255,255,223,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 1 },
 { {0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 61 },
 { {0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 44 },
 { {0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 37 },
 { {0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 30 },
 { {0,0,0,0,0,0,0,0,64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 11 },
 { {0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 3 },
 { {0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 4 },
 { {0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 5 },
 { {0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 6 },
 { {0,0,0,0,0,0,0,0,0,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 7 },
 { {0,0,0,0,0,0,0,0,0,64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 8 },
 { {0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 9 },
 { {0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 10 },
 { {0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 12 },
 { {0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 24 },
 { {0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 13 },
 { {0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 14 },
 { {0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 15 },
 { {0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 20 },
 { {0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 16 },
 { {0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 17 },
 { {0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 18 },
 { {0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 19 },
 { {0,0,0,0,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 21 },
 { {0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 22 },
 { {0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 23 },
 { {0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 25 },
 { {0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 26 },
 { {0,0,0,0,0,0,0,0,0,64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 27 },
 { {0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 28 },
 { {0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 29 },
 { {0,0,0,0,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 31 },
 { {0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 32 },
 { {0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 33 },
 { {0,0,0,0,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 34 },
 { {0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 35 },
 { {0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 36 },
 { {0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 38 },
 { {0,0,0,0,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 39 },
 { {0,0,0,0,0,0,0,0,64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 40 },
 { {0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 41 },
 { {0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 42 },
 { {0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 43 },
 { {0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 45 },
 { {0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 46 },
 { {0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 47 },
 { {0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 48 },
 { {0,0,0,0,0,0,0,0,0,0,0,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 49 },
 { {0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 50 },
 { {0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 51 },
 { {0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 52 },
 { {0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 53 },
 { {0,0,0,0,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 54 },
 { {0,0,0,0,0,0,0,0,0,0,0,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 55 },
 { {0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 56 },
 { {0,0,0,0,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 57 },
 { {0,0,0,0,0,0,0,0,64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 58 },
 { {0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 59 },
 { {0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 60 },
 { {0,0,0,0,0,0,0,0,0,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 62 },
 { {0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 63 },
 { {0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 64 }

};

static int yy_init_states[] = {

 0

};

#define YY_STATE_A 0
#define YY_MAXSTATE 0
#define YY_INITSTATE YY_STATE_A


Template_state * TemplateInit( void * (*alloc)(size_t),
    void (*unalloc)(void *) )
{
    yyml_state *ms;

    if(alloc == NULL || unalloc == NULL)
        return NULL;

    ms = alloc(sizeof(yyml_state));

    if(ms == NULL)
        return NULL;

    ms->is_in_error = 0;
    ms->curr_state = yy_init_states[YY_INITSTATE];
    ms->curr_start_state = YY_INITSTATE;
    ms->last_done_num = 0;
    ms->last_done_len = 0;

    ms->string_len = 0;
    ms->curr_buf_size = 64;
    ms->buf = ms->start_buf;

    ms->alloc = alloc;
    ms->unalloc = unalloc;

    return ms;
}

void TemplateDestroy( Template_state *lexer )
{
    yyml_state *ms = lexer;

    if(ms == NULL)
        return;

    if(ms->buf != NULL && ms->buf != ms->start_buf) {
        ms->unalloc(ms->buf);
    }

    ms->unalloc(ms);
}

static void yymoonlime_action(int done_num, const char *yytext, size_t yylen,
                              int *yy_start_state);

static int yyrun_char(yyml_state *ms, char c, int add_to_buf, int len)
{
    int curr_trans, end_trans, c_idx, c_mask, next_state, i;
    char *new_buf;

    curr_trans = yy_x[ms->curr_state].trans_start;
    end_trans = yy_x[ms->curr_state].trans_end;

    c_idx = ((unsigned char) c) >> 3;
    c_mask = 1 << (c & 7);

    if(add_to_buf) {
        if(ms->string_len >= ms->curr_buf_size - 1) {
                if((new_buf = ms->alloc(ms->curr_buf_size * 2)) == NULL) {
                    ms->is_in_error = 1;
                return 0;
            }
            for(i = 0; i < ms->string_len; ++i)
                new_buf[i] = ms->buf[i];
            ms->curr_buf_size *= 2;
            if(ms->buf != ms->start_buf)
                ms->unalloc(ms->buf);
            ms->buf = new_buf;
        }
        ms->buf[ms->string_len++] = c;
    }

    while(curr_trans < end_trans) {
        if(yy_y[curr_trans].transset[c_idx] & c_mask) {
            ms->curr_state = next_state = yy_y[curr_trans].dest_state;

            if(yy_x[next_state].done_num) {
                ms->last_done_num = yy_x[next_state].done_num;
                ms->last_done_len = len;
            }
            return 1;
        }
        ++curr_trans;
    }

    return 0;
}

static void yyreset_state(yyml_state *ms)
{
    int i;

    for(i = ms->last_done_len; i < ms->string_len; ++i)
        ms->buf[i - ms->last_done_len] = ms->buf[i];
    ms->string_len -= ms->last_done_len;
    ms->last_done_len = ms->last_done_num = 0;
    ms->curr_state = yy_init_states[ms->curr_start_state];
}

int TemplateRead( Template_state *lexer, char *input, size_t len )
{
    int done_relexing, i;
    char *end = input + len;
    yyml_state *ms = lexer;

    if(ms == NULL || ms->is_in_error)
        return 0;

    if(len == 0) { /* Signifies EOF */
        if(ms->string_len == 0)
            return 1;

        if(ms->last_done_num == 0) {
            ms->is_in_error = 1;
            return 0;
        }

        yymoonlime_action(ms->last_done_num, ms->buf, ms->last_done_len,
                          &(ms->curr_start_state));
        yyreset_state(ms);

        while(ms->string_len > 0) {
            for(i = 0; i < ms->string_len; ++i) {
                if(!yyrun_char(ms, ms->buf[i], 0, i+1) ||
                   i == ms->string_len - 1) {
                    if(ms->is_in_error || ms->last_done_num == 0) {
                        ms->is_in_error = 1;
                        return 0;
                    }

                    yymoonlime_action(ms->last_done_num, ms->buf,
                                      ms->last_done_len,
                                      &(ms->curr_start_state));
                    yyreset_state(ms);
                    break;
                }
            }
        }

        return 1;
    }

    while(input < end) {
        if(!yyrun_char(ms, *input, 1, ms->string_len + 1)) { /* past pattern */
            if(ms->is_in_error)
                return 0;
            if(ms->last_done_num == 0) { /* no pattern matches buf */
                ms->is_in_error = 1;
                return 0;
            }
            yymoonlime_action(ms->last_done_num, ms->buf, ms->last_done_len,
                              &(ms->curr_start_state));
            yyreset_state(ms);

            /* Re-lex remaining part of the buffer */
            done_relexing = 0;
            while(ms->string_len > 0 && !done_relexing) {
                i = 0;
                while(i < ms->string_len) {
                    if(!yyrun_char(ms, ms->buf[i], 0, i+1)) {
                        if(!ms->is_in_error && ms->last_done_num == 0)
                            ms->is_in_error = 1;
                        if(ms->is_in_error)
                            return 0;

                        yymoonlime_action(ms->last_done_num, ms->buf,
                                          ms->last_done_len,
                                          &(ms->curr_start_state));
                        yyreset_state(ms);
                        i = 0;
                        continue;
                    }
                    ++i;
                }

                if(i == ms->string_len)
                    done_relexing = 1;
            }
        }
        ++input;
    }

    return 1;
}

#define YYSTART(x) do { *yy_start_state = YY_STATE_ ## x ; } while(0)

static void yymoonlime_action(int done_num, const char *yytext, size_t yylen,
                              int *yy_start_state)
{
    switch(done_num) {
case 1: {

    if(tstate->st->header != NULL)
        fprintf(tstate->f, "%.*s", (int) tstate->st->header->len,
                tstate->st->header->s);

} break;
case 2: {

    if(tstate->st->top != NULL)
        fprintf(tstate->f, "%.*s", (int) tstate->st->top->len,
                tstate->st->top->s);

} break;
case 3: {

    if(tstate->st->prefix != NULL)
        fprintf(tstate->f, "%.*s", (int) tstate->st->prefix->len,
                tstate->st->prefix->s);
    else
        fputs("Lexer", tstate->f);

} break;
case 4: {

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

} break;
case 5: {

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
                    if(t->cond[(i+j)/ML_UINT_BIT] &
                       (1 << ((i+j)%ML_UINT_BIT)))
                    val |= 1 << j;
                }
                fprintf(tstate->f, "%d%s", val, (i < 248) ? "," : "");
            }
            fprintf(tstate->f, "}, %d }", t->dest->id);
        }
    }

    fputs("\n", tstate->f);

} break;
case 6: {

    fa_list_t *l;

    for(l = tstate->start_states; l != NULL; l = l->next)
        fprintf(tstate->f, "%s\n %d", (l == tstate->start_states) ? "" : ",",
                l->state->id);

    fputs("\n", tstate->f);

} break;
case 7: {

    fa_list_t *l;
    int i = 0;

    for(l = tstate->start_states; l != NULL; l = l->next)
        fprintf(tstate->f, "#define YY_STATE_%.*s %d\n",
                (int) ((len_string *) l->data1)->len,
                ((len_string *) l->data1)->s, i++);

    fprintf(tstate->f, "#define YY_MAXSTATE %d\n", i-1);
    fprintf(tstate->f, "#define YY_INITSTATE YY_STATE_%.*s\n",
            (int) tstate->st->initstate->len, tstate->st->initstate->s);

} break;
case 8: {

    fa_list_t *l;
    len_string *code;

    for(l = tstate->patterns; l != NULL; l = l->next) {
        code = (len_string *) l->data3;
        fprintf(tstate->f, "case %d: {\n%.*s\n} break;\n", l->done_num,
                (int) code->len, code->s);
    }

} break;
case 9: {

    fputc(yytext[0], tstate->f);

} break;

    }

    if((*yy_start_state < 0) || (*yy_start_state > YY_MAXSTATE))
        *yy_start_state = YY_INITSTATE;
}
