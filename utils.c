/*
 * utils.c: Random useful things.
 *
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms.
 */

#include "utils.h"

#ifndef ML_STRING_H
#define ML_STRING_H
#include <string.h>
#endif

/* Allocate memory or die trying */
void * malloc_or_die_impl(size_t len, const char *type,
                          const char *fname, int line)
{
    void *ptr = malloc(len);

    /* Fail fast! */
    if(ptr == NULL) {
        fprintf(stderr,
                "%s:%d: Can\'t allocate memory for %zu bytes, type %s\n",
                fname, line, len, type);
        exit(1);
    }

    return ptr;
}

static len_string * mk_lstring(size_t len, const char *fname, int line)
{
    len_string *ptr = malloc_or_die_impl(sizeof(*ptr) + len, "len_string",
        fname, line);

    /* Note that size_t is an unsigned type,
     * so no problems with negative sizes. */
    ptr->len = len;

    return ptr;
}

len_string * mk_blank_lstring_impl(size_t len, const char *fname, int line)
{
    len_string *ptr = mk_lstring(len, fname, line);

    while(len-- > 0)
        ptr->s[len] = '\0';

    return ptr;
}

len_string * lstring_dupbuf_impl(size_t len, const char *buf,
                                 const char *fname, int line)
{
    len_string *ptr = mk_lstring(len, fname, line);

    while(len-- > 0)
        ptr->s[len] = buf[len];

    return ptr;
}

static const len_string nilstr = { 0, {'\0'} };
static const char blank_str[] = "";

len_string * lstrcat_impl(const len_string *a, const len_string *b,
                          const char *fname, int line)
{
    len_string *ptr;
    size_t i, j;

    if(a == NULL)
        a = &nilstr;
    if(b == NULL)
        b = &nilstr;

    ptr = mk_lstring(a->len + b->len, fname, line);

    for(i = 0; i < a->len; i++)
        ptr->s[i] = a->s[i];
    for(j = 0; j < b->len; j++)
        ptr->s[i++] = b->s[j];

    return ptr;
}

len_string * lstrcat_s_impl(const len_string *a, const char *str,
                            const char *fname, int line)
{
    len_string *ptr;
    size_t i, slen;

    if(a == NULL)
        a = &nilstr;
    if(str == NULL)
        str = blank_str;

    slen = strlen(str);

    ptr = mk_lstring(a->len + slen, fname, line);

    for(i = 0; i < a->len; i++)
        ptr->s[i] = a->s[i];
    strncpy(ptr->s + a->len, str, slen);

    return ptr;
}

len_string * lstrcat_buf_impl(const len_string *a, size_t len, const char *buf,
                              const char *fname, int line)
{
    len_string *ptr;
    size_t i, j;

    if(a == NULL)
        a = &nilstr;
    if(buf == NULL)
        len = 0;

    ptr = mk_lstring(a->len + len, fname, line);

    for(i = 0; i < a->len; i++)
        ptr->s[i] = a->s[i];
    for(j = 0; j < len; j++)
        ptr->s[i++] = buf[j];

    return ptr;
}

int lstr_eq(const len_string *a, const len_string *b)
{
    if(a == NULL || b == NULL)
        return 0;

    if(a->len != b->len)
        return 0;

    if(a->len == 0 && b->len == 0)
        return 1;

    return !memcmp(a->s, b->s, a->len);
}

void lstr_fwrite(const len_string *lstr, FILE *f)
{
    size_t len, nwritten;

    if(lstr == NULL) {
        fputs("(nil)", f);
        return;
    }

    len = lstr->len;

    while(len > 0) {
        nwritten = fwrite(lstr->s + (lstr->len - len), 1, len, f);
        if(nwritten == 0)
            break;
        len -= nwritten;
    }
}

int lstr_in_list(const len_string *s, const lstr_list_t *l)
{
    while(l != NULL) {
        if(lstr_eq(s, l->s))
            return 1;
        l = l->next;
    }

    return 0;
}

const char hex_digits[256] = {
    ['0'] = 0, ['1'] = 1, ['2'] = 2, ['3'] = 3, ['4'] = 4,
    ['5'] = 5, ['6'] = 6, ['7'] = 7, ['8'] = 8, ['9'] = 9,
    ['a'] = 10, ['b'] = 11, ['c'] = 12, ['d'] = 13, ['e'] = 14, ['f'] = 15,
    ['A'] = 10, ['B'] = 11, ['C'] = 12, ['D'] = 13, ['E'] = 14, ['F'] = 15
};
