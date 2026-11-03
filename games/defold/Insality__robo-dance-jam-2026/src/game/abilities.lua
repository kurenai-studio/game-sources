local field_const = require("system.field.field.const")
local field_turn_action = require("system.field.field.field_turn_action")

---@class game.ability
---@field id string
---@field description string|nil
---@field icon string|nil
---@field color string|vector4|nil
---@field color_back string|vector4|nil
---@field get_turn_action? fun(entity_id: string, side: "up" | "down" | "left" | "right", params: table|nil): field.turn_action[]

---@class abilities.map
---@field wait game.ability
---@field move_1 game.ability
---@field damage_1 game.ability
---@field fire_laser_1 game.ability
---@field projectile_flying game.ability
---@field attack_swipe game.ability
---@field teleport_swap game.ability
---@field teleport_2 game.ability
local M = {}

local function opposite(side)
	return field_const.TURN_SIDE_DATA[side].opposite
end


M["wait"] = {
	id = "wait",
	description = "ui_ability_wait",
	icon = "icon_turn_wait",
	color = "#7081A2",
	color_back = "#657492",
	get_turn_action = function(entity_id, side)
		return {}
	end
}

M["move_1"] = {
	id = "move_1",
	description = "ui_ability_move_1",
	icon = "icon_turn_move",
	color = "#93B99A",
	color_back = "#84A68B",
	get_turn_action = function(entity_id, side)
		return {
			field_turn_action.move(entity_id, 1, side),
			--field_turn_action.knockback_attack(entity_id, 1, side),
			--field_turn_action.knockback_move(entity_id, 1, side),
		}
	end
}


M["saw_1"] = {
	id = "saw_1",
	description = "ui_ability_saw_1",
	icon = "icon_turn_saw",
	color = "#93B99A",
	color_back = "#84A68B",
	get_turn_action = function(entity_id, side)
		return {
			field_turn_action.move(entity_id, 1, side),
			field_turn_action.damage(entity_id, 1, side),
			field_turn_action.knockback_attack(entity_id, 1, side),
			field_turn_action.support_damage(entity_id, 1, field_const.TURN_SIDE.NONE),
			field_turn_action.support_knockback(entity_id, 1, field_const.TURN_SIDE.NONE),
		}
	end
}

M["floor_move_1"] = {
	id = "floor_move_1",
	description = "ui_ability_floor_move_1",
	icon = "icon_turn_move",
	color = "#93B99A",
	color_back = "#84A68B",
	get_turn_action = function(entity_id, side)
		return {
			field_turn_action.knockback_move(entity_id, 1, side),
			field_turn_action.knockback_attack(entity_id, 1, side)
		}
	end
}

M["damage_1"] = {
	id = "damage_1",
	description = "ui_ability_damage_1",
	icon = "icon_turn_damage",
	color = "#CC9292",
	color_back = "#B88383",
	get_turn_action = function(entity_id, side)
		return {
			field_turn_action.damage(entity_id, 1, side),
			field_turn_action.knockback_attack(entity_id, 1, side)
		}
	end
}


M["fire_laser_1"] = {
	id = "fire_laser_1",
	get_turn_action = function(entity_id, side)
		return {
			field_turn_action.spawn_entity(entity_id, side, "projectile_laser"),
		}
	end
}


M["laser_projectile"] = {
	id = "laser_projectile",
	--description = nil,--"ui_ability_projectile_flying",
	--icon = nil,--"icon_turn_projectile_flying",
	--color = nil, --"#CC9292",
	--color_back = nil, --"#B88383",
	get_turn_action = function(entity_id, side)
		return {
			field_turn_action.move(entity_id, 1, side),
			field_turn_action.damage(entity_id, 1, side),
			field_turn_action.knockback_attack(entity_id, 1, side),
			field_turn_action.support_damage(entity_id, 1, field_const.TURN_SIDE.NONE),
			--field_turn_action.support_knockback(entity_id, 1, field_const.TURN_SIDE.NONE),
		}
	end
}

