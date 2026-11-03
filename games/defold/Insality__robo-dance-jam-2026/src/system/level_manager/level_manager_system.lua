local log = require("log.log")
local decore = require("decore.decore")
local detiled = require("detiled.detiled")
local level_manager_command = require("system.level_manager.level_manager_command")

---@class system.level_manager: system
---@field level_entity entity|nil
---@field map_params detiled.map_params|nil
local M = {}

---@return system.level_manager
function M.create()
	local self = decore.system(M, "level_manager")
	self.level_entity = nil
	self.map_params = nil

	level_manager_command.register(self)

	return self
end


function M:load_level(level_path)
	self:unload_level()

	local instances, map_params = self:parse_level(level_path)
	self:spawn_level_entity(instances)
	self.map_params = map_params
end


function M:unload_level()
	if not self.level_entity then
		return
	end

	self.world:removeEntity(self.level_entity)
	self.level_entity = nil
	--self.map_params = nil
end


---@param level_path string
---@return table[], detiled.map_params|nil
function M:parse_level(level_path)
	local layers, map_params = detiled.parse(level_path)

	local instances = {}
	for _, layer_data in pairs(layers) do
		for _, entity in ipairs(layer_data.entities) do
			table.insert(instances, entity)
		end
	end

	return instances, map_params
end


---@param instances table[]
function M:spawn_level_entity(instances)
	self.level_entity = decore.create({ child_instancies = instances })
	self.world:addEntity(self.level_entity)

	log:info("Created level entity", { entities = #instances })
end


---@param world_x number
---@param world_y number
---@return number, number
function M:get_ij(world_x, world_y)
	return detiled.pos_to_cell(world_x, world_y, self.map_params)
end


---@param i number
---@param j number
---@return number, number
function M:get_xy(i, j)
	return detiled.cell_to_pos(i, j, self.map_params)
end


return M
