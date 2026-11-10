function love.load()
    love.window.setTitle("\"Minesweeper\"")
    love.window.setMode(600, 600)
    GAME_FONT = love.graphics.newFont(25)
    love.graphics.setFont(GAME_FONT)
    math.randomseed(os.time())
    DIFFICULTY = 1 -- 1 for easy, 2 for normal, 3 for hard
    -- Contains the sizes of the game, in tiles, for each difficulty
    GAME_SIZES = {
        [1] = 10,
        [2] = 15,
        [3] = 20
    }
    -- Contains the bomb count for each difficulty
    BOMB_NUMBERS = {
        [1] = 10,
        [2] = 40,
        [3] = 99
    }
    BOARD_SIZE = GAME_SIZES[DIFFICULTY]
    TILE_SIZE = 600/BOARD_SIZE

    game_ended = false
    level_generated = false
    -- Create the tilemap
    tiles = {}
    for column=0, BOARD_SIZE - 1 do
        for row=0, BOARD_SIZE - 1 do
            table.insert(tiles, {x = row, y = column, type = 0, has_bomb = false, num = -1}) -- A tile's type can be one of 3: 0 is not clicked, 1 is clicked, 2 is flagged
        end
    end
end

function love.update(dt)
    --print("X: " .. math.floor(love.mouse.getX()/TILE_SIZE))
    --print("Y: " .. math.floor(love.mouse.getY()/TILE_SIZE))
    --print("Button: " .. (math.floor(love.mouse.getX()/TILE_SIZE) + 1)+(math.floor(love.mouse.getY()/TILE_SIZE))*BOARD_SIZE)
    --print(tiles[1].type)
end

function love.draw()
    for i, tile in pairs(tiles) do
        -- Drawing the tile background
        if (tile.x + tile.y)%2 == 0 then
            love.graphics.setColor(3/255, 171/255, 9/255)
        else
            love.graphics.setColor(9/255, 224/255, 17/255)
        end
        if tile.type == 1 then
            -- Light orange for clicked tile
            love.graphics.setColor(214/255, 162/255, 73/255)
            -- Red background if bomb tile was clicked
            if tile.has_bomb then
                love.graphics.setColor(255/255, 0/255, 0/255)
                game_ended = true
            end
        end
        --if tile.num ~= -1 then
        --    love.graphics.setColor(214/255, 162/255, 73/255)
        --end

        love.graphics.rectangle("fill", tile.x*TILE_SIZE, tile.y*TILE_SIZE, TILE_SIZE, TILE_SIZE)
        
        if tile.type == 1 then
            if tile.has_bomb then
                love.graphics.setColor(255/255, 0/255, 0/255)
            end
            if tile.num > 0 then
                love.graphics.setColor(0, 0, 1)
                love.graphics.printf(tile.num, tile.x*TILE_SIZE, tile.y*TILE_SIZE+TILE_SIZE/4, TILE_SIZE,"center")
            end
        end

        -- Drawing the numbers/flags/mines on the tiles
        if tile.type == 2 then
            love.graphics.setColor(1, 0, 0)
            local triangle_vertices = {
                tile.x*TILE_SIZE + TILE_SIZE/5,
                tile.y*TILE_SIZE + TILE_SIZE/5,
                tile.x*TILE_SIZE + TILE_SIZE/1.25,
                tile.y*TILE_SIZE + TILE_SIZE/2,
                tile.x*TILE_SIZE + TILE_SIZE/5,
                tile.y*TILE_SIZE + TILE_SIZE/1.25
            }
            love.graphics.polygon("fill", triangle_vertices)
        end
        
        --[[
        if tile.num > 0 then
            love.graphics.setColor(0, 0, 1)
            love.graphics.printf(tile.num, tile.x*TILE_SIZE, tile.y*TILE_SIZE+TILE_SIZE/4, TILE_SIZE,"center")
        end
        ]]
    end
end

function love.mousereleased(x, y, button)
    -- Get the tile the button was released on
    local tile = (math.floor(love.mouse.getX()/TILE_SIZE) + 1)+(math.floor(love.mouse.getY()/TILE_SIZE))*BOARD_SIZE

    -- Generate level on first click
    if not level_generated then
        generateLevel(math.floor(love.mouse.getX()/TILE_SIZE), math.floor(love.mouse.getY()/TILE_SIZE))
        return nil
    end

    -- Normal click on button(checking for mine)
    if button == 1 then
        tiles[tile].type = 1

    -- Flag/unflag button
    elseif button == 2 and tiles[tile].type ~= 1 then
        if tiles[tile].type == 2 then
            tiles[tile].type = 0
        elseif tiles[tile].type == 0 then
            tiles[tile].type = 2
        end
    end
end

