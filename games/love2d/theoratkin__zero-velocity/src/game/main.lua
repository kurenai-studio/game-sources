Sprite  = require "sprite"
Ship = require "ship"
Laser = require "laser"
AsteroidManager = require "asteroid_manager"
UI = require "ui"
Input = require "input"
FrameAnim = require "frameanim"
Session = require "session"
Config = require "config"

local TLfres = require "tlfres"

local CANVAS_WIDTH = 1920
local CANVAS_HEIGHT = 1080
local POINT_SIZE = 1

local moonshine = require "moonshine"


GENLOGO = false
if GENLOGO then
	logo = require "logo"
end


function love.load()
	love.graphics.setBackgroundColor(0, 0, 0)

	love.physics.setMeter(20)
	world = love.physics.newWorld(0, 0, true)
	world:setCallbacks(beginContact, endContact)

	config = Config()
	input = Input()
	session = Session()

	sprites = Sprite("res/sprites.png")

	sprites:addQuad("fighter", 1, 1, 12, 20, 6, 7)
	sprites:addQuad("hauler", 17, 1, 14, 20, 9, 10)
	sprites:addQuad("shuttle", 38, 4, 6, 9, 3, 4)
	sprites:addQuad("icebreaker", 49, 2, 22, 31, 11, 15)

	asteroids = AsteroidManager()
	laser = Laser(asteroids)
	ship = Ship()
	ship:set(config.values.ship)

	ship.onGameOver:add(session.gameOver, session)

	music = love.audio.newSource("res/music.ogg", "stream")
	music:setLooping(true)
	music:setVolume(config.values.music / 100)
	music:play()

	setSoundVolume(config.values.sound)

	explosion = Sprite("res/explosion.png")
	explosionAnim = FrameAnim(explosion, 40, 5, 5, 11)
	explosionAnim.onAnimEnd:add(session.finalAnimEnd, session)

	gameModes = {
		"escape",
		"endless"
	}
	setGameMode(config.values.gamemode)

	showCollision = false

	ui = UI()
	ui.startGameCallback:add(session.start, session)
	ui.changeMusicVolumeCallback = changeMusicVolume
	ui.changeSoundVolumeCallback = changeSoundVolume
	ui.changeMSAACallback = changeMSAA
	ui.changeBloom = changeBloom
	ui.toggleScanlines = toggleScanlines
	ui.changeCRT = changeCRT
	ui.changePixel = changePixel
	ui.shipSelect = shipSelect
	ui.selectMode = selectMode

	-- Post-processing.
	effect = moonshine(moonshine.effects.glow)
	effect.chain(moonshine.effects.pixelate)
	effect.glow.min_luma = 0
	effect.glow.strength = config.values.bloom
	effect.pixelate.size = {config.values.pixel, config.values.pixel}
	if config.values.bloom == 0 then
		effect.disable("glow")
	end
	if config.values.pixel == 1 then
		effect.disable("pixelate")
	end
	globeffect = moonshine(moonshine.effects.crt)
	globeffect.chain(moonshine.effects.scanlines)
	setCRT(config.values.crt)
	globeffect.scanlines.frequency = love.graphics.getHeight()
	if not config.values.scanlines then
		globeffect.disable("scanlines")
	end
	if config.values.crt == 0 then
		globeffect.disable("crt")
	end

	if GENLOGO then
		logo.gen()
	end
end


function love.keypressed(key, scancode, isrepeat)
	if scancode == "f2" then
		ui:toggleFPS()
	end
	if scancode == "f3" then
		showCollision = not showCollision
	end
end


function love.update(dt)
	if not GENLOGO then
		input:update(dt)
	end
	if not session._paused then
		world:update(dt)
	end
	asteroids:update(dt)
	ship:update(dt)
	explosionAnim:update(dt)
	session:update(dt)
	ui:update(dt)
end


function love.draw()
	globeffect(function()
		effect(function()
		TLfres.beginRendering(CANVAS_WIDTH, CANVAS_HEIGHT)
		love.graphics.setPointSize(TLfres.getScale()*POINT_SIZE)
		asteroids:draw()
		ship:draw()
		explosionAnim:draw()
			if GENLOGO then
				logo.draw()
			end
		TLfres.endRendering()
		end)
		TLfres.beginRendering(CANVAS_WIDTH, CANVAS_HEIGHT)
		if not GENLOGO then
			ui:draw()
		end
		if showCollision then
			drawCollision()
		end
		TLfres.endRendering()
	end)
end


