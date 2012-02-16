-- limeparse.lua: Parses the input file
-- Copyright © 2012 Zachary Catlin. See LICENSE for terms.

-- The package table
local P = {}

if _REQUIREDNAME == nil then
  limeparse = P
else
  _G[_REQUIREDNAME] = P
end

-- External imports
local coroutine = coroutine
local string = string
local error = error
local tonumber = tonumber
local table = table
require('limeutil')
local lu = limeutil

setfenv(1, P)

-- How much of a file do we read at one time?
blockSize = 8192

-- Commonly-used patters
local WHSP = '[ \t\n]'
local nWHSP = '[^ \t\n]'

-- The file parser is structure as a top-level function (readFile) that
-- chooses a sub-parser based on the initial bytes of a section (regexp,
-- directive, comment, etc.); the sub-parser is run as a coroutine with the
-- following flow, where s is the read-in but unparsed portion of the file
-- and conf is the object representing the parsed file configuration:
--
--               readFile                  sub-parser
-- initial call:
--                         -> (conf, s)
--
-- sub-parser needs more bytes:
--                         <- (false, nil)
--
-- readFile gives more bytes:
--                         -> (more-bytes)
--
-- readFile can't give more bytes, since it's at EOF:
--                         -> (nil)
--
-- sub-parser is done, and returns any trailing bytes it didn't parse:
--                         <- (true, s)
--
-- sub-parser finds an error in the file:
--                                         error(message)

-- A simple sub-parser: skip through a C-style comment
local function readCComment(conf, s)
  local isDone = false
  local moreS

  -- Skip past the initial '/*'
  while string.len(s) < 2 do
    moreS = coroutine.yield(false, nil)
    if moreS == nil then return true, '' end
    s = s .. moreS
  end
  s = string.sub(s, 3, -1)

  -- Search for ending '*/'
  while not isDone do
    local a,b = string.find(s, '*/', 1, true)

    if a ~= nil then
      s = string.sub(s, b+1, -1)
      isDone = true
    else
      -- no '*/'; any possible match will involve only the last byte of
      -- the current s, if that
      moreS = coroutine.yield(false, nil)
      if moreS == nil then return true, '' end
      s = string.sub(s, -1, -1) .. moreS
    end
  end

  return true, s
end

-- An even simpler sub-parser: skip through whitespace
local function readWhitespace(conf, s)
  local moreS = ''
  local a,b

  while moreS ~= nil do
    s = s .. moreS
    a,b = string.find(s, nWHSP)

    if a ~= nil then
      return true, string.sub(s, b, -1)
    else
      moreS = coroutine.yield(false, nil)
    end
  end

  return true, ''
end

-- Skip through a C++-style short comment
local function readShortComment(conf, s)
  local moreS = ''
  local a,b

  -- Skip past intial '//'
  while string.len(s) < 2 do
    moreS = coroutine.yield(false, nil)
    if moreS == nil then return true, '' end
    s = s .. moreS
  end
  s = string.sub(s, 3, -1)

  while moreS ~= nil do
    s = s .. moreS
    a,b = string.find(s, '\n', 1, true)

    if a ~= nil then
      return true, string.sub(s, b+1, -1)
    else
      moreS = coroutine.yield(false, nil)
    end

    s = ''
  end

  return true, ''
end

-- This is a table with directive names (with '%' at start) as keys and arrays
-- as values, where the first element of the array is a function to run if the
-- directive name is at the exact end of the file and the second element is
-- a function to run if there is still part of the file after the array;
-- a[1] = function(conf, d) -> (ignored) and a[2] = function(conf, s, d) -> s
-- where conf is the table representing the parsed file, s is the read-in but
-- currently-unparsed part of the file, and d is the directive name.
local directives

-- Read a directive, which is of the form '%name [stuff]', where the exact
-- form of [stuff] depends on the directive.
local function readDirective(conf, s)
  local moreS = ''
  local a,b = nil, nil

  a,b = string.find(s, WHSP)
  -- Try to find the first whitespace after the directive name:
  while a == nil do
    moreS = coroutine.yield(false, nil)
    if moreS == nil then break end
    s = s .. moreS
    a,b = string.find(s, WHSP)
  end

  if a == nil then -- directive name is at EOF
    if directives[s] == nil then
      error('Unrecognized directive ' .. s)
    end

    directives[s][1](conf, s)
    return true, ''
  else
    local name = string.sub(s, 1, b-1)
    if directives[name] == nil then
      error('Unrecognized directive ' .. name)
    end

    s = string.sub(s, b, -1)
    return true, directives[name][2](conf, s, name)
  end

  return true, s
end

local function makeError(s)
  return function()
    error(s, 1)
  end
end

