local decore = require("decore.decore")

---@class entity
---@field player_visual boolean|nil

---@class entity.player_visual: entity
---@field player_visual boolean
---@field game_object component.game_object

decore.register_component("player_visual")

---@class system.player_visual: system
---@field entities entity.player_visual[]
---@field fx_timers number[]
local M = {}


---@return system.player_visual
function M.create_system()
	local self = decore.system(M, "player_visual", { "player_visual" })
	self.fx_timers = {}

	return self
end


function M:postWrap()
	self.world.event_bus:process("transform_event", self.process_transform_event, self)
end


---@param event system.transform.event
function M:process_transform_event(event)
	local entity = event.entity --[[@as entity.player_visual]]
	if not entity.player_visual then
		return
	end

	if event.animate_time and event.is_position_changed then
		-- Enable particles for movement
		local game_object = entity.game_object
		local fx_url = msg.url(nil, game_object.root, "trail_particles")
		if game_object.root and go.exists(game_object.root) then
			particlefx.play(fx_url)
			table.insert(self.fx_timers, timer.delay((event.animate_time * 0.6) + (event.delay or 0), false, function()
				particlefx.stop(fx_url)
			end))
		end

		self.world.panthera:play(entity, "slide", true)
	end
end


return M
