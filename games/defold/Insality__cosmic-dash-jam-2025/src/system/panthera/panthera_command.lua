local panthera = require("panthera.panthera")

---@class world
---@field panthera system.panthera.command

---@class system.panthera.command
---@field panthera system.panthera
local M = {}


---@return system.panthera.command
function M.create(panthera_decore)
	return setmetatable({ panthera = panthera_decore }, { __index = M })
end


---@param entity entity
---@param animation_state panthera.animation
---@param animation_id string
function M:play_state(entity, animation_state, animation_id)
	if not self.panthera.indices[entity] then
		return
	end

	panthera.play(animation_state, animation_id)
end

local play_options = {
	is_skip_init = false,
	is_loop = false,
	speed = 1,
}

---@param entity entity
---@param animation_id string
---@param is_skip_init boolean|nil
---@param is_loop boolean|nil
---@param speed number|nil
function M:play(entity, animation_id, is_skip_init, is_loop, speed)
	local p = entity.panthera
	assert(p, "Entity doesn't have panthera component")

	if not self.panthera.indices[entity] then
		return
	end

	panthera.play(p.animation_state, animation_id, {
		is_skip_init = is_skip_init or false,
		is_loop = is_loop or false,
		speed = speed or 1,
		callback = function()
			if p.default_animation then
				self.panthera:play_default_animation(entity)
			end
		end,
	})
end


function M:play_detached(entity, animation_id, is_skip_init, is_loop, speed)
	local p = entity.panthera
	assert(p, "Entity doesn't have panthera component")

	if not self.panthera.indices[entity] then
		return
	end

	play_options.is_skip_init = is_skip_init or false
	play_options.is_loop = is_loop or false
	play_options.speed = speed or 1

	panthera.play_detached(p.animation_state, animation_id, play_options)
end

---@param entity entity
---@param animation_id string
---@param progress number
function M:set_progress(entity, animation_id, progress)
	local p = entity.panthera
	assert(p, "Entity doesn't have panthera component")

	if not self.panthera.indices[entity] then
		return
	end

	local time = panthera.get_duration(p.animation_state, animation_id)
	panthera.set_time(p.animation_state, animation_id, time * progress)
end


---@param entity entity
---@return string?
function M:get_current_animation(entity)
	local p = entity.panthera
	assert(p, "Entity doesn't have panthera component")

	if panthera.is_playing(p.animation_state) then
		return panthera.get_latest_animation_id(p.animation_state)
	end

	return nil
end

return M