function drawCollision()
	love.graphics.setColor(0, 1, 0, .5)
	for _, body in pairs(world:getBodies()) do
		if not body:isActive() then
			goto continue
		end
		for _, fixture in pairs(body:getFixtures()) do
			local shape = fixture:getShape()

			if shape:typeOf("CircleShape") then
				local cx, cy = body:getWorldPoints(shape:getPoint())
				love.graphics.circle("fill", cx, cy, shape:getRadius())
			elseif shape:typeOf("PolygonShape") then
				love.graphics.polygon("fill", body:getWorldPoints(shape:getPoints()))
			else
				love.graphics.line(body:getWorldPoints(shape:getPoints()))
			end
		end
		::continue::
	end
	love.graphics.setColor(1, 1, 1, 1)
end


function love.resize(w, h)
	effect.resize(w, h)
	globeffect.resize(w, h)
	globeffect.scanlines.frequency = h
	--ship:resize(w, h)
	--ui:resize(w, h)
end


function love.joystickadded(joystick)
	input:joystickadded(joystick)
end


function love.joystickremoved(joystick)
	input:joystickremoved(joystick)
end


function love.quit()
	config:save()
end


function beginContact(a, b, contact)
	ship:onContact(a:getUserData(), b:getUserData())
	laser:beginContact(a:getUserData(), b:getUserData())
end


function endContact(a, b, contact)
	laser:endContact(a:getUserData(), b:getUserData())
end


function changeMusicVolume()
	config.values.music = config.values.music + 10
	if config.values.music > 100 then
		config.values.music = 0
	end
	local vol = config.values.music
	music:setVolume(vol / 100)
	return vol
end


function changeSoundVolume()
	config.values.sound = config.values.sound + 10
	if config.values.sound > 100 then
		config.values.sound = 0
	end
	local vol = config.values.sound
	setSoundVolume(vol)
	return vol
end


function setSoundVolume(vol)
	asteroids:setVolume(vol / 100)
	ship.sound:setVolume(vol / 100)
	laser.sound:setVolume(vol / 100)
	laser.overheatingSound:setVolume(vol / 100)
end


function changeMSAA()
	local msaa = config.values.msaa
	msaa = msaa * 2
	if msaa == 0 then msaa = 1 end
	if msaa > 2^3 then msaa = 0 end
	love.window.setMode(
		love.graphics.getWidth(),
		love.graphics.getHeight(),
		{ msaa = msaa }
	)
	config.values.msaa = msaa
	return msaa
end


function shipSelect()
	config.values.ship = config.values.ship + 1
	if config.values.ship > ship:shipsCount() then
		config.values.ship = 1
	end
	local shipid = config.values.ship
	ship:set(shipid)
	return shipid
end


function selectMode()
	config.values.gamemode = config.values.gamemode + 1
	if config.values.gamemode > #gameModes then
		config.values.gamemode = 1
	end
	return setGameMode(config.values.gamemode)
end


function setGameMode(mode)
	local name = gameModes[mode]
	if name == "endless" then
		session.endlessMode = true
	else
		session.endlessMode = false
	end
	return name
end


function changeBloom()
	config.values.bloom = config.values.bloom + 1
	if config.values.bloom > 10 then
		config.values.bloom = 0
	end
	effect.glow.strength = config.values.bloom
	if config.values.bloom == 0 then
		effect.disable("glow")
	elseif config.values.bloom == 1 then
		effect.enable("glow")
	end
	return config.values.bloom
end


function toggleScanlines()
	config.values.scanlines = not config.values.scanlines
	if config.values.scanlines then
		globeffect.enable("scanlines")
	else
		globeffect.disable("scanlines")
	end
end


function changeCRT()
	config.values.crt = config.values.crt + 1
	if config.values.crt > 10 then
		config.values.crt = 0
	end
	setCRT(config.values.crt)
end

function setCRT(factor)
	globeffect.crt.distortionFactor = {
		1 + factor / 30,
		1 + factor / 30
	}
	if config.values.crt == 0 then
		globeffect.disable("crt")
	elseif config.values.crt == 1 then
		globeffect.enable("crt")
	end
end


function changePixel()
	config.values.pixel = config.values.pixel + 1
	if config.values.pixel > 10 then
		config.values.pixel = 1
	end
	effect.pixelate.size = {
		config.values.pixel,
		config.values.pixel
	}
	if config.values.pixel == 1 then
		effect.disable("pixelate")
	elseif config.values.pixel == 2 then
		effect.enable("pixelate")
	end
	return config.values.bloom
end
