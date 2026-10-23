-- Paddle: la plataforma controlada por el jugador.
-- Solo se mueve con la intención que le llega en `input` y aplica un tween
-- al ancho (para el power-up de paleta ancha). No decide el flujo del juego.
local Config = require("src.config")

local Paddle = {}
Paddle.__index = Paddle

function Paddle.new(x, y, width, speed)
    local w = width or Config.paddleWidth
    return setmetatable({
        x = x, y = y,
        w = w, h = Config.paddleHeight,
        speed = speed or Config.paddleSpeed,
        baseWidth = w,
        targetWidth = w,      -- destino del tween de ancho
    }, Paddle)
end

function Paddle:moveLeft(dt)
    self.x = self.x - self.speed * dt
end

function Paddle:moveRight(dt)
    self.x = self.x + self.speed * dt
end

function Paddle:update(dt, input)
    if input.left then self:moveLeft(dt) end
    if input.right then self:moveRight(dt) end

    -- Mantener la paleta dentro de la pantalla.
    if self.x < 0 then self.x = 0 end
    if self.x + self.w > Config.width then self.x = Config.width - self.w end

    -- Tween del ancho hacia su destino (suaviza el power-up).
    self.w = self.w + (self.targetWidth - self.w) * math.min(1, 12 * dt)
end

function Paddle:reset()
    self.w = self.baseWidth
    self.targetWidth = self.baseWidth
    self.x = (Config.width - self.w) / 2
end

function Paddle:draw()
    local c = Config.colorPaddle
    love.graphics.setColor(c)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 4, 4)
    love.graphics.setColor(1, 1, 1)
end

return Paddle
