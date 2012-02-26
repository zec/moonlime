/*
 * regex.c: Procedures for dealing with regular expressions.
 *
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms.
 */

#include "regex.h"

#ifndef ML_STDIO_H
#define ML_STDIO_H
#include <stdio.h>
#endif

static regex_t * alloc_regex(size_t array_sz, const char *fname, int line)
{
    regex_t *ptr, **init_array;

    if( (ptr = malloc(sizeof(*ptr))) == NULL ) {
        fprintf(stderr, "%s:%d: Unable to allocate memory for regex_t\n",
                fname, line);
        exit(1);
    }

    ptr->next = NULL;

    if(array_sz <= 0)
        return ptr;

    if( (init_array = malloc(array_sz * sizeof(*init_array))) == NULL ) {
        fprintf(stderr, "%s:%d: Unable to allocate memory for regex_t *[]\n",
                fname, line);
        exit(1);
    }

    ptr->data.list.n_enc = 0;
    ptr->data.list.array_sz = array_sz;
    ptr->data.list.enc = init_array;

    return ptr;
}

regex_t * mk_char_rx_impl(char c, const char *fname, int line)
{
    regex_t *rx = alloc_regex(0, fname, line);

    rx->type = R_CHAR;
    rx->data.c = 0xff & (int)c;

    return rx;
}

regex_t * mk_char_class_rx_impl(int is_inverted, const char *fname, int line)
{
    int i;
    regex_t *rx = alloc_regex(0, fname, line);

    rx->type = R_CLASS;
    rx->data.cls.is_inverted = is_inverted;
    for(i = 0; i < CLASS_SZ; ++i)
        rx->data.cls.set[i] = 0;

    return rx;
}

void add_to_char_class_impl(regex_t *rx, char c, const char *fname, int line)
{
    int ic = 0xff & (int) c;

    if(rx == NULL || rx->type != R_CLASS) {
        fprintf(stderr, "%s:%d: Invalid argument to add_to_char_class\n",
                fname, line);
        exit(1);
    }

    rx->data.cls.set[ic / ML_UINT_BIT] |= 1 << (ic % ML_UINT_BIT);
}

regex_t * mk_any_rx_impl(const char *fname, int line)
{
    regex_t *rx = alloc_regex(0, fname, line);

    rx->type = R_ANY;

    return rx;
}

#define DEF_ARRAY_SZ 16

regex_t * mk_option_rx_impl(const char *fname, int line)
{
    regex_t *rx = alloc_regex(DEF_ARRAY_SZ, fname, line);

    rx->type = R_OPTION;

    return rx;
}

regex_t * mk_concat_rx_impl(size_t start_len, const char *fname, int line)
{
    regex_t *rx = alloc_regex((start_len <= 0) ? DEF_ARRAY_SZ : start_len,
                              fname, line);

    rx->type = R_CONCAT;

    return rx;
}

void add_enc_rx_impl(regex_t *rx, regex_t *enc, const char *fname, int line)
{
    size_t i, new_sz;
    regex_t **new_enc;

    if(rx == NULL || (rx->type != R_OPTION && rx->type != R_CONCAT)) {
        fprintf(stderr, "%s:%d: Invalid argument to add_enc_rx\n",
                fname, line);
        exit(1);
    }

    if(enc == NULL) {
        fprintf(stderr, "%s:%d: NULL enclosed regex for add_enc_rx\n",
                fname, line);
        exit(1);
    }

    if(rx->data.list.n_enc + 1 >= rx->data.list.array_sz) {
        new_sz = rx->data.list.array_sz * 2 + 1;
        if( (new_enc = malloc(new_sz * sizeof(*new_enc))) == NULL) {
            fprintf(stderr,
                    "%s:%d: Unable to allocate new memory for enc array\n",
                    fname, line);
            exit(1);
        }

        for(i = 0; i < rx->data.list.n_enc; ++i)
            new_enc[i] = rx->data.list.enc[i];

        free(rx->data.list.enc);
        rx->data.list.enc = new_enc;
        rx->data.list.array_sz = new_sz;
    }

    rx->data.list.enc[rx->data.list.n_enc++] = enc;
}

regex_t * mk_maybe_rx_impl(regex_t *enc, const char *fname, int line)
{
    regex_t *rx;

    if(enc == NULL) {
        fprintf(stderr, "%s:%d: NULL enclosed regex for mk_maybe_rx\n",
                fname, line);
        exit(1);
    }
    rx = alloc_regex(0, fname, line);

    rx->type = R_MAYBE;
    rx->data.enc = enc;

    return rx;
}

regex_t * mk_star_rx_impl(regex_t *enc, const char *fname, int line)
{
    regex_t *rx;

    if(enc == NULL) {
        fprintf(stderr, "%s:%d: NULL enclosed regex for mk_star_rx\n",
                fname, line);
        exit(1);
    }
    rx = alloc_regex(0, fname, line);

    rx->type = R_STAR;
    rx->data.enc = enc;

    return rx;
}

regex_t * mk_plus_rx_impl(regex_t *enc, const char *fname, int line)
{
    regex_t *rx;

    if(enc == NULL) {
        fprintf(stderr, "%s:%d: NULL enclosed regex for mk_plus_rx\n",
                fname, line);
        exit(1);
    }
    rx = alloc_regex(0, fname, line);

    rx->type = R_PLUS;
    rx->data.enc = enc;

    return rx;
}

regex_t * mk_num_rx_impl(regex_t *enc, int min, int max,
                         const char *fname, int line)
{
    regex_t *rx;

    if(enc == NULL) {
        fprintf(stderr, "%s:%d: NULL enclosed regex for mk_num_rx\n",
                fname, line);
        exit(1);
    }
    rx = alloc_regex(0, fname, line);

    rx->type = R_NUM;
    rx->data.num.enc = enc;
    rx->data.num.min = min;
    rx->data.num.max = max;

    return rx;
}

regex_t * mk_zero_rx_impl(const char *fname, int line)
{
    regex_t *rx = alloc_regex(0, fname, line);

    rx->type = R_ZERO;

    return rx;
}

regex_t * mk_paren_rx_impl(const char *fname, int line)
{
    regex_t *rx = alloc_regex(0, fname, line);

    rx->type = R_PAREN;

    return rx;
}

void free_regex_tree_impl(regex_t *rx, const char *fname, int line)
{
    size_t i;

    if(rx == NULL) {
        fprintf(stderr, "%s:%d: Tried to free a NULL object!\n", fname, line);
        exit(1);
    }

    switch(rx->type) {
      case R_OPTION:
      case R_CONCAT:
        for(i = 0; i < rx->data.list.n_enc; ++i)
            free_regex_tree_impl(rx->data.list.enc[i], fname, line);
        free(rx->data.list.enc);
        break;

      case R_MAYBE:
      case R_STAR:
      case R_PLUS:
        free_regex_tree_impl(rx->data.enc, fname, line);
        break;

      case R_NUM:
        free_regex_tree_impl(rx->data.num.enc, fname, line);
        break;

      default: ;
    }

    free(rx);
}
