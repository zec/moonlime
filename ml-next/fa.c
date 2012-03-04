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

#ifndef ML_STRING_H
#define ML_STRING_H
#include <string.h>
#endif

#ifndef ML_LIMITS_H
#define ML_LIMITS_H
#include <limits.h>
#endif

#ifndef ML_UTILS_H
#include "utils.h"
#endif

#ifndef ML_REGEX_H
#include "regex.h"
#endif

/* Creates and sets up an FA object */
static fa_t * mkfa()
{
    fa_t *fa = malloc_or_die(1, fa_t);
    fa->n_states = 0;
    fa->first = fa->last = NULL;

    return fa;
}

/* Frees an FA object and all its subsidiary state and transition objects */
void destroy_fa(fa_t *fa)
{
    state_t *st, *nst;
    trans_t *tr, *ntr;

    for(st = fa->first; st != NULL; st = nst) {
        for(tr = st->trans; tr != NULL; tr = ntr) {
            ntr = tr->next;
            free(tr);
        }

        nst = st->next;
        free(st);
    }

    free(fa);
}

/* Makes a state in a particular finite automaton fa */
static state_t * mkstate(fa_t *fa)
{
    state_t *st = malloc_or_die(1, state_t);

    st->id = fa->n_states++;
    st->done_num = 0;
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

        tr = mktrans(init_st, subfrag->init);
        tr->is_nil = 1;

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
            dummy.data.enc = rx->data.num.enc;
            while(i < rx->data.num.max) {
                subfrag = regex_to_nfa_frag(&dummy, fa);
                for(p = frag->final; p != NULL; p = p->next_fin)
                    p->dest = subfrag->init;
                frag->final = subfrag->final;
                free(subfrag);
                ++i;
            }
        } else {
            dummy.type = R_STAR;
            dummy.data.enc = rx->data.num.enc;
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

fa_t * single_regex_compile(regex_t *rx, state_t **initstate)
{
    fa_t *fa = mkfa();
    fa_frag_t *frag;
    state_t *endstate;
    trans_t *p;

    frag = regex_to_nfa_frag(rx, fa);

    endstate = mkstate(fa);
    endstate->done_num = 1;

    for(p = frag->final; p != NULL; p = p->next_fin)
        p->dest = endstate;

    if(initstate != NULL)
        *initstate = frag->init;

    free(frag);

    return fa;
}

/* Here, fa_list_t.data1 is interpreted as a regex_t * */
fa_t * multi_regex_compile(fa_list_t *l)
{
    fa_t *fa = mkfa();
    fa_frag_t *frag;
    state_t *endstate;
    trans_t *t;
    int n = 0;

    while(l != NULL) {
        frag = regex_to_nfa_frag((regex_t *) l->data1, fa);

        endstate = mkstate(fa);
        l->done_num = endstate->done_num = ++n;
        for(t = frag->final; t != NULL; t = t->next_fin)
            t->dest = endstate;

        l->state = frag->init;

        free(frag);
        l = l->next;
    }

    return fa;
}

static void calc_nil_closure(state_t *s, char *bitset)
{
    trans_t *t;
    int id = s->id;

    bitset[id / CHAR_BIT] |= (1 << (id % CHAR_BIT));

    for(t = s->trans; t != NULL; t = t->next) {
        if(!t->is_nil)
            continue;
        id = t->dest->id;
        if((bitset[id / CHAR_BIT] & (1 << (id % CHAR_BIT))) == 0)
            calc_nil_closure(t->dest, bitset);
    }
}

static state_t * get_state(fa_list_t **state_map, len_string *state_set,
                           state_t **nfa, fa_t *dfa, int *is_new)
{
    fa_list_t *l;
    state_t *st;
    size_t i, k;
    int j, done_num = INT_MAX;

    if(is_new != NULL)
        *is_new = 0;

    for(l = *state_map; l != NULL; l = l->next)
        if(lstr_eq((len_string *) l->data1, state_set))
            return l->state;

    /* If we get here, the state isn't already in the list, so we make it: */
    if(is_new != NULL)
        *is_new = 1;
    st = mkstate(dfa);

    for(i = 0; i < state_set->len; ++i) {
        if(state_set->s[i] == 0)
            continue;

        for(j = 0; j < CHAR_BIT; ++j)
            if(state_set->s[i] & (1 << j)) {
                k = i * CHAR_BIT + j;
                if(nfa[k]->done_num != 0 && nfa[k]->done_num < done_num)
                    done_num = nfa[k]->done_num;
            }
    }
    if(done_num != INT_MAX)
        st->done_num = done_num;

    l = malloc_or_die(1, fa_list_t);
    l->state = st;
    l->data1 = lstrcat(state_set, NULL);
    l->next = *state_map;
    *state_map = l;

    return st;
}

static void set_or(char *a, const char *b, size_t str_size)
{
    size_t i;

    for(i = 0; i < str_size; ++i)
        a[i] |= b[i];
}

static state_t * nfa_to_dfa(len_string *state_set, fa_t *dfa,
                            fa_list_t **state_map, size_t str_size,
                            const char *nil_closures, state_t **nfa)
{
    int is_new, i, k;
    size_t j, n_unpacked = 0;
    state_t *dfa_init = get_state(state_map, state_set, nfa, dfa, &is_new);
    len_string *set = mk_blank_lstring(str_size);
    state_t **unpacked = malloc_or_die(str_size * CHAR_BIT, state_t *);
    state_t *st;
    trans_t *t;

    if(is_new) {

        for(j = 0; j < str_size; ++j) {
            if(!state_set->s[j])
                continue;
            for(k = 0; k < CHAR_BIT; ++k)
                if(state_set->s[j] & (1 << k))
                    unpacked[n_unpacked++] = nfa[j * CHAR_BIT + k];
        }

        for(i = 0; i < 256; ++i) {
            memset(set->s, 0, str_size);
            for(j = 0; j < n_unpacked; ++j) {
                for(t = unpacked[j]->trans; t != NULL; t = t->next)
                    if(!t->is_nil &&
                       t->cond[j / CHAR_BIT] & (1 << (j % CHAR_BIT))) {
                        k = t->dest->id;
                        set_or(set->s, nil_closures + (k * str_size), str_size);
                    }
            }

            st = nfa_to_dfa(state_set, dfa, state_map, str_size, nil_closures,
                            nfa);

            for(t = dfa_init->trans; t != NULL; t = t->next) {
                if(t->dest == st) {
                    t->cond[i / CHAR_BIT] |= 1 << (i % CHAR_BIT);
                    break;
                }
            }

            if(t == NULL) { /* No pre-existing transitions to st */
                t = mktrans(dfa_init, st);
                t->cond[i / CHAR_BIT] |= 1 << (i % CHAR_BIT);
                t->next = dfa_init->trans;
                dfa_init->trans = t;
            }
        }
    }

    free(set);
    free(unpacked);
    return dfa_init;
}

/* nfa_list->data2 is interpreted as a lstr_list_t * of start states, and
 * dfa_list->data1 is interpreted as a len_string * start-state name. */
fa_t * nfas_to_dfas(fa_t *nfa, fa_list_t *nfa_list, fa_list_t *dfa_list)
{
    fa_list_t *pn, *pd;
    state_t *initstate, *st;
    trans_t *t;
    fa_t *dfa = mkfa();
    state_t **nfa_arr;
    char *nil_closures;
    fa_list_t *state_map = NULL;
    fa_list_t *ptr, *next;
    size_t set_size;
    len_string *str;

    for(pd = dfa_list; pd != NULL; pd = pd->next) {
        pd->state = initstate = mkstate(nfa);

        for(pn = nfa_list; pn != NULL; pn = pn->next) {
            if(!lstr_in_list((len_string *) pd->data1,
                             (lstr_list_t *) pn->data2))
                continue;

            t = mktrans(initstate, pn->state);
            t->is_nil = 1;
        }
    }

    set_size = (nfa->n_states + CHAR_BIT - 1) / CHAR_BIT;
    nil_closures = malloc_or_die(set_size * nfa->n_states, char);
    memset(nil_closures, 0, set_size * nfa->n_states);

    for(st = nfa->first; st != NULL; st = st->next)
        calc_nil_closure(st, nil_closures + (st->id * set_size));

    nfa_arr = malloc_or_die(nfa->n_states, state_t *);
    for(st = nfa->first; st != NULL; st = st->next)
        nfa_arr[st->id] = st;

    for(pd = dfa_list; pd != NULL; pd = pd->next) {
        str = lstring_dupbuf(set_size,
                             nil_closures + (pd->state->id * set_size));
        pd->state = nfa_to_dfa(str, dfa, &state_map, set_size,
                               nil_closures, nfa_arr);
        free(str);
    }

    free(nil_closures);
    free(nfa_arr);
    for(ptr = state_map; ptr != NULL; ptr = next) {
        next = ptr->next;
        free(ptr);
    }

    return dfa;
}

void print_fa(FILE *f, fa_t *fa, state_t *initstate)
{
    state_t *st;
    trans_t *tr;
    int i, j, k;

    if(fa == NULL) {
        fputs("[NULL]\n", f);
        return;
    }

    for(st = fa->first; st != NULL; st = st->next) {
        fprintf(f, "State %d%s:\n", st->id, (st == initstate) ? " [init]" : "");
        if(st->done_num != 0)
            fprintf(f, "  done_num = %d\n", st->done_num);

        fputs("  Transitions:\n", f);
        for(tr = st->trans; tr != NULL; tr = tr->next) {
            if(tr->is_nil)
                fprintf(f, "    [nil] -> %d\n", (tr->dest != NULL) ?
                                                tr->dest->id : -1);
            else {
                fputs("    ", f);
                for(i = 0; i < CLASS_SZ; ++i) {
                    if(!tr->cond[i])
                        continue;
                    for(j = 0; j < ML_UINT_BIT; ++j) {
                        if(!(tr->cond[i] & (1 << j)))
                            continue;
                        k = (i * ML_UINT_BIT) + j;
                        if(k == 10)
                            fputs("\\n", f);
                        else if(k < 0x20 || k >= 0x7f)
                            fprintf(f, "\\x%02x", k & 0xff);
                        else if(k == ' ' || k == '\\')
                            fprintf(f, "\\%c", k);
                        else
                            fputc(k, f);
                    }
                }
                fprintf(f, " -> %d\n", (tr->dest != NULL) ? tr->dest->id : -1);
            }
        }
    }
}
