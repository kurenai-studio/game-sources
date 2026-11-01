local keyboard = {}

local keySwitch = {
    UP = { "up", "w" },
    DOWN = { "down", "s" },
    LEFT = { "left", "a" },
    RIGHT = { "right", "d" }
}

function keyboard.isUpPressed(key)
    return keySwitch.UP[1] == key or keySwitch.UP[2] == key
end

function keyboard.isDownPressed(key)
    return keySwitch.DOWN[1] == key or keySwitch.DOWN[2] == key
end

function keyboard.isLeftPressed(key)
    return keySwitch.LEFT[1] == key or keySwitch.LEFT[2] == key
end

function keyboard.isRightPressed(key)
    return keySwitch.RIGHT[1] == key or keySwitch.RIGHT[2] == key
end

function keyboard.isQuit(key)
    return key == "q";
end

return keyboard
