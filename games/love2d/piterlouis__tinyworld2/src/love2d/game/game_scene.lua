--
-- TinyWorld
--
-- Copyright (c) 2025 piterlouis
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local love = require("love")
local shield = require("game.shield")
local score = require("game.score")
local tablex = require("game.batteries.tablex")
local Meteorite = require("game.meteorite")
local fxManager = require("game.fxmanager")
local Emitter = require("game.emitter")
local shaders = require("game.shaders")
local fonts = require("game.fonts")
local flux = require("game.flux")

local M = {
  isGameOver = false
}

local TIME_RESPAWN = 3
local MAX_RESPAWN = 5
local HW = love.graphics.getWidth() / 2.0
local HH = love.graphics.getHeight() / 2.0
local LEVEL_TRANSITION_TIME = 3
local HP_MAX = 20
local BLINKING_FADE_TIME = 1
local ARMOR_COOLDOWN = 10
local BG_TIMER = 6

local time = 0
local planet = { x = 0, y = 0, radius = 25, color = 1, s = 1 }
local meteorites = {}
local level = 1
local timeRespawn = TIME_RESPAWN
local numRespawn = 1

local levelFont = fonts.orbitron20
local levelText = love.graphics.newText(levelFont, "LEVEL - " .. tostring(level))
local textGameOver = love.graphics.newText(levelFont, "Game Over")
local textSpacebar = love.graphics.newText(levelFont, "- PRESS SPACEBAR -")
local textArmorOn = love.graphics.newText(levelFont, "- PLANETARY ARMOR CHARGED -")
local isLevelTransition = LEVEL_TRANSITION_TIME
local isArmorCharging = 0
local blinkingFade = 0

local shd = shield:new(planet.radius)

local scoreW = score:new(HP_MAX / 2, 20, 20, 0)        -- White color
local scoreR = score:new(5, 580, HH * 2 - 50, 1)       -- Red color
local scoreG = score:new(5, 580 + 70, HH * 2 - 50, 2)  -- Green color
local scoreB = score:new(5, 580 + 140, HH * 2 - 50, 3) -- Red color
local colorScore = { scoreR, scoreG, scoreB }

local emitterW = Emitter:new(1, 1, 1, 1, 1, 1, 1, 0) -- White color
local emitterR = Emitter:new(1, 0, 0, 1, 1, 0, 0, 0) -- Red color
local emitterG = Emitter:new(0, 1, 0, 1, 0, 1, 0, 0) -- Green color
local emitterB = Emitter:new(0, 0, 1, 1, 0, 0, 1, 0) -- Blue color
local emitters = { emitterR, emitterG, emitterB, emitterW }

local planetArmor = 0
local planetArmorCooldown = 0
local planetArmorBackColor = 0

local background = love.graphics.newImage("game/images/bg_starfield.png")
background:setFilter("linear", "nearest")
local bg_x, bg_y = 0, 0
local bg_offset = 0

local shake_magnitude = 0
local shake_timer = 0

local function startShake(duration, magnitude)
  shake_magnitude = magnitude
  shake_timer = duration
end

local function explodeMeteoro(meteoro)
  local emitter = emitters[meteoro.color]
  emitter:setPosition(meteoro.x, meteoro.y)
  emitter:emit(250)
end

local function meteoroShieldCollided(meteoro)
  meteoro.visible = false
  explodeMeteoro(meteoro)
  fxManager.playFxShield()
end

local function meteoroPlanetCollided(meteoro)
  meteoro.visible = false
  planet.s = 1.25
  flux.to(planet, 0.3, {s = 1}):ease('sineout')
  if planetArmor > 0 then
    fxManager.playFxShield()
    explodeMeteoro(meteoro)
    return
  end

  scoreW.s = 1.5
  flux.to(scoreW, 0.3, {s = 1}):ease('quadout')

  if planet.color == meteoro.color then
    scoreW:setPoints(math.min(HP_MAX, scoreW.points + 1))
    fxManager.playFxShoot()

    if colorScore[meteoro.color].points == 0 then
      colorScore[1]:setPoints(colorScore[1].points - 1)
      colorScore[2]:setPoints(colorScore[2].points - 1)
      colorScore[3]:setPoints(colorScore[3].points - 1)
    else
      colorScore[meteoro.color]:setPoints(colorScore[meteoro.color].points - 1)
      if meteoro.color == 1 then
        scoreR.s = 1.5
        flux.to(scoreR, 0.3, {s = 1}):ease('quadout')
      elseif meteoro.color == 2 then
        scoreG.s = 1.5
        flux.to(scoreG, 0.3, {s = 1}):ease('quadout')
      elseif meteoro.color == 3 then
        scoreB.s = 1.5
        flux.to(scoreB, 0.3, {s = 1}):ease('quadout')
      end
    end
    return
  end
  scoreW:setPoints(math.max(0, scoreW.points - 3))
  fxManager.playFxChange()
  startShake(0.5, 6)

  planet.color = meteoro.color
  explodeMeteoro(meteoro)
  fxManager.playFxExplosion()
