/*
 * The syntax of Moonlime lexers, as expressed by a Moonlime lexer.
 *
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms.
 */

%header {
/* A lexer for Moonlime lexers.
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms. */

#ifndef ML_UTILS_H
#include "utils.h"
#endif

typedef struct {
    const char *dir_name;
    int c_nest_depth;
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

%prefix Moonlime

%initstate MAIN

%state MAIN
%state IN_REGEX
%state C_CODE
%state PRE_C_CODE
%state PRE_C_TOKEN
%state NON_WHSP_IS_ERROR

<MAIN>[%][^ \t\n]+ {
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

<PRE_C_CODE>[{] {
    file_state->c_nest_depth = 1;

    if(file_state->code != NULL)
        free(file_state->code);
    file_state->code = mk_blank_lstring(0);

    YYSTART(C_CODE);
}

<C_CODE>[{] {
    len_string *x;
    ++file_state->c_nest_depth;
    x = lstrcat_s(file_state->code, "{");
    free(file_state->code);
    file_state->code = x;
}

<C_CODE>[}] {
    len_string *x;

    if(--file_state->c_nest_depth == 0) {
        if(file_state->dir_name != NULL) {
            printf("Directive %s: {\n", file_state->dir_name);
            lstr_fwrite(file_state->code, stdout);
            fputs("\n}\n", stdout);
            file_state->dir_name = NULL;
        }

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
        [^{}"'] | \n {
    len_string *x = lstrcat_buf(file_state->code, yylen, yytext);
    free(file_state->code);
    file_state->code = x;
}

<PRE_C_TOKEN>[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_]
[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]* {
    printf("Directive \'%s\': ", file_state->dir_name);
    fwrite(yytext, 1, yylen, stdout);

    file_state->dir_name = NULL;
    YYSTART(NON_WHSP_IS_ERROR);
}

<NON_WHSP_IS_ERROR>[ \t\n] { YYSTART(MAIN); }

// Catch-all ignoring of whitespace
[ \t\n] { ; }
