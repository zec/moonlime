/*
 * The syntax of Moonlime lexers, as expressed by a Moonlime lexer.
 *
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms.
 */

%prefix Moonlime

%userdata { lexer_lexer_state * }

%header {
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
    D_PREFIX,
    D_USTATE_TYPE
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
    len_string *ustate_type; /* The type of the (optional) user state object */
} lexer_lexer_state;

void init_lexer_lexer_state(lexer_lexer_state *st);
}

%top {
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
    st->ustate_type = NULL;
}

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
      case D_USTATE_TYPE:
        return "%userdata";
    }

    return NULL;
}
#endif

#define vfprintf if(yydata->verb) fprintf
#define vfputs(s) if(yydata->verb) fputs((s), yydata->verb)
#define LEN ((int) yylen)
}

%initstate MAIN

%state MAIN
%state IN_SELECTOR
%state IN_REGEX
%state IN_CHARCLASS
%state C_CODE
%state PRE_C_CODE
%state PRE_C_TOKEN
%state NON_WHSP_IS_ERROR

// Ignore C- and C++-style comments
<MAIN,IN_REGEX> ([/][*]([^*]|[*]+[^*/])*[*][/]) |
                ([/][/][^\n]*\n) { ; }

<MAIN> [%][abcdefghijklmnopqrstuvwxyz]+ {
    if(yylen == 4 && !strncmp(yytext, "%top", yylen)) {
        yydata->dir = D_TOP;
        YYSTART(PRE_C_CODE);

    } else if(yylen == 7 && !strncmp(yytext, "%header", yylen)) {
        yydata->dir = D_HEADER;
        YYSTART(PRE_C_CODE);

    } else if(yylen == 6 && !strncmp(yytext, "%state", yylen)) {
        yydata->dir = D_STATE;
        YYSTART(PRE_C_TOKEN);

    } else if(yylen == 10 && !strncmp(yytext, "%initstate", yylen)) {
        yydata->dir = D_INITSTATE;
        YYSTART(PRE_C_TOKEN);

    } else if(yylen == 7 && !strncmp(yytext, "%prefix", yylen)) {
        yydata->dir = D_PREFIX;
        YYSTART(PRE_C_TOKEN);

    } else if(yylen == 9 && !strncmp(yytext, "%userdata", yylen)) {
        yydata->dir = D_USTATE_TYPE;
        YYSTART(PRE_C_CODE);

    } else {
        fprintf(stderr, "Unknown directive %.*s!\n", (int) yylen, yytext);
        exit(1);
    }
}

// Start-state selector
<MAIN> [<] { YYSTART(IN_SELECTOR); }

// Start state
<IN_SELECTOR> [^,>]+ {
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

    yydata->curr_st = add_to_list(yytext, yylen, yydata->curr_st);

#ifdef LEXER_DBG
    vfprintf(yydata->verb, "Start-state selector \"%.*s\"\n", LEN, yytext);
#endif
}

// Start-state separator
<IN_SELECTOR> , { ; }

// End of selector
<IN_SELECTOR> [>] { YYSTART(IN_REGEX); }

// Any character
<MAIN,IN_REGEX> [.] {
#ifdef LEXER_DBG
    vfputs("Any\n");
#endif
    add_simple_regex(yydata, mk_any_rx());
    YYSTART(IN_REGEX);
}

// Character class
<MAIN,IN_REGEX> \[\^? {
#ifdef LEXER_DBG
    vfprintf(yydata->verb, "Character class%s:\n",
             (yylen > 1) ? " (inverted)" : "");
#endif
    add_simple_regex(yydata, mk_char_class_rx(yylen > 1));
    YYSTART(IN_CHARCLASS);
}

<IN_CHARCLASS> \\(x[0123456789abcdefABCDEF]{2}|[^x]) {
#ifdef LEXER_DBG
    vfprintf(yydata->verb,
             yytext[1] != 'x' ? " \'\\%c\'\n" : " \'\\%c%c%c\'\n",
             yytext[1], yytext[2], yytext[3]);
#endif
    add_to_char_class(yydata->curr_rx, unescape_rx_escape(yytext));
}

<IN_CHARCLASS> [^\\\]]|\n {
#ifdef LEXER_DBG
    vfprintf(yydata->verb, " \'%c\'\n", yytext[0]);
#endif
    add_to_char_class(yydata->curr_rx, yytext[0]);
}