end

local function update_collisions(dt, meteoro)
  -- Collision detection

  -- with Shield
  local dx = shd.x - meteoro.x
  local dy = shd.y - meteoro.y
  local d = dx * dx + dy * dy

  if d < 225 then -- 15*15
    meteoroShieldCollided(meteoro)
    return
  end

  -- with TinyWorld
  dx = planet.x - meteoro.x
  dy = planet.y - meteoro.y
  d = dx * dx + dy * dy

  if d < planet.radius * planet.radius then -- 30*30
    meteoroPlanetCollided(meteoro)
    return
  end
end

local function winLevel()
  local meteo = tablex.pop(meteorites)
  while meteo do
    meteo.visible = false
    explodeMeteoro(meteo)
    meteo = tablex.pop(meteorites)
  end

  level = level + 1
  levelText:set("LEVEL - " .. tostring(level))
  timeRespawn = TIME_RESPAWN - (level * TIME_RESPAWN / 10)
  numRespawn = 1 + (level * MAX_RESPAWN / 10)
  scoreR:setPoints(level * 5)
  scoreG:setPoints(level * 5)
  scoreB:setPoints(level * 5)
  if planet.radius < 25 then
      planet.radius = 25
  end
  isLevelTransition = LEVEL_TRANSITION_TIME
end

local function endGame()
	local meteo = tablex.pop(meteorites)
	while meteo do
    meteo.visible = false
		explodeMeteoro(meteo)
		meteo = tablex.pop(meteorites)
  end
	M.isGameOver = true
end

-- Main update function -------------------------------------------------------
function M.update(dt)
  if shake_timer > 0 then
    shake_timer = shake_timer - dt
  end

  for _, emitter in ipairs(emitters) do
    emitter:update(dt)
  end

  if isLevelTransition > 0 then
    isLevelTransition = isLevelTransition - dt
  end
  if isArmorCharging > 0 then
    isArmorCharging = isArmorCharging - dt
  end
  blinkingFade = (blinkingFade + dt) % BLINKING_FADE_TIME

  flux.update(dt)

  if planetArmor > 0 then
    planet.color = 0
  elseif planetArmorBackColor > 0 then
    planet.color = planetArmorBackColor
    planetArmorBackColor = 0
  end
  planetArmor = math.max(0, planetArmor - dt)
  local prev = planetArmorCooldown
  planetArmorCooldown = math.max(0, planetArmorCooldown - dt)
  if prev > 0 and planetArmorCooldown == 0 then
    isArmorCharging = LEVEL_TRANSITION_TIME
  end

  if M.isGameOver then return end

  if scoreW.points <= 0 then
    endGame()
    return
  end

  -- Check win condition
  local totalPoints = scoreB.points + scoreG.points + scoreR.points
  if totalPoints == 0 then winLevel() end

  time = time + dt
  if time % 30 then
    planet.x = love.math.random() * 6 - 2 + HW
    planet.y = love.math.random() * 6 - 2 + HH
  end
  shd:update(dt)

  for i, meteoro in ipairs(meteorites) do
      meteoro:update(dt)
      update_collisions(dt, meteoro)
      if not meteoro.visible then
        tablex.remove(meteorites, i)
      end
  end

  if time > timeRespawn then
		time = 0
    local maxi = 1 + love.math.random() * numRespawn
		for i=0, maxi do
			local meteoro = Meteorite:new(level)
			meteoro.delay = love.math.random() * timeRespawn
      tablex.push(meteorites, meteoro)
    end
	end

  scoreW:update(dt)
  scoreR:update(dt)
  scoreG:update(dt)
  scoreB:update(dt)
end

-- Main draw function ---------------------------------------------------------
local backCanvas = love.graphics.newCanvas()
local frontCanvas = love.graphics.newCanvas()

