local base_countdown_length = 20
local countdown_length = base_countdown_length
local battery_capacity = 1
local time = countdown_length
local window_flags = { vsync = 1, resizable = true }

GameWidth = 320
GameHeight = 180
GameAspect = 320 / 180
DefaultOffsetX = GameWidth / 2
DefaultOffsetY = GameHeight / 2
TileSize = 16

love = require("love")

local flash = 0
local flashColorR = 255
local flashColorG = 255
local flashColorB = 255

require("input")
require("door")
require("vectors")
require("paper")
require("battery")
require("map")
require("player")
require("prompt")
require("output")

CurrentRoom = nil
Textures = {}
Sounds = {}

Unlocks = {}
LogUnlocks = {}
Unlocks.base_open = false
Complete = false
Crashed = false

local textTimerObject

AsepriteFont = love.graphics.newFont("textures/aseprite.otf/aseprite.otf", 7)

AsepriteFont:setLineHeight(1.5)
local low_res_canvas

function Flash(flash_time, r, g, b)
	flash = flash_time
	flashColorR = r
	flashColorG = g
	flashColorB = b
end

function AddBattery()
	battery_capacity = battery_capacity + 1
	countdown_length = base_countdown_length + battery_capacity * 5
end

local function drawUi()
	local newstatus = "Battery: "
		.. math.ceil(time)
		.. "\nHull integrity: "
		.. math.floor(PlayerHp / PLAYER_MAX_HP * 100)
		.. "%"
	textTimerObject:set(newstatus)
	love.graphics.draw(textTimerObject, 8, 8)
end
local function DrawWorld()
	Room.DrawBg(CurrentRoom)
	Player_Draw()
	Room.Draw(CurrentRoom)
end

function love.draw()
	love.graphics.setCanvas(low_res_canvas)
	love.graphics.clear(2 / 255, 24 / 255, 15 / 255)

	if Crashed then
		love.graphics.clear(0, 0, 0)
	end

	if Outputting then
		DrawWorld()
		OutputDraw(dt)
		drawUi()
	elseif Prompting then
		DrawWorld()
		PromptDraw()
		drawUi()
	elseif Complete then
		love.graphics.draw(Textures.ending, 87, 27)
	elseif Crashed then
		love.graphics.draw(Textures.crash, 87, 27)
	else
		DrawWorld()
		drawUi()
	end

	if flash > 0 then
		love.graphics.setColor(flashColorR, flashColorB, flashColorG, flash * 3)
		love.graphics.rectangle("fill", 0, 0, GameWidth, GameHeight)
		love.graphics.setColor(1, 1, 1)
	end

	love.graphics.setCanvas()
	love.graphics.clear(0, 0, 0)
	local win_width, win_height = love.graphics.getDimensions()
	if win_height > win_width / GameAspect then
		win_height = win_width / GameAspect
	else
		win_width = win_height * GameAspect
	end
	love.graphics.draw(low_res_canvas, 0, 0, 0, win_width / GameWidth, win_height / GameHeight)
end

function love.load()
	textTimerObject = love.graphics.newText(AsepriteFont, "hi")
	love.window.setMode(GameWidth * 3, GameHeight * 3, window_flags)
	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	Textures.tile_a = love.graphics.newImage("textures/cookies.png")
	Textures.player = love.graphics.newImage("textures/player.png")
	Textures.base = love.graphics.newImage("textures/base.png")
	Textures.base_back = love.graphics.newImage("textures/baseback.png")
	Textures.prompt = love.graphics.newImage("textures/prompt.png")
	Textures.outputbg = love.graphics.newImage("textures/window.png")
	Textures.paper = love.graphics.newImage("textures/paper.png")
	Textures.battery = love.graphics.newImage("textures/battery.png")
	Textures.ending = love.graphics.newImage("textures/screens2.png")
	Textures.crash = love.graphics.newImage("textures/screens1.png")
	Sounds.door = love.audio.newSource("sounds/door.wav", "static")
	Sounds.tick = love.audio.newSource("sounds/tick.wav", "static")
	Sounds.enter = love.audio.newSource("sounds/enter.wav", "static")
	Sounds.enter:setVolume(0.3)
	Sounds.type = love.audio.newSource("sounds/type.wav", "static")
	Sounds.type:setVolume(0.3)
	Sounds.hurt = love.audio.newSource("sounds/hurt.wav", "static")
	Sounds.die = love.audio.newSource("sounds/die.wav", "static")
	Sounds.item = love.audio.newSource("sounds/item.wav", "static")
	Sounds.ambience = love.audio.newSource("sounds/ambience.ogg", "static")
	Sounds.ambience:setVolume(0.7)
	Sounds.ambience:setLooping(true)
	love.audio.play(Sounds.ambience)
	Sounds.dronefly = love.audio.newSource("sounds/buzz.wav", "static")
	Sounds.dronefly:setLooping(true)


	local roomCount = 9
	for i = 1, roomCount do
		Textures["fg" .. i] = love.graphics.newImage("textures/fg" .. i .. ".png")
		Textures["bg" .. i] = love.graphics.newImage("textures/bg" .. i .. ".png")
	end

	low_res_canvas = love.graphics.newCanvas(GameWidth, GameHeight)
	LoadRooms()
	PromptLoad()
	OutputsLoad()
	CurrentRoom = Rooms.base
end

function love.keypressed(key, scancode, isrepeat)
	if Outputting then
		OutputKeypressed(key, scancode, isrepeat)
	elseif Prompting then
		PromptKeypressed(key, scancode, isrepeat)
	end
end

function BatteryDead()
	love.audio.play(Sounds.die)
	PlayerPos = Vector.new(64, 64)
	PlayerHp = PLAYER_MAX_HP
	SetVelocity(Vector.new(0, 0))

	for _, object in pairs(HoldingObjects) do
		table.insert(object.room.objects, object)
		object:Reset()
	end
	HoldingObjects = {}
	Crashed = true
end

function love.update(dt)
	if Complete and not Outputting then
		PlayerUpdateDroneSound(dt, false)
		return
	end
	if flash > 0 then
		flash = flash - dt
	end
	if Crashed then
		PlayerUpdateDroneSound(dt, false)
		if input_pressed(Inputs.continue) then
			Crashed = false
		end
		return
	end
	if CurrentRoom == Rooms.base then
		time = countdown_length
	end
	if Outputting then
		OutputUpdate(dt)
	elseif Prompting then
		PromptUpdate(dt)
	else
		PlayerUpdate(dt)
		local start = math.floor(time)
		time = time - dt
		if time < 10 and start ~= math.floor(time) then
			love.audio.play(Sounds.tick)
		end
		if time < 0 then
			BatteryDead()
		end
	end
end
