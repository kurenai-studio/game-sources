local lang = require("lang.lang")
local event = require("event.event")
local plan_panel = require("widget.plan_panel.plan_panel")
local levels = require("game.levels")
local text_animated = require("widget.text_animated.text_animated")

---@class widget.gui_game: druid.widget
---@field plan_panel widget.plan_panel
---@field on_action_card_drag event
---@field on_add_turn event
---@field on_turn_icon_click event
---@field on_button_action event
local M = {}


---@param entity entity.gui_game
function M:init(entity)
	self.on_action_card_drag = event.create()
	self.on_add_turn = event.create()
	self.on_turn_icon_click = event.create()
	self.on_button_action = event.create()

	self.root = self:get_node("root")

	self.button_menu = self.druid:new_button("button_menu", entity.gui_game.on_menu)
	self.button_menu:set_key_trigger("key_esc")

	self.button_restart = self.druid:new_button("button_restart", entity.gui_game.on_restart)
	self.button_restart:set_key_trigger("key_r")

	self.plan_panel = self.druid:new_widget(plan_panel, "plan_panel")


	--self.druid:new_lang_text("text_hint_control", "ui_hint_control")
	self.text_hint_control = self.druid:new_widget(text_animated, "text_hint_control")
	self.text_hint_control:animate_text("ui_hint_control")
	self._timer_hint_control = timer.delay(0.6 * 8 * 4, true, function()
		self.text_hint_control:animate_text("ui_hint_control")
	end)

	self.text_level = self.druid:new_lang_text("text_level")
	self.button_level_left = self.druid:new_button("icon_left", entity.gui_game.on_level_left)
	self.button_level_right = self.druid:new_button("icon_right", entity.gui_game.on_level_right)


	self:bind_events()
end


function M:onRemove()
	timer.cancel(self._timer_hint_control)
end


function M:on_language_change()
	self.text_hint_control:animate_text("ui_hint_control")
end


function M:bind_events()
	self.plan_panel.on_action_card_drag:subscribe(self.on_action_card_drag)
	self.plan_panel.on_add_turn:subscribe(self.on_add_turn)
	self.plan_panel.on_turn_icon_click:subscribe(self.on_turn_icon_click)
	self.plan_panel.on_button_action:subscribe(self.on_button_action)
end


---@param entity entity
function M:set_selected_character(entity)
	self.plan_panel:bind_character(entity)

	self:set_level_number(levels.get_current_level_index())
end


---@param bar_beat_counter integer
function M:on_music_beat(bar_beat_counter)
	self.plan_panel:on_music_beat(bar_beat_counter)
end


---@param is_running boolean
function M:set_turn_execution_running(is_running)
	self.plan_panel:set_turn_execution_running(is_running)
end


---@param time_left number
function M:set_turn_execution_running_time_progress(time_left)
	self.plan_panel:set_turn_execution_running_time_progress(time_left)
end


function M:set_level_number(level_number)
	self.text_level:translate("ui_level", level_number)
end


return M
