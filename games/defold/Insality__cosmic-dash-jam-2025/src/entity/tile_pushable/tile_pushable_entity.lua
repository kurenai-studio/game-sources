---@diagnostic disable: missing-fields
---@type entity
return {
	transform = { size_x = 128, size_y = 128 },
	game_object = { factory_url = "/entities#tile_pushable", remove_delay = 0.5 },
	tile_pushable_visual = true,
	field = { solid = true },
	field_movable = true,
	field_pushable = true,
	panthera = { animation_path = require("entity.tile_pushable.tile_pushable_panthera") },
	field_appear = { delay = 0 },
}
