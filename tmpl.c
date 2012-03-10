/* The default lexical-scanner template for Moonlime. Terms under which the
 * generated code may be distributed, modified, etc. are provided by the
 * lexer-writer below. */

%HEADER%

%TOP%

#include <stdlib.h>

typedef struct {
  int done_num;
  int trans_start;
  int trans_end;
} yyml_fa;

typedef struct {
  unsigned char transset[32];
  int dest_state;
} yyml_trans;

typedef struct {
  int is_in_error;
  int curr_state; /* state of the DFA */
  int curr_start_state; /* which DFA to use... */
  int last_done_num;
  int last_done_len;
  size_t string_len;
  size_t curr_buf_size;
  void * (*alloc)(size_t);
  void (*unalloc)(void *);
  char *buf;
  char start_buf[64];
} yyml_state;

static yyml_fa yy_x[] = {
%FASTATES%
};

static yyml_trans yy_y[] = {
%FATRANS%
};

static int yy_init_states[] = {
%FASTARTS%
};

%START_STATE_DEFS%

void * %PREFIX%Init( void * (*alloc)(size_t), void (*unalloc)(void *) )
{
    yyml_state *ms;

    if(alloc == NULL || unalloc == NULL)
        return NULL;

    ms = alloc(sizeof(yyml_state));

    if(ms == NULL)
        return NULL;

    ms->is_in_error = 0;
    ms->curr_state = yy_init_states[YY_INITSTATE];
    ms->curr_start_state = YY_INITSTATE;
    ms->last_done_num = 0;
    ms->last_done_len = 0;

    ms->string_len = 0;
    ms->curr_buf_size = 64;
    ms->buf = ms->start_buf;

    ms->alloc = alloc;
    ms->unalloc = unalloc;

    return ms;
}

void %PREFIX%Destroy( void *lexer )
{
    yyml_state *ms = lexer;

    if(ms == NULL)
        return;

    if(ms->buf != NULL && ms->buf != ms->start_buf) {
        ms->unalloc(ms->buf);
    }

    ms->unalloc(ms);
}

static void yymoonlime_action(int done_num, const char *yytext, size_t yylen,
                              int *yy_start_state);

static int yyrun_char(yyml_state *ms, char c, int add_to_buf, int len)
{
    int curr_trans, end_trans, c_idx, c_mask, next_state, i;
    char *new_buf;

    curr_trans = yy_x[ms->curr_state].trans_start;
    end_trans = yy_x[ms->curr_state].trans_end;

    c_idx = ((unsigned char) c) >> 3;
    c_mask = 1 << (c & 7);

    if(add_to_buf) {
        if(ms->string_len >= ms->curr_buf_size - 1) {
                if((new_buf = ms->alloc(ms->curr_buf_size * 2)) == NULL) {
                    ms->is_in_error = 1;
                return 0;
            }
            for(i = 0; i < ms->string_len; ++i)
                new_buf[i] = ms->buf[i];
            ms->curr_buf_size *= 2;
            if(ms->buf != ms->start_buf)
                ms->unalloc(ms->buf);
            ms->buf = new_buf;
        }
        ms->buf[ms->string_len++] = c;
    }

    while(curr_trans < end_trans) {
        if(yy_y[curr_trans].transset[c_idx] & c_mask) {
            ms->curr_state = next_state = yy_y[curr_trans].dest_state;

            if(yy_x[next_state].done_num) {
                ms->last_done_num = yy_x[next_state].done_num;
                ms->last_done_len = len;
            }
            return 1;
        }
        ++curr_trans;
    }

    return 0;
}

static void yyreset_state(yyml_state *ms)
{
    int i;

    for(i = ms->last_done_len; i < ms->string_len; ++i)
        ms->buf[i - ms->last_done_len] = ms->buf[i];
    ms->string_len -= ms->last_done_len;
    ms->last_done_len = ms->last_done_num = 0;
    ms->curr_state = yy_init_states[ms->curr_start_state];
}

int %PREFIX%Read( void *lexer, char *input, size_t len )
{
    int done_relexing, i;
    char *end = input + len;
    yyml_state *ms = lexer;

    if(ms == NULL || ms->is_in_error)
        return 0;

    if(len == 0) { /* Signifies EOF */
        if(ms->string_len == 0)
            return 1;

        if(ms->last_done_num == 0) {
            ms->is_in_error = 1;
            return 0;
        }

        yymoonlime_action(ms->last_done_num, ms->buf, ms->last_done_len,
                          &(ms->curr_start_state));
        yyreset_state(ms);

        while(ms->string_len > 0) {
            for(i = 0; i < ms->string_len; ++i) {
                if(!yyrun_char(ms, ms->buf[i], 0, i+1) ||
                   i == ms->string_len - 1) {
                    if(ms->is_in_error || ms->last_done_num == 0) {
                        ms->is_in_error = 1;
                        return 0;
                    }

                    yymoonlime_action(ms->last_done_num, ms->buf,
                                      ms->last_done_len,
                                      &(ms->curr_start_state));
                    yyreset_state(ms);
                    break;
                }
            }
        }

        return 1;
    }

    while(input < end) {
        if(!yyrun_char(ms, *input, 1, ms->string_len + 1)) { /* past pattern */
            if(ms->is_in_error)
                return 0;
            if(ms->last_done_num == 0) { /* no pattern matches buf */
                ms->is_in_error = 1;
                return 0;
            }
            yymoonlime_action(ms->last_done_num, ms->buf, ms->last_done_len,
                              &(ms->curr_start_state));
            yyreset_state(ms);

            /* Re-lex remaining part of the buffer */
            done_relexing = 0;
            while(ms->string_len > 0 && !done_relexing) {
                i = 0;
                while(i < ms->string_len) {
                    if(!yyrun_char(ms, ms->buf[i], 0, i+1)) {
                        if(!ms->is_in_error && ms->last_done_num == 0)
                            ms->is_in_error = 1;
                        if(ms->is_in_error)
                            return 0;

                        yymoonlime_action(ms->last_done_num, ms->buf,
                                          ms->last_done_len,
                                          &(ms->curr_start_state));
                        yyreset_state(ms);
                        i = 0;
                        continue;
                    }
                    ++i;
                }

                if(i == ms->string_len)
                    done_relexing = 1;
            }
        }
        ++input;
    }

    return 1;
}

#define YYSTART(x) do { *yy_start_state = YY_STATE_ ## x ; } while(0)

static void yymoonlime_action(int done_num, const char *yytext, size_t yylen,
                              int *yy_start_state)
{
    switch(done_num) {
%ACTIONS%
    }

    if((*yy_start_state < 0) || (*yy_start_state > YY_MAXSTATE))
        *yy_start_state = YY_INITSTATE;
}
