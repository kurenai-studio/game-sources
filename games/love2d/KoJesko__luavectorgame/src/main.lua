-- Vector Class Setup via Metatables
local Vector = {}
Vector.__index = Vector

function Vector.new(x, y)
    local v = {x = x or 0, y = y or 0}
    setmetatable(v, Vector)
    return v
end

-- Overload addition to add vectors
function Vector.__add(a, b)
    return Vector.new(a.x + b.x, a.y + b.y)
end

-- Calculate the distance (Euclidian) between vectors
function Vector:dist(other)
    local dx = self.x - other.x
    local dy = self.y - other.y
    return math.sqrt(dx * dx + dy * dy)
end

-- Game State Tables
local player = {}
local targets = {}
local score = 0
local inputText = ""

-- Spawn Random targets
local function spawnTarget()
    table.insert(targets, {
        pos = Vector.new(math.random(50, 750), math.random(50, 550)),
        radius = 15
    })
end

function love.load()
    love.keyboard.setKeyRepeat(true)
    math.randomseed(os.time())

    player = {
        pos = Vector.new(400, 300),
        radius = 10
    }

    -- Spawn Our Targets Initially
    for i = 1, 3 do
        spawnTarget()
    end
end

function love.update(dt)
    -- Iterate backwards when removing items from a table to avoid skipping indices
    for i = #targets, 1, -1 do
        local t = targets[i]

        -- Collision detection: Distance between center and < sum of radii
        if player.pos:dist(t.pos) < (player.radius + t.radius) then
            table.remove(targets, i)
            score = score + 1
            spawnTarget()
        end
    end
end

function love.draw()
    -- Draw Targets (Red Circles, you target)
    love.graphics.setColor(1, 0, 0)
    for _, t in ipairs(targets) do
        love.graphics.circle("fill", t.pos.x, t.pos.y, t.radius)
    end

    -- Draw Player (You as Green Dot)
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle("fill", player.pos.x, player.pos.y, player.radius)

    -- Draw UI (White Text)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 10, 10)
    love.graphics.print("Enter translation vector (e.g., '50 -20'): " .. inputText, 10, 30)
end

-- Handle character input for the vector string
function love.textinput(t)
    -- Filter out control characters (fixes backspace issues on Ubuntu/Linux)
    if t:byte() < 32 or t:byte() == 127 then
        return
    end

    -- Accept only digits, spaces, and negative signs
    if t:match("[%d%s%-]") then
        inputText = inputText .. t
    end
end

-- Handle backspace and enter logic
function love.keypressed(key)
    if key == "backspace" then
        -- Remove last character safely (input is ASCII-only, so byte removal is fine)
        if #inputText > 0 then
            inputText = string.sub(inputText, 1, #inputText - 1)
        end
    elseif key == "return" then
        -- Parse the input string for two numbers
        local dx, dy = inputText:match("([%-%d%.]+)%s+([%-%d%.]+)")
        if dx and dy then
            -- Create a new vector and use overloaded __add method
            local moveVec = Vector.new(tonumber(dx), tonumber(dy))
            player.pos = player.pos + moveVec
        end
        inputText = ""
    end
end
