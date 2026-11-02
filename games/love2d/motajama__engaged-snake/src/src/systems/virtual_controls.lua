local VirtualControls = {}
VirtualControls.__index = VirtualControls

function VirtualControls.new()
    return setmetatable({}, VirtualControls)
end

local function compute_bounds(buttons)
    local min_x, min_y = math.huge, math.huge
    local max_x, max_y = -math.huge, -math.huge

    for _, button in pairs(buttons) do
        min_x = math.min(min_x, button.x - button.radius)
        min_y = math.min(min_y, button.y - button.radius)
        max_x = math.max(max_x, button.x + button.radius)
        max_y = math.max(max_y, button.y + button.radius)
    end

    return {
        x = min_x,
        y = min_y,
        w = max_x - min_x,
        h = max_y - min_y,
    }
end

function VirtualControls:get_buttons(width, height, hud_height, layout)
    local radius = 18
    local side_margin = radius + 12
    local bottom_margin = radius + 12
    local spacing = radius * 2 + 12
    local top_limit = hud_height + radius + 6
    local base_y = height - bottom_margin
    local left_x = side_margin + radius
    local right_x = width - side_margin - radius
    local left_center = left_x + spacing
    local right_center = right_x - spacing

    if base_y < top_limit + spacing then
        base_y = top_limit + spacing
    end

    if layout == "left_handed" then
        return {
            up = { x = right_center, y = base_y - spacing, radius = radius, label = "^" },
            left = { x = right_center - spacing, y = base_y, radius = radius, label = "<" },
            down = { x = right_center, y = base_y, radius = radius, label = "v" },
            right = { x = right_center + spacing, y = base_y, radius = radius, label = ">" },
        }
    end

    if layout == "split" then
        return {
            up = { x = left_x + radius + 6, y = base_y - spacing, radius = radius, label = "^" },
            left = { x = left_x, y = base_y, radius = radius, label = "<" },
            right = { x = right_x, y = base_y - spacing, radius = radius, label = ">" },
            down = { x = right_x - spacing, y = base_y, radius = radius, label = "v" },
        }
    end

    return {
        up = { x = left_center, y = base_y - spacing, radius = radius, label = "^" },
        left = { x = left_center - spacing, y = base_y, radius = radius, label = "<" },
        down = { x = left_center, y = base_y, radius = radius, label = "v" },
        right = { x = left_center + spacing, y = base_y, radius = radius, label = ">" },
    }
end

function VirtualControls:get_bounds(width, height, hud_height, layout)
    return compute_bounds(self:get_buttons(width, height, hud_height, layout))
end

function VirtualControls:get_direction_at(x, y, width, height, hud_height, layout)
    for direction, button in pairs(self:get_buttons(width, height, hud_height, layout)) do
        local dx = x - button.x
        local dy = y - button.y
        if dx * dx + dy * dy <= button.radius * button.radius then
            return direction
        end
    end
    return nil
end

function VirtualControls:draw(assets, width, height, hud_height, layout)
    love.graphics.setFont(assets:get_font("medium"))
    for _, button in pairs(self:get_buttons(width, height, hud_height, layout)) do
        love.graphics.setColor(0.06, 0.1, 0.16, 0.4)
        love.graphics.circle("fill", button.x, button.y, button.radius)
        love.graphics.setColor(0.92, 0.96, 1, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", button.x, button.y, button.radius)
        love.graphics.printf(button.label, button.x - button.radius, button.y - 7, button.radius * 2, "center")
    end
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

return VirtualControls
