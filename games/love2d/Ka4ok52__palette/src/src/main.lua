-- Lua 5.4.6
-- Palette by Koti4
local love = require('love')
local shapes = {}
local colors = {
    {1, 0.3, 0.3},      -- Red
    {1, 0.6, 0.2},      -- Orange
    {1, 1, 0.3},        -- Yellow
    {0.3, 1, 0.3},      -- Green
    {0.2, 0.8, 0.8},    -- Cyan
    {0.3, 0.3, 1},      -- Blue
    {0.6, 0.3, 0.9},    -- Violette
    {1, 0.5, 0.7},      -- Pink
    {0.5, 0.3, 0.1},    -- Brown
    {0.15, 0.15, 0.15}, -- Dark-gray
    {0.6, 0.6, 0.6},    -- White-gray
    {1, 1, 1}           -- White
}
local selected_shape = "square"
local selected_color = colors[1]
local panel_height = 80
local cell_size = 40

function love.load()
    -- code here
end

function love.mousepressed(x, y, button)
    local screen_height = love.graphics.getHeight()
    local canvas_limit = screen_height - panel_height

    if button == 1 then
        if y < canvas_limit then
            local col = math.floor(x / cell_size)
            local row = math.floor(y / cell_size)
            local key = col .. "_" .. row

            if selected_shape == "square" then
                local new_shape = {
                    type = selected_shape,
                    col = col,
                    row = row,
                    color = selected_color
                }
                shapes[key] = new_shape
            elseif selected_shape == "eraser" then
                shapes[key] = nil
            end
        else
            for i, color in ipairs(colors) do
                local row_idx = math.floor((i - 1) / 6)
                local col_idx = (i - 1) % 6

                local btn_x = 20 + col_idx * 35
                local btn_y = (canvas_limit + 12) + row_idx * 32

                if x >= btn_x and x <= btn_x + 25 and y >= btn_y and y <= btn_y + 25 then
                    selected_color = color
                    selected_shape = "square" 
                end
            end

            local shape_y = canvas_limit + 15
            if x >= 300 and x <= 350 and y >= shape_y and y <= shape_y + 50 then
                selected_shape = "square"
            end
            if x >= 380 and x <= 430 and y >= shape_y and y <= shape_y + 50 then
                selected_shape = "eraser"
            end
        end

    elseif button == 2 and y < canvas_limit then
        local col = math.floor(x / cell_size)
        local row = math.floor(y / cell_size)
        shapes[col .. "_" .. row] = nil
    end
end

function love.draw()
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()
    local canvas_limit = screen_height - panel_height

    love.graphics.clear(0.09, 0.09, 0.09)
    for _, shape in pairs(shapes) do
        love.graphics.setColor(shape.color)

        local x = shape.col * cell_size
        local y = shape.row * cell_size

        love.graphics.rectangle("fill", x, y, cell_size, cell_size)
    end

    local mx, my = love.mouse.getPosition()
    if my < canvas_limit then
        local m_col = math.floor(mx / cell_size)
        local m_row = math.floor(my / cell_size)

        if selected_shape == "eraser" then
            love.graphics.setColor(1, 0.2, 0.2, 0.4)
        else
            love.graphics.setColor(1, 1, 1, 0.15)
        end
        love.graphics.rectangle("line", m_col * cell_size, m_row * cell_size, cell_size, cell_size)
    end

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, canvas_limit, screen_width, panel_height)

    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.line(0, canvas_limit, screen_width, canvas_limit)

    for i, color in ipairs(colors) do
        local row_idx = math.floor((i - 1) / 6)
        local col_idx = (i - 1) % 6

        local btn_x = 20 + col_idx * 35
        local btn_y = (canvas_limit + 12) + row_idx * 32

        love.graphics.setColor(color)
        love.graphics.rectangle("fill", btn_x, btn_y, 25, 25)

        if color == selected_color and selected_shape == "square" then
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", btn_x - 2, btn_y - 2, 29, 29)
        end
    end

    local shape_y = canvas_limit + 15

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("fill", 300, shape_y, 50, 50)
    if selected_shape == "square" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 298, shape_y - 2, 54, 54)
    end

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("line", 380, shape_y, 50, 50)
    love.graphics.line(385, shape_y + 45, 425, shape_y + 5) 
    if selected_shape == "eraser" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 378, shape_y - 2, 54, 54)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LCM: Action. RCM: Quick Erase. R: Reset. Q: Quit", 510, canvas_limit + 32)
end

function love.keypressed(key)
    if key == "r" then
        shapes = {}
    elseif key == "q" then
        love.event.quit()
    end
end
