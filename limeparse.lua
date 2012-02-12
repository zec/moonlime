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
    a,b = string.find(s, '[^ \t\n]')

    if a ~= nil then
      return true, string.sub(s, b, -1)
    else
      moreS = coroutine.yield(false, nil)
    end
  end

  return true, s
end

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
    else
      error('Unknown thing ' .. string.sub(s, 1, 2))
    end
  else
    error('Unknown thing ' .. firstByte)
  end
end

function readFile(f)
  local conf, state = {}, nil
  local buf, inString = '', f:read(blockSize)
  local co = nil
  local coFirst = false
  local needMoreBytes = false

  local runSubparser = function()
    if co == nil then -- No running sub-parser; start one up
      co, needMoreBytes = chooseSubparser(buf)
      coFirst = true
    else
      local isOK, isDone, s

      if coFirst then
        isOK, isDone, s = coroutine.resume(co, conf, buf)
        coFirst = false
      else
        isOK, isDone, s = coroutine.resume(co, buf)
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

  -- We may have hit EOF, but there may still be unparsed parts of the file...
  needMoreBytes = false
  while buf ~= '' and not needMoreBytes do
    runSubparser()
  end

  if needMoreBytes then
    error('Ambiguous EOF: ' .. buf)
  end

  return conf
end

return P
