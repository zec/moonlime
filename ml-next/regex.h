/*
 * regex.h: Structures and procedures for dealing with regular expressions.
 *
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms.
 */

#ifndef ML_REGEX_H
#define ML_REGEX_H

typedef enum {
    R_CHAR,   /* Matches a given character */
    R_CLASS,  /* Matches one of a given set of single characters */
    R_ANY,    /* Matches any given character */
    R_OPTION, /* Matches any of the enclosed regexes */
    R_CONCAT, /* Matches the concatenation of the enclosed regexes */
    R_MAYBE,  /* Matches zero or one of the enclosed regex */
    R_STAR,   /* Kleene star; matches zero or more of the enclosed regex */
    R_PLUS,   /* Matches one or more of the enclosed regex */
    R_NUM,    /* Matches a number of repetitions of the enclosed regex;
               * the minimum and/or maximum number of repetitions is given. */
    R_ZERO,   /* A placeholder for "matching" a zero-length string */
    R_PAREN   /* Not actually a regex type; used to delimit a parenthesized
               * sub-expression on the regex stack */
} regex_type;

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

#define ML_UINT_BIT (sizeof(unsigned int) * CHAR_BIT)
#define CLASS_SZ ((256 + ML_UINT_BIT - 1) / ML_UINT_BIT)

typedef struct regex_struct {
    regex_type type;
    struct regex_struct *next; /* Used for the regex stack */
    union {
        int c; /* Character */

        struct {
            int is_inverted;
            unsigned int set[CLASS_SZ];
        } cls;

        struct regex_struct *enc; /* Enclosed regex (maybe, star, plus) */

        struct {
            int min;
            int max;
            struct regex_struct *enc;
        } num; /* Enclosed regex and min/max counts (num)
                * (-1 in min or max mean no min/max) */

        struct {
            size_t n_enc;
            size_t array_sz;
            struct regex_struct **enc; /* Pointer to array */
        } list; /* Enclosed regexes (option, concat) */
    } data;
} regex_t;

/* The following allocate and initialize regex objects of various kinds: */
regex_t * mk_char_rx_impl(char c, const char *fname, int line);
regex_t * mk_char_class_rx_impl(int is_inverted, const char *fname, int line);
regex_t * mk_any_rx_impl(const char *fname, int line);
regex_t * mk_option_rx_impl(const char *fname, int line);
regex_t * mk_concat_rx_impl(size_t start_len, const char *fname, int line);
regex_t * mk_maybe_rx_impl(regex_t *enc, const char *fname, int line);
regex_t * mk_star_rx_impl(regex_t *enc, const char *fname, int line);
regex_t * mk_plus_rx_impl(regex_t *enc, const char *fname, int line);
regex_t * mk_num_rx_impl(regex_t *enc, int min, int max,
                         const char *fname, int line);
regex_t * mk_zero_rx_impl(const char *fname, int line);
regex_t * mk_paren_rx_impl(const char *fname, int line);

#define mk_char_rx(c) mk_char_rx_impl((c), __FILE__, __LINE__)
#define mk_char_class_rx(inv) mk_char_class_rx_impl((inv), __FILE__, __LINE__)
#define mk_any_rx() mk_any_rx_impl(__FILE__, __LINE__)
#define mk_option_rx() mk_option_rx_impl(__FILE__, __LINE__)
#define mk_concat_rx(len) mk_concat_rx_impl((len), __FILE__, __LINE__)
#define mk_maybe_rx(enc) mk_maybe_rx_impl((enc), __FILE__, __LINE__)
#define mk_star_rx(enc) mk_star_rx_impl((enc), __FILE__, __LINE__)
#define mk_plus_rx(enc) mk_plus_rx_impl((enc), __FILE__, __LINE__)
#define mk_num_rx(enc, min, max) mk_num_rx_impl((enc), (min), (max), \
    __FILE__, __LINE__)
#define mk_zero_rx() mk_zero_rx_impl(__FILE__, __LINE__)
#define mk_paren_rx() mk_paren_rx_impl(__FILE__, __LINE__)


/* The following modify certain existing regex objects: */
void add_to_char_class_impl(regex_t *rx, char c, const char *fname, int line);
void add_enc_rx_impl(regex_t *rx, regex_t *enc, const char *fname, int line);

#define add_to_char_class(rx, c) add_to_char_class_impl((rx), (c), \
    __FILE__, __LINE__)
#define add_enc_rx(rx, enc) add_enc_rx_impl((rx), (enc), __FILE__, __LINE__)

/* The following unallocates a tree of regex objects: */
void free_regex_tree_impl(regex_t *rx, const char *fname, int line);

#define free_regex_tree(rx) free_regex_tree_impl((rx), __FILE__, __LINE__)

/* The following prints out a human-readable version of a regex tree: */
void print_regex_tree(FILE *f, regex_t *rx);

#endif
