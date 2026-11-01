local random = {}

local function range(low, high)
    local result = {}
    for i = low, high do
        result[#result + 1] = i
    end
    return result
end

local function isTaken(possibleSelect, takenList)
    for _, alreadyTaken in pairs(takenList) do
        if alreadyTaken == possibleSelect then
            return true
        end
    end

    return false
end

local function createAvailable(possibleSelection, takenList)
    local result = {}
    for _, possibleSelect in ipairs(possibleSelection) do
        if not isTaken(possibleSelect, takenList) then
            result[#result + 1] = possibleSelect
        end
    end
    return result
end

function random.generate(low, high, takenList)
    takenList = takenList or {}
    local available = createAvailable(range(low, high), takenList)

    return available[math.random(#available)]
end

return random
