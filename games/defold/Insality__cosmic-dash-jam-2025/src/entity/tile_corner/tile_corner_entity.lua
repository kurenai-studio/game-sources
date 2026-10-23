---@diagnostic disable: missing-fields
---@type table<string, entity>
return {
	["tile_corner"] = {
		transform = { size_x = 128, size_y = 128 },
		game_object = { factory_url = "/entities#tile_corner", remove_delay = 0.5 },
		field = { solid = true },
		field_appear = { delay = 0 },
		field_corner = "NE"
	},
	["tile_corner_NW"] = {
		parent_prefab_id = "tile_corner",
		field_corner = "NW"
	},
	["tile_corner_SE"] = {
		parent_prefab_id = "tile_corner",
		field_corner = "SE"
	},
	["tile_corner_SW"] = {
		parent_prefab_id = "tile_corner",
		field_corner = "SW"
	},
	["tile_corner_NE"] = {
		parent_prefab_id = "tile_corner",
		field_corner = "NE"
	},
}