function M.draw()
  love.graphics.setColor(1, 1, 1, 1)

  love.graphics.setCanvas(frontCanvas)
  love.graphics.clear()

  love.graphics.setShader(shaders.motionTrail)
  love.graphics.draw(backCanvas)
  love.graphics.setShader()

  -- Draw planet
  if planet.color == 0 then
    love.graphics.setColor(1, 1, 1) -- White color for the planet
  elseif planet.color == 1 then
    love.graphics.setColor(1, 0, 0)
  elseif planet.color == 2 then
    love.graphics.setColor(0, 1, 0)
  elseif planet.color == 3 then
    love.graphics.setColor(0, 0, 1)
  end
  love.graphics.circle("fill", planet.x, planet.y, planet.radius * planet.s)
  love.graphics.setColor(1, 1, 1)

  shd:draw()

  for _, meteoro in ipairs(meteorites) do
    meteoro:draw()
  end

  scoreW:drawIcon()
  scoreR:drawIcon()
  scoreG:drawIcon()
  scoreB:drawIcon()

  love.graphics.setColor(1, 1, 1)
  love.graphics.setCanvas(backCanvas)
  love.graphics.setBlendMode("replace", "premultiplied")
  love.graphics.draw(frontCanvas)
  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas()

  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.draw(background, bg_x + bg_offset, bg_y + bg_offset)

  if shake_timer > 0 then
    local dx = love.math.random(-shake_magnitude, shake_magnitude)
    local dy = love.math.random(-shake_magnitude, shake_magnitude)
    love.graphics.translate(dx, dy)
  end

  love.graphics.setColor(1, 1, 1)
  love.graphics.setShader(shaders.boxBlur)
  love.graphics.draw(frontCanvas)
  love.graphics.setShader()

  local armorIconAlpha = 1
  if planetArmorCooldown > 0 then
    armorIconAlpha = 1 - planetArmorCooldown / ARMOR_COOLDOWN
    scoreW.color = {1, 1, 1, armorIconAlpha}
  end

  love.graphics.setColor(1, 1, 1)  -- Reset color to white
  for _, emitter in ipairs(emitters) do
    emitter:draw()
  end

  love.graphics.setColor(1, 1, 1)
  scoreW:drawText()
  scoreR:drawText()
  scoreG:drawText()
  scoreB:drawText()

  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle("fill", 20, 770, 100, 8)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("fill", 20, 770, 100 - 100 * (planetArmorCooldown/ARMOR_COOLDOWN), 8)

  if M.isGameOver then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(textGameOver, HW - textGameOver:getWidth() / 2, HH - 250 - textGameOver:getHeight() / 2)
    love.graphics.setColor(1, 1, 1, blinkingFade / BLINKING_FADE_TIME)
    love.graphics.draw(textSpacebar, HW - textSpacebar:getWidth() / 2, HH - 200 - textSpacebar:getHeight() / 2)
  end

  if isLevelTransition > 0 then
    love.graphics.setColor(1, 1, 1, isLevelTransition / LEVEL_TRANSITION_TIME)
    love.graphics.draw(levelText, HW - levelText:getWidth() / 2, HH - 200 - levelText:getHeight() / 2)
  end
  if isArmorCharging > 0 then
    love.graphics.setColor(1, 1, 1, isArmorCharging / LEVEL_TRANSITION_TIME)
    love.graphics.draw(textArmorOn, HW - textArmorOn:getWidth() / 2, HH - 160 - textArmorOn:getHeight() / 2)
  end
end

function M.keypressed(key)
  if key == "up" and planetArmorCooldown == 0 then
    planetArmor = 2 -- 2 seconds of planetoid defense
    planetArmorCooldown = ARMOR_COOLDOWN
    planetArmorBackColor = planet.color
    fxManager.playFxChange()
  end
end

function M.reset()
  M.isGameOver = false
  tablex.clear(meteorites)
  time = 0
  level = 1
  timeRespawn = TIME_RESPAWN
  numRespawn = 1
  planet.x = HW
  planet.y = HH
  planet.radius = 25
  planet.color = 1
  planet.s = 1
  planetArmor = 0
  planetArmorCooldown = 0
  planetArmorBackColor = 0

  isLevelTransition = 0
  isArmorCharging = 0

  scoreW:setPoints(HP_MAX / 2)
  scoreR:setPoints(10)
  scoreG:setPoints(10)
  scoreB:setPoints(10)
end

return M
