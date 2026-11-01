local bus = {}

local queue = {}
local isOff = false

function bus.add(msg)
    table.insert(queue, msg)
end

function bus.remove()
    table.remove(queue, 1)
end

function bus.isEmpty()
    return #queue == 0
end

function bus.peek()
    if queue[1] == nil then
        return -1
    end

    return queue[1]
end

function bus.stop()
    isOff = true
end

function bus.isOff()
    return isOff
end

return bus
