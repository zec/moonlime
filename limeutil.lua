-- limeparse.lua: Parses the input file
-- Copyright © 2012 Zachary Catlin. See LICENSE for terms.

-- The package table
local P = {}
if _REQUIREDNAME == nil then
  limeutil = P
else
  _G[_REQUIREDNAME] = P
end

-- Imports
local setmetatable = setmetatable
local ins = table.insert
local remove = table.remove
local maxn = table.maxn
local string = string
local pairs = pairs
local concat = table.concat
local error = error

setfenv(1, P)

function makeFileData()
  local x = {}
  x.prefix = 'Lexer' -- prefix put in front of generated functions,
                     -- exported structures
  x.header = '' -- code put at the top of the generated file
  x.currRegex = nil -- current regular-expression fragment being worked on
  x.regexStack = {} -- current stack of regular-expression fragments;
                    -- should only be of types 'concat' and 'option'!
  x.tokens = {} -- array of (token regex, action) pairs, in the order they
                -- appear in the file
  x.states = {} -- table with start-state names as keys
  x.initState = nil -- initial start state of lexer
  x.currStStates = {} -- table of start states that apply to the current regex;
                      -- the states are the keys of the table

  return x
end

-- Regular-expression fragments
re = {}

local charMetatable = { __index = {
  type = 'char',
  optimize = function(r)
    return r
  end
} }

-- Matches a specific character
function re.char(c)
  local x = { char = c }
  setmetatable(x, charMetatable)
  return x
end

local classMetatable = { __index = {
  type = 'class',
  add = function(t, s)
    local x, y = {}, {}
    for i = 1,string.len(s) do
      x[string.sub(s, i, i)] = true
    end
    for k in pairs(x) do
      local a = string.find(t.set, k, 1, true)
      if a == nil then
        ins(y, k)
      end
    end
    t.set = t.set .. concat(y)
  end,
  optimize = function(r)
    return r
  end
} }

-- Matches any character from a to-be-specified set
function re.charClass()
  local x = { negated = false, set = '' }
  setmetatable(x, classMetatable)
  return x
end

local anyMetatable = { __index = {
  type = 'any',
  optimize = function(r)
    return r
  end
} }

-- Matches any single non-newline character
function re.any()
  local x = { }
  setmetatable(x, anyMetatable)
  return x
end

local optionMetatable = { __index = {
  type = 'option',
  add = function(t, r) ins(t.enc, r) end,
  optimize = function(r)
    local opt, noZero, i = {}, true, 1

    for j = 1,maxn(r.enc) do
      opt[j] = r.enc[j]:optimize()
    end

    while i <= maxn(opt) do
      while opt[i] ~= nil and opt[i].type == 'zero' do
        remove(opt, i)
        noZero = false
      end
      i = i + 1
    end

    if maxn(opt) == 0 then
      return re.zero()
    end

    local newr = re.option()

    if maxn(opt) == 1 then
      newr = opt[1]
    else
      for j = 1,maxn(opt) do
        newr:add(opt[j])
      end
    end

    if not noZero then
      newr = re.maybe(newr)
    end

    return newr
  end
} }

-- Matches any of several enclosed regular expressions. r is an optional
-- argument; if it is given, it is the first regular expression in the option.
function re.option(r)
  local x = { enc = { } }
  if r ~= nil then
    x.enc[1] = r
  end
  setmetatable(x, optionMetatable)
  return x
end

local concatMetatable = { __index = {
  type = 'concat',
  add = function(t, r) ins(t.enc, r) end,
  optimize = function(r)
    local i = 1
    local opt = {}
    for j = 1,maxn(r.enc) do
      opt[j] = r.enc[j]:optimize()
    end

    while i <= maxn(opt) do
      while opt[i] ~= nil and opt[i].type == 'zero' do
        remove(opt, i)
      end
      i = i + 1
    end

    if maxn(opt) == 0 then
      return re.zero()
    elseif maxn(opt) == 1 then
      return opt[1]
    end

    local newr = re.concat()
    for j = 1,maxn(opt) do
      newr:add(opt[j])
    end
    return newr
  end
} }

-- Matches the concatentation of the enclosed regular expressions. r is an
-- optional argument; if it is given, it is the first regular expression in
-- the concatenation.
function re.concat(r)
  local x = { enc = { } }
  if r ~= nil then
    x.enc[1] = r
  end
  setmetatable(x, concatMetatable)
  return x
end

