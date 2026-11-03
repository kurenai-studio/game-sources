local luax = require("game.luax")
local event = require("event.event")
local decore = require("decore.decore")
local field_turn_result = require("system.field.field.field_turn_result")

---@class entity
---@field turn_list component.turn_list|nil
---@field patterns component.patterns|nil

---@class entity.turn_list: entity
---@field turn_list component.turn_list
---@field patterns component.patterns|nil

---@class component.turn_list.turn
---@field ability_id string
---@field side "up" | "down" | "left" | "right" | "none" | nil
---@field params table|nil

---@class component.turn_list
---@field scheduled component.turn_list.turn[]
---@field scheduled_length_max integer
---@field sequence_list component.turn_list.turn[]
---@field sequence_last_index integer
---@field intro_sequence_list component.turn_list.turn[]
---@field intro_last_index integer
---@field inherited_side "up" | "down" | "left" | "right" | "none" | nil Fallback when step has no side and field last_move_side is none (e.g. spawned attack cells)
---@field pattern_index integer|string|nil Index or name in `patterns.list`, or a named field on `patterns`
---@field pattern_on_damage integer|string|nil Index or name in `patterns` that is activated when entity receives DAMAGE result
---@field pattern_delay integer|nil Prepends this many `wait` turns at the start of intro (editor-friendly delay before pattern intro)
---@field on_changed event

---@class component.turns_sequence.turn
---@field ability_id string
---@field side "up" | "down" | "left" | "right" | nil
---@field params table|nil

---@class component.turns_sequence
---@field list component.turns_sequence.turn[]|nil

decore.register_component("turn_list", {
	scheduled = {},
	scheduled_length_max = 4,
	sequence_list = {},
	sequence_last_index = 0,
	intro_sequence_list = {},
	intro_last_index = 0,
	pattern_index = nil,
	pattern_on_damage = nil,
	pattern_delay = 0,
	on_changed = event.create(),
})


--- Plain array of turns (loops forever), or intro once then loop.
---@alias component.patterns.pattern_item component.turns_sequence.turn[]|component.patterns.pattern_with_loop

---@class component.patterns.pattern_with_loop
---@field intro component.turns_sequence.turn[]|nil
---@field loop component.turns_sequence.turn[]

---@class component.patterns
---@field list table|nil Ordered entries `[1..n]` and/or string keys; extra named patterns may also be fields on `patterns` (siblings of `list`)

decore.register_component("patterns", {
	list = {},
})


---@param patterns component.patterns
---@param pattern_index integer|string
---@return component.patterns.pattern_item|nil
local function resolve_pattern(patterns, pattern_index)
	local list = patterns.list
	local pattern
	if list then
		local key = pattern_index
		if type(pattern_index) == "string" then
			local n = tonumber(pattern_index)
			if n ~= nil then
				key = n
			end
		end
		pattern = list[key]
		if pattern == nil and type(pattern_index) == "string" then
			pattern = list[pattern_index]
		end
	end
	if pattern == nil and type(pattern_index) == "string" then
		pattern = patterns[pattern_index]
	end
	return pattern
end


---@param intro component.turns_sequence.turn[]
---@param delay integer|nil
---@return component.turns_sequence.turn[]
local function apply_pattern_delay(intro, delay)
	if not delay or delay < 1 then
		return intro
	end
	local out = {}
	for index = 1, delay do
		out[index] = { "wait", nil, nil }
	end
	for index = 1, #intro do
		out[#out + 1] = intro[index]
	end
	return out
end


---@class system.turn_list: system
---@field entities entity.turn_list[]
local M = {}


---@return system.turn_list
function M.create()
	return decore.system(M, "turn_list", "turn_list")
end


function M:postWrap()
	self.world.event_bus:process("field_turn_visual_event", self.process_field_turn_visual_event, self)
end


---@param entity entity.turn_list
function M:onAdd(entity)
	self:parse_turns_sequence(entity)
end


---@param event { entity: entity.turn_list, turn: field.turn_result }
function M:process_field_turn_visual_event(event)
	local entity = event.entity
	if not self.indices[entity] then
		return
	end

	local turn_list = entity.turn_list
	local turn = event.turn
	if turn.type ~= field_turn_result.TURN_RESULT_TYPE.DAMAGE or turn_list.pattern_on_damage == nil then
		return
	end

	turn_list.pattern_index = turn_list.pattern_on_damage
	self:parse_turns_sequence(entity)
end


---@param entity entity.turn_list
function M:parse_turns_sequence(entity)
	entity.turn_list.sequence_last_index = 0
	entity.turn_list.intro_last_index = 0

	if entity.turn_list.pattern_index ~= nil and entity.patterns then
		---@type component.patterns.pattern_item|nil
		local pattern = resolve_pattern(entity.patterns, entity.turn_list.pattern_index)
		if pattern then
			---@type component.patterns.pattern_with_loop|nil
			local with_loop = pattern.loop ~= nil and pattern or nil
			local delay = entity.turn_list.pattern_delay
			if with_loop then
				entity.turn_list.sequence_list = with_loop.loop
				entity.turn_list.intro_sequence_list = apply_pattern_delay(with_loop.intro or {}, delay)
			else
				entity.turn_list.sequence_list = pattern --[[@as component.turns_sequence.turn[] ]]
				entity.turn_list.intro_sequence_list = apply_pattern_delay({}, delay)
			end
		end
	end
end


return M
