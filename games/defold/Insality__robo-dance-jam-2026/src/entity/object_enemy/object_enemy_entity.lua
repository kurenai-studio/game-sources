---@diagnostic disable: missing-fields
---@class entity
return {
	object_enemy_visual = true,
	transform = {
		size_x = 125,
		size_y = 125,
	},
	game_object = { collectionfactory_url = "/entities#object_enemy" },
	panthera = { animation_path = require("entity.object_enemy.object_enemy_panthera") },
	field_appear = true,
	field_actor = {
		movable = true,
		health = 2,
	},
	turn_list = {
		pattern_index = 1
	},
	patterns = {
		list = {
			["attack"] = {
				{ "set_state", nil, { prepare_attack = true } },
				{ "attack_swipe" },
				{},
				{}
			},
			["attack_fast"] = {
				{ "set_state", nil, { prepare_attack = true } },
				{ "attack_swipe" },
			},
			["attack_slow"] = {
				{ "set_state", nil, { prepare_attack = true } },
				{ "attack_swipe" },
				{}
			},
			["onset"] = {
				{ "move_1" },
				{ "move_1" },
				{ "move_1" },
				{ "attack_swipe" },
			},
		}
	},
}
