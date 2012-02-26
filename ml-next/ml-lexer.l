/*
 * The syntax of Moonlime lexers, as expressed by a Moonlime lexer.
 *
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms.
 */

%prefix Moonlime

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

typedef struct {
    const char *dir_name; /* Name of current directive */
    int c_nest_depth;     /* Current brace-nesting depth in C code */
    int regex_nest_depth; /* Current parenthesis-nesting depth in regex */
    len_string *code;     /* The current chunk of C code */

    regex_t *curr_rx; /* Current regular-expression fragment being worked on */
    regex_t *rx_stack; /* Stack of regular-expression fragments -- only
                        * types R_CONCAT, R_OPTION, and R_PAREN should be on
                        * the stack! */
} lexer_lexer_state;

void init_lexer_lexer_state(lexer_lexer_state *st);

extern lexer_lexer_state *file_state;
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

    st->dir_name = NULL;
    st->code = NULL;
    st->curr_rx = st->rx_stack = NULL;
    st->regex_nest_depth = st->c_nest_depth = 0;
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
      default:
        c = buf[1];
    }

    return c;
}
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
<MAIN,IN_REGEX> [/][*]([^*]|[*]+[^*/])*[*][/] |
                [/][/][^\n]*\n { ; }

<MAIN> [%][abcdefghijklmnopqrstuvwxyz]+ {
    if(yylen == 4 && !strncmp(yytext, "%top", yylen)) {
        file_state->dir_name = "top";
        YYSTART(PRE_C_CODE);

    } else if(yylen == 7 && !strncmp(yytext, "%header", yylen)) {
        file_state->dir_name = "header";
        YYSTART(PRE_C_CODE);

    } else if(yylen == 6 && !strncmp(yytext, "%state", yylen)) {
        file_state->dir_name = "state";
        YYSTART(PRE_C_TOKEN);

    } else if(yylen == 10 && !strncmp(yytext, "%initstate", yylen)) {
        file_state->dir_name = "initstate";
        YYSTART(PRE_C_TOKEN);

    } else if(yylen == 7 && !strncmp(yytext, "%prefix", yylen)) {
        file_state->dir_name = "prefix";
        YYSTART(PRE_C_TOKEN);

    } else {
        fprintf(stderr, "Unknown directive!\n");
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
        fputs("Invalid start-state selector", stderr);
        exit(1);
    }

    fputs("Start-state selector \"", stdout);
    fwrite(yytext, 1, yylen, stdout);
    fputs("\"\n", stdout);
}

// Start-state separator
<IN_SELECTOR> , { ; }

// End of selector
<IN_SELECTOR> [>] { YYSTART(IN_REGEX); }

// Any character
<MAIN,IN_REGEX> [.] {
    printf("Any\n");
    add_simple_regex(file_state, mk_any_rx());
    YYSTART(IN_REGEX);
}

// Character class
<MAIN,IN_REGEX> \[\^? {
    printf("Character class%s:\n", (yylen > 1) ? " (inverted)" : "");
    add_simple_regex(file_state, mk_char_class_rx(yylen > 1));
    YYSTART(IN_CHARCLASS);
}

<IN_CHARCLASS> \\(x[0123456789abcdefABCDEF]{2})|[^x] {
    printf(yytext[1] != 'x' ? " \'\\%c\'\n" : " \'\\%c%c%c\'\n",
           yytext[1], yytext[2], yytext[3]);
    add_to_char_class(file_state->curr_rx, unescape_rx_escape(yytext));
}

<IN_CHARCLASS> [^\\\]]|\n {
    printf(" \'%c\'\n", yytext[0]);
    add_to_char_class(file_state->curr_rx, yytext[0]);
}

<IN_CHARCLASS> \] {
    printf("End character class\n");
    YYSTART(IN_REGEX);
}

