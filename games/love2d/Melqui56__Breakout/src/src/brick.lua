-- Brick: clase base de un ladrillo destructible.
-- _hp y _dead llevan guion bajo: son estado interno. El resto del juego
-- interactúa a través de onHit(), no toca los datos directamente.
local Config = require("src.config")

local Brick = {}
Brick.__index = Brick

function Brick.new(x, y, w, h, hp)
    return setmetatable({
        x = x, y = y,
        w = w or Config.brickW,
        h = h or Config.brickH,
        _hp = hp or 1,
        _dead = false,
        _flash = 0,            -- temporizador de destello al recibir un golpe
        color = Config.colorBrick,
        points = 10,
    }, Brick)
end

-- Comportamiento por defecto: muere de un golpe.
function Brick:onHit()
    self._dead = true
    self._flash = 0.12
    return self.points
end

function Brick:update(dt)
    if self._flash > 0 then
        self._flash = math.max(0, self._flash - dt)
    end
end

function Brick:draw()
    if self._dead then return end
    local c = self.color
    if self._flash > 0 then
        -- Tween: el destello interpola hacia blanco mientras dura.
        local t = self._flash / 0.12
        love.graphics.setColor(c[1] + (1 - c[1]) * t, c[2] + (1 - c[2]) * t, c[3] + (1 - c[3]) * t)
    else
        love.graphics.setColor(c)
    end
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 3, 3)
end

return Brick
