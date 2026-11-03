local panthera = require("panthera.panthera")

local M = {}


---@param panthera_decore system.panthera
function M.register(panthera_decore)
	M.panthera = panthera_decore
end


---@param entity entity
---@param animation_state panthera.animation
---@param animation_id string
function M.play_state(entity, animation_state, animation_id)
	if not M.panthera.indices[entity] then
		return
	end

	panthera.play(animation_state, animation_id)
end


---@param entity entity
---@param animation_id string
---@return boolean
function M.is_playing(entity, animation_id)
	local p = entity.panthera
	assert(p, "Entity doesn't have panthera component")
	return panthera.is_playing(p.animation_state) and panthera.get_latest_animation_id(p.animation_state) == animation_id
end


---@param entity entity
---@param animation_id string
---@param options panthera.options?
function M.play(entity, animation_id, options)
	local p = entity.panthera
	assert(p, "Entity doesn't have panthera component")

	if not M.panthera.indices[entity] then
		return
	end

	options = options or {}

	panthera.play(p.animation_state, animation_id, {
		is_skip_init = options.is_skip_init or false,
		is_loop = options.is_loop or false,
		speed = options.speed or 1,
		callback_event = options.callback_event,
		callback = function(animation_path)
			if p.default_animation then
				panthera.play(p.animation_state, p.default_animation, {
					is_loop = p.is_loop or false,
					speed = p.speed or 1,
				})
			end

			if options.callback then
				options.callback(animation_id)
			end
		end
	})
end


local EMPTY_OPTIONS = {}

---@param entity entity
---@param animation_id string
---@param track_id string|number|nil nil = use p.animation_state, else clone state to p.tracks[track_id]
---@param options panthera.options?
function M.play_track(entity, animation_id, track_id, options)
	local p = entity.panthera
	assert(p, "Entity doesn't have panthera component")

	if not M.panthera.indices[entity] then
		return
	end

	options = options or EMPTY_OPTIONS
	local state = M.get_animation_state(entity, track_id)

	panthera.play(state, animation_id, {
		is_skip_init = options.is_skip_init or false,
		is_loop = options.is_loop or false,
		speed = options.speed or 1,
		callback_event = options.callback_event,
		callback = function(animation_path)
			if p.default_animation and state == p.animation_state then
				panthera.play(p.animation_state, p.default_animation, {
					is_loop = p.is_loop or false,
					speed = p.speed or 1,
				})
			end

			if options.callback then
				options.callback(animation_id)
			end
		end
	})
end


---@param entity entity
---@param animation_id string
---@param progress number
---@param track_id string|number|nil nil = use p.animation_state, else clone state to p.tracks[track_id]
function M.set_progress(entity, animation_id, progress, track_id)
	local p = entity.panthera
	assert(p, "Entity doesn't have panthera component")

	if not M.panthera.indices[entity] then
		return
	end

	local state = M.get_animation_state(entity, track_id)
	local time = panthera.get_duration(state, animation_id)
	panthera.set_time(state, animation_id, time * progress)
end


---@param entity entity
---@param track_id string|number|nil nil = use p.animation_state, else clone state to p.tracks[track_id]
---@return panthera.animation
function M.get_animation_state(entity, track_id)
	local p = entity.panthera
	assert(p, "Entity doesn't have panthera component")

	if track_id then
		p.tracks = p.tracks or {}
		p.tracks[track_id] = p.tracks[track_id] or panthera.clone_state(p.animation_state)
		return p.tracks[track_id]
	end

	return p.animation_state
end


---@param entity entity
---@param animation_id string
---@param track_id string|number|nil nil = use p.animation_state
---@return number progress 0..1, or 0 if animation not found
function M.get_progress(entity, animation_id, track_id)
	local state = M.get_animation_state(entity, track_id)
	local duration = panthera.get_duration(state, animation_id)
	if duration == 0 then
		return 0
	end
	return panthera.get_time(state) / duration
end


return M
