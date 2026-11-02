--
-- TinyWorld
--
-- Copyright (c) 2025 piterlouis
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local mainMenu = require("game.main_menu")
local gameScene = require("game.game_scene")
local rulesScene = require("game.rules_scene")
local score = require("game.score")
local shaders = require("game.shaders")
local fx = require("game.fxmanager")
local fonts = require("game.fonts")

local STATE_MENU = 0
local STATE_GAME = 1
local STATE_RULE = 2

local state = 0

function love.load()
  love.graphics.setFont(fonts.pixelify16)

  local wd = love.filesystem.getWorkingDirectory()
  state = STATE_MENU

  local score1 = score:new()
  local score2 = score:new()

  score1:setPoints(10)

  shaders.boxBlur:send("radius", 2)
  shaders.boxBlur:send("texSize", { 800, 800 })

  rulesScene.load()
end

function love.update(dt)
  if state == STATE_MENU then
    mainMenu.update(dt)
  elseif state == STATE_GAME then
    gameScene.update(dt)
  elseif state == STATE_RULE then
    rulesScene.update(dt)
  end
end

function love.draw()
  if state == STATE_MENU then
    mainMenu.draw()
  elseif state == STATE_GAME then
    gameScene.draw()
  elseif state == STATE_RULE then
    rulesScene.draw()
  end
end

function love.keypressed(key)
  if state == STATE_GAME then
    if key == "escape" then
      fx.playFxPing()
      state = STATE_MENU
      -- gameScene.reset()
      package.loaded["game.game_scene"] = nil
      gameScene = require("game.game_scene")
      return
    end

    gameScene.keypressed(key)
    if key == 'space' and gameScene.isGameOver then
      state = STATE_MENU
      gameScene.reset()
    end
    return
  end

  if state == STATE_RULE then
    if key == "escape" then
      fx.playFxPing()
      state = STATE_MENU
    end
    return
  end

  if state == STATE_MENU then
    if key == "escape" then
      love.event.quit()
      return
    end

    if key == "return" and mainMenu.selectedOption == 1 then
      fx.playFxPing()
      state = STATE_GAME
      return
    end

    if key == "return" and mainMenu.selectedOption == 2 then
      state = STATE_RULE
      return
    end
    mainMenu.keypressed(key)
    return
  end
end