// Parenthesis operators
<MAIN,IN_REGEX> [(] {
    regex_t *new_rx, *paren;
    ++file_state->regex_nest_depth;
    printf("(\n");
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
}

<IN_REGEX> [)] {
    regex_t *re, *top;
    if(--file_state->regex_nest_depth < 0) {
        fprintf(stderr, "Improper parentheses nesting!\n");
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
}

// Character escape
<MAIN,IN_REGEX> \\(x[0123456789abcdefABCDEF]{2}|[^x]) {
    printf((yytext[1] != 'x') ? "Char \'\\%c\'\n" : "Char \'\\%c%c%c\'\n",
           yytext[1], yytext[2], yytext[3]);

    add_simple_regex(file_state, mk_char_rx(unescape_rx_escape(yytext)));
    YYSTART(IN_REGEX);
}

// Option operator
<MAIN,IN_REGEX> [|] {
    regex_t *re, *top, *next;
    printf("|\n");
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
}

// Repetition operators
<IN_REGEX> [?*+] {
    printf("Repetition: ");
    fwrite(yytext, 1, yylen, stdout);
    printf("\n");
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
}

<IN_REGEX> \{[0-9]+,?\} {
    int n;

    if(file_state->curr_rx == NULL) {
        fputs("Tried to apply repetition to empty regex\n", stderr);
        exit(1);
    }

    n = (int) strtol(yytext+1, NULL, 10);

    if(yytext[yylen-2] != ',')
        file_state->curr_rx = mk_num_rx(file_state->curr_rx, n, n);
    else
        file_state->curr_rx = mk_num_rx(file_state->curr_rx, n, -1);
}

<IN_REGEX> \{[0-9]*,[0-9]+\} {
    int n, m;
    char *ptr = (char *)(yytext+1);

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
}

// Code associated with a pattern
<IN_REGEX> [{] {
    regex_t *re, *next;
    if(file_state->regex_nest_depth > 0) {
        fprintf(stderr, "Code improperly contained inside parentheses!\n");
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

    file_state->dir_name = NULL;
    YYSTART(C_CODE);
}

<PRE_C_CODE> [{] {
    file_state->c_nest_depth = 1;

    if(file_state->code != NULL)
        free(file_state->code);
    file_state->code = mk_blank_lstring(0);

    YYSTART(C_CODE);
}

<C_CODE> [{] {
    len_string *x;

    ++file_state->c_nest_depth;
    x = lstrcat_s(file_state->code, "{");
    free(file_state->code);
    file_state->code = x;
}

<C_CODE> [}] {
    len_string *x;

    if(--file_state->c_nest_depth == 0) {
        if(file_state->dir_name != NULL) {
            printf("Directive %s: {\n", file_state->dir_name);
            lstr_fwrite(file_state->code, stdout);
            fputs("\n}\n", stdout);
        } else {
            printf("Pattern:\n");
            print_regex_tree(stdout, file_state->curr_rx);
            free_regex_tree(file_state->curr_rx);
            file_state->curr_rx = NULL;
            printf("Code associated with pattern: {\n");
            lstr_fwrite(file_state->code, stdout);
            fputs("\n}\n", stdout);
        }

        file_state->dir_name = NULL;

        free(file_state->code);
        file_state->code = NULL;
        YYSTART(MAIN);
    } else {
        x = lstrcat_s(file_state->code, "{");
        free(file_state->code);
        file_state->code = x;
    }
}

<C_CODE>["]([^"\\]|\\.|\n)*["] |
        [']([^'\\]|\\.|\n)*['] |
        [/][*]([^*]|[*]+[^*/])*[*][/] |
        [/][/][^\n]*\n |
        [^{}"'] | \n {
    len_string *x = lstrcat_buf(file_state->code, yylen, yytext);
    free(file_state->code);
    file_state->code = x;
}

<PRE_C_TOKEN>[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_]
[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]* {
    printf("Directive \'%s\': ", file_state->dir_name);
    fwrite(yytext, 1, yylen, stdout);
    fputs("\n", stdout);

    file_state->dir_name = NULL;
    YYSTART(NON_WHSP_IS_ERROR);
}

<NON_WHSP_IS_ERROR>[ \t\n] { YYSTART(MAIN); }

// Catch-all ignoring of whitespace
[ \t\n] { ; }

// Catch-all single-character regexes
<MAIN,IN_REGEX> [^{\\\])?*+<] {
    printf("Char \'%c\'\n", yytext[0]);
    add_simple_regex(file_state, mk_char_rx(yytext[0]));
    YYSTART(IN_REGEX);
}
