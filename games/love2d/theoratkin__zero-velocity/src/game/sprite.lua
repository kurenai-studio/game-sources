Object = require "classic"
local Sprite = Object:extend()


function Sprite:new(path)
	self.image = love.graphics.newImage(path)
	self.quads = {}

	-- It's a pixel art game, so we're never going to use linear filtering.
	self.image:setFilter("nearest", "nearest")

	-- Adding a fullsize quad as a shortcut.
	self:addQuad("fullsize", 0, 0, self.image:getWidth(), self.image:getHeight())
end


function Sprite:getImage()
	return self.image
end


function Sprite:addQuad(name, x, y, h, w, ox, oy)
	self.quads[name] = {
		quad = love.graphics.newQuad(
			x, y, h, w, self.image:getWidth(), self.image:getHeight()
		),
		x = x, y = y,
		w = w, h = h,
		ox = ox or 0,
		oy = oy or 0
	}
end


function Sprite:getQuad(name)
	return self.quads[name]
end


return Sprite
