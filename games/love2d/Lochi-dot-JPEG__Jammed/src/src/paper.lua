Paper = {}
function Paper:new(_position, _id, room)
	local newPaper = { init_pos = _position * TileSize, position = _position * TileSize, id = _id, room = room }
	self.__index = self
	return setmetatable(newPaper, self)
end

function Paper:Reset()
	self.position = self.init_pos
end

function Paper:Draw()
	local paper_pos = self.position - PlayerPos
	love.graphics.draw(Textures.paper, paper_pos.x + DefaultOffsetX, paper_pos.y + DefaultOffsetY)
end
