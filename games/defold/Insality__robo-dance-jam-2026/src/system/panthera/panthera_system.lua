local decore = require("decore.decore")
local panthera = require("panthera.panthera")

local command_panthera = require("system.panthera.panthera_command")

---@class entity
---@field panthera component.panthera|nil

---@class entity.panthera: entity
---@field panthera component.panthera
---@field game_object component.game_object
---@field transform component.transform

---@class component.panthera
---@field animation_path string|table
---@field animation_state panthera.animation
---@field tracks table|nil [track_id] = panthera.animation
---@field default_animation string
---@field speed number|nil
---@field is_loop boolean|nil
---@field play_on_start string|boolean|nil
---@field play_on_remove string|nil Play animation on entity remove
---@field randomize_start_time boolean|nil Randomize start time of the animation
decore.register_component("panthera", {})

---@class system.panthera: system
---@field entities entity.panthera[]
local M = {}


---@return system.panthera
function M.create()
	local system = decore.system(M, "panthera")
	system.filter = decore.ecs.requireAll("panthera", "game_object", decore.ecs.rejectAll("hidden"))
	command_panthera.register(system)

	return system
end


---@private
function M:postWrap()
	self.world.event_bus:process_all("window_event", self.process_window_event, self)
end


---@param entity entity.panthera
function M:onAdd(entity)
	local p = entity.panthera

	local animation_state
	if entity.game_object.object then
		animation_state = panthera.create_go(p.animation_path, nil, entity.game_object.object)
	else
		animation_state = panthera.create_go(p.animation_path, nil, { ["/"]  = entity.game_object.root })
	end

	if animation_state then
		p.animation_state = animation_state
		p.animation_path = animation_state.animation_path

		if p.play_on_start then
			local animation_id = p.play_on_start
			if type(animation_id) == "boolean" then
				animation_id = p.default_animation
			end
			if animation_id then
				if p.randomize_start_time then
					-- Can I do this normally?..
					local duration = panthera.get_duration(p.animation_state, animation_id)
					local from = math.random() * duration
					local speed = duration / (duration - from)

					panthera.play_tweener(p.animation_state, animation_id, {
						from = math.random() * duration,
						speed = speed,
						callback = function()
							if p.default_animation then
								panthera.play(p.animation_state, p.default_animation, {
									is_loop = p.is_loop or false,
									speed = p.speed or 1
								})
							end
						end
					})
				else
					panthera.play(p.animation_state, animation_id, {
						is_loop = false,
						speed = p.speed or 1,
						callback = function()
							if p.default_animation then
								panthera.play(p.animation_state, p.default_animation, {
									is_loop = p.is_loop or false,
									speed = p.speed or 1
								})
							end
						end
					})
				end
			end
		end
	end
end


---@param entity entity.panthera
function M:onRemove(entity)
	local p = entity.panthera
	panthera.stop(p.animation_state)

	if p.play_on_remove then
		panthera.play(p.animation_state, p.play_on_remove)
	end
end


---@private
---@param window_events constant[]
function M:process_window_event(window_events)
	for i = 1, #window_events do
		local window_event = window_events[i]
		if window_event == window.WINDOW_EVENT_FOCUS_GAINED then
			panthera.reload_animation()
		end
	end
end


return M
