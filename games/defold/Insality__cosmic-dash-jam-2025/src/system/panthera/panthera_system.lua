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
---@field animation_state panthera.animation|nil
---@field default_animation string Played after any animation or on start if `play_on_start` is true
---@field speed number
---@field is_loop boolean|nil
---@field is_skip_init boolean|nil
---@field play_on_start string|boolean|nil Play animation_id on start. If boolean, use default_animation. Only once then default_animation will be played.
---@field play_on_remove string|nil Play animation on entity remove
decore.register_component("panthera")

---@class system.panthera: system
---@field entities entity.panthera[]
local M = {}


---@return system.panthera
function M.create_system()
	local self = decore.system(M, "panthera")
	self.filter = decore.ecs.requireAll("panthera", "game_object", decore.ecs.rejectAll("hidden"))

	return self
end


---@private
function M:postWrap()
	self.world.event_bus:process("window_event", self.process_window_event, self)
end


function M:onAddToWorld()
	self.world.panthera = command_panthera.create(self)
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
	end

	local play_on_start = p.play_on_start
	if play_on_start then
		if type(play_on_start) == "boolean" then
			play_on_start = p.default_animation
		end
		---@cast play_on_start string

		panthera.play(p.animation_state, play_on_start, {
			is_loop = p.is_loop or false,
			speed = p.speed or 1,
			is_skip_init = p.is_skip_init or false,
		})
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


function M:play_default_animation(entity)
	local p = entity.panthera
	panthera.play(p.animation_state, p.default_animation, {
		is_loop = p.is_loop or false,
		speed = p.speed or 1,
		is_skip_init = p.is_skip_init or false,
	})
end


---@private
---@param window_event system.window_event.event
function M:process_window_event(window_event)
	if window_event == window.WINDOW_EVENT_FOCUS_GAINED then
		panthera.reload_animation()
	end
end


return M
