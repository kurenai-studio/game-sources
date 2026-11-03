local decore = require("decore.decore")

local camera_command = require("system.camera.camera_command")
local transform_command = require("system.transform.transform_command")

---@class entity
---@field follow_cursor boolean|nil

---@class entity.follow_cursor: entity
---@field follow_cursor boolean
decore.register_component("follow_cursor", false)

---@class system.follow_cursor: system
---@field entities entity.follow_cursor[]
local M = {}


---@return system.follow_cursor
function M.create()
	return decore.system(M, "follow_cursor", { "follow_cursor", "transform" })
end


function M:postWrap()
	self.world.event_bus:process_all("input_event", self.process_inputs, self)
end


---@param actions system.input.event[]
function M:process_inputs(actions)
	if #self.entities == 0 then
		return
	end

	for i = 1, #actions do
		local action = actions[i]
		if action.screen_x ~= nil and action.screen_y ~= nil then
			local x, y = camera_command.screen_to_world(action.screen_x, action.screen_y)
			for index = 1, #self.entities do
				local entity = self.entities[index]
				transform_command.set_position(entity, x, y)
			end
		end
	end
end


return M
