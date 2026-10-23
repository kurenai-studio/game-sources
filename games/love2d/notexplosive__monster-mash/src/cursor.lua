require 'drawlib'
require 'menu'

MENU_OPEN = false
SELECTED_OBJECT = nil

local Cursor = {
  x=0,
  y=0,

  spawn = function(self)
  end,

  draw = function(self)
    -- local x,y = self.x,self.y
    -- love.graphics.rectangle('fill', self.x, self.y, 4, 6)
  end
}

function love.mousemoved(x, y, dx, dy)
  Cursor.x = x/2
  Cursor.y = y/2

  local any_hovers = false
  for i=1, #AllObstacles do
    local obj = AllObstacles[i]
    local displacement = {x = obj.x - Cursor.x, y = obj.y - Cursor.y}
    local length = math.sqrt(displacement.x * displacement.x + displacement.y * displacement.y)
    if length < 20 then
      obj.hover = true
      any_selected = true
    else
      obj.hover = false
    end
  end

  -- if none of the obstacles got hovered then we can select zombies
  if not any_hovers then
    for i=1, #LiveObjects do
      local obj = LiveObjects[i]
      if obj.isZombie then
        local displacement = {x = obj.x - Cursor.x, y = obj.y - Cursor.y}
        local length = math.sqrt(displacement.x * displacement.x + displacement.y * displacement.y)
        if length < 20 then
          obj.hover = true
        else
          obj.hover = false
        end
      end
    end
  end

  MENU.selectedItem = 0
  for i=1,3 do
    if Cursor.x > MENU.x + 32*(i-1) and Cursor.y > MENU.y and Cursor.x < MENU.x + 32*i and Cursor.y < MENU.y + 32 then
      MENU.selectedItem = i
    end
  end
end

function love.mousepressed(x, y, button, isTouch)
  x = x/2
  y = y/2
  for i=1, #AllObstacles do
    local obj = AllObstacles[i]
    if obj.hover and obj.level == 1 then
      MENU_OPEN = true
      SELECTED_OBJECT = obj
    end
  end

  for i=1, #LiveObjects do
    local obj = LiveObjects[i]
    if obj.isZombie and obj.hover then
      MENU_OPEN = false
      SELECTED_OBJECT = obj
      print(obj.name)
    end
  end

  if MENU.selectedItem ~= 0 and MENU_OPEN then
    MENU_OPEN = false

    for i=1,6 do
      local zombie = newZombie()
      local ox, oy = SELECTED_OBJECT.x,SELECTED_OBJECT.y
      ox = math.cos(love.math.random() * math.pi) * 32 + ox
      oy = math.sin(love.math.random() * math.pi) * 32 + oy
      particleExplode(zombie.sprite.asset,ox,oy)
      zombie.x = ox
      zombie.y = oy
    end
    SELECTED_OBJECT.level = MENU.selectedItem+1
    SELECTED_OBJECT = nil
  end
end

addLiveObject(Cursor)
