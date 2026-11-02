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

local smallFont = fonts.pixelify16
local font = fonts.pixelify25
local bigFont = fonts.pixelify50

---@class MainMenu
local MainMenu = {
  title = love.graphics.newText(bigFont, "Tiny World"),
  subtitle = love.graphics.newText(smallFont, "a game by piterlouis"),
  option1 = love.graphics.newText(font, "Play"),
  option2 = love.graphics.newText(font, "How to play"),
  madein1 = love.graphics.newText(smallFont, "Made in 48 hours"),
  madein2 = love.graphics.newText(smallFont, "for Ludum Dare #23"),
  pingFx = love.audio.newSource("game/fx/Ping.mp3", "static"),
  selectedOption = 1,
}

local function playPingFx()
  if MainMenu.pingFx:isPlaying() then
    MainMenu.pingFx:stop()
  end
  MainMenu.pingFx:play()
end

function MainMenu.draw(dt)
  love.graphics.setShader(shaders.glow)
  love.graphics.setColor(1, 1, 1)  -- Set color to white for drawing text
  love.graphics.draw(MainMenu.title, 100, 50)
  love.graphics.draw(MainMenu.subtitle, 160, 100)
  if MainMenu.selectedOption == 1 then
    love.graphics.setColor(1, 0, 0)  -- Highlight the selected option in red
    love.graphics.draw(MainMenu.option1, 140, 250)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(MainMenu.option2, 140, 280)

  elseif MainMenu.selectedOption == 2 then
    love.graphics.draw(MainMenu.option1, 140, 250)
    love.graphics.setColor(1, 0, 0)  -- Highlight the selected option in red
    love.graphics.draw(MainMenu.option2, 140, 280)
    love.graphics.setColor(1, 1, 1)
  end
  love.graphics.draw(MainMenu.madein1, 550, 730)
  love.graphics.draw(MainMenu.madein2, 550, 760)
  love.graphics.setShader()
end

function MainMenu.update(dt)
  -- Update logic for the main menu can be added here
  -- For example, handling input to navigate to different states
  -- if love.keyboard.isDown("return") then
    -- Transition to game state or rules state
    -- This is just a placeholder; actual state management would be handled in the main game loop
    -- print("Start Game or Show Rules")
  -- end
end

function MainMenu.keypressed(key)
  if key == "return" then
    -- Play the ping sound effect when the return key is pressed
    playPingFx()

  elseif key == "down" then
    playPingFx()
    MainMenu.selectedOption = 1 + (MainMenu.selectedOption) % 2

  elseif key == "up" then
    playPingFx()
    MainMenu.selectedOption = 1 + (MainMenu.selectedOption - 2) % 2

  end
end

return MainMenu
