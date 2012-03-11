#ifndef YYML_%PREFIX%_HEADER
#define YYML_%PREFIX%_HEADER

/* The default lexical-scanner template for Moonlime. Terms under which the
 * generated code may be distributed, modified, etc. are provided by the
 * lexer-writer below. */

%HEADER%

typedef struct yy_%PREFIX%_state %PREFIX%_state;

%PREFIX%_state * %PREFIX%Init( void * (*alloc)(size_t),
    void (*unalloc)(void *) );
void %PREFIX%Destroy( %PREFIX%_state *lexer );
int %PREFIX%Read( %PREFIX%_state *lexer, char *input, size_t len %UPARAM% );

#endif
