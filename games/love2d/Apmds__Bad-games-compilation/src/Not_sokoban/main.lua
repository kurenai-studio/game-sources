function love.load()
    debug_mode = false
    fps = 0 
    love.window.setTitle("\"Sokoban\"")
    level_ended = false
    game_paused = false
    LEVELS = require("levels")
    -- Player data
    player = {}
    player.x = 0
    player.y = 0
    player.last_x = 0
    player.last_y = 0

    -- Level_data
    load_level(0)
end

function love.update(dt)
    -- Update fps
    fps = 1/dt

    -- Check for level completion(need to put inside movement function)
    local buttons_pressed = 0
    for i, button in pairs(buttons) do
        for j, box in pairs(boxes) do
            button[3] = false
            if button[1] == box[1] and button[2] == box[2] then
                button[3] = true
                break
            end
        end
        if button[3] then
            buttons_pressed = buttons_pressed + 1
        end
    end
    level_ended = buttons_pressed == #buttons
end

function love.draw()
    -- Box/button drawing
    love.graphics.setColor(0, 1, 0)
    for i, button in pairs(buttons) do
        love.graphics.rectangle("fill", button[1]*50, button[2]*50, 50, 50)
    end

    for i, box in pairs(boxes) do
        if box[4] == nil then
            love.graphics.setColor(23/255, 26/255, 46/255)
        else
            love.graphics.setColor(0, 0, 1)
        end
        love.graphics.rectangle("fill", box[1]*50, box[2]*50, 50, 50)
    end
    -- Player drawing
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", player.x*50, player.y*50, 50, 50)
    
    -- "Level complete menu"
    if level_ended then
        love.graphics.setColor(19/255, 163/255, 11/255)
        love.graphics.printf("GG", love.graphics.getWidth()/2, love.graphics.getHeight()/2, 20, "center")
    end
    -- Debug
    if debug_mode then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Player: " .. player.x .. ";" .. player.y, 0, 0)
        love.graphics.print("Player_last: " .. player.last_x .. ";" .. player.last_y, 0, 30)
        love.graphics.print("FPS: " .. fps, 0, 60)
        love.graphics.print("Paused: " .. tostring(game_paused), 0, 90)
        for i, button in pairs(buttons) do
            love.graphics.print("Button " .. i .. ": " .. tostring(button[3]), 0, 30*i + 90)
        end
        for i, box in pairs(boxes) do
            love.graphics.print("Box " .. i .. ": " .. tostring(box[3]) .. tostring(box[4]) .. tostring(box[5]) .. tostring(box[6]), 170, 30*i-30)
        end
    end
end

function love.keypressed(key)
    if not game_paused then
        if key == "w" and player.y - 1 >= 0 then
            local box = get_box(player.x, player.y - 1)
            if box[3] then
                player.last_x = player.x
                player.last_y = player.y
                player.y = player.y - 1
                update_boxes()
            end
        elseif key == "s" and player.y + 1 <= 11 then
            local box = get_box(player.x, player.y + 1)
            if box[4] then
                player.last_x = player.x
                player.last_y = player.y
                player.y = player.y + 1
                update_boxes()
            end
        elseif key == "a" and player.x - 1 >= 0 then
            local box = get_box(player.x - 1, player.y)
            if box[5] then
                player.last_x = player.x
                player.last_y = player.y
                player.x = player.x - 1
                update_boxes()
            end
        elseif key == "d" and player.x + 1 <= 15 then
            local box = get_box(player.x + 1, player.y)
            if box[6] then
                player.last_x = player.x
                player.last_y = player.y
                player.x = player.x + 1
                update_boxes()
            end
        end
    end
    if key == "k" then
        debug_mode = not debug_mode
    end
    if key == "p" then
        game_paused = not game_paused
    end
    
    -- Try to load the level
    load_level(tonumber(key))
end

-- Get box information at some coordinates
function get_box(x, y)
    for i, box in pairs(boxes) do
        if box[1] == x and box[2] == y then
            return box
        end
    end
    return {-100, -100, true, true, true, true}
end

-- Check if box exists at some coordinates
function check_box(x, y)
    for i, box in pairs(boxes) do
        if box[1] == x and box[2] == y then
            return true
        end
    end
    return false
end


function update_box(box, direction) -- 1 for up, 2 for down, 3 for left, 4 for right; DONT USE THIS
    direction = direction or 1
    print("update_box")
    if direction == 1 then
        print("up")
        print(check_box(box[1], box[2] - 1))
        if check_box(box[1], box[2] - 1) then
            print("box at up")
            return {box[1], box[2], false, box[4], box[5], box[6]}
        else
            return box
        end
    elseif direction == 2 then
        print("down")
        print(check_box(box[1], box[2] + 1))
        if check_box(box[1]-1, box[2] + 1) then
            print("box at down")
            return {box[1], box[2], box[3], false, box[5], box[6]}
        else
            return box
        end
    elseif direction == 3 then
        print("left")
        print(check_box(box[1] - 1, box[2]))
        if check_box(box[1] - 1, box[2]) then
            print("box at left")
            return {box[1], box[2], box[3], box[4], false, box[6]}
        else
            return box
        end
    elseif direction == 4 then
        print("right")
        print(check_box(box[1] + 1, box[2]))
        if check_box(box[1] + 1, box[2]) then
            print("box at right")
            return {box[1], box[2], box[3], box[4], box[5], false}
        else
            return box
        end
    end
end

-- Called to update the status of every box object
function update_boxes()
    for i, box in pairs(boxes) do
        -- Check if box is in same position as player and move it accordingly
        if box[1] == player.x and box[2] == player.y then
            if player.last_x == player.x - 1 and get_box(box[1]+1, box[2])[6] then -- Move right 
                box[1] = box[1] + 1
            elseif player.last_x == player.x + 1 and get_box(box[1]-1, box[2])[5] then -- Move left
                box[1] = box[1] - 1
            elseif player.last_y == player.y - 1 and get_box(box[1], box[2]+1)[4] then -- Move down
                box[2] = box[2] + 1
            elseif player.last_y == player.y + 1 and get_box(box[1], box[2]-1)[3] then -- Move up
                box[2] = box[2] - 1
            end
        end
        -- Update box status
        local box_up = check_box(box[1], box[2] - 1)
        local box_down = check_box(box[1], box[2] + 1)
        local box_left = check_box(box[1] - 1, box[2])
        local box_right = check_box(box[1] + 1, box[2])
        -- Check if box is unmovable on purpose
        if box[4] ~= nil then
            if box_up or box[2] == 0 then
                box[3] = false
            else
                box[3] = true
            end

            if box_down or box[2] == 11 then
                box[4] = false
            else
                box[4] = true
            end

            if box_left or box[1] == 0 then
                box[5] = false
            else
                box[5] = true
            end

            if box_right or box[1] == 15 then
                box[6] = false
            else
                box[6] = true
            end
        end
    end
end

-- Loads the desired level
function load_level(level_num)
    -- Dont load the level if the number doesn't match to an existing level
    if LEVELS[level_num] == nil then
        return
    end
    current_level = level_num
    lvs = deepcopy(LEVELS) -- Makes a copy of the levels table, so the original doesn't get changed

    level = lvs[current_level]
    buttons = level.buttons
    boxes = level.boxes
    player.x = level.player[1]
    player.y = level.player[2]
end

-- Copies a table(from http://lua-users.org/wiki/CopyTable)
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end