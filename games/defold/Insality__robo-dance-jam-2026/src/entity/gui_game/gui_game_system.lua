local event = require("event.event")
local audio = require("audio.audio")
local decore = require("decore.decore")

local gui_game_command = require("entity.gui_game.gui_game_command")
local const = require("game.const")
local turn_list_command = require("system.turn_list.turn_list_command")
local music_command = require("system.music.music_command")
local turn_execution_command = require("system.turn_execution.turn_execution_command")
local game_manager_command = require("system.game_manager.game_manager_command")
local levels = require("game.levels")

---@class entity
---@field gui_game component.gui_game|nil

---@class entity.gui_game: entity
---@field gui_game component.gui_game
---@field game_object component.game_object

---@class component.gui_game
---@field on_menu event
---@field on_restart event
---@field on_level_left event
---@field on_level_right event
decore.register_component("gui_game", {
	on_menu = event.create(),
	on_restart = event.create(),
	on_level_left = event.create(),
	on_level_right = event.create(),
})

---@class system.gui_game: system
---@field entities entity.gui_game[]
---@field widget widget.gui_game|nil
---@field selected_character entity|nil
---@field select_arrow_entity entity|nil
local M = {}


---@return system.gui_game
function M.create()
	local self = decore.system(M, "gui_game", { "gui_game" })
	self.widget = nil
	self.selected_character = nil
	self.select_arrow_entity = nil
	gui_game_command.register(self)
	return self
end


---@param entity entity.gui_game
function M:onAdd(entity)
	self.widget = entity.druid_widget.widget --[[@as widget.gui_game]]

	self.widget:set_selected_character(self.selected_character)
	self.widget.on_action_card_drag:subscribe(self.on_action_card_drag, self)
	self.widget.on_add_turn:subscribe(self.on_add_turn, self)
	self.widget.on_turn_icon_click:subscribe(self.on_turn_icon_click, self)
	self.widget.on_button_action:subscribe(self.on_button_execute, self)

	music_command.on_beat:subscribe(self.widget.on_music_beat, self.widget)
	turn_execution_command.on_running_changed:subscribe(self.on_turn_execution_running_changed, self)

	turn_execution_command.set_running(true)
	self.widget:set_turn_execution_running(turn_execution_command.is_running())

	entity.gui_game.on_level_left:subscribe(self.on_level_left, self)
	entity.gui_game.on_level_right:subscribe(self.on_level_right, self)
end


function M:onRemove()
	music_command.on_beat:unsubscribe(self.widget.on_music_beat, self.widget)
	turn_execution_command.on_running_changed:unsubscribe(self.on_turn_execution_running_changed, self)
end


---@param entity entity
function M:select_character(entity)
	self.selected_character = entity
	self.widget:set_selected_character(entity)
end


function M:on_level_left()
	game_manager_command.load_previous_level()
end


function M:on_level_right()
	game_manager_command.load_next_level()
end

function M:on_action_card_drag(ability, side)
	assert(self.selected_character, "Selected character is not set")

	-- In world we have inversed side...
	if side == "up" then
		side = "down"
	elseif side == "down" then
		side = "up"
	end

	self:_set_select_arrow(side)
end


---@param ability game.ability
---@param side "up" | "down" | "left" | "right" | nil
function M:on_add_turn(ability, side)
	assert(self.selected_character, "Selected character is not set")
	local is_first_scheduled_turn = #self.selected_character.turn_list.scheduled == 0

	if self.select_arrow_entity then
		side = side or self.select_arrow_entity.select_arrow_visual.side
	end
	turn_list_command.add_turn(self.selected_character, ability.id, side)

	if not turn_execution_command.is_auto() and is_first_scheduled_turn then
		turn_execution_command.set_running(false)
	end

	--local is_instant_turns = true
	--if is_instant_turns then
	--	turn_execution_command.process_turns()
	--end

	self:_set_select_arrow(nil)
end


---@param index integer
function M:on_turn_icon_click(index)
	turn_list_command.remove_turn(self.selected_character, index)
end


function M:on_button_execute()
	if not self.selected_character then
		return
	end

	if turn_execution_command.is_running() then
		audio.play("fx_game_pause")
		turn_execution_command.set_running(false)
		return
	end

	local has_scheduled_turns = #self.selected_character.turn_list.scheduled > 0
	local has_full_turns = #self.selected_character.turn_list.scheduled >= self.selected_character.turn_list.scheduled_length_max
	if not has_scheduled_turns then
		audio.play("fx_game_play")
		turn_execution_command.set_running(true)
		return
	end

	if const.ONLY_FULL_TURNS_ALLOWED and not has_full_turns then
		return
	end

	audio.play("fx_game_play")
	turn_execution_command.set_running(true)
end


function M:on_turn_execution_running_changed(is_running)
	self.widget:set_turn_execution_running(is_running)
end


---@param side "up" | "down" | "left" | "right" | nil
function M:_set_select_arrow(side)
	if not side and self.select_arrow_entity then
		self.world:removeEntity(self.select_arrow_entity)
		self.select_arrow_entity = nil
		return
	end

	if side and not self.select_arrow_entity then
		self.select_arrow_entity = decore.create_prefab("select_arrow")
		self.select_arrow_entity.transform.position_x = self.selected_character.transform.position_x
		self.select_arrow_entity.transform.position_y = self.selected_character.transform.position_y
		self.select_arrow_entity.select_arrow_visual.side = side
		self.world:addEntity(self.select_arrow_entity)
	elseif side then
		self.select_arrow_entity.select_arrow_visual.side = side
	end
end


---@param dt number
function M:update(dt)
	if not self.widget then
		return
	end

	self.widget:set_turn_execution_running_time_progress(turn_execution_command.get_running_time_progress())
end


return M
