local lang = require("lang.lang")
local world = require("game.world")
local saver = require("saver.saver")
local druid = require("druid.druid")
local decore = require("decore.decore")
local panthera = require("panthera.panthera")
local animation = require("entity.window_settings.window_settings_panthera")

local settings_slider = require("widget.settings_slider.settings_slider")
local settings_button = require("widget.settings_button.settings_button")

---@class entity
---@field window_settings component.window_settings?

---@class entity.window_settings: druid.widget
---@field window_settings component.window_settings

---@class component.window_settings
---@field on_menu event
decore.register_component("window_settings")

---@class widget.window_settings: druid.widget
local M = {}


---@param entity entity
function M:init(entity)
	self.entity = entity
	self.on_menu = entity.window_settings.on_menu

	self.druid:new_back_handler(self.on_back)
	self.back_button = self.druid:new_button("background", self.on_back)
	self.back_button:set_animations_disabled()
	self.druid:new_blocker("window")

	self.slider_sound = self.druid:new_widget(settings_slider, "settings_slider_sound")
	self.slider_music = self.druid:new_widget(settings_slider, "settings_slider_music")
	self.button_language = self.druid:new_widget(settings_button, "settings_button_language")
	self.button_reset = self.druid:new_widget(settings_button, "settings_button_reset")
	self.button_menu = self.druid:new_widget(settings_button, "settings_button_menu")

	self.druid:new_lang_text("text_header", "ui_window_settings_header")
	self.druid:new_lang_text("settings_slider_sound/text", "ui_window_settings_sound")
	self.druid:new_lang_text("settings_slider_music/text", "ui_window_settings_music")
	self.druid:new_lang_text("settings_button_language/text", "ui_window_settings_language")
	self.druid:new_lang_text("settings_button_reset/text", "ui_window_settings_reset")
	self.druid:new_lang_text("settings_button_menu/text", "ui_window_settings_menu")
	self.rich_text = self.druid:new_rich_text("text_about")

	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())

	self.slider_sound.on_value_changed:subscribe(self.on_sound_value, self)
	self.slider_music.on_value_changed:subscribe(self.on_music_value, self)
	self.button_language.on_click:subscribe(self.on_language, self)
	self.button_reset.on_click:subscribe(self.on_reset, self)
	self.button_menu.on_click:subscribe(self.on_menu, self)

	self:refresh_sound_status()

	panthera.play(self.animation, "appear")

	if self.on_menu:is_empty() then
		gui.set_enabled(self:get_node("settings_button_menu/root"), false)
		gui.set_enabled(self:get_node("text_music_credits"), true)
		gui.set_enabled(self.rich_text.root, true)

		self.rich_text:set_text("Made by <color=#4AEAFF>Insality</color>\nMade with <color=#63FFDB>Defold</color>\n#<color=#F1FFE1>MadeWithDefold Jam 2025</color>")
	else
		gui.set_enabled(self:get_node("settings_button_menu/root"), true)
		gui.set_enabled(self:get_node("text_music_credits"), false)
		gui.set_enabled(self.rich_text.root, false)
	end

	self.druid:new_button("settings_slider_sound/group_info", self.on_sound_toggle)
	self.druid:new_button("settings_slider_music/group_info", self.on_music_toggle)
end


function M:on_back()
	if self._is_closing then
		return
	end

	self._is_closing = true
	panthera.play(self.animation, "disappear")
	world:removeEntity(self.entity)
end


function M:on_sound_value(value)
	world.sound:set_sound_gain(value)
end


function M:on_music_value(value)
	world.sound:set_music_gain(value)
end


function M:on_sound_toggle()
	if world.sound:is_sound_enabled() then
		world.sound:set_sound_gain(0)
	else
		world.sound:set_sound_gain(1)
	end
	self:refresh_sound_status()
end


function M:on_music_toggle()
	if world.sound:is_music_enabled() then
		world.sound:set_music_gain(0)
	else
		world.sound:set_music_gain(1)
	end
	self:refresh_sound_status()
end


function M:on_language()
	lang.set_next_lang()
	druid.on_language_change()
end


function M:on_reset()
	saver.delete_game_state()
	if html5 then
		html5.run('document.location.reload();')
	else
		sys.reboot()
	end
end


function M:refresh_sound_status()
	self.slider_sound:set_value(world.sound:get_sound_gain())
	self.slider_music:set_value(world.sound:get_music_gain())
end


return M
