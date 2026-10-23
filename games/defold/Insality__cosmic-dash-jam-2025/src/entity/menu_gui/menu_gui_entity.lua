---@diagnostic disable: missing-fields
local event = require("event.event")

---@type entity
return {
	transform = {},
	game_object = { factory_url = "/entities#menu_gui" },
	druid_widget = { widget_class = require("entity.menu_gui.menu_gui"), widget_id = "menu_gui" },
	menu_gui = { on_play = event.create() },
}
