local lang = require("lang.lang")
local audio = require("audio.audio")
local event = require("event.event")
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
---@field on_close event
decore.register_component("window_settings", {
	on_menu = event.create(),
	on_close = event.create(),
})

---@class widget.window_settings: druid.widget
local M = {}


---@param entity entity
function M:init(entity)
	self.entity = entity
	self.on_menu = entity.window_settings.on_menu
	self.on_close = entity.window_settings.on_close

	self.druid:new_back_handler(self.on_back)
	self.back_button = self.druid:new_button("background", self.on_back)
	self.back_button:set_animations_disabled()
	self.back_button:set_key_trigger("key_esc")

	self.druid:new_blocker("window")

	self.slider_sound = self.druid:new_widget(settings_slider, "settings_slider_sound")
	self.slider_music = self.druid:new_widget(settings_slider, "settings_slider_music")
	self.button_language = self.druid:new_widget(settings_button, "settings_button_language")
	self.button_menu = self.druid:new_widget(settings_button, "settings_button_menu")

	self.druid:new_lang_text("text_header", "ui_window_settings_header")
	self.druid:new_lang_text("settings_slider_sound/text", "ui_window_settings_sound")
	self.druid:new_lang_text("settings_slider_music/text", "ui_window_settings_music")
	self.druid:new_lang_text("settings_button_language/text", "ui_window_settings_language")
	self.druid:new_lang_text("settings_button_menu/text", "ui_window_settings_menu")
	self.rich_text = self.druid:new_rich_text("text_about")

	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())

	self.slider_sound.on_value_changed:subscribe(self.on_sound_value, self)
	self.slider_music.on_value_changed:subscribe(self.on_music_value, self)
	self.button_language.on_click:subscribe(self.on_language, self)
	self.button_menu.on_click:subscribe(self._on_menu, self)

	self:refresh_sound_status()

	panthera.play(self.animation, "appear")

	self.rich_text:set_text("Made by <color=#4AEAFF>Insality</color>\nMade with <color=#63FFDB>Defold</color>\n#<color=#F1FFE1>GameDevJS Jam 2026</color>")

	self.druid:new_button("settings_slider_sound/group_info", self.on_sound_toggle)
	self.druid:new_button("settings_slider_music/group_info", self.on_music_toggle)

	local text_version = M.get_version_sha_text() .. " | " .. M.get_defold_version_sha_text()
	self.text_version = self.druid:new_text("text_version", text_version)
end


function M:on_input()
	if self._is_closing then
		return false
	end

	return true
end


function M:on_back()
	if self._is_closing then
		return
	end

	self._is_closing = true
	panthera.play(self.animation, "disappear")
	self.on_close:trigger()
end


function M:_on_menu()
	if self._is_closing then
		return
	end

	self._is_closing = true
	panthera.play(self.animation, "disappear")
	self.on_menu:trigger()
end


function M:on_sound_value(value)
	audio.set_gain("sound", value)
end


function M:on_music_value(value)
	audio.set_gain("music", value)
end


function M:on_sound_toggle()
	if audio.get_gain("sound") > 0 then
		audio.set_gain("sound", 0)
	else
		audio.set_gain("sound", 1)
	end
	self:refresh_sound_status()
end


function M:on_music_toggle()
	if audio.get_gain("music") > 0 then
		audio.set_gain("music", 0)
	else
		audio.set_gain("music", 1)
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
	self.slider_sound:set_value(audio.get_gain("sound"))
	self.slider_music:set_value(audio.get_gain("music"))
end


function M.get_version_sha_text()
	local text_version = "v" .. sys.get_config_string("project.version")
	local commit_sha = sys.get_config_string("project.commit_sha", "")
	if commit_sha ~= "" then
		-- Strip commit sha to 7 symbols
		commit_sha = string.sub(commit_sha, 1, 7)
		text_version = text_version .. " (" .. commit_sha .. ")"
	end

	return text_version
end


function M.get_defold_version_sha_text()
	local info = sys.get_engine_info()
	local version = info.version
	local sha1 = info.version_sha1
	-- Strip to first 7 symbols
	local sha = string.sub(sha1, 1, 7)
	return version .. " (" .. sha .. ")"
end


return M
