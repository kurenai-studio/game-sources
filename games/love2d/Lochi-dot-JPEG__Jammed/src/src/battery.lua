Battery = {}
function Battery:new(_position, room)
	local newBattery = {
		is_battery = true,
		init_pos = _position * TileSize,
		position = _position * TileSize,
		--id = _id,
		room = room,
	}
	self.__index = self
	return setmetatable(newBattery, self)
end

function Battery:Reset()
	self.position = self.init_pos
end

function Battery:Draw()
	local battery_pos = self.position - PlayerPos
	love.graphics.draw(Textures.battery, battery_pos.x + DefaultOffsetX, battery_pos.y + DefaultOffsetY)
end
