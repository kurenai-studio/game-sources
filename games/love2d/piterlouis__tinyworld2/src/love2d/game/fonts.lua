--
-- TinyWorld
--
-- Copyright (c) 2025 piterlouis
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local M = {}

M.orbitron20 = love.graphics.newFont('game/fonts/Orbitron-Medium.ttf', 20)

M.pixelify16 = love.graphics.newFont('game/fonts/PixelifySans-Regular.ttf', 16, 'mono')
M.pixelify16:setFilter('nearest', 'nearest')

M.pixelify25 = love.graphics.newFont('game/fonts/Jersey25-Regular.ttf', 25, 'mono')
M.pixelify25:setFilter('nearest', 'nearest')

M.pixelify50 = love.graphics.newFont('game/fonts/Jersey25-Regular.ttf', 50, 'mono')

return M
