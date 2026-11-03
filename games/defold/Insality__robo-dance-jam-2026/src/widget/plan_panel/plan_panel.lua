local event = require("event.event")
local audio = require("audio.audio")
local panthera = require("panthera.panthera")
local abilities = require("game.abilities")
local const = require("game.const")
local turn_action_card = require("widget.turn_action_card.turn_action_card")
local panel_turns_plan = require("widget.panel_turns_plan.panel_turns_plan")
local button_plan_execute = require("widget.button_plan_execute.button_plan_execute")
local button_plan_mode = require("widget.button_mode.button_plan_mode")
local turn_execution_command = require("system.turn_execution.turn_execution_command")
local health_bar = require("widget.health_bar.health_bar")

---@class widget.plan_panel: druid.widget
---@field on_action_card_drag event
---@field on_add_turn event
---@field on_turn_icon_click event
---@field on_button_action event
---@field selected_character table|nil
---@field _action_cards widget.turn_action_card[]
local M = {}


function M:init()
	self.on_action_card_drag = event.create()
	self.on_add_turn = event.create()
	self.on_turn_icon_click = event.create()
	self.on_button_action = event.create()

	self.root = self:get_node("root")

	self.panel_turns_plan = self.druid:new_widget(panel_turns_plan, "panel_turns_plan")
	self.button_plan_execute = self.druid:new_widget(button_plan_execute, "button_plan_execute")
	self.button_plan_mode = self.druid:new_widget(button_plan_mode, "button_plan_mode")
	self.button_plan_mode.on_click:subscribe(self.on_button_plan_mode_click, self)
	self.button_plan_mode:set_auto(turn_execution_command.is_auto())
	self.layout_action = self.druid:new_layout("layout_action", "vertical")
	self.health_bar = self.druid:new_widget(health_bar, "health_bar")

	--self.button_plan_execute.button:set_key_trigger("key_space")
	self.druid:new_hotkey("key_space", self.on_button_action, self)
		:add_hotkey("key_enter")

	gui.set_enabled(self:get_node("turn_action_card/root"), false)

	self._action_cards = {}
	self.selected_character = nil
	self._is_turn_execution_running = false

	self.button_plan_execute.on_click:subscribe(self.on_button_action)
	self.panel_turns_plan.on_turn_icon_click:subscribe(self.on_turn_icon_click)
	self.panel_turns_plan.on_add_skip:subscribe(self.on_add_turn)

	self._wasd_hotkey_side = nil
	self._hotkey_wasd = self.druid:new_hotkey({})
	self._hotkey_wasd:add_hotkey("key_w", "down")
	self._hotkey_wasd:add_hotkey("key_s", "up")
	self._hotkey_wasd:add_hotkey("key_a", "left")
	self._hotkey_wasd:add_hotkey("key_d", "right")
	self._hotkey_wasd:add_hotkey("key_up", "down")
	self._hotkey_wasd:add_hotkey("key_down", "up")
	self._hotkey_wasd:add_hotkey("key_left", "left")
	self._hotkey_wasd:add_hotkey("key_right", "right")
	self._hotkey_wasd:bind_node(self.root)
	self._hotkey_wasd.on_hotkey_pressed:subscribe(self._on_plan_wasd_pressed, self)
	self._hotkey_wasd.on_hotkey_released:subscribe(self._on_plan_wasd_released, self)
end


---@param _ctx table
---@param side "up"|"down"|"left"|"right"
function M:_on_plan_wasd_pressed(_ctx, side)
	if not self.selected_character then
		return
	end

	self._wasd_hotkey_side = side
end


---@param _ctx table
---@param side "up"|"down"|"left"|"right"
function M:_on_plan_wasd_released(_ctx, side)
	if not self._wasd_hotkey_side or side ~= self._wasd_hotkey_side then
		return
	end

	self._wasd_hotkey_side = nil

	local card = self._action_cards[1]
	if not card then
		return
	end

	local ability = abilities[card.ability.id]
	self.on_add_turn:trigger(ability, side)
	audio.play("fx_action_selected")
