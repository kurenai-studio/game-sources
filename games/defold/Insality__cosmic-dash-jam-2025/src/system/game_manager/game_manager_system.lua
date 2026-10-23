local log = require("log.log")
local levels = require("game.levels")
local events = require("event.events")
local decore = require("decore.decore")
local promise = require("event.promise")
local detiled = require("detiled.detiled")

local command_game_manager = require("system.game_manager.game_manager_command")

---@class entity
---@field game_manager component.game_manager|nil

---@class entity.game_manager: entity
---@field game_manager component.game_manager

---@class component.game_manager
decore.register_component("game_manager")

---@class system.game_manager.state
---@field last_level_id string

---@class system.game_manager: system
---@field entities entity.game_manager[]
---@field state system.game_manager.state
---@field current_level entity?
---@field last_finish_entity entity?
local M = {}

---@return system.game_manager
function M.create_system()
	local self = decore.system(M, "game_manager", { "game_manager" })
	self.current_level = nil
	return self
end


function M:onAddToWorld()
	self.world.game_manager = command_game_manager.create(self)
	events.subscribe("game_gui.on_restart", self.on_restart, self)
	events.subscribe("game_gui.on_menu", self.on_menu, self)
	events.subscribe("game_gui.on_level_prev", self.on_level_prev, self)
	events.subscribe("game_gui.on_level_next", self.on_level_next, self)

	self.world.sound:play_music("music_game", 0)
	self.world.sound:fade_music(1, 8)
end


function M:onRemoveFromWorld()
	events.unsubscribe("game_gui.on_restart", self.on_restart, self)
	events.unsubscribe("game_gui.on_menu", self.on_menu, self)
	events.unsubscribe("game_gui.on_level_prev", self.on_level_prev, self)
	events.unsubscribe("game_gui.on_level_next", self.on_level_next, self)
end


function M:postWrap()
	self.world.event_bus:process("on_field_glue_collide", self.on_field_glue_collide, self)
end


function M:load_previous_level()
	return promise.resolved()
		:next(self.unload_level, nil, self)
		:next(self.wait_level_unload, nil, self)
		:next(levels.get_previous_level, nil, self)
		:next(self.load_level, nil, self)
		:next(self.animate_level_appear, nil, self)
end


function M:load_current_level()
	return promise.resolved()
		:next(self.unload_level, nil, self)
		:next(self.wait_level_unload, nil, self)
		:next(self.load_level, nil, self)
		:next(self.animate_level_appear, nil, self)
end


---@return promise
function M:load_next_level()
	return promise.resolved()
		:next(self.unload_level, nil, self)
		:next(self.wait_level_unload, nil, self)
		:next(levels.get_next_level, nil, self)
		:next(self.load_level, nil, self)
		:next(self.animate_level_appear, nil, self)
end


function M:unload_level()
	if self.current_level then
		local finish = decore.find_entities(self.world, "field_finish")[1]
		self.last_finish_entity = finish

		self.world:removeEntity(self.current_level)
		self.current_level = nil

		return true
	end

	return false
end


---@param is_level_unloaded boolean
function M:wait_level_unload(is_level_unloaded)
	if not is_level_unloaded then
		return
	end

	return promise.create(function(resolve)
		timer.delay(0.25, false, resolve)
	end)
end


---@param level game.const.level?
function M:load_level(level)
	local level_id = level and level.level_id or levels.get_current_level_id()
	log:info("Load level", level_id)

	local level_data = self:get_level_by_id(level_id)
	if level_data then
		local level_entity = decore.create(detiled.get_entity_from_map(level_data.path))

		self:_apply_target_offset(level_entity)
		self.current_level = self.world:addEntity(level_entity)
		levels.on_level_started(level_id)

		events.trigger("game_manager.level_loaded", level_data)
	end
end


---@param level_id string
---@return game.const.level?
function M:get_level_by_id(level_id)
	for _, level_const in pairs(levels) do
		if level_const.level_id == level_id then
			return level_const
		end
	end
end


function M:on_restart()
	if not self.current_level then
		return
	end

	self:load_current_level()
end


function M:create_menu_gui()
	local entity = decore.create_prefab("menu_gui")
	entity.menu_gui.on_play:subscribe(function()
		self.world.game_manager:start_game()
		self.world:removeEntity(entity)
	end)
	self.world:addEntity(entity)
end


function M:on_menu()
	local window_settings = decore.create_prefab("window_settings")
	window_settings.window_settings.on_menu:subscribe(function()
		self:unload_level()
		self.world:removeEntity(window_settings)
		self:create_menu_gui()
	end)

	self.world:addEntity(window_settings)
end


---@param event event.field_movable.on_glue_collide
function M:on_field_glue_collide(event)
	local entity = event.entity
	local collide = event.collide

	if entity.player and collide.field_finish then
		self.world.sound:play("level_complete")
		levels.on_level_completed()
		timer.delay(0.3, false, function()
			self:load_next_level()
		end)
		return
	end
end


---@param level_entity entity
function M:_apply_target_offset(level_entity)
	local offset_x = 0
	local offset_y = 0

	local current_finish = self.last_finish_entity
	if current_finish then
		for _, entity_prefab in pairs(level_entity.child_instancies) do
			local target_transform = entity_prefab.components and entity_prefab.components.transform
			local is_player = entity_prefab.prefab_id == "player"
			if is_player and target_transform then
				local from_x = current_finish.transform.position_x
				local from_y = current_finish.transform.position_y

				offset_x = from_x - target_transform.position_x
				offset_y = from_y - target_transform.position_y
			end
		end
	end

	decore.apply_component(level_entity, "transform", {
		position_x = offset_x,
		position_y = offset_y,
	})
end


function M:animate_level_appear()
	local entity = self.current_level
	if not entity then
		return
	end

	-- Set delay relative to the player prefab
	local entities = entity.child_instancies or {} -- table<string, entity>
	local player = nil
	for _, entity_prefab in pairs(entities) do
		if entity_prefab.prefab_id == "player" then
			player = entity_prefab
			break
		end
	end

	if player then
		local player_x = player.components.transform.position_x
		local player_y = player.components.transform.position_y

		for _, target in pairs(entities) do
			local transform = target.components.transform
			if transform then
				local target_x = transform.position_x
				local target_y = transform.position_y

				local dist = math.sqrt((target_x - player_x)^2 + (target_y - player_y)^2)
				target.components.distance_to_player = dist
			end
		end
	end

	local finish = nil
	for _, target in pairs(entities) do
		local is_finish = target.prefab_id == "tile_finish"
		if is_finish then
			finish = target
			break
		end
	end

	if finish then
		local finish_x = finish.components.transform.position_x
		local finish_y = finish.components.transform.position_y

		for _, target in pairs(entities) do
			local transform = target.components.transform
			if transform then
				local target_x = transform.position_x
				local target_y = transform.position_y

				local dist = math.sqrt((target_x - finish_x)^2 + (target_y - finish_y)^2)
				target.components.distance_to_finish = dist
			end
		end
	end
end


function M:on_level_prev()
	if not self.current_level then
		return
	end

	self:load_previous_level()
end


function M:on_level_next()
	if not self.current_level then
		return
	end

	self:load_next_level()
end


return M
