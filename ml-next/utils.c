/*
 * utils.h: Random useful things.
 *
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms.
 */

#include "utils.h"

#ifndef ML_STRING_H
#define ML_STRING_H
#include <string.h>
#endif

static len_string * mk_lstring(size_t len)
{
    len_string *ptr = malloc(sizeof(*ptr) + len);

    /* Fail fast! */
    if(ptr == NULL) {
        fputs("Can\'t allocate memory for a len_string!\n", stderr);
        exit(1);
    }

    /* Note that size_t is an unsigned type,
     * so no problems with negative sizes. */
    ptr->len = len;

    return ptr;
}

len_string * mk_blank_lstring(size_t len)
{
    len_string *ptr = mk_lstring(len);

    while(len-- > 0)
        ptr->s[len] = '\0';

    return ptr;
}

len_string * lstring_dupbuf(size_t len, const char *buf)
{
    len_string *ptr = mk_lstring(len);

    while(len-- > 0)
        ptr->s[len] = buf[len];

    return ptr;
}

static const len_string nilstr = { 0, {'\0'} };
static const char blank_str[] = "";

len_string * lstrcat(const len_string *a, const len_string *b)
{
    len_string *ptr;
    size_t i, j;

    if(a == NULL)
        a = &nilstr;
    if(b == NULL)
        b = &nilstr;

    ptr = mk_lstring(a->len + b->len);

    for(i = 0; i < a->len; i++)
        ptr->s[i] = a->s[i];
    for(j = 0; j < b->len; j++)
        ptr->s[i++] = b->s[j];

    return ptr;
}

len_string * lstrcat_s(const len_string *a, const char *str)
{
    len_string *ptr;
    size_t i, slen;

    if(a == NULL)
        a = &nilstr;
    if(str == NULL)
        str = blank_str;

    slen = strlen(str);

    ptr = mk_lstring(a->len + slen);

    for(i = 0; i < a->len; i++)
        ptr->s[i] = a->s[i];
    strncpy(ptr->s + a->len, str, slen);

    return ptr;
}

len_string * lstrcat_buf(const len_string *a, size_t len, const char *buf)
{
    len_string *ptr;
    size_t i, j;

    if(a == NULL)
        a = &nilstr;
    if(buf == NULL)
        len = 0;

    ptr = mk_lstring(a->len + len);

    for(i = 0; i < a->len; i++)
        ptr->s[i] = a->s[i];
    for(j = 0; j < len; j++)
        ptr->s[i++] = buf[j];

    return ptr;
}

void lstr_fwrite(const len_string *lstr, FILE *f)
{
    size_t len, nwritten;

    if(lstr == NULL)
        fputs("(nil)", f);

    len = lstr->len;

    while(len > 0) {
        nwritten = fwrite(lstr->s + (lstr->len - len), 1, len, f);
        if(nwritten == 0)
            break;
        len -= nwritten;
    }
}
