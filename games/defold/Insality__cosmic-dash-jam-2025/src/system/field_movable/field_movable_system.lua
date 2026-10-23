local log = require("log.log")
local decore = require("decore.decore")
local field_movable_command = require("system.field_movable.field_movable_command")

---@class entity
---@field field_movable component.field_movable?
---@field field_pushable component.field_pushable?
---@field field_portal component.field_portal?
---@field field_portal_reverse component.field_portal_reverse?
---@field user_controlled component.user_controlled?
---@field field_collectable component.field_collectable?

---@class entity.field_movable: entity
---@field field_movable boolean
---@field field component.field
---@field transform component.transform

---@class entity.field_movable_command: entity

---@class event.field_movable.on_glue_collide
---@field i number
---@field j number
---@field entity entity.field
---@field collide entity.field

---@class component.field_movable: boolean
decore.register_component("field_movable")
---@class component.field_pushable: boolean
decore.register_component("field_pushable")
---@class component.field_portal: boolean
decore.register_component("field_portal")
---@class component.field_collectable: boolean
decore.register_component("field_collectable")
---@class component.field_portal_reverse: boolean
decore.register_component("field_portal_reverse")
---@class component.user_controlled: boolean
decore.register_component("user_controlled")

---@class system.field_movable: system
---@field entities entity.field_movable[]
local M = {}


M.MOVEMENT_KEYS = {
	[hash("key_w")] = "up",
	[hash("key_s")] = "down",
	[hash("key_a")] = "left",
	[hash("key_d")] = "right",
	[hash("key_left")] = "left",
	[hash("key_right")] = "right",
	[hash("key_up")] = "up",
	[hash("key_down")] = "down",
}

M.MOVEMENT_MAP = {
	["up"] = { i = 0, j = 1 },
	["down"] = { i = 0, j = -1 },
	["left"] = { i = -1, j = 0 },
	["right"] = { i = 1, j = 0 },
}

---@return system.field_movable
function M.create_system()
	return decore.system(M, "field_movable", { "field_movable", "field", "transform" })
end


function M:onAddToWorld()
	self.world.field_movable = field_movable_command.create(self)
end


function M:postWrap()
	self.world.event_bus:process("input_event", self.process_input_event, self)
end


---@param input_event system.input.event
function M:process_input_event(input_event)
	if not input_event.pressed or not self.MOVEMENT_KEYS[input_event.action_id] then
		return
	end

	local movement = self.MOVEMENT_KEYS[input_event.action_id]
	self.world.field_movable:move_to_direction(movement)
end


---@param entity entity
---@param movement_side string
function M:move_to_direction(entity, movement_side)
	local movement = self.MOVEMENT_MAP[movement_side]
	local collide_with_entity, collide_i, collide_j = self.world.field:get_collide_entity_in_direction(entity, movement)
	self:move_to_cell(entity, collide_with_entity, collide_i, collide_j, movement)
end


---@param entity entity
---@param collide entity.field?
---@param collide_i number
---@param collide_j number
---@param movement table
function M:move_to_cell(entity, collide, collide_i, collide_j, movement)
	local entity_i, entity_j = self.world.field:get_ij(entity.transform.position_x, entity.transform.position_y)
	local distance = math.abs(entity_i - collide_i) + math.abs(entity_j - collide_j)

	local is_collide_solid = collide and collide.field.solid
	local is_collide_glue = collide and collide.field.glue
	local is_collide_pushable = collide and collide.field_pushable and distance > 1
	local is_collide_portal = collide and collide.field_portal
	local is_collide_corner = collide and collide.field_corner
	local is_user_controlled = entity.user_controlled

	if collide and is_collide_pushable  then
		log:debug("Hit pushable", { i = collide_i, j = collide_j, prefab_id = collide.prefab_id })

		local collide_entity, ci, cj = self.world.field:get_collide_entity_in_direction(collide, movement, 1)
		local is_floor_exists = self.world.field:is_floor_exists(ci, cj)
		if collide_entity or not is_floor_exists then
			is_collide_solid = true -- Stop the movement
		else
			self:move_to_cell(collide, nil, ci, cj, movement)
			self:handle_glue(entity, collide, collide_i, collide_j, movement)
			return
		end

		--self:handle_pushable(entity, collide, collide_i, collide_j, movement)
	end

	if collide and is_collide_solid then
		local target_x, target_y = self.world.field:get_xy(collide_i - movement.i, collide_j - movement.j)

		if is_collide_corner then
			return self:handle_corner(entity, collide, collide_i, collide_j, movement)
		else
			return self:handle_solid_wall(entity, collide, collide_i, collide_j, movement)
		end
	end

	if collide and is_collide_glue then
		if is_collide_portal then
			return self:handle_portal(entity, collide, collide_i, collide_j, movement)
		else
			return self:handle_glue(entity, collide, collide_i, collide_j, movement)
		end
	end

	if collide and collide.field_collectable then
		return self:handle_collectable(entity, collide, collide_i, collide_j, movement)
	end

	if not collide and not is_user_controlled then
		return self:handle_props_movement(entity, collide, collide_i, collide_j, movement)
	end

	--if not collide and is_user_controlled then
	--	return self:handle_glue(entity, collide, collide_i, collide_j, movement)
	--end
