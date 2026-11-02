--
-- TinyWorld
--
-- Copyright (c) 2025 piterlouis
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

---@class Meteorite
---@field delay number
---@field angle number
---@field distance number
---@field velocity number
---@field color number
---@field x number
---@field y number
---@field visible boolean
local Meteorite = {}
Meteorite.__index = Meteorite

function Meteorite:new(level)
  local hw = love.graphics.getWidth() / 2.0
  local hh = love.graphics.getHeight() / 2.0

  local meteoro = {
    delay = 0,
    angle = math.rad(love.math.random() * 360),
    distance = math.max(hw * 2, hh * 2) + love.math.random() * 200,
    velocity = 1 + 2 * level / 10 * love.math.random(),
    color = 0,
    x = -20,
    y = -20,
    visible = true,
  }

	local aleatory =  love.math.random()
  if aleatory < 0.33 then
		meteoro.color = 1
	elseif aleatory < 0.66 then
		meteoro.color = 2
	else
		meteoro.color = 3
  end

  setmetatable(meteoro, Meteorite)
  return meteoro
end

function Meteorite:update(dt)
	self.delay = self.delay - dt
	if self.delay > 0 then
		return
	else
		self.delay = 0
  end

	self.distance = self.distance - self.velocity
	if self.distance > 0 then
    local hw = love.graphics.getWidth() / 2.0
    local hh = love.graphics.getHeight() / 2.0
		self.x = hw + math.cos(self.angle) * self.distance;
		self.y = hh + math.sin(self.angle) * self.distance;

	else
		self.distance = 0
  end
end

function Meteorite:draw()
  if not self.visible then return end

  if self.color == 1 then
    love.graphics.setColor(1, 0, 0)  -- Red
  elseif self.color == 2 then
    love.graphics.setColor(0, 1, 0)  -- Green
  elseif self.color == 3 then
    love.graphics.setColor(0, 0, 1)  -- Blue
  end
  love.graphics.circle("fill", self.x, self.y, 10)
end

return Meteorite
