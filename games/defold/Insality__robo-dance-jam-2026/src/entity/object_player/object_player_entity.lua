---@diagnostic disable: missing-fields
---@class entity
return {
	object_player_visual = true,
	field_appear = true,
	transform = { size_x = 125, size_y = 125, size_z = 1 },
	game_object = { collectionfactory_url = "/entities#object_player" },
	panthera = {
		animation_path = require("entity.object_player.object_player_panthera"),
	},
	abilities = {
		list = {
			"move_1",
			"attack_swipe",
			"teleport_2"
		}
	},
	turn_list = { scheduled_length_max = 4 },
	field_actor = {
		health = 3,
		movable = true,
		pushable = true,
	},
	gui_selected_character = true
}
