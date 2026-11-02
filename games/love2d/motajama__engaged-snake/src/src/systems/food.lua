local Food = {}

local function pick_cell(level, snake, occupied)
    for _ = 1, 200 do
        local x = love.math.random(0, level.grid_width - 1)
        local y = love.math.random(0, level.grid_height - 1)
        local key = x .. ":" .. y
        if not snake:occupies(x, y) and not occupied[key] then
            return x, y
        end
    end

    for y = 0, level.grid_height - 1 do
        for x = 0, level.grid_width - 1 do
            local key = x .. ":" .. y
            if not snake:occupies(x, y) and not occupied[key] then
                return x, y
            end
        end
    end

    return nil, nil
end

function Food.spawn_set(level, snake, counts)
    local foods = {}
    local occupied = {}
    local good_count = counts and counts.good_count or level.good_count
    local bad_count = counts and counts.bad_count or level.bad_count
    local spawned_good = 0
    local spawned_bad = 0

    for _ = 1, good_count do
        local x, y = pick_cell(level, snake, occupied)
        if not x then
            break
        end
        occupied[x .. ":" .. y] = true
        foods[#foods + 1] = { x = x, y = y, kind = "good" }
        spawned_good = spawned_good + 1
    end

    for _ = 1, bad_count do
        local x, y = pick_cell(level, snake, occupied)
        if not x then
            break
        end
        occupied[x .. ":" .. y] = true
        foods[#foods + 1] = { x = x, y = y, kind = "bad" }
        spawned_bad = spawned_bad + 1
    end

    return foods, {
        good_count = spawned_good,
        bad_count = spawned_bad,
    }
end

function Food.consume_at(foods, x, y)
    for index, food in ipairs(foods) do
        if food.x == x and food.y == y then
            table.remove(foods, index)
            return food
        end
    end
    return nil
end

return Food
