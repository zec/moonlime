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

#ifndef ML_LIMITS_H
#define ML_LIMITS_H
#include <limits.h>
#endif

/* Either successfully allocates memory or quits the program */
void * malloc_or_die_impl(size_t len, const char *type,
                          const char *fname, int line);

#define malloc_or_die(n, type) \
    ((type *) malloc_or_die_impl(n * sizeof(type), #type, __FILE__, __LINE__))

#define mod_2(n, type, fname, line) \
    ((type *) malloc_or_die_impl(n * sizeof(type), #type, fname, line))

/* A length-prefixed, 8-bit clean string */
typedef struct {
  size_t len;
  char s[1];
} len_string;

/* A list of len_strings */
struct lstring_list {
    len_string *s;
    struct lstring_list *next;
};

typedef struct lstring_list lstr_list_t;

/* The len_string * returned by the following functions is allocated from
 * the heap and can be deallocated by a simple free() of the len_string *. */

/* Returns a pointer to a len_string of length len, initialized to all-nulls */
len_string * mk_blank_lstring_impl(size_t len, const char *fname, int line);

/* Returns a pointer to a len_string of length len, initialized to the len
 * bytes starting with buf */
len_string * lstring_dupbuf_impl(size_t len, const char *buf,
                                 const char *fname, int line);

/* The following are like a combination of strdup and strcat: */
len_string * lstrcat_impl(const len_string *a, const len_string *b,
                          const char *fname, int line);
len_string * lstrcat_s_impl(const len_string *a, const char *str,
                            const char *fname, int line);
len_string * lstrcat_buf_impl(const len_string *a, size_t len, const char *buf,
                              const char *fname, int line);

/* Generally, one uses the following macros for ease of debugging: */
#define mk_blank_lstring(len) mk_blank_lstring_impl((len), __FILE__, __LINE__)
#define lstring_dupbuf(len, buf) lstring_dupbuf_impl((len), (buf), \
    __FILE__, __LINE__)
#define lstrcat(a, b) lstrcat_impl((a), (b), __FILE__, __LINE__)
#define lstrcat_s(a, str) lstrcat_s_impl((a), (str), __FILE__, __LINE__)
#define lstrcat_buf(a, len, buf) lstrcat_buf_impl((a), (len), (buf), \
    __FILE__, __LINE__)

/* Returns 1 if the contents of a and b are equal, 0 otherwise: */
int lstr_eq(const len_string *a, const len_string *b);

/* Writes the contents of *lstr to stream f */
void lstr_fwrite(const len_string *lstr, FILE *f);

/* Returns whether or not s is contained in the list starting with l */
int lstr_in_list(const len_string *s, const lstr_list_t *l);

/* A character-to-hexadecimal digit table */
extern const char hex_digits[256];

/* It's useful to know the least number of unsigned ints that can contain
 * 256 bits: */
#define ML_UINT_BIT (sizeof(unsigned int) * CHAR_BIT)
#define CLASS_SZ ((256 + ML_UINT_BIT - 1) / ML_UINT_BIT)

#endif
