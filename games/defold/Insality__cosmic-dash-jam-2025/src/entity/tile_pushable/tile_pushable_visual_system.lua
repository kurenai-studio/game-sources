local decore = require("decore.decore")

---@class entity
---@field tile_pushable_visual boolean|nil

---@class entity.tile_pushable_visual: entity
---@field tile_pushable_visual boolean
---@field game_object component.game_object
---@field panthera component.panthera

decore.register_component("tile_pushable_visual")

---@class system.tile_pushable_visual: system
---@field entities entity.tile_pushable_visual[]
local M = {}


---@return system.tile_pushable_visual
function M.create_system()
	return decore.system(M, "tile_pushable_visual", { "tile_pushable_visual" })
end


function M:postWrap()
	self.world.event_bus:process("on_field_props_movement", self.on_field_props_movement, self)
end


---@param event event.field_movable.on_field_props_movement
function M:on_field_props_movement(event)
	local entity = event.entity --[[@as entity.tile_pushable_visual]]
	if not entity.tile_pushable_visual then
		return
	end

	self.world.panthera:play(entity, "on_hit")
	self.world.sound:play("pushable")
end


return M
