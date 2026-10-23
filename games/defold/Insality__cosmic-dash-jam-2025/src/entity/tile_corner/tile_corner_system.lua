local decore = require("decore.decore")

---@class entity
---@field field_corner string|nil

---@class entity.tile_corner: entity
---@field field_corner string
---@field game_object component.game_object

---@class component.tile_corner: string
decore.register_component("field_corner", "NE") -- "NE", "NW", "SE", "SW"
