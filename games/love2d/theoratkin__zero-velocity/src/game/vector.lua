Object = require "classic"
local Vector = Object:extend()


function Vector:new(x, y)
	self.x = x or 0
	self.y = y or 0
end


function Vector:mag()
	return math.sqrt(self.x * self.x + self.y * self.y)
end


function Vector:normalize()
	local mag = self:mag()
	self.x = self.x / mag
	self.y = self.y / mag
	return self
end


function Vector:rotate(origin, cs, sn)
	local tx = self.x - origin.x
	local ty = self.y - origin.y
	self.x = tx * cs - ty * sn + origin.x
	self.y = tx * sn + ty * cs + origin.y
end


function Vector:__add(other)
	return Vector(self.x + other.x, self.y + other.y)
end


function Vector:__mul(other)
	return Vector(self.x * other, self.y * other)
end


function Vector:__div(other)
	return Vector(self.x / other, self.y / other)
end


function Vector:__tostring()
	return "(" .. self.x .. ", " .. self.y .. ")"
end


return Vector
