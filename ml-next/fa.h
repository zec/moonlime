/*
 * fa.h: Stuff relating to finite automata.
 *
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms.
 */

#ifndef ML_FA_H
#define ML_FA_H

#ifndef ML_UTILS_H
#include "utils.h"
#endif

#ifndef ML_REGEX_H
#include "regex.h"
#endif

#ifndef ML_STDIO_H
#define ML_STDIO_H
#include <stdio.h>
#endif

typedef struct state_str state_t;

/* A transition between states */
struct transition {
    int is_nil;                  /* Is this a nil-transition (typically denoted
                                  * by epsilon; a transition in an NFA that
                                  * always happens and consumes no chars) */
    unsigned int cond[CLASS_SZ]; /* The set of characters that trigger this
                                  * transition */
    state_t *dest;               /* The state this transition goes to */
    struct transition *next;     /* Next transition in a list */
    struct transition *next_fin; /* Next transition in the list of final
                                  * transitions for this NFA fragment */
};

typedef struct transition trans_t;

/* A state in a finite automaton */
struct state_str {
    int id;           /* Unique in the automaton in question */
    int done_num;     /* Indicates that this state is an end state
                       * (and which) */
    trans_t *trans;   /* Start of the list of transitions from this state */
    state_t *next;    /* Next in the list of states in the automaton */
};

/* A finite automaton (NFA or DFA) */
typedef struct {
    int n_states;    /* Number of states currently in the automaton */
    state_t *first;  /* First in the list of states in the automaton */
    state_t *last;   /* The current tail of the list of states */
} fa_t;

/* A fragment of an NFA corresponding to part of a regular expression */
typedef struct {
    fa_t *fa;       /* The NFA this fragment is a part of */
    state_t *init;  /* The initial state of this fragment */
    trans_t *final; /* The list of transitions out of this fragment */
} fa_frag_t;

void destroy_fa(fa_t *fa);
fa_t * single_regex_compile(regex_t *rx, state_t **initstate);
void print_fa(FILE *f, fa_t *fa, state_t *initstate);

#endif
