local world = require("game.world")

local M = {}


---@param level_manager system.level_manager
function M.register(level_manager)
	M.level_manager = level_manager
end


---@param entity entity
function M.add_entity_as_level_child(entity)
	local level_entity = M.level_manager.level_entity
	if not level_entity then
		world:addEntity(entity)
		return
	end

	entity.parent_id = level_entity.id
	world:addEntity(entity)

	if not level_entity.children_ids then
		level_entity.children_ids = {}
	end

	table.insert(level_entity.children_ids, entity.id)
	world:addEntity(level_entity)
end


---@param level_path string
function M.load_level(level_path)
	M.level_manager:load_level(level_path)
end


function M.unload_level()
	M.level_manager:unload_level()
end


---@param world_x number
---@param world_y number
---@return number, number
function M.get_ij(world_x, world_y)
	return M.level_manager:get_ij(world_x, world_y)
end


---@param i number
---@param j number
---@return number, number
function M.get_xy(i, j)
	return M.level_manager:get_xy(i, j)
end


return M