local maybeMetatable = { __index = {
  type = 'maybe',
  optimize = function(r)
    local opt = r.enc:optimize()

    if opt.type == 'maybe' or opt.type == 'star' then
      return opt
    elseif opt.type == 'plus' then
      return re.star(opt.enc)
    end

    return re.maybe(opt)
  end
} }

-- Matches zero or one repetition of the enclosed regular expression r
function re.maybe(r)
  local x = { enc = r }
  setmetatable(x, maybeMetatable)
  return x
end

local starMetatable = { __index = {
  type = 'star',
  optimize = function(r)
    local opt = r.enc:optimize()

    if opt.type == 'maybe' or opt.type == 'star' or opt.type == 'plus' then
      return re.star(opt.enc)
    end

    return re.star(opt)
  end
} }

-- Matches zero or more repetitions of the enclosed regular expression r
function re.star(r)
  local x = { enc = r }
  setmetatable(x, starMetatable)
  return x
end

local plusMetatable = { __index = {
  type = 'plus',
  optimize = function(r)
    local opt = r.enc:optimize()

    if opt.type == 'maybe' then
      return re.star(opt.enc)
    elseif opt.type == 'plus' or opt.type == 'star' then
      return opt
    end

    return re.plus(opt)
  end
} }

-- Matches one or more repetitions of the enclosed regular expression r
function re.plus(r)
  local x = { enc = r }
  setmetatable(x, plusMetatable)
  return x
end

local numMetatable = { __index = {
  type = 'num',
  optimize = function(r)
    local opt = r.enc:optimize()

    if opt.type == 'maybe' then
      return re.num(opt.enc, nil, r.max)
    elseif opt.type == 'star' then
      return opt
    elseif opt.type == 'plus' then
      return re.num(opt.enc, r.min, nil)
    end

    return re.num(opt, r.min, r.max)
  end
} }

-- Matches a number of repetitions of the enclosed regular expression r;
-- the minimum and/or maximum number of repetitions is given.
function re.num(r, min, max)
  local x = { enc = r }
  x.min = min
  x.max = max
  setmetatable(x, numMetatable)
  return x
end

local zeroMetatable = { __index = {
  type = 'zero',
  optimize = function(r)
    return r
  end
} }

-- Matches a zero-length string
function re.zero()
  local x = { }
  setmetatable(x, zeroMetatable)
  return x
end

local parenMetatable = { __index = {
  type = 'paren',
  optimize = function(r)
    error('paren "regular expression fragment" in an actual tree!')
  end
} }

-- Matches nothing; this should only exist on regexStack to delimit a paren
-- expression
function re.paren()
  local x = { }
  setmetatable(x, parenMetatable)
  return x
end

function escapeString(s)
  local x = ''
  for i = 1,string.len(s) do
    local c = string.byte(s, i)

    if c == string.byte('\\') then
      x = x .. '\\\\'
    elseif c == 10 then
      x = x .. '\\n'
    elseif c <= 31 or c >= 127 then
      x = x .. string.format('\\x%02x', c)
    else
      x = x .. string.char(c)
    end
  end

  return x
end

-- Prints a human-readable representation of regular-expression tree r
-- to file f
function printRegex(f, r)
  local function treeWalker(f, re, sp)
    if re.type == 'char' then
      f:write(sp .. 'char: [' .. escapeString(re.char) .. ']\n')
    elseif re.type == 'class' then
      f:write(sp .. 'class: ')
      if re.negated then
        f:write('^')
      end
      f:write('[' .. escapeString(re.set) .. ']\n')
    elseif re.type == 'any' or re.type == 'zero' then
      f:write(sp .. re.type .. '\n')
    elseif re.type == 'maybe' or re.type == 'star' or re.type == 'plus' then
      f:write(sp .. re.type .. '\n')
      treeWalker(f, re.enc, sp .. '  ')
    elseif re.type == 'num' then
      f:write(sp .. 'num[')
      if re.min ~= nil then
        f:write(re.min)
      end
      f:write(',')
      if re.max ~= nil then
        f:write(re.max)
      end
      f:write(']\n')
      treeWalker(f, re.enc, sp .. '  ')
    elseif re.type == 'concat' or re.type == 'option' then
      f:write(sp .. re.type .. '\n')
      sp = sp .. '  '
      for i = 1,maxn(re.enc) do
        treeWalker(f, re.enc[i], sp)
      end
    else
      f:write(sp .. '[UNKNOWN]\n')
    end
  end

  treeWalker(f, r, '')
end

return P
