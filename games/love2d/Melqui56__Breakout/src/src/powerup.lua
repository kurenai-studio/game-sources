-- PowerUp: un objeto que cae y, al tocar la paleta, ejecuta un efecto.
-- El efecto es una función que se recibe al construir el power-up:
-- así el objeto no necesita saber qué hace, solo lo ejecuta.
local Config = require("src.config")

local PowerUp = {}
PowerUp.__index = PowerUp

function PowerUp.new(x, y, efecto, color, label)
    return setmetatable({
        x = x, y = y,
        w = Config.powerupW,
        h = Config.powerupH,
        vy = Config.powerupFall,
        efecto = efecto,     -- function(game)
        color = color or { 1, 1, 1 },
        label = label or "?",
        _dead = false,
    }, PowerUp)
end

function PowerUp:update(dt)
    self.y = self.y + self.vy * dt
    if self.y > Config.height then self._dead = true end
end

function PowerUp:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 4, 4)
    love.graphics.setColor(0.06, 0.07, 0.11)
    love.graphics.printf(self.label, self.x, self.y + 1, self.w, "center")
    love.graphics.setColor(1, 1, 1)
end

return PowerUp