end


---@param portal entity.field
---@return entity|nil
function M:find_pair_portal(portal)
	for _, entity in ipairs(self.world.entities) do
		if entity.field_portal and entity ~= portal and entity.prefab_id == portal.prefab_id then
			return entity
		end
	end

	return nil
end


function M:handle_corner(entity, collide, collide_i, collide_j, movement)
	log:debug("Hit corner", { i = collide_i, j = collide_j, prefab_id = collide.prefab_id })

	local tile_corner = collide.field_corner
	local next_move_side = self:_next_move_side_from_corner(tile_corner, movement)
	local is_solid = not next_move_side

	if next_move_side then
		local next_entity, next_i, next_j = self.world.field:get_collide_entity_in_direction(collide, next_move_side)
		if not next_entity then
			return nil
		end

		local target_x, target_y = self.world.field:get_xy(collide_i, collide_j)
		self.world.transform:set_position(entity, target_x, target_y)
		self.world.transform:set_animate_time(entity, 0.1, go.EASING_LINEAR, 0, function()
			self:move_to_cell(entity, next_entity, next_i, next_j, next_move_side)
		end)
		self.world.sound:play_random_speed("slide", 1.2, 0.15)
	else
		return self:handle_solid_wall(entity, collide, collide_i, collide_j, movement)
	end
end


function M:handle_solid_wall(entity, collide, collide_i, collide_j, movement)
	log:debug("Hit solid wall", { i = collide_i, j = collide_j, prefab_id = collide.prefab_id })

	-- Get a position before the next entity
	local target_x, target_y = self.world.field:get_xy(collide_i - movement.i, collide_j - movement.j)
	self.world.transform:set_position(entity, target_x, target_y)
	self.world.transform:set_animate_time(entity, 0.3, go.EASING_OUTEXPO)

	self.world.camera:shake(3, 0.3)
	self.world.sound:play_random_speed("slide", 1.2, 0.15)

	---@class event.field_movable.on_field_solid_wall_collide
	---@field i number
	---@field j number
	---@field entity entity
	---@field collide entity.field?

	self.world.event_bus:trigger("on_field_solid_wall_collide", {
		i = collide_i,
		j = collide_j,
		entity = entity,
		collide = collide,
	})
end


function M:handle_glue(entity, collide, collide_i, collide_j, movement)
	log:debug("Hit glue", { i = collide_i, j = collide_j, prefab_id = collide and collide.prefab_id })

	local target_x, target_y = self.world.field:get_xy(collide_i, collide_j)
	self.world.transform:set_position(entity, target_x, target_y)
	self.world.transform:set_animate_time(entity, 0.3, go.EASING_OUTEXPO)

	self.world.sound:play_random_speed("slide", 1.2, 0.15)

	if collide then
		self.world.event_bus:trigger("on_field_glue_collide", {
			i = collide_i,
			j = collide_j,
			entity = entity,
			collide = collide,
		})
	end
end

