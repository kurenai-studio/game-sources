Camera = {x=0,y=0}

-- obj must have x and y fields
function getDrawCoords(obj)
  local x = obj.x - Camera.x
  local y = obj.y - Camera.y
  return x, y
end
