--[[
Utility Functions - Math, RNG, and Helper Functions

Collection of commonly used utility functions for game development,
including deterministic random number generation, math helpers, 
table operations, and performance utilities.

Key features:
- Seedable random number generator for deterministic gameplay
- Common math functions (clamp, lerp, distance, etc.)
- Table manipulation utilities (deep copy, merge, etc.)
- String and formatting helpers
- Performance measurement tools
--]]

local Utils = {}

-- Deterministic Random Number Generator
local RNG = {}
RNG.__index = RNG

function RNG:new(seed)
    local instance = {
        seed = seed or os.time(),
        state = seed or os.time()
    }
    setmetatable(instance, RNG)
    return instance
end

function RNG:setSeed(seed)
    self.seed = seed
    self.state = seed
end

function RNG:getSeed()
    return self.seed
end

-- Linear congruential generator (simple but fast)
function RNG:random()
    self.state = (self.state * 1103515245 + 12345) % (2^31)
    return self.state / (2^31)
end

function RNG:randomInt(min, max)
    if not max then
        max = min
        min = 1
    end
    return math.floor(self:random() * (max - min + 1)) + min
end

function RNG:randomFloat(min, max)
    min = min or 0
    max = max or 1
    return min + (max - min) * self:random()
end

function RNG:choice(array)
    if #array == 0 then return nil end
    return array[self:randomInt(1, #array)]
end

function RNG:shuffle(array)
    local shuffled = {}
    for i, v in ipairs(array) do
        shuffled[i] = v
    end
    
    -- Fisher-Yates shuffle
    for i = #shuffled, 2, -1 do
        local j = self:randomInt(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    
    return shuffled
end

Utils.RNG = RNG

-- Math utilities
Utils.Math = {}

function Utils.Math.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function Utils.Math.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.Math.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Utils.Math.distanceSquared(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return dx * dx + dy * dy
end

function Utils.Math.angle(x1, y1, x2, y2)
    return math.atan(y2 - y1, x2 - x1)
end

function Utils.Math.normalize(x, y)
    local length = math.sqrt(x * x + y * y)
    if length == 0 then return 0, 0 end
    return x / length, y / length
end

function Utils.Math.round(value, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(value * mult + 0.5) / mult
end

function Utils.Math.sign(value)
    if value > 0 then return 1
    elseif value < 0 then return -1
    else return 0 end
end

function Utils.Math.smoothstep(edge0, edge1, x)
    x = Utils.Math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
    return x * x * (3 - 2 * x)
end

-- Easing function (alternative to animation lib for simple cases)
function Utils.Math.ease(t, type)
    type = type or "linear"
    
    if type == "linear" then
        return t
    elseif type == "quadIn" then
        return t * t
    elseif type == "quadOut" then
        return 1 - (1 - t) * (1 - t)
    elseif type == "quadInOut" then
        return t < 0.5 and 2 * t * t or 1 - 2 * (1 - t) * (1 - t)
    else
        return t
    end
end

-- Table utilities
Utils.Table = {}

function Utils.Table.copy(original)
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end
    return copy
end

function Utils.Table.deepCopy(original)
    local copy
    if type(original) == "table" then
        copy = {}
        for key, value in next, original, nil do
            copy[Utils.Table.deepCopy(key)] = Utils.Table.deepCopy(value)
        end
        setmetatable(copy, Utils.Table.deepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

function Utils.Table.merge(target, source)
    for key, value in pairs(source) do
        target[key] = value
    end
    return target
end

function Utils.Table.contains(array, value)
    for _, v in ipairs(array) do
        if v == value then return true end
    end
    return false
end

function Utils.Table.indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then return i end
    end
    return nil
end

function Utils.Table.remove(array, value)
    local index = Utils.Table.indexOf(array, value)
    if index then
        table.remove(array, index)
        return true
    end
    return false
end

function Utils.Table.filter(array, predicate)
    local filtered = {}
    for i, value in ipairs(array) do
        if predicate(value, i) then
            table.insert(filtered, value)
        end
    end
    return filtered
end

function Utils.Table.map(array, transform)
    local mapped = {}
    for i, value in ipairs(array) do
        mapped[i] = transform(value, i)
    end
    return mapped
end

function Utils.Table.keys(table)
    local keys = {}
    for key, _ in pairs(table) do
        table.insert(keys, key)
    end
    return keys
end

function Utils.Table.values(table)
    local values = {}
    for _, value in pairs(table) do
        table.insert(values, value)
    end
    return values
end

function Utils.Table.isEmpty(table)
    return next(table) == nil
end

function Utils.Table.count(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

-- String utilities  
Utils.String = {}

function Utils.String.split(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function Utils.String.trim(s)
    return s:match("^%s*(.-)%s*$")
end

function Utils.String.startsWith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

function Utils.String.endsWith(str, suffix)
    return string.sub(str, -string.len(suffix)) == suffix
end

function Utils.String.capitalize(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

function Utils.String.wrap(text, width)
    local wrapped = {}
    local line = ""
    
    for word in text:gmatch("%S+") do
        if #line + #word + 1 <= width then
            line = line .. (line == "" and "" or " ") .. word
        else
            if line ~= "" then
                table.insert(wrapped, line)
            end
            line = word
        end
    end
    
    if line ~= "" then
        table.insert(wrapped, line)
    end
    
    return wrapped
end

-- Color utilities
Utils.Color = {}

function Utils.Color.hex(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1,2), 16) / 255
    local g = tonumber(hex:sub(3,4), 16) / 255
    local b = tonumber(hex:sub(5,6), 16) / 255
    local a = hex:len() > 6 and tonumber(hex:sub(7,8), 16) / 255 or 1
    return {r, g, b, a}
end

function Utils.Color.hsv(h, s, v, a)
    h = h % 360
    s = Utils.Math.clamp(s, 0, 1)
    v = Utils.Math.clamp(v, 0, 1)
    a = a or 1
    
    local c = v * s
    local x = c * (1 - math.abs(((h / 60) % 2) - 1))
    local m = v - c
    
    local r, g, b
    if h < 60 then
        r, g, b = c, x, 0
    elseif h < 120 then
        r, g, b = x, c, 0
    elseif h < 180 then
        r, g, b = 0, c, x
    elseif h < 240 then
        r, g, b = 0, x, c
    elseif h < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    
    return {r + m, g + m, b + m, a}
end

function Utils.Color.lerp(color1, color2, t)
    return {
        Utils.Math.lerp(color1[1], color2[1], t),
        Utils.Math.lerp(color1[2], color2[2], t),
        Utils.Math.lerp(color1[3], color2[3], t),
        Utils.Math.lerp(color1[4] or 1, color2[4] or 1, t)
    }
end

-- Performance utilities
Utils.Performance = {}

function Utils.Performance.time(name, func)
    local start_time = love.timer.getTime()
    local result = func()
    local end_time = love.timer.getTime()
    print(string.format("%s took %.3f ms", name, (end_time - start_time) * 1000))
    return result
end

function Utils.Performance.profile(func, iterations)
    iterations = iterations or 1000
    local start_time = love.timer.getTime()
    
    for i = 1, iterations do
        func()
    end
    
    local end_time = love.timer.getTime()
    local total_time = end_time - start_time
    local avg_time = total_time / iterations
    
    print(string.format("Profile results: %d iterations, %.3f ms total, %.6f ms average", 
          iterations, total_time * 1000, avg_time * 1000))
    
    return avg_time
end

-- Memory tracking
local memory_tracker = {}

function Utils.Performance.trackMemory(name)
    memory_tracker[name] = collectgarbage("count")
end

function Utils.Performance.getMemoryUsage(name)
    local current = collectgarbage("count")
    local previous = memory_tracker[name] or current
    return current - previous
end

function Utils.Performance.printMemoryUsage()
    print(string.format("Memory usage: %.2f MB", collectgarbage("count") / 1024))
end

-- Generic object pool for reducing garbage collection
function Utils.createPool(create_func, reset_func, initial_size)
    initial_size = initial_size or 10
    
    local pool = {
        available = {},
        in_use = {},
        create_func = create_func,
        reset_func = reset_func
    }
    
    -- Pre-populate pool
    for i = 1, initial_size do
        table.insert(pool.available, create_func())
    end
    
    function pool:get()
        local object
        if #self.available > 0 then
            object = table.remove(self.available)
        else
            object = self.create_func()
        end
        
        table.insert(self.in_use, object)
        return object
    end
    
    function pool:release(object)
        local index = Utils.Table.indexOf(self.in_use, object)
        if index then
            table.remove(self.in_use, index)
            if self.reset_func then
                self.reset_func(object)
            end
            table.insert(self.available, object)
        end
    end
    
    function pool:clear()
        for _, object in ipairs(self.in_use) do
            if self.reset_func then
                self.reset_func(object)
            end
            table.insert(self.available, object)
        end
        self.in_use = {}
    end
    
    return pool
end

-- File utilities (for save/load functionality)
Utils.File = {}

function Utils.File.exists(filename)
    return love.filesystem.getInfo(filename) ~= nil
end

function Utils.File.readJSON(filename)
    if not Utils.File.exists(filename) then
        return nil, "File does not exist"
    end
    
    local contents = love.filesystem.read(filename)
    if not contents then
        return nil, "Failed to read file"
    end
    
    -- Simple JSON decode (for basic structures)
    local success, result = pcall(function()
        return load("return " .. contents)()
    end)
    
    if success then
        return result
    else
        return nil, "Failed to parse JSON"
    end
end

function Utils.File.writeJSON(filename, data)
    -- Simple JSON encode (for basic structures)
    local function serialize(obj, depth)
        depth = depth or 0
        local indent = string.rep("  ", depth)
        
        if type(obj) == "table" then
            local result = "{\n"
            for key, value in pairs(obj) do
                result = result .. indent .. "  " .. tostring(key) .. " = " .. serialize(value, depth + 1) .. ",\n"
            end
            result = result .. indent .. "}"
            return result
        elseif type(obj) == "string" then
            return '"' .. obj .. '"'
        else
            return tostring(obj)
        end
    end
    
    local serialized = serialize(data)
    local success = love.filesystem.write(filename, serialized)
    return success
end

-- Debug utilities
Utils.Debug = {}

function Utils.Debug.printTable(t, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    
    for key, value in pairs(t) do
        if type(value) == "table" then
            print(prefix .. tostring(key) .. ":")
            Utils.Debug.printTable(value, indent + 1)
        else
            print(prefix .. tostring(key) .. ": " .. tostring(value))
        end
    end
end

function Utils.Debug.stackTrace()
    print(debug.traceback())
end

function Utils.Debug.assert(condition, message)
    if not condition then
        error(message or "Assertion failed")
    end
end

-- Global RNG instance for convenience
Utils.globalRNG = RNG:new()

-- Convenience functions that use global RNG
function Utils.random()
    return Utils.globalRNG:random()
end

function Utils.randomInt(min, max)
    return Utils.globalRNG:randomInt(min, max)
end

function Utils.randomFloat(min, max)
    return Utils.globalRNG:randomFloat(min, max)
end

function Utils.choice(array)
    return Utils.globalRNG:choice(array)
end

function Utils.shuffle(array)
    return Utils.globalRNG:shuffle(array)
end

function Utils.setSeed(seed)
    Utils.globalRNG:setSeed(seed)
end

return Utils
