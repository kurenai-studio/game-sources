local decore = require("decore.decore")

---@class system.transform_callbacks: system
---@field callbacks table
local M = {}


---@return system.transform_callbacks
function M.create_system()
	local self = decore.system(M, "transform_callbacks")
	self.callbacks = {}

	return self
end


function M:preWrap()
	self.world.event_bus:process("transform_event", self.process_transform_event, self)
end


---@param event system.transform.event
function M:process_transform_event(event)
	if event.callback then
		local time = event.animate_time or 0
		if time == 0 then
			event.callback()
		else
			table.insert(self.callbacks, {
				callback = event.callback,
				time = time + (event.delay or 0),
			})
		end
	end
end


function M:update(dt)
	for index = #self.callbacks, 1, -1 do
		local callback = self.callbacks[index]
		if callback.time > 0 then
			callback.time = callback.time - dt
			if callback.time <= 0 then
				callback.callback()
				table.remove(self.callbacks, index)
			end
		end
	end
end


return M
