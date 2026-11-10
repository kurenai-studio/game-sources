-- Snakes and Ladders - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

function love.conf(t)
    t.identity = "SnakesAndLadders"
    t.version = "11.3"
    t.console = false
    t.accelerometerjoystick = true
    t.externalstorage = true

    t.window.title = "Snakes and Ladders - Food Adventure"
    t.window.icon = nil
    t.window.width = 1200
    t.window.height = 800
    t.window.borderless = false
    t.window.resizable = true
    t.window.minwidth = 800
    t.window.minheight = 600
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    t.window.vsync = 1
    t.window.msaa = 4
    t.window.depth = nil
    t.window.stencil = nil
    t.window.display = 1

    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = true
    t.modules.timer = true
    t.modules.touch = true
    t.modules.video = false
    t.modules.window = true
end
