function love.load()
    love.window.setMode(600, 600)
    love.window.setTitle("Tic Tac Toe")
    debug_mode = false
    game_ended = false
    places = {
        {0, 0, false, -1},
        {1, 0, false, -1},
        {2, 0, false, -1},
        {0, 1, false, -1},
        {1, 1, false, -1},
        {2, 1, false, -1},
        {0, 2, false, -1},
        {1, 2, false, -1},
        {2, 2, false, -1},
    } -- {x, y, has_owner, owner}
    current_player = 1
    winning_player = -1
end

function love.update(dt)

end

function love.draw()
    for i, place in pairs(places) do
        if place[4] == 1 then
            love.graphics.setColor(1, 0, 0)
        elseif place[4] == 2 then
            love.graphics.setColor(0, 1, 0)
        else
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.rectangle("fill", place[1]*200, place[2]*200, 200, 200)
    end
    if game_ended then
        love.graphics.setColor(0, 0, 1)
        if current_player == 2 then
            love.graphics.print("Player 1 won!", 300, 300)
        elseif current_player == 1 then
            love.graphics.print("Player " .. winning_player .. " won!", 300, 300)
        end
    end
    if debug_mode then
        love.graphics.setColor(1, 1, 1)
        for i, place in pairs(places) do
            love.graphics.print(i .. ": ".. place[1] .. " " .. place[2] .. " " .. tostring(place[3]) .. " " .. place[4], 0, i*30-30)
        end
    end
end

function love.keypressed(key)
    if key == "k" then
        debug_mode = not debug_mode
    end
end

function love.mousepressed(x, y)
    local place
    if x < 200 then
        place = 1
    elseif x < 400 then
        place = 2
    elseif x < 600 then
        place = 3
    end
    if current_player == 1 then
        if y < 200 then
            place = place
        elseif y < 400 then
            place = place + 3
        elseif y < 600 then
            place = place + 6
        end
    else
        if y < 200 then
            place = place
        elseif y < 400 then
            place = place + 3
        elseif y < 600 then
            place = place + 6
        end
    end
    if not places[place][3] then
        places[place][3] = true
        places[place][4] = current_player
    end
    if not game_ended then
        if places[1][4] == places[2][4] and places[2][4] == places[3][4] and places[1][4] ~= -1 then
            game_ended = true
            winning_player = current_player
        end
        if places[4][4] == places[5][4] and places[5][4] == places[6][4] and places[4][4] ~= -1 then
            game_ended = true
            winning_player = current_player
        end
        if places[7][4] == places[8][4] and places[8][4] == places[9][4] and places[7][4] ~= -1 then
            game_ended = true
            winning_player = current_player
        end
        if places[1][4] == places[4][4] and places[4][4] == places[7][4] and places[1][4] ~= -1 then
            game_ended = true
            winning_player = current_player
        end
        if places[2][4] == places[5][4] and places[5][4] == places[8][4] and places[2][4] ~= -1 then
            game_ended = true
            winning_player = current_player
        end
        if places[3][4] == places[6][4] and places[6][4] == places[9][4] and places[3][4] ~= -1 then
            game_ended = true
            winning_player = current_player
        end
        if places[1][4] == places[5][4] and places[5][4] == places[9][4] and places[1][4] ~= -1 then
            game_ended = true
            winning_player = current_player
        end
        if places[3][4] == places[5][4] and places[5][4] == places[7][4] and places[3][4] ~= -1 then
            game_ended = true
            winning_player = current_player
        end
    end
    
    if current_player == 1 then
        current_player = 2
    else
        current_player = 1
    end
end

function get_place(x, y)
    for i, place in pairs(places) do
        if place[0] == x and place[1] == y then
            return place
        end
    end
end