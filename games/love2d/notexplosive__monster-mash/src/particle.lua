function newParticle(startx,starty)
  if startx == nil then startx = 0 end
  if starty == nil then starty = 0 end
  particle = {
    x = startx,
    y = starty,
    vel = {
      x = 0,
      y = 0
    },
    gravity = true,
    rotate = true,
    sinex = false,
    scale = 1,
    drawOrdered = true,
    lifetime = 5,

    spawn = function(self)
      local x,y = getDrawCoords(self)
      addSpriteComponent(self,16,16,'bone.png')
      self.sprite:setAnimationRange({1})

      self.vel.y = -1
      if self.gravity then
        self.vel.y = -5 - love.math.random(5)
      end
      if self.rotate then
        self.sprite.r = math.pi * 2 * love.math.random()
      end
      self.vel.x = (love.math.random() - 0.5)*4
      -- scaling only happens when particles spawn
      self.sprite.scale = (y-100)/60 + 1
    end,

    update = function(self,dt)
      self.x = self.x + self.vel.x
      self.y = self.y + self.vel.y


      if self.y > starty then
        self.vel.x = 0
        self.vel.y = 0
        self.y = starty
        removeLiveObject(self.liveObjectIndex)
      end

      if self.gravity then
        self.vel.y = self.vel.y + .5
      end

      if self.sinex then
        self.x = math.sin(dt/math.pi)*200
      end

      self.lifetime = self.lifetime - dt
      if self.lifetime < 0 then
        removeLiveObject(self.liveObjectIndex)
      end
    end,

    draw = function(self)
      self.sprite:draw()
    end
  }
  addLiveObject(particle)
  return particle
end

function particleExplode(asset,x,y)
  for i = 0, 6 do
    local part = newParticle(x,y+16)
    if asset == 'vampire.png' then
      part.sprite:setAnimationRange({2})
    end
    if asset == 'zombie.png' then
      part.sprite:setAnimationRange({3})
    end
    part.shadeWithOrder = true
  end
end