<IN_CHARCLASS> \] {
#ifdef LEXER_DBG
    vfprintf(yydata->verb, "End character class\n");
#endif
    YYSTART(IN_REGEX);
}

// Parenthesis operators
<MAIN,IN_REGEX> [(] {
    regex_t *new_rx, *paren;
    ++yydata->regex_nest_depth;
#ifdef LEXER_DBG
    vfputs("(\n");
#endif
    if(yydata->curr_rx != NULL) {
        if(yydata->rx_stack == NULL) {
            new_rx = mk_concat_rx(0);
            add_enc_rx(new_rx, yydata->curr_rx);
            yydata->rx_stack = new_rx;
        } else switch(yydata->rx_stack->type) {
          case R_CONCAT:
          case R_OPTION:
            add_enc_rx(yydata->rx_stack, yydata->curr_rx);
            break;

          case R_PAREN:
            new_rx = mk_concat_rx(0);
            add_enc_rx(new_rx, yydata->curr_rx);
            new_rx->next = yydata->rx_stack;
            yydata->rx_stack = new_rx;
            break;

          default:
            fprintf(stderr, "Invalid stack state %d\n",
                    yydata->rx_stack->type);
            exit(1);
        }
    }

    paren = mk_paren_rx();
    paren->next = yydata->rx_stack;
    yydata->rx_stack = paren;
    yydata->curr_rx = NULL;
    YYSTART(IN_REGEX);
}

<IN_REGEX> [)] {
    regex_t *re, *top;
    if(--yydata->regex_nest_depth < 0) {
        fputs("Improper parentheses nesting!\n", stderr);
        exit(1);
    }

    re = yydata->curr_rx;
    top = yydata->rx_stack;
    if(top != NULL)
        yydata->rx_stack = top->next;

    while(top != NULL && top->type != R_PAREN) {
        if(re != NULL)
            add_enc_rx(top, re);
        else if(top->type == R_OPTION)
            add_enc_rx(top, mk_zero_rx());

        re = top;
        top = yydata->rx_stack;
        if(top != NULL)
            yydata->rx_stack = top->next;
    }

    if(top == NULL) {
        fputs("Close-paren without open-paren\n", stderr);
        exit(1);
    } else
        free_regex_tree(top);

    yydata->curr_rx = re;
}

// Character escape
<MAIN,IN_REGEX> \\(x[0123456789abcdefABCDEF]{2}|[^x]) {
#ifdef LEXER_DBG
    vfprintf(yydata->verb,
             (yytext[1] != 'x') ? "Char \'\\%c\'\n" : "Char \'\\%c%c%c\'\n",
             yytext[1], yytext[2], yytext[3]);
#endif

    add_simple_regex(yydata, mk_char_rx(unescape_rx_escape(yytext)));
    YYSTART(IN_REGEX);
}

// Option operator
<MAIN,IN_REGEX> [|] {
    regex_t *re, *top, *next;
#ifdef LEXER_DBG
    printf("|\n");
#endif
    re = yydata->curr_rx;
    if(re == NULL)
        re = mk_zero_rx();

    top = yydata->rx_stack;
    if(top != NULL)
        yydata->rx_stack = top->next;

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

        next = yydata->rx_stack;
        if(next != NULL)
            yydata->rx_stack = next->next;

        if(next != NULL && next->type == R_OPTION) {
            add_enc_rx(next, top);
            top = next;
        } else {
            if(next != NULL) {
                yydata->rx_stack = next;
            }
            next = mk_option_rx();
            add_enc_rx(next, top);
            top = next;
        }
    } else { /* top->type == R_PAREN */
        if(top != NULL)
            yydata->rx_stack = top;
        top = mk_option_rx();
        add_enc_rx(top, re);
    }

    top->next = yydata->rx_stack;
    yydata->rx_stack = top;
    yydata->curr_rx = NULL;

    YYSTART(IN_REGEX);
}

