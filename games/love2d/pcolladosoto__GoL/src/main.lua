SCREEN_HEIGHT = 600
SCREEN_WIDTH = 1000

GRID_X_DIM = 100
GRID_Y_DIM = 60

X_STEP = SCREEN_WIDTH / GRID_X_DIM
Y_STEP = SCREEN_HEIGHT / GRID_Y_DIM

STEP_TIME = 0.25

DBG = false

function draw_grid()
    love.graphics.setColor(1, 1, 0, 1)
    for i = 0, GRID_X_DIM, 1 do
        love.graphics.line(i * X_STEP, 0, i * X_STEP, SCREEN_HEIGHT)
    end
    for i = 0, GRID_Y_DIM, 1 do
        love.graphics.line(0, i * Y_STEP, SCREEN_WIDTH, i * Y_STEP)
    end
end

function draw_cells()
    love.graphics.setColor(1, 0, 1, 1)
    for i, row in ipairs(cells) do
        for j, state in ipairs(row) do
            if state == 1 then
                love.graphics.circle("fill", X_STEP * ((j - 1) + 0.5), Y_STEP * ((i - 1) + 0.5), X_STEP / 4)
            end
        end
    end
end

function print_grid(grid)
    for i, row in ipairs(grid) do
        io.write(string.format("\t"))
        for j, col in ipairs(row) do
            io.write(string.format("%d ", col))
        end
        io.write(string.format("\n"))
    end
    io.write(string.format("\n"))
end

function print_checks(x, y, idxs)
    io.write(string.format("Neighbours to check for (%d, %d): ", x, y))
    for a, b in ipairs(idxs) do
        io.write(string.format("{%2d, %2d} ", b[1], b[2]))
    end
    io.write(string.format("\n"))
end

function update_state()
    local cpy = table_copy(cells)
    for i, row in ipairs(cells) do
        for j, col in ipairs(row) do
            cpy[i][j] = update_cell(i, j, col)
        end
    end

    cells = table_copy(cpy)

    if DBG then print_grid(cells) end
end

function update_cell(i, j, state)
    local n_neighbours = 0
    local neigh_indices = {}
    if i == 1 then
        -- Top-left corner
        if j == 1 then
            neigh_indices = {{i, 2}, {i + 1, 1}, {i + 1, 2}}
        -- Top-right corner
        elseif j == GRID_X_DIM then
            neigh_indices = {{i, GRID_X_DIM - 1}, {i + 1, GRID_X_DIM}, {i + 1, GRID_X_DIM - 1}}
        -- Top row
        else
            neigh_indices = {{i, j - 1}, {i, j + 1}, {i + 1, j - 1}, {i + 1, j}, {i + 1, j + 1}}
        end
    elseif i == GRID_Y_DIM then
        -- Bottom-left corner
        if j == 1 then
            neigh_indices = {{i - 1, 1}, {i, 2}, {i - 1, 2}}
        -- Bottom-right corner
        elseif j == GRID_X_DIM then
            neigh_indices = {{i, GRID_X_DIM - 1}, {i - 1, GRID_X_DIM}, {i - 1, GRID_X_DIM - 1}}
        -- Bottom row
        else
            neigh_indices = {{i, j - 1}, {i, j + 1}, {i - 1, j - 1}, {i - 1, j}, {i - 1, j + 1}}
        end
    elseif j == 1 then
        -- Left column. The corners are taken care of above!
        neigh_indices = {{i - 1, j}, {i - 1, j + 1}, {i, j + 1}, {i + 1, j + 1}, {i + 1, j}}
    elseif j == GRID_X_DIM then
        -- Right column. The corners are taken care of above!
        neigh_indices = {{i - 1, j}, {i - 1, j - 1}, {i, j - 1}, {i + 1, j - 1}, {i + 1, j}}
    else
        neigh_indices = {
            {i - 1, j - 1},
            {i - 1, j},
            {i - 1, j + 1},
            {i, j - 1},
            {i, j + 1},
            {i + 1, j - 1},
            {i + 1, j},
            {i + 1, j + 1}
        }
    end

    -- print_checks(i, j, neigh_indices)

    for a, coords in ipairs(neigh_indices) do
        n_neighbours = n_neighbours + cells[coords[1]][coords[2]]
    end

    if state == 1 then
        if n_neighbours == 2 or n_neighbours == 3 then
            return 1
        end
        return 0
    elseif state == 0 then
        if n_neighbours == 3 then
            return 1
        end
        return 0
    end
end

function init_glider()
    cells[2][3] = 1
    cells[3][4] = 1
    cells[4][2] = 1
    cells[4][3] = 1
    cells[4][4] = 1
end

function table_copy(og)
    local ret = {}
    for i, row in ipairs(og) do
        table.insert(ret, {})
        for j, state in ipairs(row) do
            ret[i][j] = state
        end
    end
    return ret
end


function love.load(arg)
    love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)
    draw_grid()
    cells = {}
    for i = 1, GRID_Y_DIM, 1 do
        table.insert(cells, {})
        for j = 1, GRID_X_DIM, 1 do
            table.insert(cells[#cells], 0)
        end
    end
    init_glider()
    if DBG then print_grid(cells) end
    sleep_timer = 0
end

function love.update(dt)
    sleep_timer = sleep_timer + dt
    if sleep_timer >= STEP_TIME then
        update_state()
        sleep_timer = 0
    end
end

function love.draw()
    draw_grid()
    draw_cells()
end
