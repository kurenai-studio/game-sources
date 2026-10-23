require 'live_objects'
require 'sprite'
require 'particle'
require 'names'

NetSpooky = 0
boundaries = {left = 16, right = love.graphics.getWidth()/2-16, top = 100, bottom = love.graphics.getHeight()/2-64}

function newZombie(startx,starty)
  if startx == nil then startx = 0 end
  if starty == nil then starty = 0 end
  zombie = {
    x=startx,
    y=starty,
    spookyAmount=0,
    isZombie=true,
    drawOrdered=true,
    shadeWithOrder=true,
    name = generateName(),
    vel = {x=0,y=0},
    interval = 0,
    emoticon = {x=0,y=0,visible=false,draw = function(self) if self.visible then self.sprite:draw() end end},

    spawn = function(self)
      local sprites = {"zombie.png","skeleton.png","vampire.png","ghost.png" }

      local sprite = sprites[love.math.random(#sprites)]
      addSpriteComponent(self,32,32,sprite)
      self.sprite:setAnimationRange({3})

      if sprite == 'skeleton.png' then
        self.spookyAmount = 50
      else
        self.spookyAmount = 10
      end

      addSpriteComponent(self.emoticon,16,16,"emoticon.png")
      addLiveObject(self.emoticon)
      NetSpooky = NetSpooky + self.spookyAmount
    end,

    update = function(self,dt)
      self.x = self.x + self.vel.x
      self.y = self.y + self.vel.y

      self.interval = self.interval + dt

      if self.interval > love.math.random() * 2 + 1 then
        self.vel.x = love.math.random() - .5
        self.vel.y = love.math.random() - .5

        local length = math.sqrt(self.vel.x * self.vel.x + self.vel.y * self.vel.y)
        self.emoticon.x = self.x
        self.emoticon.y = self.y - 32

        if length < .5 then
          self.sprite:setAnimationRange({3})
          self.vel.x = 0
          self.vel.y = 0

          if not self.emoticon.visible then
            --self.emoticon.visible = true
            self.emoticon.sprite:setAnimationRange({love.math.random(#self.emoticon.sprite.frames)})
          end
        else
          self.emoticon.visible = false
          self.sprite:setAnimationRange({1,2})
        end
        self.vel.y = self.vel.y * .6 -- looks better to move slower on the y position
        self.interval = 0
      end

      if self.x > boundaries.right then
        self.x = boundaries.right
      end

      if self.x < boundaries.left then
        self.x = boundaries.left
      end

      if self.y < boundaries.top then
        self.y = boundaries.top
      end

      if self.y > boundaries.bottom then
        self.y = boundaries.bottom
      end
    end,

    draw = function(self)
      local x,y = getDrawCoords(self)
      local text_offset = love.graphics.getFont():getWidth(self.name)/2
      local scale = 10
      local r,g,b,a = love.graphics.getColor()

      love.graphics.setColor(255,255,255)
      -- love.graphics.print(self.name, x-text_offset, y-32)
      love.graphics.setColor(r,g,b,a)

      if self.vel.x ~= 0 then
        self.sprite.flipX = self.vel.x < 0
      end
      self.sprite.scale = (y-100)/60 + 1
      self.sprite:draw()
    end,

    die = function(self)
      local x,y = self.x, self.y
      NetSpooky = NetSpooky - self.spookyAmount
      for i = 0, 6 do
        local part = newParticle(x,y+16)
        if self.sprite.asset == 'vampire.png' then
          part.sprite:setAnimationRange({2})
        end
        if self.sprite.asset == 'zombie.png' then
          part.sprite:setAnimationRange({3})
        end
        part.shadeWithOrder = true
      end
    end
  }

  addLiveObject(zombie)
  return zombie
end

--[[
function love.mousepressed(x, y, button, isTouch)
  x = x/2
  y = y/2
  local zombie = newZombie()
  zombie.x = x
  zombie.y = y
  for i = 0, 6 do
    local part = newParticle(x,y+16)
    if zombie.sprite.asset == 'vampire.png' then
      part.sprite:setAnimationRange({2})
    end
    if zombie.sprite.asset == 'zombie.png' then
      part.sprite:setAnimationRange({3})
    end
    part.shadeWithOrder = true
  end
end
]]
