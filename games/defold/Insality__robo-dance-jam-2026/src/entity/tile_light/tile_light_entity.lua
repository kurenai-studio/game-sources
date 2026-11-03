---@diagnostic disable: missing-fields
---@class entity
return {
	transform = {},
	field_appear = true,
	game_object = { collectionfactory_url = "/entities#tile_light" },
	field_actor = {
		z = 0,
	initial_side = "none",
		movable = true
	},
	turn_list = {},
	patterns = {
		list = {
			["patrol_line_1"] = {
				{ "floor_move_1", "+down"},
			},
			["patrol_line_2"] = {
				{ "floor_move_1", "+down"},
				{ "floor_move_1"}
			},
		}
	}
}
