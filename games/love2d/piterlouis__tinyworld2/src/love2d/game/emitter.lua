--
-- TinyWorld
--
-- Copyright (c) 2025 piterlouis
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

---@class Emitter
---@field ps love.ParticleSystem
local Emitter = {}
Emitter.__index = Emitter

local particleImage = nil
function Emitter:new(r1, g1, b1, a1, r2, g2, b2, a2)
  if particleImage  == nil then
    local imageData = love.image.newImageData(4, 4)
    imageData:mapPixel(function() return 1, 1, 1, 1 end)
    particleImage = love.graphics.newImage(imageData)
  end

local ps = love.graphics.newParticleSystem(particleImage, 1000)
  ps:setParticleLifetime(0.5, 1.5)
  ps:setEmissionRate(0)
  ps:setSizes(1.0, 1.5)
  ps:setSpeed(100, 200)
  ps:setLinearAcceleration(0, 0)
  ps:setRadialAcceleration(100, 100)
  ps:setSpread(2 * math.pi)
  ps:setColors(
    r1 or 1.0, g1 or 1.0, b1 or 1.0, a1 or 1.0,
    r2 or 1.0, g2 or 1.0, b2 or 1.0, a2 or 0.0
  )

  local emitter = {
    ps = ps,
  }
  setmetatable(emitter, Emitter)

  return emitter
end

function Emitter:setPosition(x, y)
  self.ps:setPosition(x or 0, y or 0)
end

function Emitter:setColors(r1, g1, b1, a1, r2, g2, b2, a2)
  self.ps:setColors(
    r1 or 1.0, g1 or 1.0, b1 or 1.0, a1 or 1.0,
    r2 or 1.0, g2 or 1.0, b2 or 1.0, a2 or 0.0
  )
end

function Emitter:emit(count)
  self.ps:emit(count or 1)
end

function Emitter:update(dt)
  self.ps:update(dt)
end

function Emitter:draw()
  love.graphics.draw(self.ps)
end

return Emitter
