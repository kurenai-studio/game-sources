local maps = {}

maps.Map = {}

maps.Map.__index = maps.Map

function maps.Map:new(name)
    local new_object = {name = name, tiles = {}}
    setmetatable(new_object, self)
    new_object.__index = maps.Map
    return new_object
end

maps.Tile = {}

maps.Tile.__index = maps.Tile

function maps.Tile:new(name, sprite_num)
    local new_object = {
        name = name, 
        sprite_num = sprite_num,
    }
    setmetatable(new_object, self)
    new_object.__index = maps.Tile
    return new_object
end

maps.Object = {}

maps.Object.__index = maps.Object

function maps.Object:new(name, sprite_num, x, y, z)
    if not x then x = 0 end
    if not y then y = 0 end
    if not z then z = 0 end

    local new_object = {
        name = name, 
        sprite_num = sprite_num,
        x = x,
        y = y, 
        z = z
    }
    setmetatable(new_object, self)
    new_object.__index = maps.Object
    return new_object
end

function maps.Object:draw(x_offset, y_offset)
    local scaled_x = (self.x - 1) * 16 + x_offset
    local scaled_y = (self.y - 1) * 16 + y_offset
    love.graphics.draw(sprites[self.sprite_num], scaled_x, scaled_y)
end

maps.ActiveTile = {}

maps.ActiveTile.__index = maps.ActiveTile
setmetatable(maps.ActiveTile, {__index = maps.Tile})

function maps.ActiveTile:new(name, sprite_num)
    local new_object = maps.Tile:new(sprite_num)

    setmetatable(new_object, {__index = maps.ActiveTile})
    new_object.__index = maps.ActiveTile
    return new_object
end

maps.TwoTileObject = {}

maps.TwoTileObject.__index = maps.TwoTileObject
setmetatable(maps.TwoTileObject, {__index = maps.Object})

function maps.TwoTileObject:new(name, sprite_num, upper_sprite_num, x, y, z)
    local new_object = maps.Object:new(sprite_num, x, y, z)
    new_object["upper_sprite_num"] = upper_sprite_num
    new_object["upper_sprite"] = sprites[upper_sprite_num]

    setmetatable(new_object, {__index = maps.TwoTileObject})
    new_object.__index = maps.TwoTileObject
    return new_object
end


maps.Map = {}

maps.Map.__index = maps.Map

function maps.Map:new(mapdata,name)
    new_object = {
        mapdata=mapdata,
        name=name
    }
    setmetatable(new_object, self)
    new_object.__index = maps.Map
    return new_object
end


BUSH = 5 -- Object
GREEN = 1 -- Tile
FLOWERS = 2 -- Object 
PATH = 25  -- Tile (flower)
TREE_L = 15
TREE_U = 3
SPIKE = 1041

maps.bush_tile = maps.Object:new("bush", BUSH, 2, 3)

maps.all_objects = {}
table.insert(maps.all_objects, maps.bush_tile)

function maps.draw_map(game_map, sprites, x_offset, y_offset)
    local col_number, row_number, row, x, y
    for row_number, row in pairs(game_map.mapdata) do
        for col_number, tile_info in pairs(row) do
            x = (col_number - 1) * 16 + x_offset
            y = (row_number - 1) * 16 + y_offset
            -- u: underlay of sprites
            -- o: overlay of sprites
            for depth, sprite_num in pairs(tile_info.u) do
                love.graphics.draw(sprites[sprite_num], x, y)
            end
        end
    end
end

function maps.draw_map_overlay(game_map, sprites, x_offset, y_offset)
    for row_number, row in pairs(game_map.mapdata) do
        for col_number, tile_info in pairs(row) do
            x = (col_number - 1) * 16 + x_offset
            y = (row_number - 1) * 16 + y_offset
            if tile_info.o ~= nil then
                for depth, sprite_num in pairs(tile_info.o) do
                    love.graphics.draw(sprites[sprite_num], x, y)
                end
            end
            --print(row_number, col_number, sprite_num)
        end
    end
    for i, o in pairs(maps.all_objects) do
        o:draw(x_offset, y_offset)
    end
end

return maps