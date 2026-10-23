-- Ball: el proyectil móvil del juego.
-- Usa caja envolvente (x, y, w, h) para poder resolverse con AABB,
-- y dibuja un círculo con radio w/2. La velocidad se mueve por sub-pasos
-- (moveStep) para evitar el tunneling a velocidades altas.
local Config = require("src.config")

local Ball = {}
Ball.__index = Ball

function Ball.new(x, y, radius)
    radius = radius or Config.ballRadius
    return setmetatable({
        x = x, y = y,
        w = radius * 2, h = radius * 2,
        vx = 0, vy = 0,
        maxVx = Config.ballMaxVx,
        stuck = false,        -- true mientras espera sobre la paleta
    }, Ball)
end

function Ball:moveStep(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

function Ball:update(dt)
    if not self.stuck then
        self:moveStep(dt)
    end
end

function Ball:launch()
    self.stuck = false
    local dir = love.math.random() < 0.5 and -1 or 1
    self.vx = self.maxVx * 0.35 * dir
    self.vy = -Config.ballSpeed
end

function Ball:reset(x, y)
    self.x = x
    self.y = y
    self.vx = 0
    self.vy = 0
    self.stuck = true
end

function Ball:draw()
    local c = Config.colorBall
    love.graphics.setColor(c)
    love.graphics.circle("fill", self.x + self.w / 2, self.y + self.h / 2, self.w / 2)
    love.graphics.setColor(1, 1, 1)
end

return Ball
