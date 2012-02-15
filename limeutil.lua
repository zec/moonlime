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
local string = string

setfenv(1, P)

function makeFileData()
  local x = {}
  x.header = '' -- code put at the top of the generated file
  x.currRegex = nil -- current regular-expression fragment being worked on
  x.regexStack = {} -- current stack of regular-expression fragments;
                    -- should only be of types 'concat' and 'option'!
  x.tokens = {} -- array of (token regex, action) pairs, in the order they
                -- appear in the file

  return x
end

-- Regular-expression fragments
re = {}

local charMetatable = { __index = {
  type = 'char'
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
      local a = string.find(t.set, x[k], 1, true)
      if a == nil then
        ins(y, k)
      end
    end
    t.set = t.set .. table.concat(y)
  end
} }

-- Matches any character from a to-be-specified set
function re.charClass()
  local x = { negated = false, set = '' }
  setmetatable(x, classMetatable)
  return x
end

local anyMetatable = { __index = {
  type = 'any'
} }

-- Matches any single non-newline character
function re.any()
  local x = { }
  setmetatable(x, anyMetatable)
  return x
end

local optionMetatable = { __index = {
  type = 'option',
  add = function(t, r) ins(t.enc, r) end
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
  add = function(t, r) ins(t.enc, r) end
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
  type = 'maybe'
} }

-- Matches zero or one repetition of the enclosed regular expression r
function re.maybe(r)
  local x = { enc = r }
  setmetatable(x, maybeMetatable)
  return x
end

local starMetatable = { __index = {
  type = 'star'
} }

-- Matches zero or more repetitions of the enclosed regular expression r
function re.star(r)
  local x = { enc = r }
  setmetatable(x, starMetatable)
  return x
end

local plusMetatable = { __index = {
  type = 'plus'
} }

-- Matches one or more repetitions of the enclosed regular expression r
function re.plus(r)
  local x = { enc = r }
  setmetatable(x, plusMetatable)
  return x
end

local numMetatable = { __index = {
  type = 'num'
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
  type = 'zero'
} }

-- Matches a zero-length string
function re.zero()
  local x = { }
  setmetatable(x, zeroMetatable)
  return x
end

return P