M["fire_laser_2"] = {
	id = "fire_laser_2",
	get_turn_action = function(entity_id, side)
		return {
			field_turn_action.spawn_entity(entity_id, side, "projectile_laser_2"),
		}
	end
}


M["laser_projectile_2"] = {
	id = "laser_projectile_2",
	get_turn_action = function(entity_id, side)
		return {
			field_turn_action.move(entity_id, 2, side),
			field_turn_action.damage(entity_id, 1, side),
			field_turn_action.knockback_attack(entity_id, 1, side),
			field_turn_action.support_damage(entity_id, 1, field_const.TURN_SIDE.NONE),
		}
	end
}


M["attack_swipe"] = {
	id = "attack_swipe",
	description = "ui_ability_attack_swipe",
	icon = "icon_turn_attack",
	color = "#CC9292",
	color_back = "#B88383",
	get_turn_action = function(entity_id, side)
		return {
			field_turn_action.spawn_entity(entity_id, side, "field_attack_cell", { delta_i = 0, delta_j = 1, side = side }),
			field_turn_action.damage(entity_id, 0, side),
		}
	end
}


M["dodge_1"] = {
	id = "dodge_1",
	description = "ui_ability_dodge_1",
	icon = "icon_turn_teleport",
	color = "#8B9FE9",
	color_back = "#7D8FD2",
	get_turn_action = function(entity_id, side)
		return {
			field_turn_action.move(entity_id, 1, side),
			field_turn_action.knockback_move(entity_id, 1, opposite(side)),
		}
	end
}


M["teleport_2"] = {
	id = "teleport_2",
	description = "ui_ability_teleport_2",
	icon = "icon_turn_teleport",
	color = "#8B9FE9",
	color_back = "#7D8FD2",
	get_turn_action = function(entity_id, side)
		return {
			field_turn_action.teleport(entity_id, 2, side),
		}
	end
}


M["teleport_swap"] = {
	id = "teleport_swap",
	description = "ui_ability_teleport_swap",
	icon = "icon_turn_teleport",
	color = "#8B9FE9",
	color_back = "#7D8FD2",
	get_turn_action = function(entity_id, side)
		return {
			field_turn_action.spawn_entity(entity_id, side, "field_push_cell", { delta_i = -1, delta_j = -1, side = side }),
			field_turn_action.spawn_entity(entity_id, side, "field_push_cell", { delta_i = 0, delta_j = -1, side = side }),
			field_turn_action.spawn_entity(entity_id, side, "field_push_cell", { delta_i = 1, delta_j = -1, side = side }),

			field_turn_action.spawn_entity(entity_id, side, "field_push_cell", { delta_i = -1, delta_j = 0, side = side }),
			field_turn_action.spawn_entity(entity_id, side, "field_push_cell", { delta_i = 1, delta_j = 0, side = side }),

			field_turn_action.spawn_entity(entity_id, side, "field_push_cell", { delta_i = -1, delta_j = 1, side = side }),
			field_turn_action.spawn_entity(entity_id, side, "field_push_cell", { delta_i = 0, delta_j = 1, side = side }),
			field_turn_action.spawn_entity(entity_id, side, "field_push_cell", { delta_i = 1, delta_j = 1, side = side }),


			field_turn_action.damage(entity_id, 0, side),
			field_turn_action.knockback_attack(entity_id, 1, side),
		}
	end
}


M["push_1"] = {
	id = "push_1",
	description = "ui_ability_push_1",
	icon = "icon_turn_push",
	color = "#CC9292",
	color_back = "#B88383",
	get_turn_action = function(entity_id, side)
		return {
			field_turn_action.knockback_attack(entity_id, 1, side)
		}
	end
}


-- Tech ability to send events to the object at that turn
M["set_state"] = {
	id = "set_state",
	get_turn_action = function(entity_id, side, params)
		return {
			field_turn_action.set_state(entity_id, params or {})
		}
	end
}

---@cast M abilities.map
return M
