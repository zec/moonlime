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

typedef struct {
    const char *dir_name;
    int c_nest_depth;
    int regex_nest_depth;
    len_string *code;
} lexer_lexer_state;

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

lexer_lexer_state *file_state;
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

// Character class
<MAIN,IN_REGEX> \[\^? {
    printf("Character class%s:\n", (yylen > 1) ? " (inverted)" : "");
    YYSTART(IN_CHARCLASS);
}

<IN_CHARCLASS> \\(x[0123456789abcdefABCDEF]{2})|[^x] {
    printf(yytext[1] != 'x' ? " \'\\%c\'\n" : " \'\\%c%c%c\'\n",
           yytext[1], yytext[2], yytext[3]);
}

<IN_CHARCLASS> [^\\\]]|\n {
    printf(" \'%c\'\n", yytext[0]);
}

<IN_CHARCLASS> \] {
    printf("End character class\n");
    YYSTART(IN_REGEX);
}

// Parenthesis operators
<MAIN,IN_REGEX> [(] {
    ++file_state->regex_nest_depth;
    printf("(\n");
    YYSTART(IN_REGEX);
}

<IN_REGEX> [)] {
    if(--file_state->regex_nest_depth < 0) {
        fprintf(stderr, "Improper parentheses nesting!\n");
        exit(1);
    }
}

// Character escape
<MAIN,IN_REGEX> \\(x[0123456789abcdefABCDEF]{2}|[^x]) {
    printf((yytext[1] != 'x') ? "Char \'\\%c\'\n" : "Char \'\\%c%c%c\'\n",
           yytext[1], yytext[2], yytext[3]);

    YYSTART(IN_REGEX);
}

// Option operator
<MAIN,IN_REGEX> [|] {
    printf("|\n");
    YYSTART(IN_REGEX);
}

// Repetition operators
<IN_REGEX> [+?*] |
           \{[0-9]+,?\} |
           \{[0-9]*,[0-9]+\} {
    printf("Repetition: ");
    fwrite(yytext, 1, yylen, stdout);
    printf("\n");
}

// Code associated with a pattern
<IN_REGEX> [{] {
    if(file_state->regex_nest_depth > 0) {
        fprintf(stderr, "Code improperly contained inside regex!\n");
        exit(1);
    }
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
    YYSTART(IN_REGEX);
}
