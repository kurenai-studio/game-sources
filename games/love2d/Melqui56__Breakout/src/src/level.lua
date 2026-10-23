-- Level: posee los ladrillos de una etapa e informa si está completo.
-- Convierte los datos (matriz de códigos) en objetos Brick / StrongBrick.
local Config = require("src.config")
local Brick = require("src.brick")
local StrongBrick = require("src.strongbrick")

local Level = {}
Level.__index = Level

function Level.new()
    return setmetatable({ bricks = {} }, Level)
end

-- Datos -> objetos: cada código numérico se traduce a un subtipo de Brick.
function Level:load(layout)
    self.bricks = {}
    for row, cols in ipairs(layout) do
        for col, code in ipairs(cols) do
            local x = Config.brickX(col)
            local y = Config.brickY(row)
            if code == 1 then
                table.insert(self.bricks, Brick.new(x, y))
            elseif code == 2 then
                table.insert(self.bricks, StrongBrick.new(x, y))
            end
        end
    end
end

function Level:update(dt)
    for i = #self.bricks, 1, -1 do
        local b = self.bricks[i]
        b:update(dt)
        if b._dead then
            table.remove(self.bricks, i)
        end
    end
end

function Level:draw()
    for _, b in ipairs(self.bricks) do
        b:draw()
    end
end

function Level:isComplete()
    return #self.bricks == 0
end

return Level
