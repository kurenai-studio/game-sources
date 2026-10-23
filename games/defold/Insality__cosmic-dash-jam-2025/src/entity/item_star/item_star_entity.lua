---@diagnostic disable: missing-fields
---@type entity
return {
	transform = { size_x = 128, size_y = 128 },
	game_object = { factory_url = "/entities#item_star", remove_delay = 0.5 },
	field = { solid = false, glue = false },
	field_collectable = true,
	item_star = true,
	field_appear = { delay = 0 },
}
