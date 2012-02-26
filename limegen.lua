-- limegen.lua: Turns a parsed-file object and the corresponding DFA into
-- a C file
--
-- Copyright © 2012 Zachary Catlin. See LICENSE for terms.

local P = {}
if _REQUIREDNAME == nil then
  limegen = P
else
  _G[_REQUIREDNAME] = P
end

-- Imports
local table = table
local pairs = pairs
local string = string
require('limefa')
local limefa = limefa

-- Make the package table this file's global environment
-- (for safety and ease of declaration)
setfenv(1, P)

local preamble = [[

#include <stdlib.h>

typedef struct {
  int done_num;
  int trans_start;
  int trans_end;
} moonlime_fa;

typedef struct {
  unsigned char transset[32];
  int dest_state;
} moonlime_trans;

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
} moonlime_state;

]]

local genericLexer = [[

%HEADER%

%TOP%

void * %PREFIX%Init( void * (*alloc)(size_t), void (*unalloc)(void *) )
{
    moonlime_state *ms;

    if(alloc == NULL || unalloc == NULL)
        return NULL;

    ms = alloc(sizeof(moonlime_state));

    if(ms == NULL)
        return NULL;

    ms->is_in_error = 0;
    ms->curr_state = init_states[0];
    ms->curr_start_state = 0;
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
    moonlime_state *ms = lexer;

    if(ms == NULL)
        return;

    if(ms->buf != NULL && ms->buf != ms->start_buf) {
        ms->unalloc(ms->buf);
    }

    ms->unalloc(ms);
}

static void moonlime_action(int done_num, const char *yytext, size_t yylen,
                            int *yy_start_state);

static int run_char(moonlime_state *ms, char c, int add_to_buf, int len)
{
    int curr_trans, end_trans, c_idx, c_mask, next_state, i;
    char *new_buf;

    curr_trans = ml_x[ms->curr_state].trans_start;
    end_trans = ml_x[ms->curr_state].trans_end;

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
        if(ml_y[curr_trans].transset[c_idx] & c_mask) {
            ms->curr_state = next_state = ml_y[curr_trans].dest_state;

            if(ml_x[next_state].done_num) {
                ms->last_done_num = ml_x[next_state].done_num;
                ms->last_done_len = len;
            }
            return 1;
        }
        ++curr_trans;
    }

    return 0;
}

static void reset_state(moonlime_state *ms)
{
    int i;

    for(i = ms->last_done_len; i < ms->string_len; ++i)
        ms->buf[i - ms->last_done_len] = ms->buf[i];
    ms->string_len -= ms->last_done_len;
    ms->last_done_len = ms->last_done_num = 0;
    ms->curr_state = init_states[ms->curr_start_state];
}

int %PREFIX%Read( void *lexer, char *input, size_t len )
{
    int done_relexing, i;
    char *end = input + len;
    moonlime_state *ms = lexer;

    if(ms == NULL || ms->is_in_error)
        return 0;

    if(len == 0) { /* Signifies EOF */
        if(ms->string_len == 0)
            return 1;

        if(ms->last_done_num == 0) {
            ms->is_in_error = 1;
            return 0;
        }

        moonlime_action(ms->last_done_num, ms->buf, ms->last_done_len,
                        &(ms->curr_start_state));
        reset_state(ms);

        while(ms->string_len > 0) {
            for(i = 0; i < ms->string_len; ++i) {
                if(!run_char(ms, ms->buf[i], 0, i+1) ||
                   i == ms->string_len - 1) {
                    if(ms->is_in_error || ms->last_done_num == 0) {
                        ms->is_in_error = 1;
                        return 0;
                    }

                    moonlime_action(ms->last_done_num, ms->buf,
                                    ms->last_done_len,
                                    &(ms->curr_start_state));
                    reset_state(ms);
                    break;
                }
            }
        }

        return 1;
    }

    while(input < end) {
        if(!run_char(ms, *input, 1, ms->string_len + 1)) { /* past a pattern */
            if(ms->is_in_error)
                return 0;
            if(ms->last_done_num == 0) { /* no pattern matches buf */
                ms->is_in_error = 1;
                return 0;
            }
            moonlime_action(ms->last_done_num, ms->buf, ms->last_done_len,
                            &(ms->curr_start_state));
            reset_state(ms);

            /* Re-lex remaining part of the buffer */
            done_relexing = 0;
            while(ms->string_len > 0 && !done_relexing) {
                i = 0;
                while(i < ms->string_len) {
                    if(!run_char(ms, ms->buf[i], 0, i+1)) {
                        if(!ms->is_in_error && ms->last_done_num == 0)
                            ms->is_in_error = 1;
                        if(ms->is_in_error)
                            return 0;

                        moonlime_action(ms->last_done_num, ms->buf,
                                        ms->last_done_len,
                                        &(ms->curr_start_state));
                        reset_state(ms);
                        break;
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

#define YYSTART(x) do { *yy_start_state = ML_STATE_ ## x ; } while(0)

static void moonlime_action(int done_num, const char *yytext, size_t yylen,
                            int *yy_start_state)
{
    switch(done_num) {
]]

local postamble = [[
    }

    if((*yy_start_state < 0) || (*yy_start_state > ML_MAX_STATE))
        *yy_start_state = 0;
}
]]

local genericHeader = [[
#ifndef ML_%PREFIX%_HEADER
#define ML_%PREFIX%_HEADER

%HEADER%


void * %PREFIX%Init( void * (*alloc)(size_t), void (*unalloc)(void *) );
void %PREFIX%Destroy( void *lexer );
int %PREFIX%Read( void *lexer, char *input, size_t len );

#endif
]]

-- Writes out the C code corresponding to the parsed-file object inf and
-- the table of DFAs fa to file f, and a header file to fheader
function write(inf, fa, f, fheader)
  f:write(preamble)
  local next_trans = 0
  local state_tbl = limefa.makeSuperTable(fa)

  local ml_x = 'moonlime_fa ml_x[' .. (table.maxn(state_tbl) + 1) .. '] = {\n'
  local ml_y = 'moonlime_trans ml_y[] = {\n'
  local ml_st = 'int init_states[] = {\n'
  local ml_st_defs = ''

  local function mkBitset(str)
    local y = '{'
    for i = 0,248,8 do
      local n = 0
      for j = 0,7 do
        if string.find(str, string.char(i+j), 1, true) then
          n = n + (2^j)
        end
      end
      y = y .. n .. ','
    end

    return y .. '}'
  end

  for k,v in pairs(state_tbl) do
    ml_x = ml_x .. '[' .. k .. '] = {'
    if v.doneNum == nil then
      ml_x = ml_x .. '0,' .. next_trans .. ','
    else
      ml_x = ml_x .. v.doneNum .. ',' .. next_trans .. ','
    end

    for i = 1,table.maxn(v.transitions) do
      ml_y = ml_y .. '{' .. mkBitset(v.transitions[i].cond) .. ','
                  .. v.transitions[i].dest.id .. '},\n'
      next_trans = next_trans + 1
    end

    ml_x = ml_x .. next_trans .. '},\n'
  end

  ml_st = ml_st .. fa[inf.initState].id .. ',\n'
  ml_st_defs = '#define ML_STATE_' .. inf.initState .. ' 0\n'
  local startStateNum = 1
  for k,v in pairs(inf.states) do
    if k ~= inf.initState then
      ml_st = ml_st .. fa[k].id .. ',\n'
      ml_st_defs = ml_st_defs .. '#define ML_STATE_' .. k
                   .. ' ' .. startStateNum ..'\n'
      startStateNum = startStateNum + 1
    end
  end

  f:write(ml_x, '};\n\n')
  f:write(ml_y, '};\n\n')
  f:write(ml_st, '};\n\n')
  f:write(ml_st_defs, '\n')
  f:write('#define ML_MAX_STATE ', startStateNum - 1, '\n')

  local lexer = string.gsub(genericLexer, '%%PREFIX%%', inf.prefix)
  lexer = string.gsub(lexer, '%%HEADER%%', inf.header)
  lexer = string.gsub(lexer, '%%TOP%%', inf.topCode)
  f:write(lexer)

  for i = 1,table.maxn(inf.tokens) do
    f:write('case ', i, ': {\n', inf.tokens[i][2], '\n} break;\n')
  end

  f:write(postamble)

  local headerfile = string.gsub(genericHeader, '%%PREFIX%%', inf.prefix)
  headerfile = string.gsub(headerfile, '%%HEADER%%', inf.header)
  fheader:write(headerfile)
end

return P
