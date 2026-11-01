-- modules
local keyboardmodule = require("modules.keyboard")

-- factories
local publisher = require('factories.messagebus.publisher')

local keyboard = {
    Key = "keyboard"
}

local function sendMessage(dx, dy)
    publisher.send(publisher.Types.POSITION, { dx = dx, dy = dy })
end

function keyboard.handleMessage(msg)
    if msg.key ~= keyboard.Key then
        return
    end

    if keyboardmodule.isQuit(msg.value.keycode) then
        love.event.quit()
        return
    end

    local dx, dy = 0, 0

    if keyboardmodule.isUpPressed(msg.value.keycode) then
        dy = -1
    elseif keyboardmodule.isDownPressed(msg.value.keycode) then
        dy = 1
    elseif keyboardmodule.isLeftPressed(msg.value.keycode) then
        dx = -1
    elseif keyboardmodule.isRightPressed(msg.value.keycode) then
        dx = 1
    end

    if dx == 0 and dy == 0 then
        -- this means either the user didn't press any keys or press an invalid key
        return
    end

    sendMessage(dx, dy)
end

return keyboard
