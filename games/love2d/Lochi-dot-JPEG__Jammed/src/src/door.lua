Door = {}
Door.__index = Door

local red = 113 / 255
local green = 125 / 255
local blue = 168 / 255

function Door:new(x, y, width, height, unlock)
	local door = {
		x = x * TileSize,
		y = y * TileSize,
		width = width * TileSize,
		height = height * TileSize,
		unlock = unlock,
		init_pos_x = x * TileSize,
		init_pos_y = y * TileSize,
	}
	setmetatable(door, Door)
	return door
end

function Door:Reset()
	self.x = self.init_pos_x
	self.y = self.init_pos_y
end

function Door:Draw()
	local door_x = self.x - PlayerPos.x + DefaultOffsetX
	local door_y = self.y - PlayerPos.y + DefaultOffsetY
	love.graphics.setColor(red, green, blue, 1)
	love.graphics.rectangle("fill", door_x, door_y, self.width, self.height)
	--print("door draws x " .. door_x .. " y " .. door_y)
	love.graphics.setColor(1, 1, 1, 1)
end

function Door:ContainsPoint(point)
	return point.x >= self.x
	    and point.x <= self.x + self.width
	    and point.y >= self.y
	    and point.y <= self.y + self.height
end