-- Generates a level, not placing a bomb on the desired coordinates
function generateLevel(x, y)
    -- Adding of the mines
    local added_bombs = BOMB_NUMBERS[DIFFICULTY]
    while added_bombs > 0 do
        -- Get a random tile number
        local tile = math.random(1, BOARD_SIZE^2)
        -- Ignore tile if it has a bomb or is in the coordinates we want to exclude
        if tiles[tile].has_bomb or (tiles[tile].x == x and tiles[tile].y == y) then
            goto continue
        else
            tiles[tile].has_bomb = true
        end
        added_bombs = added_bombs - 1
        ::continue::
    end

    -- Setting the number for each tile
    for i, tile in pairs(tiles) do
        if tile.has_bomb then
            goto continue
        end

        local tiles_to_check = {} -- Table that will contain the tiles around the tile were currently working with

        -- Long list of if-statements to add the correct tiles to the table for every case
        if i == 1 then -- Tile is in the top left corner
            table.insert(tiles_to_check, tiles[i+1])
            table.insert(tiles_to_check, tiles[i+BOARD_SIZE])
            table.insert(tiles_to_check, tiles[i+BOARD_SIZE+1])
        elseif i == BOARD_SIZE then -- Tile is in the top right corner
            table.insert(tiles_to_check, tiles[i-1])
            table.insert(tiles_to_check, tiles[i+BOARD_SIZE])
            table.insert(tiles_to_check, tiles[i+BOARD_SIZE-1])
        elseif i == BOARD_SIZE^2 then -- Tile is in the botton right corner
            table.insert(tiles_to_check, tiles[i-1])
            table.insert(tiles_to_check, tiles[i-BOARD_SIZE])
            table.insert(tiles_to_check, tiles[i-BOARD_SIZE-1])
        elseif i == (BOARD_SIZE^2) - BOARD_SIZE + 1 then -- Tile is in the botton left corner
            table.insert(tiles_to_check, tiles[i+1])
            table.insert(tiles_to_check, tiles[i-BOARD_SIZE])
            table.insert(tiles_to_check, tiles[i-BOARD_SIZE+1])
        elseif tile.y == 0 then -- Tile is in the first row
            table.insert(tiles_to_check, tiles[i-1])
            table.insert(tiles_to_check, tiles[i+1])
            table.insert(tiles_to_check, tiles[i+BOARD_SIZE])
            table.insert(tiles_to_check, tiles[i+BOARD_SIZE-1])
            table.insert(tiles_to_check, tiles[i+BOARD_SIZE+1])
        elseif tile.y == BOARD_SIZE - 1 then -- Tile is on the last row 
            table.insert(tiles_to_check, tiles[i+1])
            table.insert(tiles_to_check, tiles[i-BOARD_SIZE])
            table.insert(tiles_to_check, tiles[i-BOARD_SIZE+1])
            table.insert(tiles_to_check, tiles[i-BOARD_SIZE-1])
        elseif tile.x == 0 then -- Tile is on the first column
            table.insert(tiles_to_check, tiles[i-BOARD_SIZE])
            table.insert(tiles_to_check, tiles[i+BOARD_SIZE])
            table.insert(tiles_to_check, tiles[i+1])
            table.insert(tiles_to_check, tiles[i-BOARD_SIZE+1])
            table.insert(tiles_to_check, tiles[i+BOARD_SIZE+1])
        elseif tile.x == BOARD_SIZE - 1 then -- Tile is on the last column
            table.insert(tiles_to_check, tiles[i-BOARD_SIZE])
            table.insert(tiles_to_check, tiles[i+BOARD_SIZE])
            table.insert(tiles_to_check, tiles[i-1])
            table.insert(tiles_to_check, tiles[i-BOARD_SIZE-1])
            table.insert(tiles_to_check, tiles[i+BOARD_SIZE-1])
        else -- Tile is not on the borders of the world
            table.insert(tiles_to_check, tiles[i+1])
            table.insert(tiles_to_check, tiles[i-1])
            table.insert(tiles_to_check, tiles[i-BOARD_SIZE])
            table.insert(tiles_to_check, tiles[i+BOARD_SIZE])
            table.insert(tiles_to_check, tiles[i-BOARD_SIZE-1])
            table.insert(tiles_to_check, tiles[i-BOARD_SIZE+1])
            table.insert(tiles_to_check, tiles[i+BOARD_SIZE-1])
            table.insert(tiles_to_check, tiles[i+BOARD_SIZE+1])
        end

        -- Looping trough the adjacent tiles and set the number to our tile
        num_of_bombs = 0
        for j, _tile in pairs(tiles_to_check) do
            if _tile.has_bomb then
                num_of_bombs = num_of_bombs + 1
            end
        end
        tile.num = num_of_bombs
        print(i, tile.num)

        ::continue::
    end
    level_generated = true
end

-- Returns the tile by number(equivalent to tiles[number], so function goes unused)
function getTile(number)
    for i, tile in pairs(tiles) do
        if number == i then
            return tile
        end
    end
    return 1 -- Return the top left tile if an invalid number is inputted
end

