local abilities = require("game.abilities")

---@diagnostic disable: missing-fields
---@class entity
return {
	projectile_laser_visual = true,
	transform = {
		size_x = 125,
		size_y = 115,
	},
	game_object = { collectionfactory_url = "/entities#projectile_laser" },
	panthera = { animation_path = require("entity.projectile_laser.projectile_laser_panthera") },
	field_actor = {
		movable = true,
		solid = false,
		flying = true,
		z = 1.25,
		height = 0.5,
		health = 4,
		remove_on_death = true,
		damage_on_collide = 4,
	},
	turn_list = {
		sequence_list = { { abilities.laser_projectile.id } },
	}
}
