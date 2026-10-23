-- Effects: partículas, screen shake y utilidades de interpolación (tween).
-- Mantiene su propio estado y no conoce el resto del juego.
local Effects = {}
Effects.__index = Effects

function Effects.new()
    return setmetatable({
        particles = {},
        shake = 0,          -- magnitud restante del screen shake
        shakeMax = 0,
    }, Effects)
end

-- Estallido de partículas al romper un ladrillo.
function Effects:burst(x, y, color, n)
    n = n or 12
    for _ = 1, n do
        local ang = love.math.random() * math.pi * 2
        local spd = 60 + love.math.random() * 160
        table.insert(self.particles, {
            x = x, y = y,
            vx = math.cos(ang) * spd,
            vy = math.sin(ang) * spd - 60,
            life = 0.35 + love.math.random() * 0.3,
            maxLife = 0.65,
            color = color,
            size = 2 + love.math.random() * 3,
        })
    end
end

function Effects:shakeIt(mag)
    self.shake = math.max(self.shake, mag)
    self.shakeMax = math.max(self.shakeMax, mag)
end

function Effects:update(dt)
    -- Partículas
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.particles, i)
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.vy = p.vy + 420 * dt     -- gravedad
            p.vx = p.vx * (1 - 1.5 * dt)
        end
    end
    -- Screen shake: decae solo con el tiempo
    if self.shake > 0 then
        self.shake = math.max(0, self.shake - 60 * dt)
    end
end

function Effects:draw()
    for _, p in ipairs(self.particles) do
        local a = math.max(0, p.life / p.maxLife)
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], a)
        love.graphics.circle("fill", p.x, p.y, p.size * a)
    end
    love.graphics.setColor(1, 1, 1)
end

-- Desplazamiento aleatorio para el temblor de cámara.
function Effects:shakeOffset()
    if self.shake <= 0 then return 0, 0 end
    return (love.math.random() - 0.5) * self.shake,
           (love.math.random() - 0.5) * self.shake
end

return Effects
