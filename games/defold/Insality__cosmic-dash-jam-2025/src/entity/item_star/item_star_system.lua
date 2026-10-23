local levels = require("game.levels")
local events = require("event.events")
local decore = require("decore.decore")

---@class entity
---@field item_star component.item_star|nil

---@class entity.item_star: entity
---@field item_star component.item_star
---@field game_object component.game_object
---@field field_collectable component.field_collectable
---@field tiled_id string

---@class component.item_star: boolean
decore.register_component("item_star")

---@class system.item_star: system
---@field entities entity.item_star[]
local M = {}


---@return system.item_star
function M.create_system()
	return decore.system(M, "item_star", { "item_star", "field_collectable", "tiled_id" })
end


function M:postWrap()
	self.world.event_bus:process("on_field_collectable_collide", self.on_field_collectable_collide, self)
end


---@param entity entity.item_star
function M:onAdd(entity)
	local is_star_collected = levels.is_star_collected(entity.tiled_id)
	if is_star_collected then
		local sprite_url = msg.url(nil, entity.game_object.object["/body"], "sprite")
		go.set(sprite_url, "color.w", 0.5)
	end
end


---@param event event.field_movable.on_field_collectable_collide
function M:on_field_collectable_collide(event)
	local collected = event.collide
	if not collected.item_star then
		return
	end

	levels.collect_star(collected.tiled_id)
	self.world.sound:play("star_collect")

	---@class event.game.on_star_collected
	---@field tiled_id string|number
	---@field stars_count number
	---@field level_id string

	events.trigger("game.star_collected", {
		tiled_id = collected.tiled_id,
		stars_count = levels.get_stars_count(),
		level_id = levels.current_level,
	})
end


return M
