require 'live_objects'
require 'sprite'

AllObstacles = {}

function newObstacle(startx,starty)
  if startx == nil then startx = 0 end
  if starty == nil then starty = 0 end
  obstacle = {
    x = startx,
    y = starty,
    drawOrdered = true,
    shadeWithOrder = true,
    obstacle = true,
    interval = 0,
    hover = false,
    name = 'Empty table',
    level = 1,

    spawn = function(self)
      addSpriteComponent(self,32,32,'tables.png')
      AllObstacles[#AllObstacles+1] = self
    end,

    update = function(self,dt)
      self.sprite:setAnimationRange({self.level})
      for i=1,#LiveObjects do
        local obj = LiveObjects[i]
        if obj.isZombie then
          local x = obj.x - self.x
          local y = obj.y - self.y
          local length = math.sqrt( x*x + y*y )
          if length < 26 then
            x = x / length
            y = y / length
            obj.vel.x = x
            obj.vel.y = y
          end
        end
      end

      self.interval = self.interval + dt
      if self.interval > 10 + love.math.random()*10 then
        self.interval = love.math.random()*5
        --[[
        local zombie = newZombie()
        local ox, oy = self.x,self.y
        ox = math.cos(ox) * 32 + self.x
        oy = math.sin(ox) * 32 + self.y
        particleExplode(zombie.sprite.asset,ox,oy)
        zombie.x = ox
        zombie.y = oy
        ]]
      end
    end,

    draw = function(self)
      local x,y = getDrawCoords(self)
      self.sprite.scale = (y-100)/60 + 1
      if self.hover then
        self.sprite.scale = (y-100)/50 + 1
      end
      self.sprite:draw()
    end
  }

  addLiveObject(obstacle)
end
