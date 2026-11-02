--
-- TinyWorld
--
-- Copyright (c) 2025 piterlouis
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local Shield = {}

function Shield:new(radius)
  local shield = {
    angle = 0.0,
    time = 0.0,
    velocity = 6,
    distance = radius + 20,
    direction = 1.0,
    firstColorChange = true,
  }
  setmetatable(shield, self)
  self.__index = self
  return shield
end

function Shield:update(dt)
  local hw = love.graphics.getWidth() / 2.0
  local hh = love.graphics.getHeight() / 2.0
	if love.keyboard.isDown('right') then
		self.angle = self.angle + self.velocity * dt --0.15
		self.direction = 1.0
	elseif love.keyboard.isDown('left') then
		self.angle = self.angle - self.velocity * dt --0.15
		self.direction = -1.0
	else
		self.angle = self.angle + self.direction * self.velocity * 0.1 * dt
  end
	self.x = hw + math.cos(self.angle) * self.distance
	self.y = hh + math.sin(self.angle) * self.distance

	if self.firstColorChange then
		self.time = self.time + dt
		if self.time > 1.0 then
			self.time = 0
			self.firstColorChange = false
    end
	end
end

function Shield:draw()
	love.graphics.circle('fill', self.x, self.y, 10)
end

function Shield:setPlanetRadius(radius)
  self.distance = radius + 30
end

return Shield
