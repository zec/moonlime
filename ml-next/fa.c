/*
 * fa.c: Stuff relating to finite automata.
 *
 * Copyright © 2012 Zachary Catlin. See LICENSE for terms.
 */

#include "fa.h"

#ifndef ML_STDLIB_H
#define ML_STDLIB_H
#include <stdlib.h>
#endif

#ifndef ML_STDIO_H
#define ML_STDIO_H
#include <stdio.h>
#endif

#ifndef ML_UTILS_H
#include "utils.h"
#endif

#ifndef ML_REGEX_H
#include "regex.h"
#endif

/* Makes a state in a particular finite automaton fa */
static state_t * mkstate(fa_t *fa)
{
    state_t *st = malloc_or_die(1, state_t);

    st->id = fa->n_states++;
    st->trans = NULL;
    st->next = NULL;

    if(fa->first == NULL)
        fa->first = fa->last = st;
    else {
        fa->last->next = st;
        fa->last = st;
    }

    return st;
}

/* Makes a transition from a state s1 to a state s2; returns the transition
 * object for further modification. */
static trans_t * mktrans(state_t *s1, state_t *s2)
{
    size_t i;
    trans_t *tr = malloc_or_die(1, trans_t);

    tr->is_nil = 0;

    for(i = 0; i < CLASS_SZ; ++i)
        tr->cond[i] = 0;

    tr->dest = s2;
    tr->next_fin = NULL;
    tr->next = s1->trans;
    s1->trans = tr;

    return tr;
}

/* Converts the regex tree rx into an NFA fragment inside the NFA fa; returns
 * the fragment object */
static fa_frag_t * regex_to_nfa_frag(regex_t *rx, fa_t *fa)
{
    fa_frag_t *frag = malloc_or_die(1, fa_frag_t);
    fa_frag_t *subfrag;
    state_t *init_st = mkstate(fa);
    trans_t *tr = NULL;
    int i;

    frag->fa = fa;
    frag->init = init_st;
    frag->final = NULL;

    switch(rx->type) {
      case R_CHAR:
        i = rx->data.c;
        tr = mktrans(init_st, NULL);
        tr->cond[i / ML_UINT_BIT] = 1 << (i % ML_UINT_BIT);
        frag->final = tr;
        break;

      case R_CLASS:
        tr = mktrans(init_st, NULL);
        if(!rx->data.cls.is_inverted) {
            for(i = 0; i < CLASS_SZ; ++i)
                tr->cond[i] = rx->data.cls.set[i];
        } else {
            for(i = 0; i < CLASS_SZ; ++i)
                tr->cond[i] = ~rx->data.cls.set[i];
        }
        frag->final = tr;
        break;

      case R_ANY:
        tr = mktrans(init_st, NULL);
        for(i = 0; i < CLASS_SZ; ++i)
            tr->cond[i] = ~0;
        frag->final = tr;
        break;

      case R_OPTION:
        ;
        break;

      case R_CONCAT:
        break;

      case R_MAYBE:
        break;

      case R_STAR:
        break;

      case R_PLUS:
        break;

      case R_NUM:
        break;

      case R_ZERO:
        tr = mktrans(init_st, NULL);
        tr->is_nil = 1;
        frag->final = tr;
        break;

      case R_PAREN:
        fprintf(stderr, __FILE__ ":%d: R_PAREN shouldn\'t be in a regex!\n",
                __LINE__);
        exit(1);
    }

    return frag;
}
