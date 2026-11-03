local luax = require("game.luax")

local decore = require("decore.decore")

---@class entity
---@field abilities component.abilities|nil

---@class entity.abilities: entity
---@field abilities component.abilities

---@class component.abilities
---@field list string[]
---@field abilities_string string?

decore.register_component("abilities", {})

---@class system.abilities: system
---@field entities entity.abilities[]
local M = {}


---@return system.abilities
function M.create()
	return decore.system(M, "abilities", "abilities")
end


---@param entity entity.abilities
function M:onAdd(entity)
	if entity.abilities.abilities_string and entity.abilities.abilities_string ~= "" then
		entity.abilities.list = luax.split(entity.abilities.abilities_string, ",")
	end
end


return M
