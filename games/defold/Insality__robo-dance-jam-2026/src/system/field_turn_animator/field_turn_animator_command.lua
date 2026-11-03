local field_const = require("system.field.field.const")
local field_turn_result = require("system.field.field.field_turn_result")
local level_manager_command = require("system.level_manager.level_manager_command")
local transform_command = require("system.transform.transform_command")
local HASH_POSITION = hash("position")


---@param position_x number
---@param position_y number
---@param position_z number
---@return number
local function get_render_position_z(position_x, position_y, position_z)
	return -position_y / 100 + position_x / 1000 + position_z / 10 + (0.0001 * math.random())
end

---@class system.field_turn_animator.command
---@field field_turn_animator system.field_turn_animator
local M = {}


---@param entity entity
---@param turn field.turn_result
---@param delay number
local function animate_blocked_push(entity, turn, delay)
	local root = entity.game_object.root
	local current_x = entity.transform.position_x
	local current_y = entity.transform.position_y
	local current_z = get_render_position_z(current_x, current_y, entity.transform.position_z)
	local side_data = field_const.TURN_SIDE_DATA[turn.side] or field_const.TURN_SIDE_DATA[field_const.TURN_SIDE.NONE]
	local target_i = turn.target_i + side_data.i
	local target_j = turn.target_j + side_data.j
	local target_x, target_y = level_manager_command.get_xy(target_i, target_j)
	local push_x = current_x + (target_x - current_x) * 0.5
	local push_y = current_y + (target_y - current_y) * 0.5
	local push_z = get_render_position_z(push_x, push_y, entity.transform.position_z)
	local push_duration = 0.6

	go.animate(root, HASH_POSITION, go.PLAYBACK_ONCE_FORWARD, vmath.vector3(push_x, push_y, push_z), go.EASING_OUTCIRC, push_duration, delay, function()
		go.animate(root, HASH_POSITION, go.PLAYBACK_ONCE_FORWARD, vmath.vector3(current_x, current_y, current_z), go.EASING_OUTBACK, push_duration / 2)
	end)
end


---@param entity entity
---@param turn field.turn_result
local function animate_attack_cell_push(entity, turn)
	local root = entity.game_object.root
	local current_x = entity.transform.position_x
	local current_y = entity.transform.position_y
	local current_z = get_render_position_z(current_x, current_y, entity.transform.position_z)
	local side_data = field_const.TURN_SIDE_DATA[turn.side]
	local target_i = turn.target_i + side_data.i
	local target_j = turn.target_j + side_data.j
	local target_x, target_y = level_manager_command.get_xy(target_i, target_j)
	local push_x = current_x + (target_x - current_x) * 0.1
	local push_y = current_y + (target_y - current_y) * 0.1
	local push_z = get_render_position_z(push_x, push_y, entity.transform.position_z)

	go.animate(root, HASH_POSITION, go.PLAYBACK_ONCE_FORWARD, vmath.vector3(push_x, push_y, push_z), go.EASING_OUTCIRC, 0.15, 0.6, function()
		go.animate(root, HASH_POSITION, go.PLAYBACK_ONCE_FORWARD, vmath.vector3(current_x, current_y, current_z), go.EASING_OUTSINE, 0.4)
	end)
end


---@param field_turn_animator system.field_turn_animator
function M.register(field_turn_animator)
	M.field_turn_animator = field_turn_animator
end


---@param turns field.turn_result[]
function M.animate_turns(turns)
	local world = M.field_turn_animator.world

	for _, turn in ipairs(turns) do
		local entity = world:findEntity("id", turn.entity_id)
		if entity then
			M.animate_turn(entity, turn)
		end
	end
end


---@param entity entity
---@param turn field.turn_result
function M.animate_turn(entity, turn)
	local t = turn.type
	if t == field_turn_result.TURN_RESULT_TYPE.MOVE then
		M.animate_turn_move(entity, turn)
	elseif t == field_turn_result.TURN_RESULT_TYPE.MOVE_BLOCKED then
		M.animate_turn_move_blocked(entity, turn)
	elseif t == field_turn_result.TURN_RESULT_TYPE.KNOCKBACK_MOVE then
		M.animate_turn_knockback_move(entity, turn)
	elseif t == field_turn_result.TURN_RESULT_TYPE.KNOCKBACK_MOVE_BLOCKED then
		M.animate_turn_knockback_move_blocked(entity, turn)
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.SET_STATE then
		M.animate_turn_set_state(entity, turn)
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.ATTACK_CELL then
		M.animate_turn_attack_cell(entity, turn)
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.DAMAGE then
		M.animate_turn_damage(entity, turn)
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.DIE then
		M.animate_turn_die(entity, turn)
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.REMOVE_ENTITY then
		M.animate_turn_remove_entity(entity, turn)
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.ENTITY_COLLISION then
		M.animate_turn_entity_collision(entity, turn)
	end

	M.field_turn_animator.world.event_bus:trigger("field_turn_visual_event", {
		entity = entity,
		turn = turn,
	})
end


-- Generic animations like grid position etc

---@param entity entity
---@param turn field.turn_result
function M.animate_turn_move(entity, turn)
	if turn.resolver_id ~= "teleport" then
		local x, y = level_manager_command.get_xy(turn.target_i, turn.target_j)
		transform_command.set_position(entity, x, y)
		transform_command.set_animate_time(entity, 0.6, go.EASING_OUTEXPO)
	else
		local x, y = level_manager_command.get_xy(turn.target_i, turn.target_j)
		timer.delay(0.3, false, function()
			transform_command.set_position(entity, x, y)
			--transform_command.set_animate_time(entity, 0.6, go.EASING_OUTEXPO)
		end)
	end
end


---@param entity entity
---@param turn field.turn_result
function M.animate_turn_move_blocked(entity, turn)
	animate_blocked_push(entity, turn, 0)
end


---@param entity entity
---@param turn field.turn_result
function M.animate_turn_set_state(entity, turn)
end


---@param entity entity
---@param turn field.turn_result
function M.animate_turn_attack_cell(entity, turn)
	if not field_const.TURN_SIDE_DATA[turn.side] then
		return
	end

	animate_attack_cell_push(entity, turn)
end


---@param entity entity
---@param turn field.turn_result
function M.animate_turn_damage(entity, turn)
end


---@param entity entity
---@param turn field.turn_result
function M.animate_turn_die(entity, turn)
end


---@param entity entity
---@param turn field.turn_result
function M.animate_turn_entity_collision(entity, turn)
end


---@param entity entity
---@param turn field.turn_result
function M.animate_turn_remove_entity(entity, turn)
	timer.delay(0.6 * 4, false, function()
		M.field_turn_animator.world:removeEntity(entity)
	end)
end


---@param entity entity
---@param turn field.turn_result
function M.animate_turn_knockback_move(entity, turn)
	timer.delay(0.6 + 0.6 - 0.5, false, function()
		local x, y = level_manager_command.get_xy(turn.target_i, turn.target_j)
		transform_command.set_position(entity, x, y)
		transform_command.set_animate_time(entity, 0.6 + 0.5, go.EASING_OUTEXPO)
	end)
end


---@param entity entity
---@param turn field.turn_result
function M.animate_turn_knockback_move_blocked(entity, turn)
	animate_blocked_push(entity, turn, 0.6 + 0.6 - 0.5)
end


---@param turn field.turn_result
function M.animate_turn_spawn(entity, turn)
end


return M
