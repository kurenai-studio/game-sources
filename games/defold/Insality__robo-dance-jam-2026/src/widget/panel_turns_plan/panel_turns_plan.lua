local audio = require("audio.audio")
local event = require("event.event")
local abilities = require("game.abilities")
local panthera = require("panthera.panthera")

local icon_turn_action = require("widget.icon_turn_action.icon_turn_action")
local icon_turn_side = require("widget.icon_turn_side.icon_turn_side")
local animation = require("widget.panel_turns_plan.panel_turns_plan_panthera")

local TURN_ICONS_COUNT = 4

---@class widget.panel_turns_plan: druid.widget
---@field on_add_skip event
---@field selected_character entity|nil
local M = {}


function M:init()
	self.on_turn_icon_click = event.create()
	self.on_add_skip = event.create()

	self.root = self:get_node("root")

	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())
	self.animation_alive = panthera.clone_state(self.animation)

	self.layout_turns = self.druid:new_layout("layout_turns", "horizontal")
	self.text_counter = self.druid:new_text("text_counter")
	self.icon_player = self:get_node("icon_selected_player")
	self.node_arrow_selected = self:get_node("arrow_selected")


	self.selected_character = nil
	self._turn_icons = {}
	self._is_character_alive = true

	gui.set_enabled(self:get_node("icon_turn_side/root"), false)
	gui.set_enabled(self.node_arrow_selected, false)

	self.icon_turn_skip = self.druid:new_widget(icon_turn_action, "icon_turn_skip")
	self.button_add_skip = self.druid:new_button(self.icon_turn_skip.root, self._on_add_skip)
	self.button_add_skip:set_key_trigger("key_e")

	self.icon_turn_skip.button_input_hint:set_enabled(true)

	self.druid:new_hotkey("key_backspace", self.on_backspace_pressed, self)

	self:_create_turn_icons()
	self:_refresh_turn_counter()
end


function M:_on_add_skip()
	audio.play("fx_action_select")
	self.on_add_skip:trigger(abilities.wait, "none")
end


---@param entity entity?
function M:bind_character(entity)
	self.selected_character = entity

	self:_check_alive_character()
end


---@param turns component.turn_list.turn[]|nil
function M:set_turn_icons(turns)
	turns = turns or {}

	for index = 1, TURN_ICONS_COUNT do
		local turn = turns[index]
		local turn_icon = self._turn_icons[index] --[[@as widget.icon_turn_side]]
		if turn then
			local ability = abilities[turn.ability_id]
			turn_icon:set_ability(ability, turn.side)
		else
			turn_icon:clear_ability()
		end
		turn_icon:set_index(index)
	end

	self:_refresh_turn_counter()
	gui.set_enabled(self.node_arrow_selected, #turns > 0)
end


---@param turn_icon widget.icon_turn_side
function M:_on_turn_icon_click(turn_icon)
	if turn_icon.ability then
		audio.play("fx_action_cancel")
	end
	self.on_turn_icon_click:trigger(turn_icon:get_index())
	-- only if exists
end


function M:on_backspace_pressed()
	local turns = self.selected_character and self.selected_character.turn_list and self.selected_character.turn_list.scheduled or nil
	local turns_count = turns and #turns or 0
	if turns_count > 0 then
		self.on_turn_icon_click:trigger(turns_count)
		audio.play("fx_action_cancel")
	end
end


function M:_create_turn_icons()
	for index = 1, TURN_ICONS_COUNT do
		local turn_icon = self.druid:new_widget(icon_turn_side, "icon_turn_side", "root")
		turn_icon.on_click:subscribe(self._on_turn_icon_click, self)
		turn_icon:set_index(index)
		turn_icon:clear_ability()
		gui.set_enabled(turn_icon.root, true)
		self.layout_turns:add(turn_icon.root)
		table.insert(self._turn_icons, turn_icon)
	end
end


function M:_refresh_turn_counter()
	if not self.selected_character or not self.selected_character.turn_list then
		self.text_counter:set_text("")
		return
	end

	local current_turns = #self.selected_character.turn_list.scheduled
	local max_turns = self.selected_character.turn_list.scheduled_length_max
	self.text_counter:set_text(current_turns .. " / " .. max_turns)
end


---@param bar_beat_counter number
function M:on_music_beat(bar_beat_counter)
	if self.selected_character and self.selected_character.field_actor then
		local actor = self.selected_character.field_actor.field_entity
		local is_alive = actor and actor.health > 0
		if is_alive then
			if bar_beat_counter == 1 or bar_beat_counter == 3 then
				panthera.play(self.animation, "on_beat_main")
			else
				panthera.play(self.animation, "on_beat_sub")
			end
		end

		if bar_beat_counter == 2 or bar_beat_counter == 4 then
			self:_check_alive_character()
		end
	end

	for index = 1, #self._turn_icons do
		local turn_icon = self._turn_icons[index] --[[@as widget.icon_turn_side]]
		turn_icon:on_music_beat(bar_beat_counter)
	end
end


function M:set_turn_execution_running(is_running)
	for index = 1, #self._turn_icons do
		local turn_icon = self._turn_icons[index] --[[@as widget.icon_turn_side]]
		turn_icon:set_turn_execution_running(is_running)
	end
end


function M:_check_alive_character()
	if not self.selected_character or not self.selected_character.field_actor then
		return
	end

	local actor = self.selected_character.field_actor.field_entity
	local is_alive = actor and actor.health > 0

	if is_alive ~= self._is_character_alive then
		self._is_character_alive = is_alive
		if is_alive then
			panthera.play(self.animation_alive, "on_alive")
		else
			panthera.play(self.animation_alive, "on_death")
		end
	end

	self._is_character_alive = is_alive
end


return M
