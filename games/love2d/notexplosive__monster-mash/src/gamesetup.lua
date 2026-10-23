require 'sprite'

-- initialized by love.load
BackgroundTilesImage = nil
BackgroundTiles = nil

function drawBackgroundTile(x,y,index)
  x = x*32 - Camera.x - 16
  y = y*32 - Camera.y
  love.graphics.draw(BackgroundTilesImage, BackgroundTiles[index], x, y, 0)
end

local Sky = {
  x=0,y=0,

  draw = function(self)
    for tilex=0,12 do
      for tiley=0,2 do
        local index = 2
        if tiley == 1 and tilex % 4 == 2 then
          index = 1
        end

        if tiley == 2 and tilex % 4 == 2 then
          index = 3
        end
        drawBackgroundTile(tilex,tiley,index)
      end
    end

    local r,g,b,a = love.graphics.getColor()
    love.graphics.setColor(90, 30, 180)
    love.graphics.setColor(0,0,0,50)
    love.graphics.setColor(r,g,b,a)
  end
}

local Ground = {
  x=0,y=100,
  draw = function(self)
    for tilex=0,12 do
      for tiley=3,9 do
        local index = 4
        drawBackgroundTile(tilex,tiley,index)
      end
    end

    local r,g,b,a = love.graphics.getColor()
    love.graphics.setColor(90, 200, 120)
    --love.graphics.rectangle('fill', self.x, self.y, love.graphics.getWidth()/2, 200)
    love.graphics.setColor(0,0,0,50)
    love.graphics.ellipse('fill', self.x+love.graphics.getWidth()/4, self.y, love.graphics.getWidth()/2, 200)
    love.graphics.ellipse('fill', self.x+love.graphics.getWidth()/4, self.y, love.graphics.getWidth()/2, 100)
    love.graphics.ellipse('fill', self.x+love.graphics.getWidth()/4, self.y, love.graphics.getWidth()/2, 50)
    love.graphics.ellipse('fill', self.x+love.graphics.getWidth()/4, self.y, love.graphics.getWidth()/2, 25)
    love.graphics.ellipse('fill', self.x+love.graphics.getWidth()/4, self.y, love.graphics.getWidth()/2, 25/2)
    love.graphics.ellipse('fill', self.x+love.graphics.getWidth()/4, self.y, love.graphics.getWidth()/2, 25/4)
    love.graphics.setColor(r,g,b,a)
  end
}


addLiveObject(Sky)
addLiveObject(Ground)
