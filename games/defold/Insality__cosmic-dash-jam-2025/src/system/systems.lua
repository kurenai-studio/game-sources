require("detiled.detiled_system")
require("entity.tile_corner.tile_corner_system")

local M = {}

function M.get_systems()
	return unpack({
		require("system.window_event.window_event_system").create_system(),
		require("system.input.input_system").create_system(),
		require("system.sound.sound_system").create_system(),
		require("system.transform.transform_system").create_system(),
		require("system.transform.transform_callbacks_system").create_system(),
		require("system.game_object.game_object_system").create_system(),
		require("system.camera.camera_system").create_system(),
		require("system.camera_debug_control.camera_debug_control_system").create_system(),
		require("system.color.color_system").create_system(),
		require("system.panthera.panthera_system").create_system(),
		require("system.druid_widget.druid_widget_system").create_system(),

		require("system.field.field_system").create_system(),
		require("system.field_movable.field_movable_system").create_system(),
		require("system.field_appear.field_appear_system").create_system(),

		require("entity.player.player_visual_system").create_system(),
		require("entity.tile_pushable.tile_pushable_visual_system").create_system(),
		require("entity.tile_wall.tile_wall_visual_system").create_system(),
		require("entity.item_star.item_star_system").create_system(),

		require("system.debug_draw.debug_draw_system").create_system(),
		require("system.debug_draw_transform.debug_draw_transform_system").create_system(),
		require("system.follow_cursor.follow_cursor_system").create_system(),
		require("system.game_manager.game_manager_system").create_system(),
	})
end

return M
