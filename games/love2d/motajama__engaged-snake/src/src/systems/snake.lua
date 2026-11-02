local Snake = {}
Snake.__index = Snake

local opposite = {
    up = "down",
    down = "up",
    left = "right",
    right = "left",
}

local vectors = {
    up = { 0, -1 },
    down = { 0, 1 },
    left = { -1, 0 },
    right = { 1, 0 },
}

function Snake.new(start_x, start_y)
    return setmetatable({
        body = {
            { x = start_x, y = start_y },
            { x = start_x - 1, y = start_y },
            { x = start_x - 2, y = start_y },
        },
        direction = "right",
        queued_direction = "right",
        pending_growth = 0,
    }, Snake)
end

function Snake:set_direction(direction)
    if direction and direction ~= opposite[self.direction] and direction ~= opposite[self.queued_direction] then
        self.queued_direction = direction
    end
end

function Snake:get_head()
    return self.body[1]
end

function Snake:occupies(x, y)
    for _, segment in ipairs(self.body) do
        if segment.x == x and segment.y == y then
            return true
        end
    end
    return false
end

function Snake:grow(amount)
    self.pending_growth = self.pending_growth + (amount or 1)
end

function Snake:shrink(amount)
    amount = amount or 1
    for _ = 1, amount do
        if #self.body > 2 then
            table.remove(self.body)
        end
    end
end

function Snake:move()
    self.direction = self.queued_direction
    local vector = vectors[self.direction]
    local head = self:get_head()
    local next_head = {
        x = head.x + vector[1],
        y = head.y + vector[2],
    }

    table.insert(self.body, 1, next_head)

    if self.pending_growth > 0 then
        self.pending_growth = self.pending_growth - 1
    else
        table.remove(self.body)
    end

    return next_head
end

function Snake:has_self_collision()
    local head = self:get_head()
    for index = 2, #self.body do
        local segment = self.body[index]
        if segment.x == head.x and segment.y == head.y then
            return true
        end
    end
    return false
end

return Snake
