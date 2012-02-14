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
    error(s, 0)
  end
end

directives = {
  ['%testdirective']= { makeError('1'), makeError('2') },
  ['%othertestdirective'] = { function(c, d) c.a = 1 end,
                              function(c, s, d) c.a = 2 return s end }
}

-- Based on the first bytes of s, choose a sub-parser to handle the first
-- part of s; returns two values, the sub-parser as a coroutine or nil,
-- and whether or not s is not sufficient to determine the next sub-parser.
local function chooseSubparser(s)
  local firstByte = string.sub(s, 1, 1)

  if firstByte == ' ' or firstByte == '\t' or firstByte == '\n' then
    return coroutine.create(readWhitespace), false

  elseif firstByte == '/' then
    local secondByte = string.sub(s, 2, 2)

    if secondByte == '' then
      return nil, true
    elseif secondByte == '*' then
      return coroutine.create(readCComment), false
    elseif secondByte == '/' then
      return coroutine.create(readShortComment), false
    else
      error('Unknown thing ' .. string.sub(s, 1, 2))
    end

  elseif firstByte == '%' then
    return coroutine.create(readDirective), false

  else
    error('Unknown thing ' .. firstByte)
  end
end

-- The top-level file parser. Either returns a table corresponding to the
-- successfully-parsed file or raises an error.
function readFile(f)
  local conf, state = {}, nil
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
