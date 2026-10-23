-- Config: constantes compartidas del juego.
local Config = {
    width = 800,
    height = 600,

    -- Bola
    ballRadius = 6,
    ballSpeed = 340,
    ballMaxVx = 260,       -- componente horizontal máxima tras el rebote en la paleta

    -- Paleta
    paddleWidth = 90,
    paddleHeight = 12,
    paddleSpeed = 460,
    paddleY = 560,

    -- Cuadrícula de ladrillos (10 columnas)
    brickCols = 10,
    brickW = 68,
    brickH = 22,
    brickGap = 4,
    brickTop = 70,

    -- Power-ups
    powerupW = 18,
    powerupH = 18,
    powerupFall = 150,
    powerupChance = 0.22,  -- probabilidad de soltar power-up al romper un ladrillo

    -- Color (rgba, para la variante de tabla de love.graphics.setColor)
    colorBackground = { 0.06, 0.07, 0.11, 1 },
    colorBall = { 0.95, 0.95, 0.85, 1 },
    colorPaddle = { 0.35, 0.75, 0.95, 1 },
    colorBrick = { 0.90, 0.35, 0.35, 1 },
    colorStrong = { 0.80, 0.60, 0.20, 1 },
    colorText = { 0.90, 0.90, 0.95, 1 },
}

-- x del centro de la columna col (1..brickCols)
function Config.brickX(col)
    local gridW = Config.brickCols * Config.brickW + (Config.brickCols - 1) * Config.brickGap
    local left = (Config.width - gridW) / 2
    return left + (col - 1) * (Config.brickW + Config.brickGap)
end

-- y de la fila row (1..n)
function Config.brickY(row)
    return Config.brickTop + (row - 1) * (Config.brickH + Config.brickGap)
end

return Config
