local abilities = require("game.abilities")

---@diagnostic disable: missing-fields
---@class entity
return {
	transform = {},
	game_object = { collectionfactory_url = "/entities#object_spikes" },
	field_actor = {
		movable = false,
		solid = false,
		height = 0.5,
	},
	panthera = { animation_path = require("entity.object_spikes.object_spikes_panthera") },
	object_spikes = { is_light_floor = false, pattern_index = 1 },
	turn_list = {
		scheduled = {},
		pattern_index = 1
	},
	patterns = {
		list = {{
			{ abilities.set_state.id, nil, { prepare_attack = true } },
			{ abilities.damage_1.id }
		}, {
			{ abilities.set_state.id, nil, { prepare_attack = true } },
			{ abilities.damage_1.id },
			{},
			{},
		}}
	},
	field_appear = true
}
