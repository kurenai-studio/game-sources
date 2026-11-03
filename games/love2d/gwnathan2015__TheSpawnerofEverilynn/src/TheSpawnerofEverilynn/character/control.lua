local character_model = require('character.model')
local utils = require('utils')

local character_control = {}

function character_control.swordsman_choose_destination()
    return character_model.main_character:pos()
end

function character_control.move_swordsman(game_map)
    local swordsman_destination_pos = character_control.swordsman_choose_destination()
    local swordsman_current_pos = character_model.swordsman:pos()

    -- destination is x = 5, y = 3
    -- current is     x = 2, y = 9

    local difference_in_x = swordsman_destination_pos.x - swordsman_current_pos.x
    local step_in_x = utils.sign(difference_in_x)

    local difference_in_y = swordsman_destination_pos.y - swordsman_current_pos.y
    local step_in_y = utils.sign(difference_in_y)
    if game_state == 'ingame' then
         -- Only allows -1, 0, 1
        character_model.swordsman:move(game_map, step_in_x, step_in_y)
    end
end

function character_control.move_main_character(game_map, key)
    if key == "w" then
        character_model.main_character:move(game_map, 0, -1)
    elseif key == "a" then
        character_model.main_character:move(game_map, -1, 0)
    elseif key == "s" then
        character_model.main_character:move(game_map, 0, 1)
    elseif key == "d" then
        character_model.main_character:move(game_map, 1, 0)
    elseif key == "r" then 
        character_model.main_character:respawn()
    elseif key == "c" then
        character_model.main_character:add_coins(math.random(1, 10))
    end
end



return character_control