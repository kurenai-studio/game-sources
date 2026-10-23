local decore = require("decore.decore")
local panthera = require("panthera.panthera")
local animation = require("entity.menu_gui.menu_gui_panthera")
local stars_progress_collected = require("widget.stars_progress_collected.stars_progress_collected")
local text_level_hint = require("widget.text_level_hint.text_level_hint")
local world = require("game.world")

---@class entity
---@field menu_gui component.menu_gui?

---@class entity.menu_gui: entity
---@field menu_gui component.menu_gui

---@class component.menu_gui
---@field on_play event
decore.register_component("menu_gui")

---@class widget.menu_gui: druid.widget
local M = {}


---@param entity entity.menu_gui
function M:init(entity)
	self.entity = entity

	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())
	self.animation_victory = panthera.clone_state(self.animation)
	panthera.play(self.animation, "idle", panthera.OPTIONS_LOOP)

	self.druid:new_button("button_text/button", self.entity.menu_gui.on_play):set_key_trigger("key_space")

	self.stars_progress_collected = self.druid:new_widget(stars_progress_collected, "stars_progress_collected")
	self.text_level_hint = self.druid:new_widget(text_level_hint, "text_level_hint")
	self.druid:new_button("button_menu", self.on_menu)
	self.druid:new_lang_text("button_text/text", "ui_play")

	local text_version = M.get_version_sha_text() .. "\n" .. M.get_defold_version_sha_text()
	self.text_version = self.druid:new_text("text_version", text_version)


	gui.set_enabled(self.text_level_hint.root, false)
	if self.stars_progress_collected:is_completed() then
		panthera.play(self.animation, "victory", panthera.OPTIONS_LOOP)
		gui.set_enabled(self.text_level_hint.root, true)
		self.text_level_hint:set_text("ui_game_completed")
	end
end


function M:on_menu()
	world:addEntity(decore.create_prefab("window_settings"))
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
