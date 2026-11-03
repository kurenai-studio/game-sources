local M = {}


---@class field.entity
---@field entity_id string Entity id
---@field name string Entity name, mostly for debugging
---@field i integer Grid position X
---@field j integer Grid position Y
---@field z integer Grid position Z
---@field height integer Grid height
---@field movable boolean Is can move
---@field pushable boolean Is can be pushed by another mover
---@field health number|nil Current health
---@field remove_on_death boolean Remove from field on death in support step
---@field solid boolean Is can move through
---@field flying boolean Is entity flying
---@field damage_on_collide number|nil Self-damage when overlapping a solid (non-solids); nil = off
---@field last_move_side string Last successful move direction ("none" if none)

local UID = 1000000

---@param i integer
---@param j integer
---@param config table?
---@return field.entity
function M.create(i, j, config)
	UID = UID + 1

	config = config or {}

	if config.last_move_side == "" then
		config.last_move_side = nil
	end

	return setmetatable({
		entity_id = config.entity_id or UID,
		name = config.name or "",
		i = i,
		j = j,
		z = config.z or 1,
		height = config.height or 1,
		movable = config.movable or false,
		pushable = config.pushable == true,
		health = config.health,
		remove_on_death = config.remove_on_death == true,
		solid = config.solid == nil and true or config.solid,
		flying = config.flying or false,
		damage_on_collide = config.damage_on_collide,
		last_move_side = config.last_move_side or "none",
	}, { __index = M })
end


---@param entity_id string
---@return field.entity
function M:set_entity_id(entity_id)
	self.entity_id = entity_id
	return self
end


---@param z number
---@return field.entity
function M:set_z(z)
	self.z = z
	return self
end


---@param height number
---@return field.entity
function M:set_height(height)
	self.height = height
	return self
end


---@param movable boolean
---@return field.entity
function M:set_movable(movable)
	self.movable = movable
	return self
end


---@param health number
---@return field.entity
function M:set_health(health)
	self.health = health
	return self
end


---@param solid boolean
---@return field.entity
function M:set_solid(solid)
	self.solid = solid
	return self
end


---@param flying boolean
---@return field.entity
function M:set_flying(flying)
	self.flying = flying
	return self
end


return M
