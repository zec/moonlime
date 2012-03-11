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

void init_lexer_lexer_state(lexer_lexer_state *st)
{
    if(st == NULL)
        return;

    st->dir = D_NONE;
    st->code = st->header = st->top = st->initstate = st->prefix = NULL;
    st->curr_rx = st->rx_stack = NULL;
    st->phead = st->ptail = NULL;
    st->states = st->curr_st = NULL;
    st->regex_nest_depth = st->c_nest_depth = 0;
    st->npats = 0;
    st->verb = NULL;
}

lexer_lexer_state *file_state;

static void add_simple_regex_impl(lexer_lexer_state *st, regex_t *rx,
                                  const char *fname, int line)
{
    regex_t *new_rx;

    if(st == NULL || rx == NULL) {
        fprintf(stderr, "%s:%d: NULL argument to add_simple_regex\n",
                fname, line);
        exit(1);
    }

    if(st->curr_rx == NULL) {
        st->curr_rx = rx;
        return;
    }

    if(st->rx_stack == NULL) {
        new_rx = mk_concat_rx(0);
        add_enc_rx_impl(new_rx, st->curr_rx, fname, line);
        st->rx_stack = new_rx;
        st->curr_rx = rx;
        return;
    }

    switch(st->rx_stack->type) {
      case R_CONCAT:
        add_enc_rx_impl(st->rx_stack, st->curr_rx, fname, line);
        break;

      case R_OPTION:
      case R_PAREN:
        new_rx = mk_concat_rx(0);
        add_enc_rx_impl(new_rx, st->curr_rx, fname, line);
        new_rx->next = st->rx_stack;
        st->rx_stack = new_rx;
        break;

      default:
        fprintf(stderr, "%s:%d: Bad type %d on the regex stack\n",
                fname, line, st->rx_stack->type);
        exit(1);
    }

    st->curr_rx = rx;
}

#define add_simple_regex(st, rx) add_simple_regex_impl((st), (rx), \
    __FILE__, __LINE__)

static char unescape_rx_escape(const char *buf)
{
    char c;

    switch(buf[1]) {
      case 'x':
        c = (hex_digits[0xff & buf[2]] << 4) | hex_digits[0xff & buf[3]];
        break;
      case 'n':
        c = '\n';
        break;
      case 't':
        c = '\t';
        break;
      default:
        c = buf[1];
    }

    return c;
}

/* Prepends the text denoted by yytext and yylen to the list starting at lst
 * if it's not already listed; returns the start of the new version of the
 * list. */
static lstr_list_t * add_to_list_impl(const char *yytext, size_t yylen,
                                      lstr_list_t *lst, const char *fname,
                                      int line_num)
{
    len_string *s = lstring_dupbuf(yylen, yytext);
    lstr_list_t *p = lst;

    while(p != NULL) {
        if(lstr_eq(s, p->s)) {
            free(s);
            return lst;
        }
        p = p->next;
    }

    p = mod_2(1, lstr_list_t, fname, line_num);

    p->s = s;
    p->next = lst;
    return p;
}

#define add_to_list(yytext, yylen, lst) \
    add_to_list_impl((yytext), (yylen), (lst), __FILE__, __LINE__)

#ifdef LEXER_DBG
static const char * directive_name(directive_kind dir)
{
    switch(dir) {
      case D_NONE:
        return "[NONE]";
      case D_TOP:
        return "%top";
      case D_HEADER:
        return "%header";
      case D_STATE:
        return "%state";
      case D_INITSTATE:
        return "%initstate";
      case D_PREFIX:
        return "%prefix";
    }

    return NULL;
}
#endif

#define vfprintf if(file_state->verb) fprintf
#define vfputs(s) if(file_state->verb) fputs((s), file_state->verb)
#define LEN ((int) yylen)


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

