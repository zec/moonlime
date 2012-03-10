#ifndef YYML_%PREFIX%_HEADER
#define YYML_%PREFIX%_HEADER

/* The default lexical-scanner template for Moonlime. Terms under which the
 * generated code may be distributed, modified, etc. are provided by the
 * lexer-writer below. */

%HEADER%

void * %PREFIX%Init( void * (*alloc)(size_t), void (*unalloc)(void *) );
void %PREFIX%Destroy( void *lexer );
int %PREFIX%Read( void *lexer, char *input, size_t len );

#endif
