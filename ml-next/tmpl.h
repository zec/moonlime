#ifndef YYML_%PREFIX%_HEADER
#define YYML_%PREFIX%_HEADER

%HEADER%


void * %PREFIX%Init( void * (*alloc)(size_t), void (*unalloc)(void *) );
void %PREFIX%Destroy( void *lexer );
int %PREFIX%Read( void *lexer, char *input, size_t len );

#endif
