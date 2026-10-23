local decore = require("decore.decore")
local entity_grid = require("system.field.field.entity_grid")

local field_command = require("system.field.field_command")

---@class entity
---@field field component.field|nil
---@field field_finish boolean|nil
---@field player boolean|nil

---@class entity.field: entity
---@field field component.field
---@field transform component.transform

---@class entity.field_command: entity

---@class component.field
---@field solid boolean|nil
---@field glue boolean|nil
---@field floor boolean|nil
decore.register_component("field", {
	solid = false,
	glue = false,
	floor = false,
})
decore.register_component("field_finish")
decore.register_component("player")

---@class system.field: system
---@field entities entity.field[]
---@field field system.field.entity_grid
local M = {}


---@return system.field
function M.create_system()
	local self = decore.system(M, "field", { "field", "transform" })
	self.field = entity_grid.create(128)

	return self
end


function M:onAddToWorld()
	self.world.field = field_command.create(self)
end


---@param entity entity.field
function M:onAdd(entity)
	self.field:add_entity(entity)
end


---@param entity entity.field
function M:onRemove(entity)
	self.field:remove_entity(entity)
end


function M:postWrap()
	self.world.event_bus:process("transform_event", self.process_transform_event, self)
end


---@param event system.transform.event
function M:process_transform_event(event)
	if event.entity.field then
		local entity = event.entity --[[@as entity.field]]
		self.field:update_entity(entity)
	end
end


---@param i number
---@param j number
---@param radius number
---@param callback fun(entity: entity, i: number, j: number)
function M:for_each_in_radius(i, j, radius, callback)
	local field = self.field

	for di = -radius, radius do
		for dj = -math.abs(radius - math.abs(di)), math.abs(radius - math.abs(di)) do
			local new_i = i + di
			local new_j = j + dj
			if new_i ~= i or new_j ~= j then
				local entities = field.grid[new_i] and field.grid[new_i][new_j]
				if #entities > 0 then
					for _, e in ipairs(entities) do
						callback(e, new_i, new_j)
					end
				end
			end
		end
	end
end


return M
