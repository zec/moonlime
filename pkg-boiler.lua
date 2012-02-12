-- Boilerplate for a Lua package (in this case called frob by default)

-- Zachary Catlin 2012. I place this in the public domain. In jurisdictions
-- which do not recognize dedication to the public domain, I grant you the
-- ability to do anything with this, so long as I don't have any liability
-- for the use.

-- The package table
local P = {}
if _REQUIREDNAME == nil then
  frob = P
else
  _G[_REQUIREDNAME] = P
end

-- Import anything this package needs from outside
local sqrt = math.sqrt
local io = io

-- Make the package table this file's global environment
-- (for safety and ease of declaration)
setfenv(1, P)

return P
