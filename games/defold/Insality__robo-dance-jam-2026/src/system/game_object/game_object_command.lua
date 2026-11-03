local M = {}


---@param game_object system.game_object
function M.register(game_object)
	M.game_object = game_object
end


---@param entity entity
function M.refresh_transform(entity)
	assert(entity.game_object, "Entity should have game_object component")
	assert(entity.transform, "Entity should have transform component")
	---@cast entity entity.game_object
	M.game_object:refresh_transform(entity)
end


---@param entity entity
---@param enabled boolean
function M.set_enabled(entity, enabled)
	assert(entity.game_object, "Entity has no game_object component")

	for _, game_object in pairs(entity.game_object.object) do
		if enabled then
			msg.post(game_object, "enable")
		else
			msg.post(game_object, "disable")
		end
	end
end


---@param entity entity
---@param object_id string
---@param enabled boolean
function M.set_object_enabled(entity, object_id, enabled)
	assert(entity.game_object, "Entity has no game_object component")
	assert(entity.game_object.object, "Entity has no object component")
	assert(entity.game_object.object[object_id], "Object not found")

	msg.post(entity.game_object.object[hash(object_id)], enabled and "enable" or "disable")
end


---@param id string|hash
---@return entity|nil
function M.get_entity(id)
	return M.game_object.root_to_entity[id]
end


return M
