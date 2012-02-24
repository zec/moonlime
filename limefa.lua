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
local setmetatable = setmetatable
local pairs = pairs
local HUGE = math.huge
require('limeutil')
local lu = limeutil
-- used in debug
--local err = io.stderr

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
  setmetatable(x, nfaFragMeta)

  return x
end

local anySet = ''
for i = 1,255 do
  local c = string.char(i)
  if c ~= '\n' then
    anySet = anySet .. c
  end
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
    frag:addFinal(makeTransition(frag.initState, anySet, nil))

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
local function makeGlobalState()
  return { nextId = 0 }
end

-- Top-level routine to turn a list of regex trees into an NFA; returns the
-- initial state of the NFA.
function regexCompile(reList)
  local gState = makeGlobalState()
  local initState = makeState(gState)

  for j = 1,table.maxn(reList) do
    local frag = regexToNFAfrag(gState, reList[j])
    local endState = makeState(gState, j)

    for k = 1,table.maxn(frag.finalTrans) do
      frag.finalTrans[k].dest = endState
    end

    makeTransition(initState, nil, frag.initState)
  end

  return initState
end

-- Prints out a representation of a finite automaton (with initial state fa)
-- to file f.
function printFA(f, fa)
  local notDone = { fa }
  local done = {}

  f:write('[initial state]\n')
  while table.maxn(notDone) > 0 do
    local currState = table.remove(notDone, 1)
    if not done[currState] then
      f:write(string.format('State %d:\n', currState.id))
      if currState.doneNum ~= nil then
        f:write(string.format('  doneNum = %d\n', currState.doneNum))
      end
      for i = 1,table.maxn(currState.transitions) do
        local x, y = currState.transitions[i].cond,
                     currState.transitions[i].dest

        if y == nil then
          y = { id = -1 }
        end

        if x == nil then
          x = '[nil]'
        elseif x == anySet then
          x = '{ANY}'
        else
          x = lu.escapeString(x)
        end

        f:write(string.format('  tr[%d]: %s -> %d\n', i, x, y.id))

        if y.id ~= -1 and not done[y] then
          table.insert(notDone, y)
        end
      end
      done[currState] = true
    end
  end
end

-- The following are some utility routines for operations on sets, where the
-- sets are represented by tables t with t[x] is truthy iff x is in t
local function union(a, b)
  local x = {}
  for k in pairs(a) do
    if a[k] then
      x[k] = true
    end
  end
  for k in pairs(b) do
    if b[k] then
      x[k] = true
    end
  end

  return x
end

local function intersect(a, b)
  local x = {}
  for k in pairs(a) do
    if a[k] and b[k] then
      x[k] = true
    end
  end

  return x
end

local function minus(a, b)
  local x = {}
  for k in pairs(a) do
    if a[k] and not b[k] then
      x[k] = true
    end
  end

  return x
end

local function setSize(a)
  local n = 0
  for k in pairs(a) do
    n = n + 1
  end
  return n
end

-- Given a set s of non-negative integers, create a reproducible key
local function mkSetKey(s)
  local m, k = table.maxn(s), {}
  for i = 0,m do
    if s[i] then
      table.insert(k, '1')
    else
      table.insert(k, '0')
    end
  end

  return table.concat(k)
end

-- For a given state s, return a set consisting of the IDs of s and the
-- states reachable from s with only nil transitions
local function nilClosure(s)
  local totalSet = {}
  local toDoQueue = { s }

  while table.maxn(toDoQueue) > 0 do
    local r = table.remove(toDoQueue)
    if not totalSet[r.id] then
      totalSet[r.id] = true
      for i = 1,table.maxn(r.transitions) do
        local trans = r.transitions[i]
        if trans.cond == nil and not totalSet[trans.dest.id] then
          table.insert(toDoQueue, trans.dest)
        end
      end
    end
  end

  return totalSet
end

-- Given a finite automaton with initial state fa, return a table with all
-- reachable states in the FA, indexed by their ID
function makeTable(fa)
  local toDoQueue = { fa }
  local tbl = {}

  while table.maxn(toDoQueue) > 0 do
    local r = table.remove(toDoQueue)
    if not tbl[r.id] then
      tbl[r.id] = r
      for i = 1,table.maxn(r.transitions) do
        local dest = r.transitions[i].dest
        if not tbl[dest.id] then
          table.insert(toDoQueue, dest)
        end
      end
    end
  end

  return tbl
end

-- Given an NFA with initial state fa, return a DFA that matches the same
-- strings, with doneNum for each end state in the DFA equal to the least value
-- of doneNum for corresponding NFA end states. This uses the classic powerset
-- method for constructing the DFA.
function NFAtoDFA(fa)
  local initSet = nilClosure(fa)
  -- A list of state-sets known to be reachable but which haven't been
  -- examined yet
  local toDoQueue = { initSet }
  -- The set of state-sets (in key string form) that have been processed
  local done = {}
  -- A table of DFA states, indexed by the NFA state-set they represent
  local dfaStates = {}
  -- The NFA states, indexed by state ID
  local nfa = makeTable(fa)

  local gState = makeGlobalState()

  local function setToState(set)
    local minDoneNum = HUGE -- assumed to be > than the # of regexes per file
    local setKey = mkSetKey(set)

    if dfaStates[setKey] ~= nil then
      return dfaStates[setKey], setKey
    end

    for k in pairs(set) do
      if set[k] and nfa[k].doneNum ~= nil and nfa[k].doneNum < minDoneNum then
        minDoneNum = nfa[k].doneNum
      end
    end

    if minDoneNum == HUGE then
      minDoneNum = nil
    end

    local state = makeState(gState, minDoneNum)
    dfaStates[setKey] = state
    return state, setKey
  end

  -- Compute all nil-closures just once
  local nilClosures = {}
  for k,v in pairs(nfa) do
    nilClosures[k] = nilClosure(v)
  end

  while table.maxn(toDoQueue) > 0 do
    local set = table.remove(toDoQueue)
    local state, stateKey = setToState(set)

    if not done[stateKey] then
      local transitions = {}

      -- Handle each individual byte value
      for i = 0,255 do
        local transSet, ch = {}, string.char(i)
        for k in pairs(set) do
          local st = nfa[k]
          for j = 1,table.maxn(st.transitions) do
            local trans = st.transitions[j]
            if trans.cond ~= nil and string.find(trans.cond, ch, 1, true) ~= nil then
              transSet = union(transSet, nilClosures[trans.dest.id])
            end
          end
        end

        if setSize(transSet) > 0 then
          local transState, transKey = setToState(transSet)
          if transitions[transKey] == nil then
            transitions[transKey] = { transSet, transState }
          end
          table.insert(transitions[transKey], ch)
        end
      end

      for k,v in pairs(transitions) do
        if not done[k] then
          table.insert(toDoQueue, v[1])
        end
          makeTransition(state, table.concat(v, '', 3), v[2])
      end

      done[stateKey] = true
    end
  end

  return setToState(initSet)
end

return P