// Repetition operators
<IN_REGEX> [?*+] {
#ifdef LEXER_DBG
    vfprintf(yydata->verb, "Repetition: %.*s\n", LEN, yytext);
#endif
    if(yydata->curr_rx == NULL) {
        fputs("Tried to apply repetition to empty regex\n", stderr);
        exit(1);
    }
    switch(yytext[0]) {
      case '?':
        yydata->curr_rx = mk_maybe_rx(yydata->curr_rx);
        break;
      case '*':
        yydata->curr_rx = mk_star_rx(yydata->curr_rx);
        break;
      case '+':
        yydata->curr_rx = mk_plus_rx(yydata->curr_rx);
    }
}

<IN_REGEX> \{[0123456789]+,?\} {
    int n;

#ifdef LEXER_DBG
    vfputs("rep1\n");
#endif
    if(yydata->curr_rx == NULL) {
        fputs("Tried to apply repetition to empty regex\n", stderr);
        exit(1);
    }

    n = (int) strtol(yytext+1, NULL, 10);

    if(yytext[yylen-2] != ',')
        yydata->curr_rx = mk_num_rx(yydata->curr_rx, n, n);
    else
        yydata->curr_rx = mk_num_rx(yydata->curr_rx, n, -1);
}

<IN_REGEX> \{[0123456789]*,[0123456789]+\} {
    int n, m;
    char *ptr = (char *)(yytext+1);

#ifdef LEXER_DBG
    vfputs("rep2\n");
#endif
    if(yydata->curr_rx == NULL) {
        fputs("Tried to apply repetition to empty regex\n", stderr);
        exit(1);
    }

    if(yytext[1] == ',') {
        n = -1;
    } else
        n = (int) strtol(ptr, &ptr, 10);

    m = (int) strtol(ptr+1, NULL, 10);

    yydata->curr_rx = mk_num_rx(yydata->curr_rx, n, m);
}

