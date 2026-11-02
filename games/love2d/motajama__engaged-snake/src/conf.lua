local Constants = require("src.core.constants")

function love.conf(t)
    t.identity = "divadelni-utopie"
    t.version = "11.4"
    t.console = false

    t.window.title = "Divadelni utopie"
    t.window.width = Constants.window_width
    t.window.height = Constants.window_height
    t.window.resizable = true
    t.window.minwidth = Constants.logical_width
    t.window.minheight = Constants.logical_height
    t.window.vsync = 1
    t.window.msaa = 0

    t.modules.physics = false
end