end


---@param entity entity?
function M:bind_character(entity)
	if self.selected_character then
		self.selected_character.turn_list.on_changed:unsubscribe(self.on_turn_list_changed, self)
		self.selected_character = nil
	end

	if not entity then
		self:set_action_cards(nil)
		self.health_bar:set_entity(nil)
		self.panel_turns_plan:bind_character(nil)
		self.button_plan_execute:set_enabled(false)
		return
	end

	self.selected_character = entity
	self.selected_character.turn_list.on_changed:subscribe(self.on_turn_list_changed, self)

	self:set_action_cards(entity.abilities.list)
	self.panel_turns_plan:bind_character(entity)
	self.panel_turns_plan:set_turn_icons(entity.turn_list.scheduled)
	self:_refresh_execute_button_state()

	self.health_bar:set_entity(entity)
end


function M:on_turn_list_changed()
	self.panel_turns_plan:set_turn_icons(self.selected_character.turn_list.scheduled)
	self:_refresh_execute_button_state()
end


---@param ability_ids string[]|nil
function M:set_action_cards(ability_ids)
	self._wasd_hotkey_side = nil

	ability_ids = ability_ids or {}

	self:_clear_action_cards()

	for index = 1, #ability_ids do
		local ability = abilities[ability_ids[index]]

		local action_card = self.druid:new_widget(turn_action_card, "turn_action_card", "root")
		action_card:set_ability(ability)
		action_card.on_drag:subscribe(self.on_action_card_drag)
		action_card.on_drag_end:subscribe(self.on_add_turn)
		action_card:set_index(index)

		gui.set_enabled(action_card.root, true)
		table.insert(self._action_cards, action_card)
		self.layout_action:add(action_card.root)
	end
end


function M:_clear_action_cards()
	for index = 1, #self._action_cards do
		panthera.stop(self._action_cards[index].animation)
	end

	self.layout_action:clear_layout()
	for index = 1, #self._action_cards do
		self.druid:remove(self._action_cards[index])
		gui.delete_node(self._action_cards[index].root)
	end
	self._action_cards = {}
end


function M:on_music_beat(bar_beat_counter)
	for index = 1, #self._action_cards do
		self._action_cards[index]:on_music_beat(bar_beat_counter)
	end
	self.panel_turns_plan:on_music_beat(bar_beat_counter)

	self.health_bar:update_hearts(bar_beat_counter)
end


---@param is_running boolean
function M:set_turn_execution_running(is_running)
	self._is_turn_execution_running = is_running
	--self.panel_turns_plan:set_turn_execution_running(is_running)
	self.button_plan_execute:set_executing(is_running)
	self:_refresh_execute_button_state()
end


---@param time_left number
function M:set_turn_execution_running_time_progress(time_left)
	self.button_plan_execute:set_running_time_progress(time_left)
end


function M:on_button_plan_mode_click()
	local is_auto = self.button_plan_mode:get_auto()
	turn_execution_command.set_auto(is_auto)
	--turn_execution_command.set_running(is_auto)
end


function M:_refresh_execute_button_state()
	if not self.selected_character then
		self.button_plan_execute:set_enabled(false)
		return
	end

	local has_scheduled_turns = #self.selected_character.turn_list.scheduled > 0
	local has_full_turns = #self.selected_character.turn_list.scheduled >= self.selected_character.turn_list.scheduled_length_max
	local can_toggle_empty_execution = not has_scheduled_turns
	local can_unpause = can_toggle_empty_execution and not self._is_turn_execution_running
	self.button_plan_execute:set_can_unpause(can_unpause)

	if const.ONLY_FULL_TURNS_ALLOWED then
		self.button_plan_execute:set_enabled(can_toggle_empty_execution or has_full_turns)
		return
	end

	local can_pause_empty_execution = self._is_turn_execution_running and can_toggle_empty_execution
	self.button_plan_execute:set_enabled(not self._is_turn_execution_running or can_pause_empty_execution)
end


return M
