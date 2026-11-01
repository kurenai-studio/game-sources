-- modules
local colormodule = require("modules.color")

local layout = {}

local backgroundColorRGBA = colormodule.getColorRGBA(colormodule.Types.GRAY)

function layout.load()
    math.randomseed(os.time())
    love.graphics.setBackgroundColor(backgroundColorRGBA.red, backgroundColorRGBA.green, backgroundColorRGBA.blue)
end

return layout
