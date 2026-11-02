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
    display = "Start"
    },
    x = 250,
    y = 500,
    onClick = function() 
        world.level = "river"
        uare.clear()
    end
    
}):style(btnStartStyle)

header = love.graphics.newImage("images/header.png")

rays = rayHandler.createRay(50, 177, 375, 177, 400, 220, 480)
rays.spreadX = 20
rayHandler.reCreateRay(rays)
rays2 = rayHandler.createRay(100, 450, 350, 450, 415, 350, 480)
rays2.spreadX = 35
rayHandler.reCreateRay(rays2)
rays3 = rayHandler.createRay(50, 550, 350, 550, 380, 625, 480)
rays3.spreadX = 20
rayHandler.reCreateRay(rays3)

end
menu.load = menuCreate

local function menuUpdate(dt)
    rayHandler.updateRay(rays, dt)
    rayHandler.updateRay(rays2, dt)
    rayHandler.updateRay(rays3, dt)
    uare.update(dt, love.mouse.getX(), love.mouse.getY())
end
menu.update = menuUpdate

local function menuDraw()
    rayHandler.drawRay(rays)
    rayHandler.drawRay(rays2)
    rayHandler.drawRay(rays3)
    love.graphics.push()
    love.graphics.scale(0.41,0.41)
    love.graphics.setColor(0.5,0.5,0.5,1)
    love.graphics.draw(header, 0 ,0)
    love.graphics.pop()
    love.graphics.setColor(0.2,0.2,0.2)
    love.graphics.rectangle("fill", 0, 480, 900, 300)
    uare.draw()
end
menu.draw = menuDraw

return menu