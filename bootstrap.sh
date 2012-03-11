#!/bin/sh -e

make bootstrap-prep
mv ml-lexer.c mllexgen.c
mv ml-lexer.h mllexgen.h
mv tmpl-lex.c tmlexgen.c
mv tmpl-lex.h tmlexgen.h
