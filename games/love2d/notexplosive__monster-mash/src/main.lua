love.graphics.setDefaultFilter( 'nearest', 'nearest' )

require 'live_objects'
require 'names'
require 'gamesetup'
require 'zombie'
require 'obstacle'
-- Cursor is last to be rendered, ie: last live object to be added (this may need revision, maybe force cursor to layer 0)
require 'cursor'
require 'ghostbuster'
require 'menu'

love.window.setTitle('MONSTER MASH')

function love.load(arg)
  AllObstacles = {}
  addSpriteComponent(MENU,32,32,"menu.png")

  local hum = newZombie(200,200)
  hum.sprite:setSprite("human.png")
  hum.name = "Norman Normie"

  newObstacle(300,120)
  newObstacle(100,120)

  newObstacle(320,180)
  newObstacle(80,180)

  BackgroundTilesImage = love.graphics.newImage('mansiontiles.png')
  BackgroundTiles = generateFrames(32,32,BackgroundTilesImage)
end

function love.update(dt)
  for i,obj in ipairs(LiveObjects) do
    if obj.update ~= nil then
      obj:update(dt)
    end
  end
end

function love.draw()
  love.graphics.push()
  love.graphics.scale(2)
  ordered_objects = {}
  for i,obj in ipairs(LiveObjects) do
    if obj ~= nil then
      if obj.draw ~= nil then
        if obj.drawOrdered == nil then
          obj:draw()
        else
          ordered_objects[#ordered_objects + 1] = obj
        end
      end
    end
  end

  local bandwidth = 128
  for i=1,bandwidth do
    for j,obj in ipairs(ordered_objects) do
      if obj ~= nil then
        local h = love.graphics.getHeight()
        local low = h/bandwidth * (i-1)
        local high = h/bandwidth * i
        local y = obj.y
        if y >= low and y < high then
          local brightness = i/bandwidth*2
          local brightnessAsColor = brightness*255
          if obj.obstacle then
            brightnessAsColor = brightnessAsColor * 1.1
          end
          if obj.shadeWithOrder then
            love.graphics.setColor(brightnessAsColor,brightnessAsColor,brightnessAsColor)
          else
            love.graphics.setColor(255,255,255)
          end
          obj:draw()
        end
      end
    end
  end
  love.graphics.setColor(255,255,255,255)
  if SELECTED_OBJECT ~= nil then
    local sdx,sdy = getDrawCoords(SELECTED_OBJECT)
    love.graphics.circle('line', SELECTED_OBJECT.x, SELECTED_OBJECT.y, 32, 4+love.math.random(10))
    if SELECTED_OBJECT.name ~= nil then
      local offsetx = love.graphics.getFont():getWidth(SELECTED_OBJECT.name)/2
      love.graphics.print(SELECTED_OBJECT.name,SELECTED_OBJECT.x-offsetx,SELECTED_OBJECT.y+32)
    end
  end

  love.graphics.print("Net spooky: " .. NetSpooky)
  love.graphics.pop()
end
