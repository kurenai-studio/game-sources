--
-- TinyWorld
--
-- Copyright (c) 2025 piterlouis
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local fonts = require("game.fonts")
local shaders = require("game.shaders")
local flux = require("game.flux")
local g = love.graphics

local M = {
  title = love.graphics.newText(fonts.orbitron20, ''),
  desc = love.graphics.newText(fonts.orbitron20, ''),
  back = love.graphics.newText(fonts.orbitron20, ''),
  alpha = 1,
  xback = 0
}

function M.load()
  local body = {0.5, 0.5, 0.5, 0.4}
  local highlight = {1, 0.2, 0}
  M.title = g.newText(fonts.pixelify25, 'How to play')
  local descriptionText = {body, [[You control the Planetoid orbiting Tiny World.
Your objective is to block meteorites with different-colored energy,
and absorb meteorites that match the energy color of Tiny World.

  - When a meteorite of a different color hits Tiny World,
      the planet will lose]], highlight, " 3 ", body, [[structural points.

  - If the color matches, the planet will recover]], highlight, " 1 ", body, [[point.
      Be careful — if Tiny World takes too much damage, it will be destroyed.

  -  Use the arrow keys]], highlight, " LEFT ", body, "and", highlight, " RIGHT ", body, [[to move your Planetoid around
      the orbit and block incoming meteorites.

  -  Press the]], highlight, " UP ", body, [[key to activate the planet's armor for a short time.



Good luck.
A game by]], {1,1,1}, " Piterlouis"}

  M.desc = g.newText(fonts.pixelify16, descriptionText)
  M.back = g.newText(fonts.pixelify16, {{1,1,1}, '- PRESS', highlight, ' ESC ', {1,1,1}, 'TO BACK -'})
  M.xback = (g.getWidth() - M.back:getWidth()) / 2
end

function M.update(dt)
  flux.update(dt)
  if M.alpha == 1 then
    flux.to(M, 1, {alpha = 0}):ease('sineout')
  end
  if M.alpha == 0 then
    flux.to(M, 1, {alpha = 1}):ease('sineout')
  end
end

function M.draw()
  g.setShader(shaders.glow)
    g.setColor(1, 1, 1)
    g.draw(M.title, 100, 50)
    g.draw(M.desc, 100, 100)
    g.setColor(1, 1, 1, M.alpha)
    g.draw(M.back, M.xback, 700)
  g.setShader()
end

return M
