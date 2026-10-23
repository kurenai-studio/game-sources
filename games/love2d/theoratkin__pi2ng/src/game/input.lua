Object = require "classic"
local Input = Object:extend()


-- Specifies how sensitive a joystick is.
JOYSTICK_DEADZONE = 0.3

-- Table of mappings. A mapping can have multiple bindings.
-- Each binding can be one of the following:
-- { "key", name, [direction, 1 by default] }
-- { "button", index, [direction, 1 by default] }
-- { "axis", index, direction }
DEFAULT_MAPPINGS = {
	right = {
		{ "key", "right" },
		{ "key", "d" },
		{ "key", "l" },
		{ "key", ";" },
		{ "axis", 1, 1},
	};

	left = {
		{ "key", "left", -1 },
		{ "key", "a", -1 },
		{ "key", "h", -1 },
		{ "key", "j", -1 },
		{ "axis", 1, -1 },
	};

	fire = {
		{ "key", "space" },
		{ "key", "return" },
		{ "button", 1 }
	};

	back = {
		{ "key", "escape" },
		{ "key", "q" },
		{ "key", "backspace" },
		{ "button", 2 },
		{ "button", 7 },
		{ "button", 8 },
	};

	flashing = {
		{ "key", "f" },
		{ "button", 3 },
	};
}

function Input:isValidJoystick(device)
	if device:getAxisCount() == 1 then
		return true
	end
end

function Input:new()
	self.joystick = nil
	if love.joystick then
		local joysticks = love.joystick.getJoysticks()
		for _, joystick in ipairs(joysticks) do
			if not self:isValidJoystick(joystick) then
				self.joystick = joystick
				break
			end
		end
	end
	self.mappings = DEFAULT_MAPPINGS
	self.axis = {}
	self.buttons = {}
	self.states = {}
	for mapping in pairs(self.mappings) do
		self.states[mapping] = { state = false, down = false, up = false }
	end
end


-- Returns whether a mapping is currently pressed.
function Input:state(name)
	return self.states[name].state
end


-- Returns true on the first frame a mapping is pressed.
function Input:down(name)
	return self.states[name].down
end


-- Returns true on the first frame a mapping is released.
function Input:up(name)
	return self.states[name].up
end


-- Returns mapping value.
function Input:value(name)
	return self.states[name].value
end


function Input:update(dt)
	-- Reset joystick state
	self.axis = {}
	self.buttons = {}
	
	-- Only process joystick input if we have a valid, connected joystick
	if self.joystick and self.joystick:isConnected() then
		for i = 1, self.joystick:getAxisCount() do
			local raw_value = self.joystick:getAxis(i)
			-- Ensure the value is within valid range
			if raw_value < -1 or raw_value > 1 then
				raw_value = 0
			end
			-- Apply deadzone
			if math.abs(raw_value) < JOYSTICK_DEADZONE then
				raw_value = 0
			end
			self.axis[i] = raw_value
		end
		
		for i = 1, self.joystick:getButtonCount() do
			self.buttons[i] = self.joystick:isDown(i)
		end
	end

	for mapping in pairs(self.mappings) do
		local prevstate = self.states[mapping].state
		local value = self:queryValue(mapping)
		local state = value ~= 0
		self.states[mapping] = {
			down = state and not prevstate;
			up   = not state and prevstate;
			state = state;
			value = value
		}
	end
end


-- Internal function that actually queries binding values.
-- Use state(), down(), up() and value() from the outside.
function Input:queryValue(name)
	local mapping = self.mappings[name]
	for i, binding in pairs(mapping) do
		if binding[1] == "key" and
			love.keyboard.isScancodeDown(binding[2])
		then
			return binding[3] or 1
		end

		if binding[1] == "button" and self.buttons[binding[2]] then
			return binding[3] or 1
		end

		if binding[1] == "axis" then
			local val = self.axis[binding[2]]
			local sign = binding[3]
			if val ~= nil then
				if sign > 0 and val > 0 then
					return val
				end
				if sign < 0 and val < 0 then
					return val
				end
			end
		end
	end
	return 0
end


function Input:joystickadded(joystick)
	if not self.joystick and not self:isValidJoystick(joystick) then
		self.joystick = joystick
	end
end


function Input:joystickremoved(joystick)
	if self.joystick == joystick then
		local joysticks = love.joystick.getJoysticks()
		self.joystick = nil
		for _, j in ipairs(joysticks) do
			if not self:isValidJoystick(j) then
				self.joystick = j
				break
			end
		end
	end
end


return Input
