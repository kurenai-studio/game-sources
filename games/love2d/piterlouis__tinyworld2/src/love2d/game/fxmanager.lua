--
-- TinyWorld
--
-- Copyright (c) 2025 piterlouis
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local fxManager = {
  changeFx = love.audio.newSource("game/fx/Change.mp3", "static"),
  explosionFx = love.audio.newSource("game/fx/Explosion.mp3", "static"),
  pingFx = love.audio.newSource("game/fx/Ping.mp3", "static"),
  shieldFx = love.audio.newSource("game/fx/Shield.mp3", "static"),
  shootFx = love.audio.newSource("game/fx/Shoot.mp3", "static"),
}

love.audio.setVolume(0.15)

function fxManager.playFxChange()
  local self = fxManager
  if self.changeFx:isPlaying() then
    self.changeFx:stop()
  end
  self.changeFx:play()
end

function fxManager.playFxExplosion()
  local self = fxManager
  if self.explosionFx:isPlaying() then
    self.explosionFx:stop()
  end
  self.explosionFx:play()
end

function fxManager.playFxPing()
  local self = fxManager
  if self.pingFx:isPlaying() then
    self.pingFx:stop()
  end
  self.pingFx:play()
end

function fxManager.playFxShield()
  local self = fxManager
  if self.shieldFx:isPlaying() then
    self.shieldFx:stop()
  end
  self.shieldFx:play()
end

function fxManager.playFxShoot()
  local self = fxManager
  if self.shootFx:isPlaying() then
    self.shootFx:stop()
  end
  self.shootFx:play()
end

return fxManager
