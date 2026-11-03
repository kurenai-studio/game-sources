---@class world
local M = {}
local METATABLE = { __index = nil }

---@param world world
function M.set_world(world)
	METATABLE.__index = world
end


---@return world
function M.get_world()
	return METATABLE.__index
end


return setmetatable(M, METATABLE)
