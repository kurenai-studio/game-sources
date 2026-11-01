local class = require 'middleclass'
local timer = class('timer')

function timer:initialize(max)
	self.time = 0
	self.max = max
end

function timer:update(dt, callback, bool)
	local bool = bool or false
	if not bool then
		self.time = self.time + dt
		if self.time > self.max then
			callback()
			self.time = 0
		end
	end
end

return timer