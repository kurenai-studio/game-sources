local events = require("event.events")
local levels = require("game.levels")
local decore = require("decore.decore")

local game_manager_command = require("system.game_manager.game_manager_command")
local level_manager_command = require("system.level_manager.level_manager_command")
local music_command = require("system.music.music_command")
local turn_execution_command = require("system.turn_execution.turn_execution_command")

---@class entity
---@field game_manager component.game_manager|nil

---@class entity.game_manager: entity
---@field game_manager component.game_manager

---@class component.game_manager
decore.register_component("game_manager", {})

---@class system.game_manager: system
---@field entities entity.game_manager[]
---@field level_transition_timer_handle number|nil
local M = {}


---@return system.game_manager
function M.create()
	local self = decore.system(M, "game_manager", { "game_manager" })
	self.level_transition_timer_handle = nil
	game_manager_command.register(self)

	return self
end


local is_debug = sys.get_engine_info().is_debug
function M:postWrap()
	if not is_debug then
		return
	end

	self.world.event_bus:process("input_event", self.process_input_event, self)
end



function M:process_input_event(event)
	if event.action_id == hash("key_j") and event.pressed then
		self:load_previous_level()
	end

	if event.action_id == hash("key_k") and event.pressed then
		self:on_level_complete()
		self:load_next_level()
	end
end


function M:start_game()
	local background = decore.create_prefab("background")
	self.world:addEntity(background)

	local camera_area = decore.create_prefab("camera_area")
	self.world:addEntity(camera_area)

	self:show_menu()
end


function M:show_menu()
	turn_execution_command.set_running(false)
	music_command.set_menu()

	local gui_menu = decore.create_prefab("gui_menu")
	self.world:addEntity(gui_menu)

	self.world.event_bus:trigger("game_active", { is_active = false })

	gui_menu.gui_menu.on_play:subscribe(function()
		self.world:removeEntity(gui_menu)
		local current_level_id = levels.get_current_level_id()
		self:show_game(current_level_id)
	end)

	gui_menu.gui_menu.on_level_select:subscribe(function()
		self.world:removeEntity(gui_menu)
		self:show_level_select()
	end)

	gui_menu.gui_menu.on_menu:subscribe(function()
		self:show_window_settings()
	end)
end


---@param level_id string
function M:show_game(level_id)
	local level_path = levels.get_level_by_id(level_id).path
	levels.set_current_level_id(level_id)

	level_manager_command.load_level(level_path)

	self.world.event_bus:trigger("game_active", { is_active = true })

	local gui_game = decore.create_prefab("gui_game")
	self.world:addEntity(gui_game)

	music_command.set_game()

	gui_game.gui_game.on_menu:subscribe(function()
		self:show_window_settings(function()
			self.world:removeEntity(gui_game)
			level_manager_command.unload_level()

			self:show_menu()
		end)
	end)

	gui_game.gui_game.on_restart:subscribe(function()
		self:reload_level()
	end)

	self:_check_input_hints(level_id)
end


function M:show_level_select()
	local gui_level_select = decore.create_prefab("gui_level_select")
	self.world:addEntity(gui_level_select)

	gui_level_select.gui_level_select.on_level_click:subscribe(function(level_id)
		self.world:removeEntity(gui_level_select)
		self:show_game(level_id)
	end)

	gui_level_select.gui_level_select.on_back:subscribe(function()
		self.world:removeEntity(gui_level_select)
		self:show_menu()
	end)

	gui_level_select.gui_level_select.on_menu:subscribe(function()
		self:show_window_settings()
	end)
end


---@param on_menu fun()|nil
function M:show_window_settings(on_menu)
	local window_settings = decore.create_prefab("window_settings")

	window_settings.window_settings.on_close:subscribe(function()
		self.world:removeEntity(window_settings)
	end)

	window_settings.window_settings.on_menu:subscribe(function()
		self.world:removeEntity(window_settings)
		if on_menu then
			on_menu()
		end
	end)

	self.world:addEntity(window_settings)
end


function M:on_level_complete()
	levels.on_level_completed()
end


function M:cancel_level_transition_timer()
	if self.level_transition_timer_handle then
		timer.cancel(self.level_transition_timer_handle)
		self.level_transition_timer_handle = nil
	end
end


function M:load_next_level()
	if self.level_transition_timer_handle then
		return
	end

	level_manager_command.unload_level()

	local next_level = levels.get_next_level()

	self.level_transition_timer_handle = timer.delay(music_command.BEAT_TIME, false, function()
		self.level_transition_timer_handle = nil
		levels.set_current_level_id(next_level.level_id)
		local level_path = levels.get_level_by_id(next_level.level_id).path
		level_manager_command.load_level(level_path)
		turn_execution_command.set_running(true)

		self:_check_input_hints(next_level.level_id)
	end)
end


function M:load_previous_level()
	if self.level_transition_timer_handle then
		return
	end

	level_manager_command.unload_level()

	local previous_level = levels.get_previous_level()

	self.level_transition_timer_handle = timer.delay(music_command.BEAT_TIME, false, function()
		self.level_transition_timer_handle = nil
		levels.set_current_level_id(previous_level.level_id)
		local level_path = levels.get_level_by_id(previous_level.level_id).path
		level_manager_command.load_level(level_path)
		turn_execution_command.set_running(true)

		self:_check_input_hints(previous_level.level_id)
	end)
end


function M:reload_level()
	if self.level_transition_timer_handle then
		return
	end

	level_manager_command.unload_level()
	local current_level_id = levels.get_current_level_id()
	levels.set_current_level_id(current_level_id)

	local level_path = levels.get_level_by_id(current_level_id).path

	self.level_transition_timer_handle = timer.delay(music_command.BEAT_TIME, false, function()
		self.level_transition_timer_handle = nil
		level_manager_command.load_level(level_path)
		turn_execution_command.set_running(true)

		self:_check_input_hints(current_level_id)
	end)
end


function M:_check_input_hints(level_id)
	local level_index = levels.get_level_index(levels.LEVELS, level_id)
	timer.delay(0.6, false, function()
		events.trigger("show_input_hint", level_index <= 3)
	end)
end


return M
