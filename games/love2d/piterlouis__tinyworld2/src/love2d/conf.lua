--
-- TinyWorld
--
-- Copyright (c) 2025 piterlouis
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

function love.conf(t)
    t.version = "11.5"
    t.window.title = "Tiny World 1.0"
    t.window.width = 800
    t.window.height = 800
    t.window.msaa = 0
    t.modules.joystick = false
    t.modules.physics = false
end
