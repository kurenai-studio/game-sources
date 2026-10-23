Racket    = require "racket"
Ball      = require "ball"
UI        = require "ui"
Input     = require "input"
FinalAnim = require "finalanim"

RADIUS = 100 

COLORS = {
	"#000000",
	"#1D2B53",
	"#7E2553",
	"#008751",
	"#AB5236",
	"#5F574F",
	"#C2C3C7",
	"#FFF1E8",
	"#FF004D",
	"#FFA300",
	"#FFEC27",
	"#00E436",
	"#29ADFF",
	"#83769C",
	"#FF77A8",
	"#FFCCAA",
}
RACKET1_COLOR = 14
RACKET2_COLOR = 3
SUN_COLOR = 5
SUN_LINE_COLOR = 7
TEXT_COLOR = 7
UI_SEGMENTS_COLOR = 2
STARS_COLOR = 7

for i in pairs(COLORS) do
    hex = COLORS[i]:gsub("#","")
	COLORS[i] = {
		tonumber("0x"..hex:sub(1,2))/255,
		tonumber("0x"..hex:sub(3,4))/255,
		tonumber("0x"..hex:sub(5,6))/255
	}
end

function love.load()
	input = Input()
	ui = UI()
	racket1 = Racket()
	racket2 = Racket(true)
	racket2.width = 3
	racket2.startLength = 30
	racket1.opposite = racket2
	racket2.opposite = racket1
	ball = Ball(ui)
	debug = false
	flashing = true

	music = love.audio.newSource("res/music.ogg", "stream")
	music:setLooping(true)
	music:setVolume(0.5)
	music:play()

	size = {
		x = love.graphics.getWidth(),
		y = love.graphics.getHeight(),
	}
	center = {
		x = size.x / 2,
		y = size.y / 2,
	}

	genstars()

	finalanim = FinalAnim()

	love.graphics.setBackgroundColor(COLORS[1])
end


function genstars()
   local max_stars = math.sqrt(size.x * size.y)
 
   stars = {}
 
   for i=1, max_stars do
      local x = love.math.random(5, size.x-5)
      local y = love.math.random(5, size.y-5)
      stars[i] = {x, y}
   end
end


function love.keypressed(key, scancode, isrepeat)
	if scancode == "m" then
		if music:isPlaying() then
			music:pause()
		else
			music:play()
		end
	end
	if scancode == "f1" then
		ui.debug = not ui.debug
	end
end


function love.update(dt)
	input:update(dt)

	if input:down("flashing") then
		flashing = not flashing
	end
	if input:down("back") then
		if ui:istitle() then
			love.event.quit()
		else
			ui.restartAngle = math.pi
			ui.state = "title"
			ball.active = false
			ball:reset()
			racket1.flash = 0
			racket2.flash = 0
			racket1.angle = math.rad(50)
			racket2.angle = math.pi + math.rad(50)
			finalanim:reset()
		end
	end

	ball:update(dt)
	racket1:update(dt)
	racket2:update(dt)
	ui:update(dt)
	finalanim:update(dt)
end


function love.draw()
	love.graphics.setColor(COLORS[STARS_COLOR])
	love.graphics.points(stars)
	ui:draw()
	ball:draw()
	racket1:draw()
	racket2:draw()
	finalanim:draw()
end


function love.resize(x, y)
	size = {x = x, y = y}
	center = {x = x / 2, y = y / 2}

	ball:resize(x, y)
	racket1:resize(x, y)
	racket2:resize(x, y)
	ui:resize(x, y)
	finalanim:resize(x, y)
	genstars()
end