-- Read a chunk of C/C++ code delimited with braces, possibly with whitespace
-- in front. Called with the read-in but currently unparsed part of the file,
-- and returns the C code as a string, as well as the unparsed stuff afterward.
local function readCode(s)
  local a,b
  local moreS
  local braceDepth = 1
  local blk = ''

  -- Skip over leading whitespace
  a,b = string.find(s, nWHSP)
  while a == nil do
    moreS = coroutine.yield(false, nil)
    if moreS == nil then
      error('Looking for code block but got EOF!')
    end

    s = moreS
    a,b = string.find(s, nWHSP)
  end

  -- Check for opening brace
  if string.sub(s, a, a) ~= '{' then
    error('Looking for code block but got something other than "{"')
  end
  s = string.sub(s, a+1, -1)

  -- Scan through C code: we have to look out for comments (/* ... */ and
  -- // ... \n), open and close braces ({ and }), character literals
  -- ('...', with care taken with \'s), and string literals ("...", again
  -- with backslashes special).
  local CPAT = '[/\'\"{}]'
  local function getMore()
    moreS = coroutine.yield(false, nil)
    if moreS == nil then
      error('EOF occurred in the middle of a code block!')
    end
  end

  while braceDepth > 0 do
    -- First off, find the next comment, brace, or character/string literal:
    a = string.find(s, CPAT)
    if a == nil then
      getMore()
      blk = blk .. s
      s = moreS
    else
      b = string.sub(s, a, a)

      if b == '/' then -- comment...or division...
        blk = blk .. string.sub(s, 1, a-1)
        s = string.sub(s, a, -1)
        if string.len(s) < 2 then
          getMore()
          s = s .. moreS
        end

        b = string.sub(s, 2, 2)
        if b == '*' then -- C-style comment
          blk = blk .. '/*'
          s = string.sub(s, 3, -1)
          a,b = string.find(s, '*/', 1, true)
          while a == nil do
            getMore()
            blk = blk .. string.sub(s, 1, -2)
            s = string.sub(s, -1, -1) .. moreS
            a,b = string.find(s, '*/', 1, true)
          end
          blk = blk .. string.sub(s, 1, b)
          s = string.sub(s, b+1, -1)

        elseif b == '/' then -- C++-style comment
          a = string.find(s, '\n', 1, true)
          while a == nil do
            getMore()
            blk = blk .. s
            s = moreS
            a = string.find(s, '\n', 1, true)
          end
          blk = blk .. string.sub(s, 1, a)
          s = string.sub(s, a+1, -1)

        else -- false alarm - skip over the '/'
          blk = blk .. '/'
          s = string.sub(s, 2, -1)
        end

      elseif b == '{' then -- begin block
        blk = blk .. string.sub(s, 1, a)
        s = string.sub(s, a+1, -1)
        braceDepth = braceDepth + 1

      elseif b == '}' then -- end block
        blk = blk .. string.sub(s, 1, a-1)
        s = string.sub(s, a+1, -1)
        braceDepth = braceDepth - 1
        if braceDepth > 0 then
          blk = blk .. '}'
        end

      else -- character/string literal
        local isDone = false
        local pattern = '[\'\\]'
        if b == '\"' then
          pattern = '[\"\\]'
        end

        blk = blk .. string.sub(s, 1, a)
        s = string.sub(s, a+1, -1)

        while not isDone do
          a = string.find(s, pattern)
          while a == nil do
            getMore()
            blk = blk .. s
            s = moreS
            a = string.find(s, pattern)
          end

          b = string.sub(s, a, a)
          if b == "\'" or b == '\"' then
            isDone = true
            blk = blk .. string.sub(s, 1, a)
            s = string.sub(s, a+1, -1)
          else -- escape
            if string.len(s) < a+1 then
              getMore()
              s = s .. moreS
            end
            blk = blk .. string.sub(s, 1, a+1)
            s = string.sub(s, a+2, -1)
          end
        end
      end
    end
  end

  return blk, s
end

local function makeCode(field)
  return function(c, s, d)
    local a, b = readCode(s)
    c[field] = a
    return b
  end
end

directives = {
  ['%testdirective']= { makeError('1'), makeError('2') },
  ['%othertestdirective'] = { function(c, d) c.a = 1 end,
                              function(c, s, d) c.a = 2 return s end },
  ['%header'] = { makeError('bleh'), makeCode('header') }
}

-- Sub-parser for the single-character and 'any' (.) regular expression
-- fragments
local function readSingleCharRegex(conf, s)
  local re, c
  c = string.sub(s, 1, 1)
  s = string.sub(s, 2, -1)

  if c == '.' then
    re = lu.re.any()
  else
    re = lu.re.char(c)
  end

  if conf.currRegex == nil then
    conf.currRegex = re
  else
    local top = table.remove(conf.regexStack)
    if top == nil then
      top = lu.re.concat(conf.currRegex)
    elseif top.type == 'paren' then
      table.insert(conf.regexStack, top)
      top = lu.re.concat(conf.currRegex)
    elseif top.type == 'option' then
      table.insert(conf.regexStack, top)
      top = lu.re.concat(conf.currRegex)
    else -- top.type == 'concat'
      top:add(conf.currRegex)
    end
    table.insert(conf.regexStack, top)

    conf.currRegex = re
  end

  return true, s
end

-- Sub-parser for the '[]' character-class regex fragment
local function readCharClass(conf, s)
  local done = false
  local re = lu.re.charClass()

  -- Get rid of initial '['
  s = string.sub(s, 2, -1)

  -- If there is a '^' at front, invert the sense
  local c = string.sub(s, 1, 1)
  while c == '' do
    local moreS = coroutine.yield(false, nil)
    if moreS == nil then
      error('EOF occurred in middle of regular expression')
    end
    s = s .. moreS
  end

  if c == '^' then
    re.negated = true
    s = string.sub(s, 2, -1)
  end

  while not done do
    local a = string.find(s, ']', 1, true)
    if a == nil then
      local moreS = coroutine.yield(false, nil)
      if moreS == nil then
        error('EOF occurred in middle of regular expression')
      end
      s = s .. moreS
    else
      re:add(string.sub(s, 1, a-1))
      s = string.sub(s, a+1, -1)
      done = true
    end
  end

  if conf.currRegex == nil then
    conf.currRegex = re
  else
    local top = table.remove(conf.regexStack)
    if top == nil then
      top = lu.re.concat(conf.currRegex)
    elseif top.type == 'paren' then
      table.insert(conf.regexStack, top)
      top = lu.re.concat(conf.currRegex)
    elseif top.type == 'option' then
      table.insert(conf.regexStack, top)
      top = lu.re.concat(conf.currRegex)
    else -- top.type == 'concat'
      top:add(conf.currRegex)
    end
    table.insert(conf.regexStack, top)

    conf.currRegex = re
  end

  return true, s
end

-- Sub-parser for the '?', '*', and '+' regular expression operators
local function readRegexOperator(conf, s)
  local reGen, c
  c = string.sub(s, 1, 1)
  s = string.sub(s, 2, -1)

  if c == '?' then
    reGen = lu.re.maybe
  elseif c == '*' then
    reGen = lu.re.star
  else -- c == '+'
    reGen = lu.re.plus
  end

  if conf.currRegex == nil then
    error('Tried to use ' .. c .. ' on an empty regular expression')
  end

  conf.currRegex = reGen(conf.currRegex)
  return true, s
end

-- Sub-parser for the numbered repetition regular-expression operator
local function readNumRepOperator(conf, s)
  local a, b, x, y

  if conf.currRegex == nil then
    error('Tried to use repetition on an empty regular expression')
  end

  a, b, x = string.find(s, '^{(%d+)}')
  if a ~= nil then
    x = tonumber(x, 10)
    conf.currRegex = lu.re.num(conf.currRegex, x, x)
    return true, string.sub(s, b+1, -1)
  end

  a, b, x, y = string.find(s, '^{(%d*),(%d*)}')
  if a ~= nil then
    if x == '' then x = nil else x = tonumber(x, 10) end
    if y == '' then y = nil else y = tonumber(y, 10) end
    if x == nil and y == nil then
      conf.currRegex = lu.re.star(conf.currRegex)
    else
      conf.currRegex = lu.re.num(conf.currRegex, x, y)
    end
    return true, string.sub(s, b+1, -1)
  end

  error('An invalid repetition was given')
end

-- Sub-parser for the '(' and ')' regular expression operators
local function readParenOperators(conf, s)
  local c = string.sub(s, 1, 1)
  local re = conf.currRegex

  if c == '(' then
    if re ~= nil then
      local top = table.remove(conf.regexStack)
      if top == nil then
        top = lu.re.concat(re)
      elseif top.type == 'concat' or top.type == 'option' then
        top:add(re)
      else -- top.type == 'paren'
        table.insert(conf.regexStack, top)
        top = lu.re.concat(re)
      end

      table.insert(conf.regexStack, top)
    end

    table.insert(conf.regexStack, lu.re.paren())
    conf.currRegex = nil

  else -- c == ')'
    local top = table.remove(conf.regexStack)
    while top ~= nil and top.type ~= 'paren' do
      if re ~= nil then
        top:add(re)
      elseif top.type == 'option' then
        top:add(lu.re.zero())
      end

      re, top = top, table.remove(conf.regexStack)
    end

    if top == nil then
      error('close-paren without open-paren')
    end

    conf.currRegex = re
  end

  return true, string.sub(s, 2, -1)
end

-- Sub-parser for the '|' regular expression operator
local function readOptionOperator(conf, s)
  local re = conf.currRegex

  if re == nil then
    re = lu.re.zero()
  end

  local top = table.remove(conf.regexStack)

  if top == nil then
    top = lu.re.option(re)
  elseif top.type == 'option' then
    top:add(re)
  elseif top.type == 'concat' then
    if re.type ~= 'zero' then
      top:add(re)
    end

    local next = table.remove(conf.regexStack)
    if next ~= nil and next.type == 'option' then
      next:add(top)
      top = next
    else
      table.insert(conf.regexStack, next)
      top = lu.re.option(top)
    end

  else -- top.type == 'paren'
    table.insert(conf.regexStack, top)
    top = lu.re.option(re)
  end

  table.insert(conf.regexStack, top)
  conf.currRegex = nil

  return true, string.sub(s, 2, -1)
end

-- Sub-parser for actions associated with regexes
local function readCodeAction(conf, s)
  local re, code
  -- No regex or finding oneself nested inside a stack of subregexes is
  -- an error condition
  if conf.currRegex == nil and conf.regexStack[1] == nil then
    error('A code block without a regex!')
  elseif table.maxn(conf.regexStack) > 1 then
    error('A code block inside a regex!')
  end

  if conf.regexStack[1] ~= nil then
    re = table.remove(conf.regexStack)
    if re.type == 'option' and conf.currRegex == nil then
      re:add(lu.re.zero())
    else
      re:add(conf.currRegex)
    end
  else
    re = conf.currRegex
  end

  code, s = readCode(s)

  table.insert(conf.tokens, { re, code })

  conf.currRegex = nil

  return true, s
end

-- Based on the first bytes of s, choose a sub-parser to handle the first
-- part of s; returns two values, the sub-parser as a coroutine or nil,
-- and whether or not s is not sufficient to determine the next sub-parser.
local function chooseSubparser(s)
  local firstByte = string.sub(s, 1, 1)

  if firstByte == '' then -- 'No data' is not enough to go on
    error('Premature EOF!')

  elseif firstByte == ' ' or firstByte == '\t' or firstByte == '\n' then
    return coroutine.create(readWhitespace), false

  elseif firstByte == '?' or firstByte == '*' or firstByte == '+' then
    return coroutine.create(readRegexOperator), false

  elseif firstByte == '(' or firstByte == ')' then
    return coroutine.create(readParenOperators), false

  elseif firstByte == '|' then
    return coroutine.create(readOptionOperator), false

  elseif firstByte == '[' then
    return coroutine.create(readCharClass), false

  -- this could be the start of a code block or part of a regular expression...
  elseif firstByte == '{' then
    local a,b = string.find(s, '}', 1, true)
    if a == nil then -- need more context
      return nil, true
    else
      a,b = string.find(s, '^{%d*,?%d*}')
      if a == nil then
        return coroutine.create(readCodeAction), false
      else
        return coroutine.create(readNumRepOperator), false
      end
    end

  elseif firstByte == '/' then
    local secondByte = string.sub(s, 2, 2)

    if secondByte == '' then
      return nil, true
    elseif secondByte == '*' then
      return coroutine.create(readCComment), false
    elseif secondByte == '/' then
      return coroutine.create(readShortComment), false
    else
      return coroutine.create(readSingleCharRegex), false
    end

  elseif firstByte == '%' then
    return coroutine.create(readDirective), false

  else
    return coroutine.create(readSingleCharRegex), false
  end
end

-- The top-level file parser. Either returns a table corresponding to the
-- successfully-parsed file or raises an error.
function readFile(f)
  local conf, state = lu.makeFileData(), nil
  local buf, inString = '', f:read(blockSize)
  local co = nil
  local coFirst = false
  local needMoreBytes = false
  local isDone = false
  local atEOF = false

  local runSubparser = function()
    if co == nil then -- No running sub-parser; start one up
      co, needMoreBytes = chooseSubparser(buf)
      coFirst = true
    else
      local isOK, s
      local buf2 = buf
      if atEOF and buf == '' then
        buf2 = nil
      end

      if coFirst then
        isOK, isDone, s = coroutine.resume(co, conf, buf2)
        coFirst = false
      else
        isOK, isDone, s = coroutine.resume(co, buf2)
      end

      if not isOK then
        error('Uhhh, something wrong... ' .. isDone)
      end

      if isDone then
        co = nil
        buf = s
      else
        buf = ''
      end
    end
  end

  while inString ~= nil do
    buf = buf .. inString

    while buf ~= '' and not needMoreBytes do
      runSubparser()
    end

    inString = f:read(blockSize)
  end
  atEOF = true

  -- We may have hit EOF, but there may still be unparsed parts of the file...
  needMoreBytes = false
  while (buf ~= '' or not isDone) and not needMoreBytes do
    runSubparser()
  end

  if needMoreBytes then
    error('Ambiguous EOF: ' .. buf)
  end

  return conf
end

return P
