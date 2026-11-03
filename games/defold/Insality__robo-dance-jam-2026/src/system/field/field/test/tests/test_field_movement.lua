local field_entity = require("system.field.field.internal.field_entity")
local field_class = require("system.field.field.field")
local field_turn = require("system.field.field.field_turn_action")
return function()
	describe("Field Movement", function()
		local field ---@type field
		local player ---@type field.entity

		before(function()
			field = field_class.create()

			-- Floors
			for i = 1, 4 do
				for j = 1, 4 do
					local entity = field_entity.create(i, j, {
						z = 0,
					})
					field:add_entity(entity)
				end
			end

			-- Player
			player = field:add_entity(field_entity.create(2, 2, {
				movable = true
			}))

			-- Wall
			field:add_entity(field_entity.create(3, 2, {
				solid = true,
			}))

			-- x x x x
			-- x x x x
			-- x P W x
			-- x x x x
		end)

		it("Should move to free cell", function()
			-- Move from 2, 2 to 2, 3
			local result_actions = field:resolve_turn({
				field_turn.move(player.entity_id, 1, "up"),
			})

			assert(#result_actions == 1)
			assert(result_actions[1].entity_id == player.entity_id)
			assert(result_actions[1].target_i == 2)
			assert(result_actions[1].target_j == 3)
			assert(result_actions[1].side == "up")
			assert(result_actions[1].type == "move")
		end)

		it("Should move blocked by wall", function()
			-- Move from 2, 2 to 3, 2
			local result_actions = field:resolve_turn({
				field_turn.move(player.entity_id, 1, "right"),
			})

			assert(#result_actions == 1)
			assert(result_actions[1].entity_id == player.entity_id)
			assert(result_actions[1].target_i == 2)
			assert(result_actions[1].target_j == 2)
			assert(result_actions[1].side == "right")
			assert(result_actions[1].type == "move_blocked")
		end)

		it("Should teleport over blocking cell", function()
			local result_actions = field:resolve_turn({
				field_turn.teleport(player.entity_id, 2, "right"),
			})

			assert(#result_actions == 1)
			assert(result_actions[1].entity_id == player.entity_id)
			assert(result_actions[1].target_i == 4)
			assert(result_actions[1].target_j == 2)
			assert(result_actions[1].side == "right")
			assert(result_actions[1].type == "move")
		end)

		it("Should being blocked by movement in the same cell", function()
			local player2 = field:add_entity(field_entity.create(4, 2, {
				movable = true
			}))


			local result_actions = field:resolve_turn({
				field_turn.move(player.entity_id, 1, "right"),
				field_turn.move(player2.entity_id, 1, "left"),
			})

			assert(#result_actions == 2)
		end)

		it("Should being blocked by movement to the empty cell", function()
			local entity = field:get_grid():get_entities_at(3, 2)[1]
			field:remove_entity(entity)

			local result_actions = field:resolve_turn({
				field_turn.move(player.entity_id, 1, "right"),
			})

			assert(#result_actions == 1)
			assert(result_actions[1].entity_id == player.entity_id)
			assert(result_actions[1].target_i == 2)
			assert(result_actions[1].target_j == 2)
			assert(result_actions[1].side == "right")
			assert(result_actions[1].type == "move_blocked")
		end)

		it("Should be good to move one character into another in a row", function()
			local player_down = field:add_entity(field_entity.create(2, 1, {
				movable = true
			}))
			local player_top = field:add_entity(field_entity.create(2, 3, {
				movable = true
			}))

			local result_actions = field:resolve_turn({
				field_turn.move(player_down.entity_id, 1, "up"),
				field_turn.move(player.entity_id, 1, "up"),
				field_turn.move(player_top.entity_id, 1, "up"),
			})

			assert(#result_actions == 3)

			local result_by_entity_id = {}
			for _, result_action in ipairs(result_actions) do
				result_by_entity_id[result_action.entity_id] = result_action
			end

			assert(result_by_entity_id[player_down.entity_id].type == "move")
			assert(result_by_entity_id[player_down.entity_id].target_i == 2)
			assert(result_by_entity_id[player_down.entity_id].target_j == 2)

			assert(result_by_entity_id[player.entity_id].type == "move")
			assert(result_by_entity_id[player.entity_id].target_i == 2)
			assert(result_by_entity_id[player.entity_id].target_j == 3)

			assert(result_by_entity_id[player_top.entity_id].type == "move")
			assert(result_by_entity_id[player_top.entity_id].target_i == 2)
			assert(result_by_entity_id[player_top.entity_id].target_j == 4)
		end)

		it("Should be good to move one character into another in a row v2", function()
			local player_down = field:add_entity(field_entity.create(2, 1, {
				movable = true
			}))
			local player_top = field:add_entity(field_entity.create(2, 3, {
				movable = true
			}))

			field:add_entity(field_entity.create(3, 3))

			local result_actions = field:resolve_turn({
				field_turn.move(player_down.entity_id, 1, "up"),
				field_turn.move(player.entity_id, 1, "up"),
				field_turn.move(player_top.entity_id, 1, "right"),
			})

			assert(#result_actions == 3)

			local result_by_entity_id = {}
			for _, result_action in ipairs(result_actions) do
				result_by_entity_id[result_action.entity_id] = result_action
			end

			assert(result_by_entity_id[player_down.entity_id].type == "move_blocked")
			assert(result_by_entity_id[player_down.entity_id].target_i == 2)
			assert(result_by_entity_id[player_down.entity_id].target_j == 1)

			assert(result_by_entity_id[player.entity_id].type == "move_blocked")
			assert(result_by_entity_id[player.entity_id].target_i == 2)
			assert(result_by_entity_id[player.entity_id].target_j == 2)

			assert(result_by_entity_id[player_top.entity_id].type == "move_blocked")
			assert(result_by_entity_id[player_top.entity_id].target_i == 2)
			assert(result_by_entity_id[player_top.entity_id].target_j == 3)
		end)

		it("Should be resolve with different move distance", function()
			-- x x x x
			-- x x S x
			-- x P W x
			-- x x x x

			local player_speed = field:add_entity(field_entity.create(3, 3, {
				movable = true
			}))

			local result_actions = field:resolve_turn({
				field_turn.move(player_speed.entity_id, 2, "left"),
				field_turn.move(player.entity_id, 1, "up"),
			})

			local result_by_entity_id = {}
			for _, result_action in ipairs(result_actions) do
				result_by_entity_id[result_action.entity_id] = result_action
			end

			assert(result_by_entity_id[player_speed.entity_id].type == "move_blocked")
			assert(result_by_entity_id[player_speed.entity_id].target_i == 3)
			assert(result_by_entity_id[player_speed.entity_id].target_j == 3)
			assert(result_by_entity_id[player_speed.entity_id].side == "left")

			assert(result_by_entity_id[player.entity_id].type == "move_blocked")
			assert(result_by_entity_id[player.entity_id].target_i == 2)
			assert(result_by_entity_id[player.entity_id].target_j == 2)
			assert(result_by_entity_id[player.entity_id].side == "up")
		end)

		it("Should be resolve with different move distance v2", function()
			-- x x x x
			-- x x x S
			-- x P W x
			-- x x x x

			local player_speed = field:add_entity(field_entity.create(4, 3, {
				movable = true
			}))

			local result_actions = field:resolve_turn({
				field_turn.move(player_speed.entity_id, 2, "left"),
				field_turn.move(player.entity_id, 1, "up"),
			})

			local result_by_entity_id = {}
			for _, result_action in ipairs(result_actions) do
				result_by_entity_id[result_action.entity_id] = result_action
			end

			assert(result_by_entity_id[player_speed.entity_id].type == "move_blocked")
			assert(result_by_entity_id[player_speed.entity_id].target_i == 3)
			assert(result_by_entity_id[player_speed.entity_id].target_j == 3)
			assert(result_by_entity_id[player_speed.entity_id].side == "left")

			assert(result_by_entity_id[player.entity_id].type == "move")
			assert(result_by_entity_id[player.entity_id].target_i == 2)
			assert(result_by_entity_id[player.entity_id].target_j == 3)
			assert(result_by_entity_id[player.entity_id].side == "up")
		end)


		it("Should move projectile full distance after solids (non-solid phase)", function()
			local field2 = field_class.create()
			for i = 1, 4 do
				for j = 1, 4 do
					field2:add_entity(field_entity.create(i, j, {
						z = 0,
					}))
				end
			end

			local follower = field2:add_entity(field_entity.create(1, 2, {
				movable = true,
				solid = true,
			}))
			local projectile = field2:add_entity(field_entity.create(2, 2, {
				movable = true,
				solid = false,
			}))

			local result_actions = field2:resolve_turn({
				field_turn.move(follower.entity_id, 1, "right"),
				field_turn.move(projectile.entity_id, 2, "right"),
			})

			local by_id = {}
			for _, r in ipairs(result_actions) do
				by_id[r.entity_id] = r
			end

			assert(by_id[follower.entity_id].type == "move")
			assert(by_id[follower.entity_id].target_i == 2)
			assert(by_id[follower.entity_id].target_j == 2)

			assert(by_id[projectile.entity_id].type == "move")
			assert(by_id[projectile.entity_id].target_i == 4)
			assert(by_id[projectile.entity_id].target_j == 2)
		end)


		it("Flying non-solid slides across cells without floor", function()
			local field2 = field_class.create()
			field2:add_entity(field_entity.create(1, 1, {
				z = 0,
			}))
			field2:add_entity(field_entity.create(3, 1, {
				z = 0,
			}))
			local proj = field2:add_entity(field_entity.create(1, 1, {
				movable = true,
				solid = false,
				flying = true,
				z = 1.5,
			}))

			local result_actions = field2:resolve_turn({
				field_turn.move(proj.entity_id, 2, "right"),
			})

			assert(#result_actions == 1)
			assert(result_actions[1].type == "move")
			assert(result_actions[1].target_i == 3)
			assert(result_actions[1].target_j == 1)
		end)


		it("Should hold non-solid on mutual swap with solid (no pass-through)", function()
			local field2 = field_class.create()
			for i = 1, 4 do
				for j = 1, 4 do
					field2:add_entity(field_entity.create(i, j, {
						z = 0,
					}))
				end
			end

			local hero = field2:add_entity(field_entity.create(2, 2, {
				movable = true,
				solid = true,
			}))
			local projectile = field2:add_entity(field_entity.create(3, 2, {
				movable = true,
				solid = false,
			}))

			local result_actions = field2:resolve_turn({
				field_turn.move(hero.entity_id, 1, "right"),
				field_turn.move(projectile.entity_id, 1, "left"),
			})

			local by_id = {}
			for _, r in ipairs(result_actions) do
				by_id[r.entity_id] = r
			end

			assert(by_id[hero.entity_id].type == "move")
			assert(by_id[hero.entity_id].target_i == 3)
			assert(by_id[hero.entity_id].target_j == 2)

			assert(by_id[projectile.entity_id].type == "move_blocked")
			assert(by_id[projectile.entity_id].target_i == 3)
			assert(by_id[projectile.entity_id].target_j == 2)

			local g = field2:get_grid()
			local at_cell = g:get_entities_at(3, 2)
			local has_hero = false
			local has_proj = false
			for _, e in ipairs(at_cell) do
				if e.entity_id == hero.entity_id then
					has_hero = true
				end
				if e.entity_id == projectile.entity_id then
					has_proj = true
				end
			end
			assert(has_hero)
			assert(has_proj)
		end)


		it("Should not hold non-solid swap when solid cannot enter projectile cell", function()
			local field2 = field_class.create()
			for i = 1, 4 do
				for j = 1, 4 do
					field2:add_entity(field_entity.create(i, j, {
						z = 0,
					}))
				end
			end

			field2:add_entity(field_entity.create(3, 2, {
				solid = true,
				movable = false,
			}))
			local hero = field2:add_entity(field_entity.create(2, 2, {
				movable = true,
				solid = true,
			}))
			local projectile = field2:add_entity(field_entity.create(3, 2, {
				movable = true,
				solid = false,
				flying = true,
				z = 1.5,
			}))

			local result_actions = field2:resolve_turn({
				field_turn.move(hero.entity_id, 1, "right"),
				field_turn.move(projectile.entity_id, 1, "left"),
			})

			local by_id = {}
			for _, r in ipairs(result_actions) do
				by_id[r.entity_id] = r
			end

			assert(by_id[hero.entity_id].type == "move_blocked")
			assert(by_id[hero.entity_id].target_i == 2)
			assert(by_id[hero.entity_id].target_j == 2)

			assert(by_id[projectile.entity_id].type == "move")
			assert(by_id[projectile.entity_id].target_i == 2)
			assert(by_id[projectile.entity_id].target_j == 2)
		end)


		it("Should push movable solid target without explicit move action", function()
			local field2 = field_class.create()
			for i = 1, 5 do
				for j = 1, 3 do
					field2:add_entity(field_entity.create(i, j, {
						z = 0,
					}))
				end
			end

			local mover = field2:add_entity(field_entity.create(2, 2, {
				movable = true,
				solid = true,
			}))
			local box = field2:add_entity(field_entity.create(3, 2, {
				movable = true,
				solid = true,
				pushable = true,
			}))

			local result_actions = field2:resolve_turn({
				field_turn.move(mover.entity_id, 1, "right"),
			})

			local by_id = {}
			for _, result in ipairs(result_actions) do
				by_id[result.entity_id] = result
			end

			assert(by_id[mover.entity_id].type == "move")
			assert(by_id[mover.entity_id].target_i == 3)
			assert(by_id[mover.entity_id].target_j == 2)

			assert(by_id[box.entity_id].type == "move")
			assert(by_id[box.entity_id].target_i == 4)
			assert(by_id[box.entity_id].target_j == 2)
		end)


		it("Should block on movable solid target when it is not pushable", function()
			local field2 = field_class.create()
			for i = 1, 5 do
				for j = 1, 3 do
					field2:add_entity(field_entity.create(i, j, {
						z = 0,
					}))
				end
			end

			local mover = field2:add_entity(field_entity.create(2, 2, {
				movable = true,
				solid = true,
			}))
			local blocker = field2:add_entity(field_entity.create(3, 2, {
				movable = true,
				solid = true,
			}))

			local result_actions = field2:resolve_turn({
				field_turn.move(mover.entity_id, 1, "right"),
			})

			local by_id = {}
			for _, result in ipairs(result_actions) do
				by_id[result.entity_id] = result
			end

			assert(by_id[mover.entity_id].type == "move_blocked")
			assert(by_id[mover.entity_id].target_i == 2)
			assert(by_id[mover.entity_id].target_j == 2)
			assert(by_id[blocker.entity_id] == nil)
		end)


		it("Should pass set_state as result action", function()
			local result_actions = field:resolve_turn({
				field_turn.set_state(player.entity_id, {
					state = "charging",
					power = 2,
				}),
			})

			assert(#result_actions == 1)
			assert(result_actions[1].entity_id == player.entity_id)
			assert(result_actions[1].type == "set_state")
			assert(result_actions[1].state.state == "charging")
			assert(result_actions[1].state.power == 2)
		end)
	end)
end
