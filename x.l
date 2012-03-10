// This is a comment

%header { typedef int z; /* a comment } in code */ // another comment in code }
// Note: the two closing braces in the line above should *not*
// end the directive.
}

/* This is also a comment */
%top {
#include <stdio.h>
}

%state ABC

%state DEF

%initstate ABC

%prefix XyzLexer

ab c { puts("1"); }

a ?b* c+ { puts("2"); }

d{5} { puts("3"); }

d{6,8} { puts("4"); }

d{9,} { puts("5"); }

d{,4} { puts("6"); }

ef|ghi { puts("7"); }

(ef|gh)j { puts("8"); }

e(fg||gh)(|fg)(fg|)(f|)(|g)k { puts("9"); }

j(l{4,5}){3}k { puts("10"); }

j+?{,6} { puts("11"); }
