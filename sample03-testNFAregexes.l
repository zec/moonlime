%prefix Sample

%top {
#include <stdio.h>
#define LEN ((int) yylen)
}

a { printf("1 %.*s\n", LEN, yytext); }

b|c { printf("2 %.*s\n", LEN, yytext); }

[bcde] { printf("3 %.*s\n", LEN, yytext); }

[^abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ] { printf("4\n"); }

a(bc) { printf("5 %.*s\n", LEN, yytext); }

bc|def { printf("6 %.*s\n", LEN, yytext); }

a(bc)?d { printf("7 %.*s\n", LEN, yytext); }

a*b?c+d { printf("8 %.*s\n", LEN, yytext); }

a{2,3}b{,4}c{3} { printf("9 %.*s\n", LEN, yytext); }
