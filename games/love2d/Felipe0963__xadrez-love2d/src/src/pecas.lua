-- Peças desenhadas por código (coordenadas normalizadas 0..1 dentro da casa).
local Pecas = {}

local CORPO = { "pol", { 0.34, 0.80, 0.41, 0.52, 0.59, 0.52, 0.66, 0.80 } }
local BASE = { "ret", 0.22, 0.78, 0.56, 0.10 }

local FORMAS = {
    P = { { "pol", { 0.36, 0.80, 0.43, 0.52, 0.57, 0.52, 0.64, 0.80 } }, { "circ", 0.50, 0.40, 0.13 } },
    R = { { "ret", 0.32, 0.38, 0.36, 0.42 }, { "ret", 0.27, 0.27, 0.46, 0.13 },
          { "ret", 0.27, 0.17, 0.10, 0.11 }, { "ret", 0.45, 0.17, 0.10, 0.11 }, { "ret", 0.63, 0.17, 0.10, 0.11 } },
    N = { { "pol", { 0.30, 0.80, 0.34, 0.58, 0.44, 0.44, 0.30, 0.48, 0.24, 0.40, 0.34, 0.26,
                     0.46, 0.18, 0.50, 0.12, 0.54, 0.18, 0.66, 0.26, 0.72, 0.46, 0.70, 0.80 } },
          { "circ", 0.42, 0.30, 0.025 } },
    B = { { "circ", 0.50, 0.20, 0.05 }, { "elip", 0.50, 0.42, 0.13, 0.18 },
          { "pol", { 0.36, 0.80, 0.43, 0.56, 0.57, 0.56, 0.64, 0.80 } }, { "linha", 0.55, 0.33, 0.47, 0.45 } },
    Q = { CORPO, { "pol", { 0.30, 0.52, 0.24, 0.26, 0.38, 0.40, 0.50, 0.20, 0.62, 0.40, 0.76, 0.26, 0.70, 0.52 } },
          { "circ", 0.24, 0.23, 0.04 }, { "circ", 0.50, 0.16, 0.04 }, { "circ", 0.76, 0.23, 0.04 } },
    K = { { "ret", 0.46, 0.08, 0.08, 0.28 }, { "ret", 0.38, 0.14, 0.24, 0.07 },
          CORPO, { "ret", 0.33, 0.33, 0.34, 0.21 } },
}

local function forma(f, x, y, t, cp, cc)
    local k = f[1]
    for passo = 1, 2 do
        love.graphics.setColor(passo == 1 and cp or cc)
        local modo = passo == 1 and "fill" or "line"
        if k == "ret" then
            love.graphics.rectangle(modo, x + f[2] * t, y + f[3] * t, f[4] * t, f[5] * t, t * 0.02, t * 0.02)
        elseif k == "circ" then
            love.graphics.circle(modo, x + f[2] * t, y + f[3] * t, f[4] * t)
        elseif k == "elip" then
            love.graphics.ellipse(modo, x + f[2] * t, y + f[3] * t, f[4] * t, f[5] * t)
        elseif k == "pol" then
            local pts = {}
            for i, v in ipairs(f[2]) do pts[i] = (i % 2 == 1 and x or y) + v * t end
            if modo == "fill" then
                for _, tri in ipairs(love.math.triangulate(pts)) do love.graphics.polygon("fill", tri) end
            else
                love.graphics.polygon("line", pts)
            end
        elseif k == "linha" and passo == 2 then
            love.graphics.line(x + f[2] * t, y + f[3] * t, x + f[4] * t, y + f[5] * t)
        end
    end
end

-- peca: letra FEN ("K" rei branco, "k" rei preto...); (x, y) canto superior esquerdo; tam = lado da casa.
function Pecas.desenhar(peca, x, y, tam)
    local tipo = peca:upper()
    local branca = peca == tipo
    local cp = branca and { 0.97, 0.95, 0.90 } or { 0.16, 0.16, 0.20 }
    local cc = branca and { 0.18, 0.16, 0.14 } or { 0.85, 0.85, 0.88 }
    love.graphics.setLineWidth(math.max(1.5, tam * 0.03))
    for _, f in ipairs(FORMAS[tipo]) do forma(f, x, y, tam, cp, cc) end
    forma(BASE, x, y, tam, cp, cc)
    love.graphics.setLineWidth(1)
end

return Pecas