// Code associated with a pattern
<IN_REGEX> [{] {
    regex_t *re, *next;
#ifdef LEXER_DBG
    vfputs("Start action code\n");
#endif
    if(yydata->regex_nest_depth > 0) {
        fputs("Code improperly contained inside parentheses!\n", stderr);
        exit(1);
    }

    if(yydata->curr_rx == NULL && yydata->rx_stack == NULL) {
        fputs("A code action without a regex!\n", stderr);
        exit(1);
    }

    if(yydata->curr_rx != NULL) {
        re = yydata->curr_rx;
        next = yydata->rx_stack;
        if(next != NULL)
            yydata->rx_stack = next->next;
    } else {
        re = yydata->rx_stack;
        if(re->type == R_OPTION)
            add_enc_rx(re, mk_zero_rx());
        next = re->next;
        if(next != NULL)
            yydata->rx_stack = next->next;
        else
            yydata->rx_stack = NULL;
    }

    while(next != NULL) {
        if(re->type == R_PAREN || next->type == R_PAREN) {
            fputs("A code action inside a paren sub-regex!\n", stderr);
            exit(1);
        }

        add_enc_rx(next, re);
        re = next;
        next = yydata->rx_stack;
        if(next != NULL)
            yydata->rx_stack = next->next;
    }

    yydata->curr_rx = re;

    yydata->dir = D_NONE;
    yydata->c_nest_depth = 1;
    YYSTART(C_CODE);
}

<PRE_C_CODE> [{] {
    yydata->c_nest_depth = 1;

    if(yydata->code != NULL)
        free(yydata->code);
    yydata->code = mk_blank_lstring(0);

    YYSTART(C_CODE);
}

<C_CODE> [{] {
    len_string *x;

    ++yydata->c_nest_depth;
    x = lstrcat_s(yydata->code, "{");
    free(yydata->code);
    yydata->code = x;
}

<C_CODE> [}] {
    len_string *x;
    pat_entry_t *ent;

    if(--yydata->c_nest_depth == 0) {
        switch(yydata->dir) {
          case D_NONE:
            vfprintf(yydata->verb, "Pattern:\n");
            if(yydata->verb != NULL)
                print_regex_tree(yydata->verb, yydata->curr_rx);
            vfputs("Code associated with pattern: {\n");
            if(yydata->verb != NULL)
                lstr_fwrite(yydata->code, yydata->verb);
            vfputs("\n}\n");

            ent = malloc_or_die(1, pat_entry_t);

            ent->rx = yydata->curr_rx;
            ent->code = yydata->code;
            ent->states = yydata->curr_st;
            ent->next = NULL;

            if(yydata->phead == NULL) {
                yydata->phead = yydata->ptail = ent;
            } else {
                yydata->ptail->next = ent;
                yydata->ptail = ent;
            }

            ++yydata->npats;

            yydata->curr_rx = NULL;
            yydata->curr_st = NULL;

            break;

          case D_HEADER:
            vfputs("Header: {\n");
            if(yydata->verb != NULL)
                lstr_fwrite(yydata->code, yydata->verb);
            vfputs("\n}\n");

            if(yydata->header != NULL)
                free(yydata->header);
            yydata->header = yydata->code;
            break;

          case D_TOP:
            vfputs("Top: {\n");
            if(yydata->verb != NULL)
                lstr_fwrite(yydata->code, yydata->verb);
            vfputs("\n}\n");

            if(yydata->top != NULL)
                free(yydata->top);
            yydata->top = yydata->code;
            break;

          case D_USTATE_TYPE:
            vfprintf(yydata->verb, "User-state: {\n%.*s\n}\n",
                     (int) yydata->code->len, yydata->code->s);
            if(yydata->ustate_type != NULL)
                free(yydata->ustate_type);
            yydata->ustate_type = yydata->code;
            break;

          default:
            fprintf(stderr, __FILE__ ":%d: invalid directive with code\n",
                    __LINE__);
            exit(1);
        }

        yydata->dir = D_NONE;
        yydata->code = NULL;
        YYSTART(MAIN);
    } else {
        x = lstrcat_s(yydata->code, "}");
        free(yydata->code);
        yydata->code = x;
    }
}

<C_CODE> (["]([^"\\]|\\.|\n)*["]) |
 ([']([^'\\]|\\.|\n)*[']) |
 ([/][*]([^*]|[*]+[^*/]|\n)*[*][/]) |
 ([/][/][^\n]*\n) |
 [^{}"'] | \n {
    len_string *x = lstrcat_buf(yydata->code, yylen, yytext);
    free(yydata->code);
    yydata->code = x;
}

<PRE_C_TOKEN>[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_]
[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]* {
#ifdef LEXER_DBG
    vfprintf(yydata->verb, "Directive \'%s\': %.*s\n",
             directive_name(yydata->dir), LEN, yytext);
#endif

    switch(yydata->dir) {
      case D_STATE:
        vfprintf(yydata->verb, "%%state directive: %.*s\n", LEN, yytext);

        yydata->states = add_to_list(yytext, yylen, yydata->states);

        if(yydata->initstate == NULL)
            yydata->initstate = lstring_dupbuf(yylen, yytext);

        break;

      case D_INITSTATE:
        if(yydata->initstate != NULL)
            free(yydata->initstate);
        yydata->initstate = lstring_dupbuf(yylen, yytext);
        yydata->states = add_to_list(yytext, yylen, yydata->states);
        break;

      case D_PREFIX:
        if(yydata->prefix != NULL)
            free(yydata->prefix);
        yydata->prefix = lstring_dupbuf(yylen, yytext);
        break;

      default:
        fprintf(stderr, __FILE__ ":%d: Given invalid directive!\n", __LINE__);
        exit(1);
    }

    yydata->dir = D_NONE;
    YYSTART(NON_WHSP_IS_ERROR);
}

<NON_WHSP_IS_ERROR>[ \t\n] { YYSTART(MAIN); }

// Catch-all ignoring of whitespace
[ \t\n] { ; }

// Catch-all single-character regexes
<MAIN,IN_REGEX> [^{}\\\[\]()?*+<] {
#ifdef LEXER_DBG
    vfprintf(yydata->verb, "Char \'%c\'\n", yytext[0]);
#endif
    add_simple_regex(yydata, mk_char_rx(yytext[0]));
    YYSTART(IN_REGEX);
}
