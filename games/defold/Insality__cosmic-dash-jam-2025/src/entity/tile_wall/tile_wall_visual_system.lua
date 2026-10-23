local decore = require("decore.decore")

---@class entity
---@field tile_wall_visual boolean|nil

---@class entity.tile_wall_visual: entity
---@field tile_wall_visual boolean
---@field game_object component.game_object
---@field panthera component.panthera

decore.register_component("tile_wall_visual")

---@class system.tile_wall_visual: system
---@field entities entity.tile_wall_visual[]
local M = {}


---@return system.tile_wall_visual
function M.create_system()
	return decore.system(M, "tile_wall_visual", { "tile_wall_visual" })
end


function M:postWrap()
	self.world.event_bus:process("on_field_solid_wall_collide", self.on_field_solid_wall_collide, self)
end


---@param event event.field_movable.on_field_solid_wall_collide
function M:on_field_solid_wall_collide(event)
	local collide = event.collide --[[@as entity.field]]
	if not collide.tile_wall_visual then
		return
	end

	self.world.panthera:play(collide, "on_hit")
end


return M
