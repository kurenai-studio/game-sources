require("tile")
require("unit")

map = {}
map.x = 10
map.y = 10



map.Under = {{field, field, field, field, field, field, field, field, field, field} ,
             {field, field, field, field, field, field, field, field, cave, cave} ,
             {field, field, field, field, field, field, field, cave, cave, cave} ,
             {field, field, field, field, field, field, cave, cave, cave, cave} ,
             {field, field, field, field, field, cave, cave, cave, cave, cave} ,
             {field, field, field, field, field, cave, cave, cave, cave, cave} ,
             {field, field, field, field, field, field, cave, cave, cave, cave} ,
             {field, field, field, field, field, field, field, cave, cave, cave} ,
             {field, field, field, field, field, field, field, field, cave, cave} ,
             {field, field, field, field, field, field, field, field, field, field}}
			 
map.Upper = {{nil, nil, nil, nil, nil, nil, nil, nil, mountain, mountain} ,
             {nil, nil, nil, forest, nil, nil, nil, mountain, nil, nil} ,
             {nil, nil, nil, nil, nil, nil, mountain, nil, nil, nil} ,
             {nil, nil, forest, nil, forest, mountain, nil, nil, nil, nil} ,
             {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil} ,
             {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil} ,
             {nil, nil, hill, nil, nil, mountain, nil, nil, nil, nil} ,
             {nil, nil, nil, nil, nil, nil, mountain, nil, nil, nil} ,
             {nil, nil, nil, hill, nil, nil, nil, mountain, nil, nil} ,
             {nil, nil, nil, nil, nil, nil, nil, nil, mountain, mountain}}

map.Units = {}

map.Units[1] = razey
map.Units[2] = cavalryman
map.Units[3] = archer
map.Units[4] = swordsman
map.Units[5] = m1
map.Units[6] = m2
map.Units[7] = leader

function map.getTile(yVal, xVal) 
  if(map.Upper[yVal][xVal] ~= nil) then
    return map.Upper[yVal][xVal]
  else
    return map.Under[yVal][xVal]
  end
end

function map.refreshStamina()
	for i = 1, #map.Units do
		map.Units[i].stamina = map.Units[i].maxStamina
	end
end
function map.getUnit(yVal, xVal)
  local i
  for i=1, #map.Units do
    if yVal == map.Units[i].y and xVal == map.Units[i].x then
      return map.Units[i]
    end
  end
    return nil
end

function map.setUnit(yVal, xVal, cunit)
  map.Units[yVal][xVal] = cunit
end

function map.setTile(yVal, xVal, tile)
  map.Upper[yVal][xVal] = tile
end

function map.moveUnit(dy, dx, cunit)
    print(cunit == nil)
    print(unit.move == nil)
  unit.move(cunit, dx, dy)
end

function map.draw()
    for y=1, #map.Under do
        for x=1, #map.Under[y] do
            tile.draw(map.Under[y][x], y, x)
			if(map.Upper[y][x] ~= nil) then
	    		tile.draw(map.Upper[y][x], y, x)
			end
        end
    end
    for i=1, #map.Units do
        unit.draw(map.Units[i])
    end
end

function map.update(dt)
    for i=1, #map.Units do
        local curUnit = map.Units[i]
        if unit.dead(curUnit) then
            table.remove(map.Units, i)
        end
    end
end
