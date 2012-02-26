/*
 * utils.h: Random useful things.
 *
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms.
 */
#ifndef ML_UTILS_H
#define ML_UTILS_H

#ifndef ML_STDLIB_H
#define ML_STDLIB_H
#include <stdlib.h>
#endif

#ifndef ML_STDIO_H
#define ML_STDIO_H
#include <stdio.h>
#endif

/* A length-prefixed, 8-bit clean string */
typedef struct {
  size_t len;
  char s[1];
} len_string;

/* The len_string * returned by the following functions is allocated from
 * the heap and can be deallocated by a simple free() of the len_string *. */

/* Returns a pointer to a len_string of length len, initialized to all-nulls */
len_string * mk_blank_lstring(size_t len);

/* Returns a pointer to a len_string of length len, initialized to the len
 * bytes starting with buf */
len_string * lstring_dupbuf(size_t len, const char *buf);

/* The following are like a combination of strdup and strcat: */
len_string * lstrcat(const len_string *a, const len_string *b);
len_string * lstrcat_s(const len_string *a, const char *str);
len_string * lstrcat_buf(const len_string *a, size_t len, const char *buf);

/* Writes the contents of *lstr to stream f */
void lstr_fwrite(const len_string *lstr, FILE *f);

#endif
