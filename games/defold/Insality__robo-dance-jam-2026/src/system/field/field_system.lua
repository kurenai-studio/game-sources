local decore = require("decore.decore")

local field = require("system.field.field.field")
local field_command = require("system.field.field_command")
local field_entity = require("system.field.field.internal.field_entity")
local level_manager_command = require("system.level_manager.level_manager_command")

---@class entity.field: entity
---@field field_actor component.field_actor
---@field transform component.transform

---@class system.field: system
---@field entities entity.field[]
---@field field field
---@field _preview_results field.turn_result[]
---@field _field_map_by_id table<number, field.entity>
local M = {}


---@return system.field
function M.create()
	local self = decore.system(M, "field", { "field_actor", "transform" })
	field_command.register(self)
	self._preview_results = {}
	self._field_map_by_id = {}

	self.field = field.create()

	return self
end


---@param entity entity
function M:onAdd(entity)
	if self._field_map_by_id[entity.id] then
		return
	end

	local field_entity = self:build_field_entity(entity)
	self._field_map_by_id[entity.id] = field_entity
	self.field:add_entity(field_entity)

	--print("- Add field entity", field_entity.entity_id, field_entity.name, field_entity.i, field_entity.j, field_entity.last_move_side)
end


---@param entity entity
function M:onRemove(entity)
	local field_entity = self._field_map_by_id[entity.id]
	if field_entity then
		self.field:remove_entity(field_entity)
		self._field_map_by_id[entity.id] = nil
	end
end


---@param entity entity
---@return field.entity
function M:build_field_entity(entity)
	local i, j = level_manager_command.get_ij(entity.transform.position_x, entity.transform.position_y)
	local field_entity = field_entity.create(i, j, {
		entity_id = entity.id,
		name = entity.prefab_id,
		z = entity.field_actor.z,
		height = entity.field_actor.height,
		movable = entity.field_actor.movable,
		pushable = entity.field_actor.pushable,
		solid = entity.field_actor.solid,
		health = entity.field_actor.health,
		remove_on_death = entity.field_actor.remove_on_death,
		flying = entity.field_actor.flying,
		damage_on_collide = entity.field_actor.damage_on_collide,
		last_move_side = entity.field_actor.initial_side,
	})
	entity.field_actor.field_entity = field_entity

	return field_entity
end


---@param entity_id number
---@return field.entity|nil
function M:get_field_entity(entity_id)
	return self._field_map_by_id[entity_id]
end


return M