typedef struct yy_Moonlime_state {
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

typedef struct yy_Moonlime_state Moonlime_state;

static yyml_fa yy_x[] = {

 {0, 0, 1},
 {25, 1, 1},
 {0, 1, 3},
 {26, 3, 3},
 {24, 3, 4},
 {0, 4, 6},
 {20, 6, 6},
 {0, 6, 13},
 {23, 13, 13},
 {23, 13, 13},
 {0, 13, 16},
 {0, 16, 17},
 {0, 17, 20},
 {0, 20, 21},
 {23, 21, 23},
 {0, 23, 25},
 {0, 25, 28},
 {0, 28, 30},
 {0, 30, 32},
 {21, 32, 32},
 {22, 32, 32},
 {0, 32, 36},
 {10, 36, 36},
 {10, 36, 36},
 {0, 36, 38},
 {9, 38, 38},
 {0, 38, 39},
 {0, 39, 40},
 {11, 40, 40},
 {0, 40, 51},
 {27, 51, 51},
 {26, 51, 51},
 {12, 51, 51},
 {13, 51, 51},
 {16, 51, 51},
 {7, 51, 51},
 {27, 51, 53},
 {0, 53, 55},
 {0, 55, 58},
 {0, 58, 60},
 {1, 60, 60},
 {0, 60, 62},
 {8, 62, 63},
 {8, 63, 63},
 {0, 63, 65},
 {14, 65, 65},
 {0, 65, 66},
 {0, 66, 67},
 {19, 67, 69},
 {0, 69, 70},
 {0, 70, 72},
 {18, 72, 72},
 {0, 72, 75},
 {0, 75, 77},
 {17, 77, 77},
 {15, 77, 77},
 {0, 77, 81},
 {4, 81, 82},
 {4, 82, 83},
 {5, 83, 83},
 {6, 83, 83},
 {0, 83, 93},
 {27, 93, 94},
 {2, 94, 95},
 {3, 95, 95}

};

static yyml_trans yy_y[] = {

 { {0,6,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 1 },
 { {0,0,0,0,0,0,0,0,254,255,255,135,254,255,255,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 4 },
 { {0,6,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 3 },
 { {0,0,0,0,0,0,255,3,254,255,255,135,254,255,255,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 4 },
 { {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 6 },
 { {0,6,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 3 },
 { {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 20 },
 { {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 19 },
 { {0,0,0,0,0,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 14 },
 { {0,0,0,0,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 12 },
 { {0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 10 },
 { {0,6,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 9 },
 { {255,249,255,255,122,127,255,255,255,255,255,255,255,255,255,215,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 8 },
 { {0,0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 11 },
 { {0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 8 },
 { {255,255,255,255,251,255,255,255,255,255,255,239,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 10 },
 { {255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 10 },
 { {0,0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 13 },
 { {0,0,0,0,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 8 },
 { {255,255,255,255,127,255,255,255,255,255,255,239,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 12 },
 { {255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 12 },
 { {0,0,0,0,0,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 18 },
 { {0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 15 },
 { {0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 16 },
 { {255,255,255,255,255,251,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 15 },
 { {0,0,0,0,0,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 8 },
 { {0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 17 },
 { {255,255,255,255,255,123,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 15 },
 { {0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 17 },
 { {255,255,255,255,255,123,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 15 },
 { {0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 8 },
 { {255,251,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 18 },
 { {0,0,0,0,0,0,0,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 28 },
 { {0,0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 24 },
 { {0,6,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 23 },
 { {255,249,255,255,254,255,255,255,255,255,255,207,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 22 },
 { {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 26 },
 { {255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,254,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 25 },
 { {0,0,0,0,0,0,255,3,126,0,0,0,126,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 27 },
 { {0,0,0,0,0,0,255,3,126,0,0,0,126,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 25 },
 { {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 55 },
 { {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 48 },
 { {0,0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 44 },
 { {0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 42 },
 { {0,0,0,0,0,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 36 },
 { {0,0,0,0,0,64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 35 },
 { {0,0,0,0,0,12,0,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 34 },
 { {0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 33 },
 { {0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 32 },
 { {0,6,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 31 },
 { {255,249,255,255,254,48,255,111,255,255,255,199,255,255,255,231,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 30 },
 { {0,0,0,0,0,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 41 },
 { {0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 37 },
 { {0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 38 },
 { {255,255,255,255,255,251,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 37 },
 { {0,0,0,0,0,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 40 },
 { {0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 39 },
 { {255,255,255,255,255,123,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 37 },
 { {0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 39 },
 { {255,255,255,255,255,123,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 37 },
 { {0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 40 },
 { {255,251,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 41 },
 { {0,0,0,0,0,0,0,0,0,0,0,64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 43 },
 { {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 46 },
 { {255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,254,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 45 },
 { {0,0,0,0,0,0,255,3,126,0,0,0,126,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 47 },
 { {0,0,0,0,0,0,255,3,126,0,0,0,126,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 45 },
 { {0,0,0,0,0,0,255,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 52 },
 { {0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 49 },
 { {0,0,0,0,0,0,255,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 50 },
 { {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 51 },
 { {0,0,0,0,0,0,255,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 50 },
 { {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 54 },
 { {0,0,0,0,0,0,255,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 52 },
 { {0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 53 },
 { {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 54 },
 { {0,0,0,0,0,0,255,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 50 },
 { {0,0,0,0,0,0,0,64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 60 },
 { {0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 59 },
 { {0,6,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 58 },
 { {255,249,255,255,254,239,255,191,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 57 },
 { {255,255,255,255,255,239,255,191,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 57 },
 { {255,255,255,255,255,239,255,191,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 57 },
 { {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 55 },
 { {0,0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 44 },
 { {0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 42 },
 { {0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 64 },
 { {0,0,0,0,0,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 36 },
 { {0,0,0,0,0,64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 35 },
 { {0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 32 },
 { {0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 62 },
 { {0,6,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 31 },
 { {255,249,255,255,222,48,255,111,255,255,255,199,255,255,255,231,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255}, 30 },
 { {0,0,0,0,0,0,0,0,0,0,0,0,254,255,255,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 63 },
 { {0,0,0,0,0,0,0,0,0,0,0,0,254,255,255,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, 63 }

};

static int yy_init_states[] = {

 0,
 2,
 5,
 7,
 21,
 29,
 56,
 61

};

#define YY_STATE_NON_WHSP_IS_ERROR 0
#define YY_STATE_PRE_C_TOKEN 1
#define YY_STATE_PRE_C_CODE 2
#define YY_STATE_C_CODE 3
#define YY_STATE_IN_CHARCLASS 4
#define YY_STATE_IN_REGEX 5
#define YY_STATE_IN_SELECTOR 6
#define YY_STATE_MAIN 7
#define YY_MAXSTATE 7
#define YY_INITSTATE YY_STATE_MAIN


Moonlime_state * MoonlimeInit( void * (*alloc)(size_t),
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

void MoonlimeDestroy( Moonlime_state *lexer )
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

int MoonlimeRead( Moonlime_state *lexer, char *input, size_t len )
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
 ; 
} break;
case 2: {

    if(yylen == 4 && !strncmp(yytext, "%top", yylen)) {
        file_state->dir = D_TOP;
        YYSTART(PRE_C_CODE);

    } else if(yylen == 7 && !strncmp(yytext, "%header", yylen)) {
        file_state->dir = D_HEADER;
        YYSTART(PRE_C_CODE);

    } else if(yylen == 6 && !strncmp(yytext, "%state", yylen)) {
        file_state->dir = D_STATE;
        YYSTART(PRE_C_TOKEN);

    } else if(yylen == 10 && !strncmp(yytext, "%initstate", yylen)) {
        file_state->dir = D_INITSTATE;
        YYSTART(PRE_C_TOKEN);

    } else if(yylen == 7 && !strncmp(yytext, "%prefix", yylen)) {
        file_state->dir = D_PREFIX;
        YYSTART(PRE_C_TOKEN);

    } else {
        fprintf(stderr, "Unknown directive!\n");
        exit(1);
    }

} break;
case 3: {
 YYSTART(IN_SELECTOR); 
} break;
case 4: {

    int i, still_valid = 1;

    /* These ifs are only guaranteed to work reliably
     * on ASCII-like character encodings */
    if((yytext[0] < 'a' || yytext[0] > 'z') &&
       (yytext[0] < 'A' || yytext[0] > 'Z') &&
       (yytext[0] != '_'))
        still_valid = 0;
        
    for(i = 1; i < yylen && still_valid; i++) {
        if((yytext[i] < 'a' || yytext[i] > 'z') &&
           (yytext[i] < 'A' || yytext[i] > 'Z') &&
           (yytext[i] < '0' || yytext[i] > '9') &&
           (yytext[i] != '_'))
            still_valid = 0;
    }

    if(!still_valid) {
        fprintf(stderr, "Invalid start-state selector: %.*s\n", LEN, yytext);
        exit(1);
    }

    file_state->curr_st = add_to_list(yytext, yylen, file_state->curr_st);

#ifdef LEXER_DBG
    vfprintf(file_state->verb, "Start-state selector \"%.*s\"\n", LEN, yytext);
#endif

} break;
case 5: {
 ; 
} break;
case 6: {
 YYSTART(IN_REGEX); 
} break;
case 7: {

#ifdef LEXER_DBG
    vfputs("Any\n");
#endif
    add_simple_regex(file_state, mk_any_rx());
    YYSTART(IN_REGEX);

} break;
case 8: {

#ifdef LEXER_DBG
    vfprintf(file_state->verb, "Character class%s:\n",
             (yylen > 1) ? " (inverted)" : "");
#endif
    add_simple_regex(file_state, mk_char_class_rx(yylen > 1));
    YYSTART(IN_CHARCLASS);

} break;
case 9: {

#ifdef LEXER_DBG
    vfprintf(file_state->verb,
             yytext[1] != 'x' ? " \'\\%c\'\n" : " \'\\%c%c%c\'\n",
             yytext[1], yytext[2], yytext[3]);
#endif
    add_to_char_class(file_state->curr_rx, unescape_rx_escape(yytext));

} break;
case 10: {

#ifdef LEXER_DBG
    vfprintf(file_state->verb, " \'%c\'\n", yytext[0]);
#endif
    add_to_char_class(file_state->curr_rx, yytext[0]);

} break;
case 11: {

#ifdef LEXER_DBG
    vfprintf(file_state->verb, "End character class\n");
#endif
    YYSTART(IN_REGEX);

} break;
case 12: {

    regex_t *new_rx, *paren;
    ++file_state->regex_nest_depth;
#ifdef LEXER_DBG
    vfputs("(\n");
#endif
    if(file_state->curr_rx != NULL) {
        if(file_state->rx_stack == NULL) {
            new_rx = mk_concat_rx(0);
            add_enc_rx(new_rx, file_state->curr_rx);
            file_state->rx_stack = new_rx;
        } else switch(file_state->rx_stack->type) {
          case R_CONCAT:
          case R_OPTION:
            add_enc_rx(file_state->rx_stack, file_state->curr_rx);
            break;

          case R_PAREN:
            new_rx = mk_concat_rx(0);
            add_enc_rx(new_rx, file_state->curr_rx);
            new_rx->next = file_state->rx_stack;
            file_state->rx_stack = new_rx;
            break;

          default:
            fprintf(stderr, "Invalid stack state %d\n",
                    file_state->rx_stack->type);
            exit(1);
        }
    }

    paren = mk_paren_rx();
    paren->next = file_state->rx_stack;
    file_state->rx_stack = paren;
    file_state->curr_rx = NULL;
    YYSTART(IN_REGEX);

} break;
case 13: {

    regex_t *re, *top;
    if(--file_state->regex_nest_depth < 0) {
        fputs("Improper parentheses nesting!\n", stderr);
        exit(1);
    }

    re = file_state->curr_rx;
    top = file_state->rx_stack;
    if(top != NULL)
        file_state->rx_stack = top->next;

    while(top != NULL && top->type != R_PAREN) {
        if(re != NULL)
            add_enc_rx(top, re);
        else if(top->type == R_OPTION)
            add_enc_rx(top, mk_zero_rx());

        re = top;
        top = file_state->rx_stack;
        if(top != NULL)
            file_state->rx_stack = top->next;
    }

    if(top == NULL) {
        fputs("Close-paren without open-paren\n", stderr);
        exit(1);
    } else
        free_regex_tree(top);

    file_state->curr_rx = re;

} break;
case 14: {

#ifdef LEXER_DBG
    vfprintf(file_state->verb,
             (yytext[1] != 'x') ? "Char \'\\%c\'\n" : "Char \'\\%c%c%c\'\n",
             yytext[1], yytext[2], yytext[3]);
#endif

    add_simple_regex(file_state, mk_char_rx(unescape_rx_escape(yytext)));
    YYSTART(IN_REGEX);

} break;
case 15: {

    regex_t *re, *top, *next;
#ifdef LEXER_DBG
    printf("|\n");
#endif
    re = file_state->curr_rx;
    if(re == NULL)
        re = mk_zero_rx();

    top = file_state->rx_stack;
    if(top != NULL)
        file_state->rx_stack = top->next;

    if(top == NULL) {
        top = mk_option_rx();
        add_enc_rx(top, re);
    } else if(top->type == R_OPTION) {
        add_enc_rx(top, re);
    } else if(top->type == R_CONCAT) {
        if(re->type != R_ZERO) {
            add_enc_rx(top, re);
        } else
            free_regex_tree(re);

        next = file_state->rx_stack;
        if(next != NULL)
            file_state->rx_stack = next->next;

        if(next != NULL && next->type == R_OPTION) {
            add_enc_rx(next, top);
            top = next;
        } else {
            if(next != NULL) {
                file_state->rx_stack = next;
            }
            next = mk_option_rx();
            add_enc_rx(next, top);
            top = next;
        }
    } else { /* top->type == R_PAREN */
        if(top != NULL)
            file_state->rx_stack = top;
        top = mk_option_rx();
        add_enc_rx(top, re);
    }

    top->next = file_state->rx_stack;
    file_state->rx_stack = top;
    file_state->curr_rx = NULL;

    YYSTART(IN_REGEX);

} break;
case 16: {

#ifdef LEXER_DBG
    vfprintf(file_state->verb, "Repetition: %.*s\n", LEN, yytext);
#endif
    if(file_state->curr_rx == NULL) {
        fputs("Tried to apply repetition to empty regex\n", stderr);
        exit(1);
    }
    switch(yytext[0]) {
      case '?':
        file_state->curr_rx = mk_maybe_rx(file_state->curr_rx);
        break;
      case '*':
        file_state->curr_rx = mk_star_rx(file_state->curr_rx);
        break;
      case '+':
        file_state->curr_rx = mk_plus_rx(file_state->curr_rx);
    }

} break;
case 17: {

    int n;

#ifdef LEXER_DBG
    vfputs("rep1\n");
#endif
    if(file_state->curr_rx == NULL) {
        fputs("Tried to apply repetition to empty regex\n", stderr);
        exit(1);
    }

    n = (int) strtol(yytext+1, NULL, 10);

    if(yytext[yylen-2] != ',')
        file_state->curr_rx = mk_num_rx(file_state->curr_rx, n, n);
    else
        file_state->curr_rx = mk_num_rx(file_state->curr_rx, n, -1);

} break;
case 18: {

    int n, m;
    char *ptr = (char *)(yytext+1);

#ifdef LEXER_DBG
    vfputs("rep2\n");
#endif
    if(file_state->curr_rx == NULL) {
        fputs("Tried to apply repetition to empty regex\n", stderr);
        exit(1);
    }

    if(yytext[1] == ',') {
        n = -1;
    } else
        n = (int) strtol(ptr, &ptr, 10);

    m = (int) strtol(ptr+1, NULL, 10);

    file_state->curr_rx = mk_num_rx(file_state->curr_rx, n, m);

} break;
case 19: {

    regex_t *re, *next;
#ifdef LEXER_DBG
    vfputs("Start action code\n");
#endif
    if(file_state->regex_nest_depth > 0) {
        fputs("Code improperly contained inside parentheses!\n", stderr);
        exit(1);
    }

    if(file_state->curr_rx == NULL && file_state->rx_stack == NULL) {
        fputs("A code action without a regex!\n", stderr);
        exit(1);
    }

    if(file_state->curr_rx != NULL) {
        re = file_state->curr_rx;
        next = file_state->rx_stack;
        if(next != NULL)
            file_state->rx_stack = next->next;
    } else {
        re = file_state->rx_stack;
        if(re->type == R_OPTION)
            add_enc_rx(re, mk_zero_rx());
        next = re->next;
        if(next != NULL)
            file_state->rx_stack = next->next;
        else
            file_state->rx_stack = NULL;
    }

    while(next != NULL) {
        if(re->type == R_PAREN || next->type == R_PAREN) {
            fputs("A code action inside a paren sub-regex!\n", stderr);
            exit(1);
        }

        add_enc_rx(next, re);
        re = next;
        next = file_state->rx_stack;
        if(next != NULL)
            file_state->rx_stack = next->next;
    }

    file_state->curr_rx = re;

    file_state->dir = D_NONE;
    file_state->c_nest_depth = 1;
    YYSTART(C_CODE);

} break;
case 20: {

    file_state->c_nest_depth = 1;

    if(file_state->code != NULL)
        free(file_state->code);
    file_state->code = mk_blank_lstring(0);

    YYSTART(C_CODE);

} break;
case 21: {

    len_string *x;

    ++file_state->c_nest_depth;
    x = lstrcat_s(file_state->code, "{");
    free(file_state->code);
    file_state->code = x;

} break;
case 22: {

    len_string *x;
    pat_entry_t *ent;

    if(--file_state->c_nest_depth == 0) {
        switch(file_state->dir) {
          case D_NONE:
            vfprintf(file_state->verb, "Pattern:\n");
            if(file_state->verb != NULL)
                print_regex_tree(file_state->verb, file_state->curr_rx);
            vfputs("Code associated with pattern: {\n");
            if(file_state->verb != NULL)
                lstr_fwrite(file_state->code, file_state->verb);
            vfputs("\n}\n");

            ent = malloc_or_die(1, pat_entry_t);

            ent->rx = file_state->curr_rx;
            ent->code = file_state->code;
            ent->states = file_state->curr_st;
            ent->next = NULL;

            if(file_state->phead == NULL) {
                file_state->phead = file_state->ptail = ent;
            } else {
                file_state->ptail->next = ent;
                file_state->ptail = ent;
            }

            ++file_state->npats;

            file_state->curr_rx = NULL;
            file_state->curr_st = NULL;

            break;

          case D_HEADER:
            vfputs("Header: {\n");
            if(file_state->verb != NULL)
                lstr_fwrite(file_state->code, file_state->verb);
            vfputs("\n}\n");

            if(file_state->header != NULL)
                free(file_state->header);
            file_state->header = file_state->code;
            break;

          case D_TOP:
            vfputs("Top: {\n");
            if(file_state->verb != NULL)
                lstr_fwrite(file_state->code, file_state->verb);
            vfputs("\n}\n");

            if(file_state->top != NULL)
                free(file_state->top);
            file_state->top = file_state->code;
            break;

          default:
            fprintf(stderr, __FILE__ ":%d: invalid directive with code\n",
                    __LINE__);
            exit(1);
        }

        file_state->dir = D_NONE;
        file_state->code = NULL;
        YYSTART(MAIN);
    } else {
        x = lstrcat_s(file_state->code, "}");
        free(file_state->code);
        file_state->code = x;
    }

} break;
case 23: {

    len_string *x = lstrcat_buf(file_state->code, yylen, yytext);
    free(file_state->code);
    file_state->code = x;

} break;
case 24: {

#ifdef LEXER_DBG
    vfprintf(file_state->verb, "Directive \'%s\': %.*s\n",
             directive_name(file_state->dir), LEN, yytext);
#endif

    switch(file_state->dir) {
      case D_STATE:
        vfprintf(file_state->verb, "%%state directive: %.*s\n", LEN, yytext);

        file_state->states = add_to_list(yytext, yylen, file_state->states);

        if(file_state->initstate == NULL)
            file_state->initstate = lstring_dupbuf(yylen, yytext);

        break;

      case D_INITSTATE:
        if(file_state->initstate != NULL)
            free(file_state->initstate);
        file_state->initstate = lstring_dupbuf(yylen, yytext);
        file_state->states = add_to_list(yytext, yylen, file_state->states);
        break;

      case D_PREFIX:
        if(file_state->prefix != NULL)
            free(file_state->prefix);
        file_state->prefix = lstring_dupbuf(yylen, yytext);
        break;

      default:
        fprintf(stderr, __FILE__ ":%d: Given invalid directive!\n", __LINE__);
        exit(1);
    }

    file_state->dir = D_NONE;
    YYSTART(NON_WHSP_IS_ERROR);

} break;
case 25: {
 YYSTART(MAIN); 
} break;
case 26: {
 ; 
} break;
case 27: {

#ifdef LEXER_DBG
    vfprintf(file_state->verb, "Char \'%c\'\n", yytext[0]);
#endif
    add_simple_regex(file_state, mk_char_rx(yytext[0]));
    YYSTART(IN_REGEX);

} break;

    }

    if((*yy_start_state < 0) || (*yy_start_state > YY_MAXSTATE))
        *yy_start_state = YY_INITSTATE;
}
