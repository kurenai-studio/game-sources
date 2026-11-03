local abilities = require("game.abilities")

---@diagnostic disable: missing-fields
---@class entity
return {
	object_turret_visual = true,
	transform = {},
	game_object = { collectionfactory_url = "/entities#object_turret" },
	panthera = { animation_path = require("entity.object_turret.object_turret_panthera") },
	field_actor = {
		movable = true,
		height = 1,
		health = 1,
	},
	turn_list = {
		pattern_index = 1
	},
	patterns = {
		list = {
			{
				{ "set_state", nil, { prepare_attack = true } },
				{ "fire_laser_1" },
				{},
				{}
			},
			{
				{ "set_state", nil, { prepare_attack = true } },
				{ "fire_laser_2" },
				{},
				{}
			},
		}
	},
	field_appear = true,
}
