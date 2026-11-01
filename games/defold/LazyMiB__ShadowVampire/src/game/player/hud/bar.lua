local MAX_VALUE = 12
local MIN_VALUE = 1
local DISCHARGE_SPEED = 5
local CHARGE_SPEED = 0.5

local M = {
	value = MAX_VALUE,
	min_value = MIN_VALUE,
	max_value = MAX_VALUE,
	t = 0,
	paused = true,
	charge = true,
	discharge_speed = DISCHARGE_SPEED,
	charge_speed = CHARGE_SPEED
}
M.__index = M

M.DISCHARGE_SPEED = DISCHARGE_SPEED
M.CHARGE_SPEED = CHARGE_SPEED
M.MIN_VALUE = MIN_VALUE
M.MAX_VALUE = MAX_VALUE

function M.new()
	local obj = setmetatable({}, M)
	return obj
end

--- @return boolean true if is full
function M:increase()
	if self.value < self.max_value then
		self.value = self.value + 1
	end
	return self.value == self.max_value
end

--- @return boolean true if is dead
function M:decrease()
	if self.value > self.min_value then
		self.value = self.value - 1
	end
	return self.value == self.min_value
end

--- @return boolean true if is value changed
function M:update(dt)
	self.t = self.t + dt
	if self.charge then
		if self.t >= self.charge_speed then
			self.t = 0
			if self.value < self.max_value then
				self.value = self.value + 1
				return true
			end
		end
		return false
	end
	if self.paused then
		if not self.charge then
			self.t = 0
		end
		return false
	end
	if self.t >= self.discharge_speed then
		self.t = 0
		if self.value > self.min_value then
			self.value = self.value - 1
			return true
		end
	end
	return false
end

function M:is_dead()
	return self.value == self.min_value 
end

function M:is_full()
	return self.value == self.max_value
end

--- @param pause boolean
function M:set_pause(pause)
	self.paused = pause
end

function M:is_paused()
	return self.paused
end

--- @param charge boolean
function M:set_charge(charge)
	self.charge = charge
end

function M:is_charge()
	return self.charge
end

function M:get_value()
	return self.value
end

--- @param charge number
--- @param discharge number
function M:set_speed(charge, discharge)
	self.charge_speed = charge
	self.discharge_speed = discharge
end

--- @param min number
--- @param max number
function M:set_min_max(min, max)
	self.min_value = min
	self.max_value = max
end

return M