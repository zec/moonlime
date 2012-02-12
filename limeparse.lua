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
--local sqrt = math.sqrt

setfenv(1, P)

return P
