a { 1; }

bc { 2; }

[abc] { 3; }

[abc]? { 4; }

a?a { 5; }

(xa|by)q { 6; }

.+(a(a|b|c)[def])?.q { 7; }

a?b*c+ { 8; }

m(iss)+pi { 9; }

z[^qua]y { 10; }

/* The following is legal, if redundantly convoluted. */
i*?{14,15} { 11; }

cd{,20}e { 12; }

fg{7}h { 13; }

ij{18,}k { 14; }
