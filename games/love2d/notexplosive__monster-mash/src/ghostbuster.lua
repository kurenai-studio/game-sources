Player = {}

function newBuster(startx,starty)
  if startx == nil then startx = 0 end
  if starty == nil then starty = 0 end
  buster = {
    x = startx,
    y = starty,
    drawOrdered = true,
    shadeWithOrder = true,
    oldlength = 0,
    walking = false,

    spawn = function(self)
      player = self
      addSpriteComponent(self,32,32,'ghost.png')
    end,

    update = function(self,dt)
      dis = {x=0,y=0}

      if love.keyboard.isDown('right') then
        dis.x = 1
      end
      if love.keyboard.isDown('left') then
        dis.x = -1
      end
      if love.keyboard.isDown('up') then
        dis.y = -1
      end
      if love.keyboard.isDown('down') then
        dis.y = 1
      end

      if self.x + dis.x > boundaries.right then
        dis.x = 0
      end

      if self.x + dis.x < boundaries.left then
        dis.x = 0
      end

      if self.y + dis.y < boundaries.top then
        dis.y = 0
      end

      if self.y + dis.y > boundaries.bottom then
        dis.y = 0
      end

      if dis.x ~= 0 then
          self.sprite.flipX = dis.x < 0
      end

      for i=1,#AllObstacles do
        local ox = AllObstacles[i].x
        local oy = AllObstacles[i].y

        local x = self.x + dis.x
        local y = self.y + dis.y

        local diffx = ox - x
        local diffy = oy - y

        local length = math.sqrt(diffx*diffx + diffy*diffy)
        if length < 20 then
          local lengthx = math.sqrt(diffx*diffx + 0)
          local lengthy = math.sqrt(0 + diffy*diffy)
          if lengthx < 18 then
            dis.y = -dis.y
          end
          if lengthy < 18 then
            dis.x = -dis.x
          end
        end
      end

      self.x = self.x + dis.x
      self.y = self.y + dis.y * .6

      if dis.x ~= 0 or dis.y ~= 0 then
        if not self.walking then
          self.sprite:setAnimationRange({1,2})
        end
        self.walking = true
      else
        self.walking = false
        self.sprite:setAnimationRange({3})
      end

      self.oldlength = length
    end,

    draw = function(self)
      local x,y = getDrawCoords(self)
      local scale = 10
      self.sprite.scale = (y-100)/60 + 1
      self.sprite:draw()
    end,
  }

  addLiveObject(buster)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'space' then
    local x,y = player.x, player.y
    for i=1,#LiveObjects do
      local obj = LiveObjects[i]
      if obj.isZombie then
        local zx,zy = obj.x,obj.y
        local diffx,diffy = obj.x-x,obj.y-y
        local length = math.sqrt(diffx*diffx+diffy*diffy)
        if length < 24 then
          removeLiveObject(obj.liveObjectIndex)
          break
        end
      end
    end
  end
end
