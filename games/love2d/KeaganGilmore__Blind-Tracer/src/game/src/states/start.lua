local Maze = require("src.maze") -- Assuming 'src.maze' exists and provides a Maze class

local Start = {}

function Start:init()
	self.maze = Maze(21, 21)
	self:resizeMaze()
end

function Start:resizeMaze()
	local sW, sH = love.graphics.getDimensions()
	local size = math.min(sW, sH) * 0.9
	self.maze:setSize(size, size)
	local w, h = self.maze:getDisplayDimensions()
	self.maze:setPosition((sW - w) / 2, (sH - h) / 2)
end

function Start:update(dt)
	-- No update logic needed for this simple maze display
end

function Start:draw()
	love.graphics.setShader(self.shader)
	self.maze:draw()
	love.graphics.setShader()
end

function Start:mousepressed()
	-- self.maze = Maze(21, 21)
	-- self:resizeMaze()
end

function Start:resize(w, h)
	self:resizeMaze()
end

return Start
