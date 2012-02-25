%header {
#include <stdio.h>
}

%prefix Sample

(.|\n){16} {
  printf("%02x %02x %02x %02x %02x %02x %02x %02x  "
         "%02x %02x %02x %02x %02x %02x %02x %02x\n",
         yytext[0],  yytext[1],  yytext[2],  yytext[3],
         yytext[4],  yytext[5],  yytext[6],  yytext[7],
         yytext[8],  yytext[9],  yytext[10], yytext[11],
         yytext[12], yytext[13], yytext[14], yytext[15]);
}

(.|\n){1,15} {
  int i;
  for(i = 0; i < yylen; i++)
    printf((i != 7) ? "%02x " : "%02x  ", yytext[i]);
  printf("\n");
}
