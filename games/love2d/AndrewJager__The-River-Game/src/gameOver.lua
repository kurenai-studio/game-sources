local menu = {}

local uare = require "Libraries/uare"
local rayHandler = require "godrays"

local header = nil 
local rays = nil

local function menuCreate(world)
btnStartStyle = uare.newStyle({

    width = 400,
    height = 60,
    
    --color
    color = {0.313, 0.298, 0.380},
    hoverColor = {0.313, 0.298, 0.380},
    holdColor = {0.066, 0.047, 0.152},
    
    --border
    border = {
    color = {0.125, 0.031, 0.211},
    hoverColor = {0.0, 0.0, 0.0},
    holdColor = {0.031, 0.349, 0.090},
    size = 5
    },
    
    --text
    text = {
    color = {0.9, 0.9, 0.9},
    hoverColor = {0.9, 0.9, 0.9},
    holdColor = {0.9, 0, 0},
    font = world.btnFont,
    align = "center",
    offset = {
        x = 0,
        y = -25
    }
    },

})

myButton1 = uare.new({
    
    text = {
    display = "Play again"
    },
    x = 250,
    y = 500,
    onClick = function() 
        world.level = "menu"
        uare.clear()
    end
    
}):style(btnStartStyle)

header = love.graphics.newImage("images/header.png")

rays = rayHandler.createRay(5, 175, 380, 175, 430, 280, 480)
rays.spreadX = 45
rays.spreadY = 0
rays.colorA = {0.860, 0.760, 0.058, 0.1}
rays.colorB = {0.990, 0.790, 0.058, 0.1}
rayHandler.reCreateRay(rays)

end
menu.load = menuCreate

local function menuUpdate(dt)
    rayHandler.updateRay(rays, dt)
    uare.update(dt, love.mouse.getX(), love.mouse.getY())
end
menu.update = menuUpdate

local function menuDraw(world)
    love.graphics.setFont(world.titleFont)
    love.graphics.print("Game Over!", 300, 150)
    love.graphics.setFont(world.btnFont)
    love.graphics.print("Your score was: "..world.score, 310, 250)
    uare.draw()
end
menu.draw = menuDraw

return menu