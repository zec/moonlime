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

/* switch between start-states */
p { printf("-> P\n"); YYSTART(P); }
q { printf("-> Q\n"); YYSTART(Q); }
i { printf("-> INIT\n"); YYSTART(INIT); }

<INIT> b { printf("b\n"); }
<P> b { printf("B\n"); }
<Q> b { printf("c\n"); }

<INIT,Q> c { printf("C\n"); }
c { printf("CCC\n"); }

<P,Q> d { printf("d\n"); }
