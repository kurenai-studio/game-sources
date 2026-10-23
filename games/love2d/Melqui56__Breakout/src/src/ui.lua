-- UI: dibuja el HUD (puntaje, vidas, nivel) y los mensajes de pantalla.
-- No contiene lógica de juego: solo presenta los datos que recibe.
local Config = require("src.config")

local UI = {}
UI.__index = UI

local HUD_H = 56

function UI.new()
    return setmetatable({
        score = 0,
        lives = 0,
        level = 1,
        message = "",
    }, UI)
end

function UI:setHud(score, lives, level)
    self.score = score
    self.lives = lives
    self.level = level
end

function UI:setMessage(msg)
    self.message = msg or ""
end

local function formatScore(n)
    local s = tostring(math.floor(n))
    local k
    repeat
        s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1.%2")
    until k == 0
    return s
end

-- Corazón vectorial (la fuente por defecto no dibuja bien el glifo ♥).
local function drawHeartIcon(x, y, size)
    local w, h = size, size
    local cx = x + w * 0.5
    local fill = { 0.95, 0.28, 0.38 }
    local shade = { 0.72, 0.12, 0.22 }

    love.graphics.setColor(shade)
    love.graphics.polygon("fill",
        cx, y + h * 0.88,
        x + w * 0.02, y + h * 0.38,
        x + w * 0.22, y + h * 0.08,
        cx, y + h * 0.28,
        x + w * 0.78, y + h * 0.08,
        x + w * 0.98, y + h * 0.38
    )

    love.graphics.setColor(fill)
    love.graphics.polygon("fill",
        cx, y + h * 0.82,
        x + w * 0.06, y + h * 0.36,
        x + w * 0.24, y + h * 0.10,
        cx, y + h * 0.26,
        x + w * 0.76, y + h * 0.10,
        x + w * 0.94, y + h * 0.36
    )

    love.graphics.setColor(1, 0.55, 0.62, 0.55)
    love.graphics.circle("fill", x + w * 0.32, y + h * 0.22, size * 0.11)
end

local function drawHearts(x, y, count)
    local size = 14
    local gap = 18
    for i = 1, math.max(0, count) do
        drawHeartIcon(x + (i - 1) * gap, y + 1, size)
    end
end

local function drawLevelBadge(level)
    local label = "NIVEL " .. level
    local font = love.graphics.getFont()
    local tw = font:getWidth(label)
    local padX, padY = 12, 6
    local bw = tw + padX * 2
    local bx = Config.width - 20 - bw
    local by = 12

    love.graphics.setColor(0.18, 0.22, 0.32, 0.95)
    love.graphics.rectangle("fill", bx, by, bw, font:getHeight() + padY * 2, 6, 6)
    love.graphics.setColor(0.45, 0.55, 0.75, 0.9)
    love.graphics.rectangle("line", bx, by, bw, font:getHeight() + padY * 2, 6, 6)
    love.graphics.setColor(Config.colorText)
    love.graphics.print(label, bx + padX, by + padY)
end

function UI:draw()
    -- Franja superior legible sobre el campo de ladrillos
    love.graphics.setColor(0.08, 0.09, 0.13, 0.88)
    love.graphics.rectangle("fill", 0, 0, Config.width, HUD_H)
    love.graphics.setColor(0.35, 0.40, 0.55, 0.55)
    love.graphics.rectangle("fill", 0, HUD_H, Config.width, 2)

    love.graphics.setColor(Config.colorText)
    love.graphics.print("PUNTOS", 20, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(formatScore(self.score), 20, 26)

    love.graphics.setColor(Config.colorText)
    love.graphics.print("VIDAS", 168, 10)
    drawHearts(168, 26, self.lives)

    drawLevelBadge(self.level)

    if self.message ~= "" then
        local font = love.graphics.getFont()
        local mw = math.min(Config.width - 80, font:getWidth(self.message) + 48)
        local mx = (Config.width - mw) / 2
        local my = Config.height / 2 - 36
        love.graphics.setColor(0.06, 0.07, 0.11, 0.82)
        love.graphics.rectangle("fill", mx, my, mw, 48, 8, 8)
        love.graphics.setColor(0.45, 0.55, 0.75, 0.7)
        love.graphics.rectangle("line", mx, my, mw, 48, 8, 8)
        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.printf(self.message, 0, my + 14, Config.width, "center")
    end

    love.graphics.setColor(1, 1, 1)
end

return UI
