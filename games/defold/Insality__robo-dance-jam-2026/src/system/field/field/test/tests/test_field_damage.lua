local const = require("system.field.field.const")
local field_entity = require("system.field.field.internal.field_entity")
local field_class = require("system.field.field.field")
local field_turn = require("system.field.field.field_turn_action")
local field_turn_result = require("system.field.field.field_turn_result")

return function()
	describe("Field Damage Resolver", function()
		local field ---@type field


		before(function()
			field = field_class.create()

			for i = 1, 4 do
				for j = 1, 4 do
					field:add_entity(field_entity.create(i, j, {
						z = 0,
					}))
				end
			end
		end)


		it("Should damage adjacent entity with health", function()
			local attacker = field:add_entity(field_entity.create(2, 2, {
				health = 100,
			}))
			local victim = field:add_entity(field_entity.create(2, 3, {
				health = 80,
			}))

			local results = field:resolve_turn({
				field_turn.damage(attacker.entity_id, 25, const.TURN_SIDE.UP),
			})

			assert(#results == 2)
			assert(results[1].type == field_turn_result.TURN_RESULT_TYPE.ATTACK_CELL)
			assert(results[1].entity_id == attacker.entity_id)
			assert(results[1].target_i == 2)
			assert(results[1].target_j == 3)
			assert(results[1].side == const.TURN_SIDE.UP)
			assert(results[1].damage == 25)
			assert(results[2].type == field_turn_result.TURN_RESULT_TYPE.DAMAGE)
			assert(results[2].entity_id == victim.entity_id)
			assert(results[2].target_i == 2)
			assert(results[2].target_j == 3)
			assert(results[2].side == const.TURN_SIDE.UP)
			assert(results[2].damage == 25)
			assert(victim.health == 55)
			assert(attacker.health == 100)
		end)


		it("Should skip targets with zero health", function()
			local attacker = field:add_entity(field_entity.create(2, 2, {
				health = 10,
			}))
			field:add_entity(field_entity.create(3, 2, {
				health = 0,
				solid = true,
			}))

			local results = field:resolve_turn({
				field_turn.damage(attacker.entity_id, 5, const.TURN_SIDE.RIGHT),
			})

			assert(#results == 1)
			assert(results[1].type == field_turn_result.TURN_RESULT_TYPE.ATTACK_CELL)
			assert(results[1].entity_id == attacker.entity_id)
			assert(results[1].target_i == 3)
			assert(results[1].target_j == 2)
			assert(results[1].damage == 5)
		end)


		it("Should hit own cell with NONE and damage all with health including self", function()
			local a = field:add_entity(field_entity.create(2, 2, {
				health = 50,
			}))
			local b = field:add_entity(field_entity.create(2, 2, {
				health = 40,
			}))

			local results = field:resolve_turn({
				field_turn.damage(a.entity_id, 10, const.TURN_SIDE.NONE),
			})

			assert(#results == 3)
			assert(a.health == 40)
			assert(b.health == 30)
			assert(results[1].type == field_turn_result.TURN_RESULT_TYPE.ATTACK_CELL)
			assert(results[1].entity_id == a.entity_id)
			assert(results[1].target_i == 2)
			assert(results[1].target_j == 2)
			assert(results[1].side == const.TURN_SIDE.NONE)
			assert(results[1].damage == 10)
			local hit_ids = {
				[results[2].entity_id] = true,
				[results[3].entity_id] = true,
			}
			assert(hit_ids[a.entity_id] and hit_ids[b.entity_id])
			assert(results[2].type == field_turn_result.TURN_RESULT_TYPE.DAMAGE)
			assert(results[3].type == field_turn_result.TURN_RESULT_TYPE.DAMAGE)
			for index = 2, #results do
				assert(results[index].target_i == 2)
				assert(results[index].target_j == 2)
				assert(results[index].side == const.TURN_SIDE.NONE)
				assert(results[index].damage == 10)
			end
		end)


		it("Should treat nil turn_side as own cell", function()
			local attacker = field:add_entity(field_entity.create(2, 2, {
				health = 20,
			}))

			local results = field:resolve_turn({
				{
					entity_id = attacker.entity_id,
					turn_step = const.TURN_STEPS.ATTACK,
					turn_action = const.TURN_ACTIONS.ATTACK,
					turn_params = {
						damage = 7,
					},
				},
			})

			assert(#results == 2)
			assert(results[1].type == field_turn_result.TURN_RESULT_TYPE.ATTACK_CELL)
			assert(results[1].entity_id == attacker.entity_id)
			assert(results[1].damage == 7)
			assert(results[2].type == field_turn_result.TURN_RESULT_TYPE.DAMAGE)
			assert(results[2].entity_id == attacker.entity_id)
			assert(results[2].damage == 7)
			assert(attacker.health == 13)
		end)


		it("Should produce no damage when attacker is missing from grid", function()
			local results = field:resolve_turn({
				field_turn.damage("nonexistent_id", 10, const.TURN_SIDE.UP),
			})

			assert(#results == 0)
		end)


		it("Should append damage after move in same turn", function()
			local mover = field:add_entity(field_entity.create(2, 2, {
				movable = true,
				health = 100,
			}))
			local prey = field:add_entity(field_entity.create(4, 2, {
				health = 60,
			}))

			local results = field:resolve_turn({
				field_turn.move(mover.entity_id, 1, const.TURN_SIDE.RIGHT),
				field_turn.damage(mover.entity_id, 15, const.TURN_SIDE.RIGHT),
			})

			assert(#results == 3)
			assert(results[1].type == "move")
			assert(results[2].type == field_turn_result.TURN_RESULT_TYPE.ATTACK_CELL)
			assert(results[2].entity_id == mover.entity_id)
			assert(results[2].damage == 15)
			assert(results[3].type == field_turn_result.TURN_RESULT_TYPE.DAMAGE)
			assert(results[3].entity_id == prey.entity_id)
			assert(results[3].damage == 15)
			assert(prey.health == 45)
		end)


		it("Should knockback movable victim one cell in attack direction by explicit action", function()
			local attacker = field:add_entity(field_entity.create(2, 2, {
				health = 100,
			}))
			local victim = field:add_entity(field_entity.create(2, 3, {
				health = 80,
				movable = true,
				z = 1,
				height = 1,
			}))

			local results = field:resolve_turn({
				field_turn.damage(attacker.entity_id, 10, const.TURN_SIDE.UP),
				field_turn.knockback_attack(attacker.entity_id, 1, const.TURN_SIDE.UP),
			})

			assert(#results == 3)
			assert(results[2].type == field_turn_result.TURN_RESULT_TYPE.DAMAGE)
			assert(results[3].type == field_turn_result.TURN_RESULT_TYPE.KNOCKBACK_MOVE)
			assert(results[3].entity_id == victim.entity_id)
			assert(results[3].side == const.TURN_SIDE.UP)
			assert(results[3].target_i == 2)
			assert(results[3].target_j == 4)
			assert(victim.i == 2 and victim.j == 4)
		end)


		it("Should emit kill result with full payload for lethal damage", function()
			local attacker = field:add_entity(field_entity.create(2, 2, {
				health = 10,
			}))
			local victim = field:add_entity(field_entity.create(2, 3, {
				health = 5,
			}))

			local results = field:resolve_turn({
				field_turn.damage(attacker.entity_id, 10, const.TURN_SIDE.UP),
			})

			assert(#results == 3)
			assert(results[3].type == field_turn_result.TURN_RESULT_TYPE.DIE)
			assert(results[3].entity_id == victim.entity_id)
			assert(results[3].source_entity_id == attacker.entity_id)
			assert(results[3].target_i == 2)
			assert(results[3].target_j == 3)
			assert(results[3].side == const.TURN_SIDE.UP)
		end)


		it("Should self-damage non-solid with damage_on_collide when overlapping solid", function()
			local proj = field:add_entity(field_entity.create(2, 2, {
				solid = false,
				z = 1.5,
				health = 50,
				damage_on_collide = 100,
			}))
			field:add_entity(field_entity.create(2, 2, {
				solid = true,
				z = 1,
				height = 1,
			}))

			local results = field:resolve_turn({})

			local has_damage = false
			local has_die = false
			for _, r in ipairs(results) do
				if r.type == field_turn_result.TURN_RESULT_TYPE.DAMAGE and r.entity_id == proj.entity_id then
					has_damage = true
				end
				if r.type == field_turn_result.TURN_RESULT_TYPE.DIE and r.entity_id == proj.entity_id then
					has_die = true
				end
			end

			assert(has_damage)
			assert(has_die)
			assert(proj.health <= 0)
		end)


		it("Should not self damage attacker by default", function()
			local projectile = field:add_entity(field_entity.create(2, 2, {
				health = 1,
			}))
			local victim = field:add_entity(field_entity.create(2, 3, {
				health = 3,
			}))

			local results = field:resolve_turn({
				field_turn.damage(projectile.entity_id, 1, const.TURN_SIDE.UP),
			})

			assert(#results == 2)
			assert(results[1].type == field_turn_result.TURN_RESULT_TYPE.ATTACK_CELL)
			assert(results[2].type == field_turn_result.TURN_RESULT_TYPE.DAMAGE)
			assert(results[2].entity_id == victim.entity_id)
			assert(projectile.health == 1)
			assert(victim.health == 2)
		end)


		it("Should apply support damage without knockback", function()
			local projectile = field:add_entity(field_entity.create(2, 2, {
				health = 3,
			}))
			local victim = field:add_entity(field_entity.create(2, 2, {
				health = 2,
				movable = true,
			}))

			local results = field:resolve_turn({
				field_turn.support_damage(projectile.entity_id, 1, const.TURN_SIDE.NONE),
			})

			local has_attack_cell = false
			local has_damage = false
			local has_knockback = false
			for _, result in ipairs(results) do
				if result.type == field_turn_result.TURN_RESULT_TYPE.ATTACK_CELL and result.entity_id == projectile.entity_id then
					has_attack_cell = true
				end
				if result.type == field_turn_result.TURN_RESULT_TYPE.DAMAGE and result.entity_id == victim.entity_id then
					has_damage = true
				end
				if result.type == field_turn_result.TURN_RESULT_TYPE.KNOCKBACK_MOVE then
					has_knockback = true
				end
			end

			assert(has_attack_cell)
			assert(has_damage)
			assert(not has_knockback)
			assert(victim.health == 1)
		end)


		it("Should apply support knockback in support step", function()
			local projectile = field:add_entity(field_entity.create(2, 2, {
				health = 3,
			}))
			local victim = field:add_entity(field_entity.create(2, 2, {
				health = 2,
				movable = true,
			}))

			local results = field:resolve_turn({
				field_turn.support_knockback(projectile.entity_id, 1, const.TURN_SIDE.UP),
			})

			local has_knockback = false
			for _, result in ipairs(results) do
				if result.type == field_turn_result.TURN_RESULT_TYPE.KNOCKBACK_MOVE then
					has_knockback = true
					assert(result.entity_id == victim.entity_id)
					assert(result.side == const.TURN_SIDE.UP)
					assert(result.target_i == 2)
					assert(result.target_j == 3)
				end
			end

			assert(has_knockback)
			assert(victim.i == 2 and victim.j == 3)
		end)
	end)
end
