%prefix Sample

%top {
#include <stdio.h>
}

a { printf("1\n"); }

b|c { printf("2\n"); }

[bcde] { printf("3\n"); }

[^abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ] { printf("4\n"); }

a(bc) { printf("5\n"); }

bc|def { printf("6\n"); }

a(bc)?d { printf("7\n"); }

a*b?c+d { printf("8\n"); }

a{2,3}b{,4}c{3} { printf("9\n"); }