function M:handle_portal(entity, collide, collide_i, collide_j, movement)
	log:debug("Hit portal", { i = collide_i, j = collide_j, prefab_id = collide.prefab_id })

	local target_x, target_y = self.world.field:get_xy(collide_i, collide_j)
	local pair_portal = self:find_pair_portal(collide)

	local is_revese_movement = collide.field_portal_reverse
	if is_revese_movement then
		movement = { i = -movement.i, j = -movement.j }
	end

	local is_will_collide_after_portal = pair_portal and self.world.field:get_collide_entity_in_direction(pair_portal, movement)

	if pair_portal and is_will_collide_after_portal then
		self.world.event_bus:trigger("on_field_portal_collide", {
			i = collide_i,
			j = collide_j,
			entity = entity,
			collide = collide,
		})

		-- Move entity to the pair portal position
		self.world.sound:play_random_speed("slide", 1.2, 0.15)
		self.world.transform:set_position(entity, target_x, target_y)
		self.world.transform:set_animate_time(entity, 0.25, go.EASING_OUTBACK, 0, function()
			self.world.sound:play("portal")
			self.world.transform:set_position(entity, pair_portal.transform.position_x, pair_portal.transform.position_y)
			self.world.transform:set_animate_time(entity, 0, nil, nil, function()
				-- Continue moving in the same direction from the portal exit
				local portal_collide_entity, portal_ci, portal_cj = self.world.field:get_collide_entity_in_direction(pair_portal, movement)
				self:move_to_cell(entity, portal_collide_entity, portal_ci, portal_cj, movement)
			end)
		end)

		return
	end
end


function M:handle_collectable(entity, collide, collide_i, collide_j, movement)
	log:debug("Hit collectable", { i = collide_i, j = collide_j, prefab_id = collide.prefab_id })

	local collide_after_pick, _, _ = self.world.field:get_collide_entity_in_direction(collide, movement)
	if not collide_after_pick then
		return
	end

	---@class event.field_movable.on_field_collectable_collide
	---@field i number
	---@field j number
	---@field entity entity
	---@field collide entity.field

	self.world.event_bus:trigger("on_field_collectable_collide", {
		i = collide_i,
		j = collide_j,
		entity = entity,
		collide = collide,
	})
	self.world:removeEntity(collide)
	-- Continue the movement, stay on the collectable (collided position)
	local collide_entity, ci, cj = self.world.field:get_collide_entity_in_direction(collide, movement)
	self:move_to_cell(entity, collide_entity, ci, cj, movement)
end


function M:handle_pushable(entity, collide, collide_i, collide_j, movement)
	log:debug("Hit pushable", { i = collide_i, j = collide_j, prefab_id = collide.prefab_id })
end


function M:handle_props_movement(entity, collide, collide_i, collide_j, movement)
	log:debug("Hit props movement", { i = collide_i, j = collide_j, prefab_id = collide and collide.prefab_id })

	local target_x, target_y = self.world.field:get_xy(collide_i, collide_j)
	self.world.transform:set_position(entity, target_x, target_y)
	self.world.transform:set_animate_time(entity, 0.3, go.EASING_OUTEXPO, 0.05)

	---@class event.field_movable.on_field_props_movement
	---@field i number
	---@field j number
	---@field entity entity
	---@field collide entity.field?

	self.world.event_bus:trigger("on_field_props_movement", {
		i = collide_i,
		j = collide_j,
		entity = entity,
		collide = collide,
	})
end


local CORNER_MAP_REVERSE = {
	["SE"] = { "right", "down" },
	["SW"] = { "left", "down" },
	["NE"] = { "right", "up" },
	["NW"] = { "left", "up" },
}

---@param tile_corner string? NE NW SE SW
---@param movement table { i = number, j = number }
---@return table? table { i = number, j = number }|nil
function M:_next_move_side_from_corner(tile_corner, movement)
	if not tile_corner then
		return nil
	end

	local first_side = CORNER_MAP_REVERSE[tile_corner][1]
	local second_side = CORNER_MAP_REVERSE[tile_corner][2]

	local first_side_movement = self.MOVEMENT_MAP[first_side]
	local second_side_movement = self.MOVEMENT_MAP[second_side]

	if first_side_movement.i == -movement.i and first_side_movement.j == -movement.j then
		return second_side_movement
	end

	if second_side_movement.i == -movement.i and second_side_movement.j == -movement.j then
		return first_side_movement
	end

	return nil
end


-- Pick specifir entity_id tile_floor_bg and highlight it
function M:highlight_cells(entity_i, entity_j, collide_i, collide_j, movement_time)

end


return M

