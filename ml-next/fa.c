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
    trans_t *p;
    int i;
    regex_t dummy;

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
        for(i = 0; i < rx->data.list.n_enc; ++i) {
            subfrag = regex_to_nfa_frag(rx->data.list.enc[i], fa);
            tr = mktrans(init_st, subfrag->init);
            tr->is_nil = 1;
            /* Prepend subfrag's outward-transition list to frag's */
            p = subfrag->final;
            while(p != NULL && p->next_fin != NULL)
                p = p->next_fin;
            if(p != NULL) {
                p->next_fin = frag->final;
                frag->final = subfrag->final;
            }
            free(subfrag);
        }
        break;

      case R_CONCAT:
        tr = mktrans(init_st, NULL);
        tr->is_nil = 1;
        frag->final = tr;

        for(i = 0; i < rx->data.list.n_enc; ++i) {
            subfrag = regex_to_nfa_frag(rx->data.list.enc[i], fa);
            /* Take frag's current outward-transition list and point them to
             * subfrag's initial state */
            for(p = frag->final; p != NULL; p = p->next_fin)
                p->dest = subfrag->init;
            /* Make subfrag's outward-transition list frag's new
             * outward-transition list */
            frag->final = subfrag->final;
            free(subfrag);
        }
        break;

      case R_MAYBE:
        subfrag = regex_to_nfa_frag(rx->data.enc, fa);
        tr = mktrans(init_st, subfrag->init);
        tr->is_nil = 1;

        tr = mktrans(init_st, NULL);
        tr->is_nil = 1;
        tr->next_fin = subfrag->final;
        frag->final = tr;

        free(subfrag);
        break;

      case R_STAR:
        subfrag = regex_to_nfa_frag(rx->data.enc, fa);
        tr = mktrans(init_st, subfrag->init);
        tr->is_nil = 1;

        for(p = subfrag->final; p != NULL; p = p->next_fin)
            p->dest = init_st;

        tr = mktrans(init_st, NULL);
        tr->is_nil = 1;
        frag->final = tr;

        free(subfrag);
        break;

      case R_PLUS:
        subfrag = regex_to_nfa_frag(rx->data.enc, fa);

        /* "init_st" is a bit of a misnomer in this case... */
        frag->init = subfrag->init;

        for(p = subfrag->final; p != NULL; p = p->next_fin)
            p->dest = init_st;

        tr = mktrans(init_st, NULL);
        tr->is_nil = 1;
        frag->final = tr;

        free(subfrag);
        break;

      case R_NUM:
        i = 0;

        tr = mktrans(init_st, NULL);
        tr->is_nil = 1;
        frag->final = tr;

        if(rx->data.num.min != -1) {
            while(i < rx->data.num.min) {
                subfrag = regex_to_nfa_frag(rx->data.num.enc, fa);
                for(p = frag->final; p != NULL; p = p->next_fin)
                    p->dest = subfrag->init;
                frag->final = subfrag->final;
                free(subfrag);
                ++i;
            }
        }

        if(rx->data.num.max != -1) {
            dummy.type = R_MAYBE;
            dummy.enc = rx->data.num.enc;
            while(i < rx->data.max) {
                subfrag = regex_to_nfa_frag(&dummy, fa);
                for(p = frag->final; p != NULL; p = p->next_fin)
                    p->dest = subfrag->init;
                frag->final = subfrag->final;
                free(subfrag);
                ++i;
            }
        } else {
            dummy.type = R_STAR;
            dummy.enc = rx->data.num.enc;
            subfrag = regex_to_nfa_frag(&dummy, fa);
            for(p = frag->final; p != NULL; p = p->next_fin)
                p->dest = subfrag->init;
            frag->final = subfrag->final;
            free(subfrag);
        }
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
