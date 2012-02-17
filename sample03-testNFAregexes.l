a { 1; }

b|c { 2; }

[bcde] { 3; }

[^abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ] { 4; }

a(bc) { 5; }

bc|def { 6; }

a(bc)?d { 7; }

a*b?c+d { 8; }

a{2,3}b{,4}c{3} { 9; }
