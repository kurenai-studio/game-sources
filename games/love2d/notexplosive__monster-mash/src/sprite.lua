require 'live_objects'

function addSpriteComponent(obj,width,height,path)
  obj.sprite = {
    image = love.graphics.newImage(path),
    asset = path,
    root = obj,
    flipX = false,
    time = 0,
    animationRange = {1,2},
    currentAnimationRangeIndex = 1,
    scale = 1,
    w = width,
    h = height,
    r = 0,

    renderFrame = function(self,index,x,y,scl)
      -- drawx and drawy
      if scl == nil then
        scl = 1
      end
      if x == nil then
        x, y = getDrawCoords(self.root)
      end
      local flipx_factor = 1
      if self.flipX then flipx_factor = -1 end
      love.graphics.draw(self.image,self.frames[index], x, y, self.r, flipx_factor*self.scale*scl, 1*self.scale*scl, self.w/2, self.h/2)
    end,

    setAnimationRange = function(self,range)
      self.animationRange = range
      self.currentAnimationRangeIndex = 1
      self.time = 0
    end,

    setSprite = function(self,asset)
      self.asset = asset
      self.image = love.graphics.newImage(asset)
      self.time = 0
      self:setAnimationRange({1})
    end,

    draw = function(self)
      self.time = self.time + 1
      if self.time % 5 == 0 then
        self.currentAnimationRangeIndex = self.currentAnimationRangeIndex + 1
        self.currentAnimationRangeIndex = self.currentAnimationRangeIndex % #self.animationRange
      end

      local frame = self.animationRange[self.currentAnimationRangeIndex + 1]

      if #self.animationRange == 1 then
        self:renderFrame(self.animationRange[1])
      else
        self:renderFrame(frame)
      end
    end
  }

  obj.sprite.frames = generateFrames(width,height,obj.sprite.image)
end

function generateFrames(width,height,image)
  frames = {}
  sw, sh = image:getDimensions()
  for x=0,sw,width do
    frames[#frames + 1] = love.graphics.newQuad(x,0,width,height,image:getDimensions())
  end

  return frames
end
