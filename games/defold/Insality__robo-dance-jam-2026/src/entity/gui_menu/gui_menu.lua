local panthera = require("panthera.panthera")
local animation = require("entity.gui_menu.gui_menu_panthera")
local text_animated = require("widget.text_animated.text_animated")

---@class widget.gui_menu: druid.widget
local M = {}


---@param entity entity.gui_menu
function M:init(entity)
	self.root = self:get_node("root")

	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())

	self.button_play = self.druid:new_button("button_play", entity.gui_menu.on_play)
	self.button_level_select = self.druid:new_button("button_levels", entity.gui_menu.on_level_select)
	self.button_menu = self.druid:new_button("button_menu", entity.gui_menu.on_menu)

	self.text_animated = self.druid:new_widget(text_animated, "text_animated")
	self.text_animated:animate_text("Robo dance")

	self.druid:new_lang_text("text_play", "ui_play")
	self.druid:new_lang_text("text_levels", "ui_levels")

	self.button_play:set_key_trigger("key_space")
end


function M:on_beat(bar_beat_counter)
	if bar_beat_counter == 1 then
		panthera.play(self.animation, "on_beat_main")
		self.text_animated:animate_text("Robo dance")
	else
		panthera.play(self.animation, "on_beat_sub")
	end
end


return M
