local const = require("system.field.field.const")
local field_entity = require("system.field.field.internal.field_entity")
local field_class = require("system.field.field.field")
local field_turn = require("system.field.field.field_turn_action")
local field_turn_result = require("system.field.field.field_turn_result")

return function()
	describe("Field Spawn Entity Resolver", function()
		local field ---@type field


		before(function()
			field = field_class.create()

			for i = 1, 6 do
				for j = 1, 6 do
					field:add_entity(field_entity.create(i, j, {
						z = 0,
					}))
				end
			end
		end)


		it("Should spawn entity at cell offset by side", function()
			local shooter = field:add_entity(field_entity.create(2, 2, {
				health = 10,
			}))

			local results = field:resolve_turn({
				field_turn.spawn_entity(shooter.entity_id, const.TURN_SIDE.RIGHT, {
					name = "projectile",
					movable = true,
					solid = false,
					health = 1,
					z = 0,
				}),
			})

			assert(#results == 1)
			assert(results[1].type == field_turn_result.TURN_RESULT_TYPE.SPAWN)
			assert(results[1].target_i == 3)
			assert(results[1].target_j == 2)
			assert(results[1].side == const.TURN_SIDE.RIGHT)
			assert(results[1].prefab_id == "projectile")
		end)


		it("Should spawn from prefab_id string with default field flags", function()
			local shooter = field:add_entity(field_entity.create(2, 2, {
				health = 10,
			}))

			local results = field:resolve_turn({
				field_turn.spawn_entity(shooter.entity_id, const.TURN_SIDE.RIGHT, "object_box"),
			})

			assert(#results == 1)
			assert(results[1].type == field_turn_result.TURN_RESULT_TYPE.SPAWN)
			assert(results[1].target_i == 3)
			assert(results[1].target_j == 2)
			assert(results[1].prefab_id == "object_box")

			local spawned = field:get_grid():get_entity(results[1].spawned_entity_id)
			assert(spawned ~= nil)
			assert(spawned.name == "object_box")
			assert(spawned.movable == true)
			assert(spawned.solid == false)
			assert(spawned.z == 0)
		end)


		it("Should run first sequence turn of spawned prefab in the same resolve_turn", function()
			local shooter = field:add_entity(field_entity.create(2, 2, {
				health = 10,
			}))

			local results = field:resolve_turn({
				field_turn.spawn_entity(shooter.entity_id, const.TURN_SIDE.RIGHT, "projectile_laser"),
			})

			assert(#results > 1)
			local spawn_count = 0
			for r = 1, #results do
				if results[r].type == field_turn_result.TURN_RESULT_TYPE.SPAWN then
					spawn_count = spawn_count + 1
				end
			end
			assert(spawn_count == 1)
		end)


		it("Should spawn on source cell when side is none", function()
			local shooter = field:add_entity(field_entity.create(2, 2, {
				health = 10,
			}))

			local results = field:resolve_turn({
				field_turn.spawn_entity(shooter.entity_id, const.TURN_SIDE.NONE, {
					name = "projectile",
					movable = true,
					solid = false,
					health = 1,
					z = 0,
				}),
			})

			assert(#results == 1)
			assert(results[1].type == field_turn_result.TURN_RESULT_TYPE.SPAWN)
			assert(results[1].target_i == 2)
			assert(results[1].target_j == 2)
			assert(results[1].side == const.TURN_SIDE.NONE)
			assert(results[1].prefab_id == "projectile")
		end)
	end)
end
