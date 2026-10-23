local M = {}

function M.merge(entities, dictionary)
	for k, v in pairs(dictionary) do
		entities[k] = v
	end
end


function M.get_entities()
	local entities = {
		["debug_panel"] = require("entity.debug_panel.debug_panel_entity"),
		["player"] = require("entity.player.player_entity"),
		["camera"] = require("system.camera.camera_entity"),

		["game_gui"] = require("entity.game_gui.game_gui_entity"),
		["menu_gui"] = require("entity.menu_gui.menu_gui_entity"),

		["window_settings"] = require("entity.window_settings.window_settings_entity"),

		["tile_floor_bg"] = require("entity.tile_floor_bg.tile_floor_bg_entity"),
		["tile_finish"] = require("entity.tile_finish.tile_finish_entity"),
		["tile_wall"] = require("entity.tile_wall.tile_wall_entity"),
		["tile_pushable"] = require("entity.tile_pushable.tile_pushable_entity"),
		["tile_corner"] = require("entity.tile_corner.tile_corner_entity"),

		["field_torch"] = require("entity.field_torch.field_torch_entity"),
		["item_star"] = require("entity.item_star.item_star_entity"),
	}

	M.merge(entities, require("entity.tile_corner.tile_corner_entity"))
	M.merge(entities, require("entity.tile_portal.tile_portal_entity"))

	return entities
end


return M
