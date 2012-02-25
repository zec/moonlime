// An example of stateful lexing ('left context sensitivity')

%prefix Sample

%header {
#include <stdio.h>
}

%state P
%state INIT
%state Q

%initstate INIT

// always treat 'a' the same way
a { printf("an a!\n"); }

// always skip over whitespace
[ \t\n] { ; }

/* switch between states */
p { printf("-> P\n"); YYSTATE(P); }
q { printf("-> Q\n"); YYSTATE(Q); }
i { printf("-> INIT\n"); YYSTATE(INIT); }

<INIT> b { printf("b\n"); }
<P> b { printf("B\n"); }
<Q> b { printf("c\n"); }
