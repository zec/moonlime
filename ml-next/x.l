// This is a comment

%header { a; /* a comment } in code */ // another comment in code }
// Note: the two closing braces in the line above should *not*
// end the directive.
}

/* This is also a comment */
%top { b; }

%state ABC

%state DEF

%initstate ABC

%prefix XyzLexer

ab c { 1; }

a ?b* c+ { 2; }

d{5} { 3; }

d{6,8} { 4; }

d{9,} { 5; }

d{,4} { 6; }

ef|ghi { 7; }

(ef|gh)j { 8; }

e(fg||gh)(|fg)(fg|)(f|)(|g)k { 9; }

j(l{4,5}){3}k { 10; }

j+?{,6} { 11; }
