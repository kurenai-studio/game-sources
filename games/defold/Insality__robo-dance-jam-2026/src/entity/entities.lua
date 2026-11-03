local M = {}

function M.get_entities()
	return {
		["debug_panel"] = require("entity.debug_panel.debug_panel_entity"),
		["camera"] = require("system.camera.camera_entity"),
		["camera_area"] = require("system.camera_area.camera_area_entity"),
		["background"] = require("entity.background.background_entity"),

		["object_box"] = require("entity.object_box.object_box_entity"),
		["object_button"] = require("entity.object_button.object_button_entity"),
		["object_convoyer"] = require("entity.object_convoyer.object_convoyer_entity"),
		["object_door"] = require("entity.object_door.object_door_entity"),
		["object_player"] = require("entity.object_player.object_player_entity"),
		["object_enemy"] = require("entity.object_enemy.object_enemy_entity"),
		["object_light"] = require("entity.object_light.object_light_entity"),
		["object_finish"] = require("entity.object_finish.object_finish_entity"),
		["projectile_laser"] = require("entity.projectile_laser.projectile_laser_entity"),
		["projectile_laser_2"] = require("entity.projectile_laser.projectile_laser_2_entity"),
		["select_arrow"] = require("entity.select_arrow.select_arrow_entity"),
		["object_spikes"] = require("entity.object_spikes.object_spikes_entity"),
		["object_saw"] = require("entity.object_saw.object_saw_entity"),
		["object_turret"] = require("entity.object_turret.object_turret_entity"),
		["tile_dark"] = require("entity.tile_dark.tile_dark_entity"),
		["tile_light"] = require("entity.tile_light.tile_light_entity"),
		["tile_wall"] = require("entity.tile_wall.tile_wall_entity"),

		["field_attack_cell"] = require("entity.field_attack_cell.field_attack_cell_entity"),
		["field_push_cell"] = require("entity.field_push_cell.field_push_cell_entity"),

		["object_text_animated"] = require("entity.object_text_animated.object_text_animated_entity"),

		["window_settings"] = require("entity.window_settings.window_settings_entity"),

		["gui_menu"] = require("entity.gui_menu.gui_menu_entity"),
		["gui_level_select"] = require("entity.gui_level_select.gui_level_select_entity"),
		["gui_game"] = require("entity.gui_game.gui_game_entity"),
	}
end

return M
