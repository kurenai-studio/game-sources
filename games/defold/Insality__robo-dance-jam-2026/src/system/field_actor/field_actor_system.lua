local decore = require("decore.decore")

---@class entity
---@field field_actor component.field_actor|nil

---@class entity.field_actor: entity
---@field field_actor component.field_actor

---@class component.field_actor
---@field field_id string
---@field z integer
---@field height integer
---@field solid boolean
---@field movable boolean
---@field pushable boolean
---@field health number
---@field remove_on_death boolean
---@field flying boolean Non-solid slides ignore missing floor (e.g. projectiles over pits)
---@field damage_on_collide number|nil Self-damage on solid overlap (see damage_on_collide_resolver)
---@field initial_side "up" | "down" | "left" | "right" | "none" | nil Starting facing for field logic (`last_move_side` until first move)
---@field field_entity field.entity|nil
decore.register_component("field_actor", {
	field_id = "game",
	z = 1,
	height = 1,
	solid = true,
	movable = false,
	pushable = false,
	remove_on_death = false,
	flying = false,
	initial_side = nil,
	field_entity = nil,
})

---@class system.field_actor: system
---@field entities entity.field_actor[]
local M = {}


---@return system.field_actor
function M.create()
	return decore.system(M, "field_actor", "field_actor")
end


return M
