-- Map of tiles, corresponding to the tinydungen tile number.
local json = require("lib.json") 
local utils = require("utils")
local maps = require("map.map")

local mapreader = {}

TILE_LOADER_MAP = {
    ["B"] = 5, -- Bush
    ["G"] = 1, -- Green
    ["f"] = 2, -- Flower
    ["T"] = 15, -- Tree lower part
    ["U"] = 3,  -- Tree upper part
    ["P"] = 25, -- Path
    ["S"] = 1041 -- spike

}

mapreader.MapStore = {}

mapreader.MapStore.__index = mapreader.MapStore

function mapreader.MapStore:new()
    new_object = {
        maps={}
    }
    setmetatable(new_object, self)
    new_object.__index = mapreader.MapStore
    return new_object
end

function mapreader.MapStore:read_maps(filename)
    local store = mapreader.MapStore:new()

    local content = love.filesystem.read(filename)
    local config = json.decode(content)

    local store_instance = mapreader.MapStore:new()
    for map_id, raw_map_data in pairs(config) do
        print('Loading map ',map_id)
        local map_instance = self:_process_map(raw_map_data)
        store_instance.maps[map_id] = map_instance
    end
    return store_instance
end

function mapreader.MapStore:_process_map(raw_map_data)
    local mapdata = {}
    for row_index, row_str in pairs(raw_map_data.map_data) do 
        -- row_str: "G   |G   |F   |G   |P   |P   |P   |G   |G   |F   "
        local row = {}
        mapdata[row_index] = row
        local i = 1
        for cell_str,v in string.gmatch(row_str, "([^|]+)") do
            u1 = TILE_LOADER_MAP[string.sub(cell_str,1,1)]
            u2 = TILE_LOADER_MAP[string.sub(cell_str,2,2)]

            u = {}
            if u1 ~= nil then u[1] = u1 end
            if u2 ~= nil then u[2] = u2 end

            o = {}
            o1 = TILE_LOADER_MAP[string.sub(cell_str,4,4)]
            if o1 ~= nil then o[1] = o1 end
            row[i] = { u=u, o=o }
            i = i+1
        end
    end
    return maps.Map:new(mapdata, raw_map_data.name)
end

return mapreader
