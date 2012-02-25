%prefix Sample

%header {
#include <stdio.h>
}

a { printf("1\n"); }

bc { printf("2\n"); }

[abc] { printf("3\n"); }

[abc]? { printf("4\n"); }

a?a { printf("5\n"); }

(xa|by)q { printf("6\n"); }

.+(a(a|b|c)[def])?.q { printf("7\n"); }

a?b*c+ { printf("8\n"); }

m(iss)+ipi { printf("9\n"); }

z[^qua]y { printf("10\n"); }

/* The following is legal, if redundantly convoluted. */
i*?{14,15} { printf("11\n"); }

cd{,20}e { printf("12\n"); }

fg{7}h { printf("13\n"); }

ij{18,}k { printf("14\n"); }

(|abc)(de||fg)(hij|kl|) { printf("15\n"); }

a|bc|d { printf("16\n"); }
