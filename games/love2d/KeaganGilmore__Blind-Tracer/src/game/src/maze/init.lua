local Class            = require("lib.middleclass")
local Maze             = Class("Maze")
local Path             = ... .. "."

-- Static configuration
Maze.static.algs       = { recursiveBacktracking = require(Path .. "algs.recursive_backtracking") }
Maze.static.tileSheet  = love.graphics.newImage(Path:gsub("%.", "/") .. "tile_sheet.png")
Maze.static.shaderFunc = require(Path .. "palette_shader")
Maze.static.tileLookup = require(Path .. "tile_map")
Maze.static.tileSize   = 128
Maze.static.tileQuads  = {}

-- Precompute quads from the tile map
do
	local sheetW, sheetH = Maze.static.tileSheet:getDimensions()
	for bitmask, pos in pairs(Maze.static.tileLookup) do
		local y = (pos[1] - 1) * Maze.tileSize
		local x = (pos[2] - 1) * Maze.tileSize
		Maze.static.tileQuads[bitmask] = love.graphics.newQuad(x, y, Maze.tileSize, Maze.tileSize, sheetW, sheetH)
	end
end

-- Constructor
function Maze:initialize(rows, cols, alg, seed)
	local generator = Maze.algs[alg or "recursiveBacktracking"]
	assert(generator, "Invalid algorithm: " .. tostring(alg))
	self.rows = rows
	self.cols = cols
	self.seed = seed
	self.grid, self.path, self.tileMap = generator(rows, cols, seed)
	self.displayScale = 0.3
	self.displayTileSize = nil
	self.x = 0
	self.y = 0
	self.canvas = love.graphics.newCanvas(self.cols * Maze.tileSize, self.rows * Maze.tileSize)
	self:renderToCanvas()
end

function Maze:setPosition(x, y)
	self.x = x or 0
	self.y = y or 0
end

-- Render the maze to the canvas (called once)
function Maze:renderToCanvas()
	love.graphics.setCanvas(self.canvas)
	love.graphics.clear()
	for r = 1, self.rows do
		for c = 1, self.cols do
			local quad = Maze.tileQuads[self.tileMap[r][c]]
			if quad then love.graphics.draw(Maze.tileSheet, quad, (c - 1) * Maze.tileSize, (r - 1) * Maze.tileSize) end
			if self.path[r][c] == 1 then
				love.graphics.setColor(1, 0, 0, 0.5)
				love.graphics.rectangle("fill", (c - 1) * Maze.tileSize, (r - 1) * Maze.tileSize, Maze.tileSize,
					Maze.tileSize)
				love.graphics.setColor(1, 1, 1, 1)
			end
		end
	end
	love.graphics.setCanvas()
end

function Maze:getPosition()
	return self.x, self.y
end

function Maze:setScale(scale)
	self.displayScale = scale
	self.displayTileSize = nil
end

function Maze:setTileSize(tileSize)
	self.displayTileSize = tileSize
	self.displayScale = tileSize / Maze.tileSize
end

function Maze:setSize(width, height)
	local scaleX = width / (self.cols * Maze.tileSize)
	local scaleY = height / (self.rows * Maze.tileSize)
	local scale = math.min(scaleX, scaleY)
	self:setScale(scale)
end

function Maze:getEffectiveTileSize()
	return self.displayTileSize or (Maze.tileSize * self.displayScale)
end

function Maze:getDisplayDimensions()
	local effectiveTileSize = self:getEffectiveTileSize()
	return self.cols * effectiveTileSize, self.rows * effectiveTileSize
end

-- Print the maze to console
function Maze:print()
	for r = 1, self.rows do
		local row = self.grid[r]
		local line = {}
		for c = 1, self.cols do
			line[#line + 1] = (row[c] == 1) and "#" or " "
		end
		print(table.concat(line))
	end
end

function Maze:draw()
	love.graphics.draw(self.canvas, self.x, self.y, 0, self.displayScale, self.displayScale)
end

return Maze
