-- limefa.lua: Converts regex trees to nondeterminstic finite automata (NFAs),
-- and then thence to a deterministic finite automaton (DFA).
--
-- Copyright © 2012 Zachary Catlin. See LICENSE for terms.

-- The package table
local P = {}
if _REQUIREDNAME == nil then
  limefa = P
else
  _G[_REQUIREDNAME] = P
end

-- Imports
local table = table
local string = string
require('limeutil')
local lu = limeutil

setfenv(1, P)

-- A state in a DFA or an NFA; state is translate-global state, and doneNum
-- is either a number associated with termination-state preference or nil.
local function makeState(state, doneNum)
  local x = {}

  x.id = state.nextId
  state.nextId = state.nextId + 1
  x.transitions = {}
  x.doneNum = doneNum

  return x
end

-- Adds a transition on character class t (can be nil for NFAs) from state s
-- (can't be nil!) to state r (can be nil for NFA fragments); returns the
-- object representing the transition.
local function makeTransition(s, t, r)
  local trans = {}
  trans.cond = t
  trans.dest = r

  table.insert(s.transitions, trans)
  return trans
end

local nfaFragMeta = { __index = {
  addFinal = function(frag, t)
    table.insert(frag.finalTrans, t)
  end
} }

-- Creates an NFA fragment, with a start state and a list of final
-- transitions (used to connect and compose fragments); state is the
-- translate-global state, and the fragment is returned.
local function makeNFAfrag(state)
  local x = {}
  x.initState = makeState(state)
  x.finalTrans = {}

  return x
end

-- Turn a regex tree into an NFA fragment; returns the NFA fragment. state
-- is the translate-global state; re is the tree.
local function regexToNFAfrag(state, re)
  local frag = makeNFAfrag(state)

  if re == nil or re.type == 'zero' then
    frag:addFinal(makeTransition(frag.initState, nil, nil))

  elseif re.type == 'char' then
    frag:addFinal(makeTransition(frag.initState, re.char, nil))

  elseif re.type == 'class' then
    local t
    if not re.negated then
      t = makeTransition(frag.initState, re.set, nil)
    else
      local set = ''
      for i = 1,255 do
        local c = string.char(i)
        local a = string.find(re.set, c, 1, true)
        if a == nil then set = set .. c end
      end
      t = makeTransition(frag.initState, set, nil)
    end
    frag:addFinal(t)

  elseif re.type == 'any' then
    local set = ''
    for i = 1,255 do
      local c = string.char(i)
      if c ~= '\n' then set = set .. c end
    end
    frag:addFinal(makeTransition(frag.initState, set, nil))

  elseif re.type == 'option' then
    for j = 1,table.maxn(re.enc) do
      local inner = regexToNFAfrag(state, re.enc[j])
      makeTransition(frag.initState, nil, inner.initState)
      for k = 1,table.maxn(inner.finalTrans) do
        frag:addFinal(inner.finalTrans[k])
      end
    end

  elseif re.type == 'concat' then
    frag = regexToNFAfrag(state, re.enc[1])
    for j = 2,table.maxn(re.enc) do
      local next = regexToNFAfrag(state, re.enc[j])
      for k = 1,table.maxn(frag.finalTrans) do
        frag.finalTrans[k].dest = next.initState
      end
      frag.finalTrans = next.finalTrans
    end

  elseif re.type == 'maybe' then
    local inner = regexToNFAfrag(state, re.enc)
    makeTransition(frag.initState, nil, inner.initState)
    frag:addFinal(makeTransition(frag.initState, nil, nil))
    for j = 1,table.maxn(inner.finalTrans) do
      frag:addFinal(inner.finalTrans[j])
    end

  elseif re.type == 'star' then
    local inner = regexToNFAfrag(state, re.enc)
    makeTransition(frag.initState, nil, inner.initState)
    frag:addFinal(makeTransition(frag.initState, nil, nil))
    for j = 1,table.maxn(inner.finalTrans) do
      inner.finalTrans[j].dest = frag.initState
    end

  elseif re.type == 'plus' then
    local inner, x = regexToNFAfrag(state, re.enc), frag.initState
    frag.initState = inner.initState

    for j = 1,table.maxn(inner.finalTrans) do
      inner.finalTrans[j].dest = x
    end

    makeTransition(x, nil, frag.initState)
    frag:addFinal(makeTransition(x, nil, nil))

  elseif re.type == 'num' then
    if re.min == nil and re.max == nil then
      frag = regexToNFAfrag(state, lu.re.star(re.enc))
    else
      local r2 = lu.re.concat()
      local min, max = re.min, re.max
      if min == nil then min = 0 end
      for j = 1,min do
        r2:add(re.enc)
      end

      if max == nil then
        r2:add(lu.re.star(re.enc))
      else
        local y = lu.re.maybe(re.enc)
        for j = min+1,max do
          r2:add(y)
        end
      end

      frag = regexToNFAfrag(state, r2)
    end

  else
    error('Unknown regex fragment type')
  end

  return frag
end

-- Returns an object that can be used by e.g. regexToNFAfrag as
-- translate-global state
local function makeState()
  return { nextId = 0 }
end

-- Turns a regex tree into an NFA fragment with end-state precedence doneNum;
-- returns the initial state of the NFA.
local function regexCompile(state, re, doneNum)
  local frag = regexToNFAfrag(state, re)
  local endState = makeState(state, doneNum)

  for j = 1,table.maxn(frag.finalTrans) do
    frag.finalTrans[j].dest = endState
  end

  return frag.initState
end

-- Top-level routine to turn a list of regex trees into an NFA; returns the
-- initial state of the NFA.
function regexCompile(reList)
  local globalState = makeState()
  local initState = makeState(globalState)

  for j = 1,table.maxn(reList) do
    local frag = regexToNFAfrag(globalState, reList[j])
    local endState = makeState(globalState, j)

    for k = 1,table.maxn(frag.finalTrans) do
      frag.finalTrans[k].dest = endState
    end

    makeTransition(initState, nil, frag.initState)
  end

  return initState
end

return P
