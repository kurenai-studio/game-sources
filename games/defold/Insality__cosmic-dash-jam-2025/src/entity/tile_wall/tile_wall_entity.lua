---@diagnostic disable: missing-fields
---@type entity
return {
	transform = { size_x = 128, size_y = 128 },
	game_object = { factory_url = "/entities#tile_wall", is_slice9 = true, sprite_url = "/body#sprite", slice9_offset = vmath.vector3(0, 40, 0), remove_delay = 0.5 },
	panthera = { animation_path = require("entity.tile_wall.tile_wall_panthera") },
	field = { solid = true },
	field_appear = { delay = 0 },
	tile_wall_visual = true,
}
