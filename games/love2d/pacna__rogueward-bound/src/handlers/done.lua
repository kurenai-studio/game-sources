-- factories
local publisher = require('factories.messagebus.publisher')

local done = {
    Key = "done"
}

function done.handleMessage(msg)
    if msg.key ~= done.Key then
        return
    end

    publisher.off()
end

return done
