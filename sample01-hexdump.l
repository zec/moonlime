%top {
#include <stdio.h>
#define lo(x) ((x) & 0xff)
}

%prefix Sample

(.|\n){16} {
  printf("%02x %02x %02x %02x %02x %02x %02x %02x  "
         "%02x %02x %02x %02x %02x %02x %02x %02x\n",
         lo(yytext[0]),  lo(yytext[1]),  lo(yytext[2]),  lo(yytext[3]),
         lo(yytext[4]),  lo(yytext[5]),  lo(yytext[6]),  lo(yytext[7]),
         lo(yytext[8]),  lo(yytext[9]),  lo(yytext[10]), lo(yytext[11]),
         lo(yytext[12]), lo(yytext[13]), lo(yytext[14]), lo(yytext[15]));
}

(.|\n){1,15} {
  int i;
  for(i = 0; i < yylen; i++)
    printf((i != 7) ? "%02x " : "%02x  ", lo(yytext[i]));
  printf("\n");
}
