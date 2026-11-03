local log = require("log.log")
local event = require("event.event")
local decore = require("decore.decore")
local abilities = require("game.abilities")

local field_command = require("system.field.field_command")
local music_command = require("system.music.music_command")
local turn_execution_command = require("system.turn_execution.turn_execution_command")
local turn_list_command = require("system.turn_list.turn_list_command")


---@class entity.turn_execution: entity.turn_list
---@field field_actor component.field_actor

---@class system.turn_execution: system
---@field entities entity.turn_execution[]
---@field is_running boolean
---@field is_auto boolean
---@field had_scheduled_turns boolean
---@field running_time_left number
---@field running_time_total number
---@field on_running_changed event
local M = {}


---@param turns field.turn_action[]
---@param turn_actions field.turn_action[]
local function append_turn_actions(turns, turn_actions)
	for index = 1, #turn_actions do
		table.insert(turns, turn_actions[index])
	end
end


---@return system.turn_execution
function M.create()
	local self = decore.system(M, "turn_execution", { "turn_list", "field_actor" })
	self.is_running = false
	self.is_auto = false
	self.had_scheduled_turns = false
	self.running_time_left = 0
	self.running_time_total = 0
	self.on_running_changed = event.create()

	turn_execution_command.register(self)

	return self
end


function M:onAddToWorld()
	music_command.on_beat:subscribe(self.on_beat, self)
end


function M:onRemoveFromWorld()
	music_command.on_beat:unsubscribe(self.on_beat, self)
end


---@param bar_beat_counter integer
function M:on_beat(bar_beat_counter)
	if not self.is_running or bar_beat_counter ~= 1 then
		return
	end

	self:process_turns()
end


function M:process_turns()
	local had_scheduled_turns_before = false
	for index = 1, #self.entities do
		if self.entities[index].turn_list.scheduled[1] then
			had_scheduled_turns_before = true
			break
		end
	end

	local turns = {}

	-- This is auto sequence turns, like a default movement for AI?
	for index = 1, #self.entities do
		local entity = self.entities[index]
		local next_turn = turn_list_command.get_next_turn(entity)
		if next_turn then
			local ability = abilities[next_turn.ability_id]
			if ability and ability.get_turn_action then
				local turn_actions = ability.get_turn_action(entity.id, next_turn.side, next_turn.params)
				append_turn_actions(turns, turn_actions)
			end
		end
	end

	log:info("Executing turns", { turns = #turns })

	field_command.process_turns(turns)

	local has_scheduled_turns_after = false
	for index = 1, #self.entities do
		if self.entities[index].turn_list.scheduled[1] then
			has_scheduled_turns_after = true
			break
		end
	end

	if had_scheduled_turns_before then
		self.had_scheduled_turns = true
	end

	if not self.is_auto and self.had_scheduled_turns and not has_scheduled_turns_after then
		self:set_running(false)
		self.had_scheduled_turns = false
	end
end


function M:set_running(is_running)
	if self.is_running == is_running then
		return
	end

	self.is_running = is_running
	self.on_running_changed:trigger(is_running)

	if is_running then
		self.had_scheduled_turns = false
		music_command.set_battle()

		-- Calculate total time based on max turns and beat time
		local max_turns = 0
		for index = 1, #self.entities do
			local entity = self.entities[index]
			max_turns = math.max(max_turns, #entity.turn_list.scheduled)
		end

		self.running_time_total = max_turns * music_command.get_turn_time() + music_command.get_next_main_beat_time()
		self.running_time_left = self.running_time_total
	else
		music_command.set_game()
	end
end


---@param is_auto boolean
function M:set_auto(is_auto)
	self.is_auto = is_auto
end


---@param dt number
function M:update(dt)
	if not self.is_running then
		return
	end

	-- Just for UI at the moment?
	if self.running_time_left > 0 then
		self.running_time_left = self.running_time_left - dt
		if self.running_time_left <= 0 then
			self.running_time_left = 0
		end
	end
end


return M
