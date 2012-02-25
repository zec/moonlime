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
  int curr_state;
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

void * %PREFIX%Init( void * (*alloc)(size_t), void (*unalloc)(void *) )
{
    moonlime_state *ms;

    if(alloc == NULL || unalloc == NULL)
        return NULL;

    ms = alloc(sizeof(moonlime_state));

    if(ms == NULL)
        return NULL;

    ms->is_in_error = 0;
    ms->curr_state = INIT_STATE;
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

static void moonlime_action(int done_num, const char *yytext, size_t yylen);

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

int %PREFIX%Read( void *lexer, char *input, size_t len )
{
    int done_relexing, i;
    char *end = input + len;
    moonlime_state *ms = lexer;

    if(ms == NULL || ms->is_in_error)
        return 0;

    while(input < end) {
        if(!run_char(ms, *input, 1, ms->string_len + 1)) { /* past a pattern */
            if(ms->is_in_error)
                return 0;
            if(ms->last_done_num == 0) { /* no pattern matches buf */
                ms->is_in_error = 1;
                return 0;
            }
            moonlime_action(ms->last_done_num, ms->buf, ms->last_done_len);

            done_relexing = 0;
            while(!done_relexing) {
relex_loop:
                for(i = ms->last_done_len; i < ms->string_len; ++i)
                    ms->buf[i - ms->last_done_len] = ms->buf[i];
                ms->string_len -= ms->last_done_len;
                ms->last_done_len = ms->last_done_num = 0;
                ms->curr_state = INIT_STATE;

                i = 0;
                while(i < ms->string_len) {
                    if(!run_char(ms, ms->buf[i], 0, i)) {
                        if(!ms->is_in_error && ms->last_done_num == 0)
                            ms->is_in_error = 1;
                        if(ms->is_in_error)
                            return 0;
                        moonlime_action(ms->last_done_num, ms->buf,
                                        ms->last_done_len);
                        goto relex_loop;
                    }
                    ++i;
                }

                done_relexing = 1;
            }
        }
        ++input;
    }

    return 1;
}

static void moonlime_action(int done_num, const char *yytext, size_t yylen)
{
    switch(done_num) {
]]

local postamble = [[
    }
}
]]

-- Writes out the C code corresponding to the parsed-file object inf and
-- the DFA fa to file f
function write(inf, fa, f)
  f:write(preamble)
  local next_trans = 0
  local state_tbl = limefa.makeTable(fa)
  f:write('#define INIT_STATE ' .. fa.id .. '\n')
  local ml_x = 'moonlime_fa ml_x[' .. (table.maxn(state_tbl) + 1) .. '] = {\n'
  local ml_y = 'moonlime_trans ml_y[] = {\n'
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
    if v.done_num == nil then
      ml_x = ml_x .. '0,' .. next_trans .. ','
    else
      ml_x = ml_x .. v.done_num .. ',' .. next_trans .. ','
    end

    for i = 1,table.maxn(v.transitions) do
      ml_y = ml_y .. '{' .. mkBitset(v.transitions[i].cond) .. ','
                  .. v.transitions[i].dest.id .. '},\n'
      next_trans = next_trans + 1
    end

    ml_x = ml_x .. next_trans .. '},\n'
  end

  f:write(ml_x, '};\n\n')
  f:write(ml_y, '};\n\n')

  local lexer = string.gsub(genericLexer, '%%PREFIX%%', inf.prefix)
  lexer = string.gsub(lexer, '%%HEADER%%', inf.header)
  f:write(lexer)

  for i = 1,table.maxn(inf.tokens) do
    f:write('case ', i, ': {\n', inf.tokens[i][2], '\n}\n')
  end

  f:write(postamble)
end

return P
