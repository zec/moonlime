%prefix Calc

%top {
#include <stdio.h>
#include <stdlib.h>

#define STK_SZ 20
long stack[STK_SZ];
int i = 0;

void err(const char *s)
{
    fputs(s, stderr);
    exit(1);
}

int main()
{
    int c; char x;
    Calc_state *r = CalcInit(malloc, free);
    while((c = getchar()) != EOF) {
        x = c;
        if(!CalcRead(r, &x, 1)) err("bad input\n");
    }
    if(!CalcRead(r, NULL, 0)) err("bad input\n");
    CalcDestroy(r);
    return 0;
}

#define op(x) if(i < 2) err("stack underflow"); \
    stack[i-2] = stack[i-2] x stack[i-1]; \
    i -= 1
}

[0123456789]+ {
    long n = 0; size_t j;
    for(j = 0; j < yylen; ++j)
        n = (n * 10) + (yytext[j] - '0');
    if(i >= STK_SZ) err("stack overflow\n");
    stack[i++] = n;
}

\+ { op(+); }
- { op(-); }
[*] { op(*); }
/ { op(/); }
p { printf("%ld\n", stack[i-1]); }

// Skip over whitespace
[ \t\n] { ; }
