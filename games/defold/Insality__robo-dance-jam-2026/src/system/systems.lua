local M = {}

function M.get_systems()
	return unpack({
		-- Debug Systems
		require("system.follow_cursor.follow_cursor_system").create(),
		require("system.camera_debug_control.camera_debug_control").create(),

		-- Core Systems
		require("system.music.music_system").create(),
		require("system.input.input_system").create(),
		require("system.transform.transform_system").create(),
		require("system.transform.transform_callbacks_system").create(),
		require("system.camera.camera_system").create(),
		require("system.game_object.game_object_system").create(),
		require("system.camera_area.camera_area_system").create(),
		require("system.druid_widget.druid_widget_system").create(),
		require("system.window_event.window_event_system").create(),
		require("system.detiled.detiled_system").create(),
		require("system.panthera.panthera_system").create(),

		-- Platforms
		--require("system.poki.poki_system").create(),
		--require("system.wavedash.wavedash_system").create(),

		-- Game Systems
		require("system.field_appear.field_appear_system").create(),
		require("system.abilities.abilities_system").create(),
		require("system.field_actor.field_actor_system").create(),
		require("system.turn_list.turn_list_system").create(),
		require("system.field.field_system").create(),
		require("system.field_turn_animator.field_turn_animator_system").create(),
		require("system.turn_execution.turn_execution_system").create(),
		require("system.camera_battle.camera_battle_system").create(),

		-- Game Entities
		require("entity.select_arrow.select_arrow_visual_system").create(),
		require("entity.object_player.object_player_visual_system").create(),
		require("entity.object_enemy.object_enemy_visual_system").create(),
		require("entity.object_box.object_box_visual_system").create(),
		require("entity.object_spikes.object_spikes_visual_system").create(),
		require("entity.object_saw.object_saw_visual_system").create(),
		require("entity.object_light.light_visual_system").create(),
		require("entity.object_finish.object_finish_visual_system").create(),
		require("entity.object_turret.object_turret_visual_system").create(),
		require("entity.projectile_laser.projectile_laser_visual_system").create(),
		require("entity.background.background_system").create(),
		require("entity.object_text_animated.object_text_animated_visual_system").create(),

		-- GUI Systems
		require("entity.gui_game.gui_game_system").create(),
		require("entity.gui_menu.gui_menu_system").create(),
		require("entity.gui_level_select.gui_level_select_system").create(),
		require("system.gui_selected_character.gui_selected_character_system").create(),

		-- Managers Systems
		require("system.level_manager.level_manager_system").create(),
		require("system.game_manager.game_manager_system").create(),
	})
end

return M
