--
-- TinyWorld
--
-- Copyright (c) 2025 piterlouis
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local fonts = require("game.fonts")

local Score = {}

local I_WHITE = 0
local I_RED = 1
local I_GREEN = 2
local I_BLUE = 3

local scoreFont = fonts.orbitron20
local hhFont = scoreFont:getHeight() / 2.0 + 1

function Score:new(points, x, y, icolor)
  local fcolor = {1, 1, 1}
  local color = icolor or 0  -- Default to 0 if no color is provided
  if color == I_WHITE then
    fcolor = {1, 1, 1}  -- Red
  elseif color == I_RED then
    fcolor = {1, 0, 0}  -- Red
  elseif color == I_GREEN then
    fcolor = {0, 1, 0}  -- Green
  elseif color == I_BLUE then
    fcolor = {0, 0, 1}  -- Blue
  end

  local score = {
    text = love.graphics.newText(scoreFont, tostring(points or 0)),
    points = points or 0,
    x = x,
    y = y,
    tw = 0,
    th = 0,
    s = 1,
    offset = {x = 0, y = 0},
    color = fcolor,
    time = 0,
  }
  setmetatable(score, self)
  self.__index = self

  return score
end

function Score:setPoints(value)
  self.points = value
  if self.points < 0 then
    self.points = 0
  end
	self.text:set(tostring(self.points))
  self.tw, self.th = self.text:getWidth() / 2, self.text:getHeight() / 2
end

function Score:update(dt)
  local time = self.time + dt
	if time % 4 then
		self.offset.x = love.math.random() * 6 - 2
		self.offset.y = love.math.random() * 6 - 2
  end
  self.time = time
end

function Score:drawIcon()
  love.graphics.setColor(self.color)
  local x, y = self.x, self.y
  local ox, oy = x + self.offset.x, y + self.offset.y
  love.graphics.circle('fill', ox, oy + hhFont, 7)
end

function Score:drawText()
  love.graphics.setColor({ self.color[1], self.color[2], self.color[3], 1 })
  local x, y, s, tw, th = self.x, self.y, self.s, self.tw, self.th
  local ox, oy = x + self.offset.x, y + self.offset.y
  love.graphics.draw(self.text, x + 16 + tw, y + th, 0, s, s, tw, th)
end

return Score
