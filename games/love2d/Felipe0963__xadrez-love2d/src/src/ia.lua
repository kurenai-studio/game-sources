-- IA: negamax com poda alfa-beta, aprofundamento iterativo e limite de tempo.
-- Pode rodar dentro de uma corrotina (opc.yield = true) para não travar a tela.
local T = require("src.tabuleiro")
local R = require("src.regras")
local IA = {}

local VALOR = { P = 100, N = 320, B = 330, R = 500, Q = 900, K = 0 }
local MATE = 100000

-- Tabelas de posição (visão das brancas; 1ª linha = 8ª fileira).
local PST = {
    P = {  0,  0,  0,  0,  0,  0,  0,  0,
          50, 50, 50, 50, 50, 50, 50, 50,
          10, 10, 20, 30, 30, 20, 10, 10,
           5,  5, 10, 25, 25, 10,  5,  5,
           0,  0,  0, 20, 20,  0,  0,  0,
           5, -5,-10,  0,  0,-10, -5,  5,
           5, 10, 10,-20,-20, 10, 10,  5,
           0,  0,  0,  0,  0,  0,  0,  0 },
    N = {-50,-40,-30,-30,-30,-30,-40,-50,
         -40,-20,  0,  0,  0,  0,-20,-40,
         -30,  0, 10, 15, 15, 10,  0,-30,
         -30,  5, 15, 20, 20, 15,  5,-30,
         -30,  0, 15, 20, 20, 15,  0,-30,
         -30,  5, 10, 15, 15, 10,  5,-30,
         -40,-20,  0,  5,  5,  0,-20,-40,
         -50,-40,-30,-30,-30,-30,-40,-50 },
    B = {-20,-10,-10,-10,-10,-10,-10,-20,
         -10,  0,  0,  0,  0,  0,  0,-10,
         -10,  0,  5, 10, 10,  5,  0,-10,
         -10,  5,  5, 10, 10,  5,  5,-10,
         -10,  0, 10, 10, 10, 10,  0,-10,
         -10, 10, 10, 10, 10, 10, 10,-10,
         -10,  5,  0,  0,  0,  0,  5,-10,
         -20,-10,-10,-10,-10,-10,-10,-20 },
    R = {  0,  0,  0,  0,  0,  0,  0,  0,
           5, 10, 10, 10, 10, 10, 10,  5,
          -5,  0,  0,  0,  0,  0,  0, -5,
          -5,  0,  0,  0,  0,  0,  0, -5,
          -5,  0,  0,  0,  0,  0,  0, -5,
          -5,  0,  0,  0,  0,  0,  0, -5,
          -5,  0,  0,  0,  0,  0,  0, -5,
           0,  0,  0,  5,  5,  0,  0,  0 },
    Q = {-20,-10,-10, -5, -5,-10,-10,-20,
         -10,  0,  0,  0,  0,  0,  0,-10,
         -10,  0,  5,  5,  5,  5,  0,-10,
          -5,  0,  5,  5,  5,  5,  0, -5,
           0,  0,  5,  5,  5,  5,  0, -5,
         -10,  5,  5,  5,  5,  5,  0,-10,
         -10,  0,  5,  0,  0,  0,  0,-10,
         -20,-10,-10, -5, -5,-10,-10,-20 },
    K = {-30,-40,-40,-50,-50,-40,-40,-30,
         -30,-40,-40,-50,-50,-40,-40,-30,
         -30,-40,-40,-50,-50,-40,-40,-30,
         -30,-40,-40,-50,-50,-40,-40,-30,
         -20,-30,-30,-40,-40,-30,-30,-20,
         -10,-20,-20,-20,-20,-20,-20,-10,
          20, 20,  0,  0,  0,  0, 20, 20,
          20, 30, 10,  0,  0, 10, 30, 20 },
}

IA.NIVEIS = {
    facil   = { prof = 1, aleatorio = 60 },
    medio   = { prof = 2 },
    dificil = { prof = 4, tempo = 2 },
}

-- Avaliação do ponto de vista de quem joga.
function IA.avaliar(e)
    local total = 0
    for c = 1, 64 do
        local p = e.casas[c]
        if p ~= "." then
            local t = p:upper()
            local branca = p == t
            local linha = branca and (9 - T.lin(c)) or T.lin(c)
            local v = VALOR[t] + PST[t][(linha - 1) * 8 + T.col(c)]
            total = total + (branca and v or -v)
        end
    end
    return e.vez == "brancas" and total or -total
end

-- Capturas valiosas com peças baratas primeiro (MVV-LVA) + promoções.
local function ordenar(ms)
    for _, m in ipairs(ms) do
        m.ordem = (m.captura and (10 * VALOR[m.captura:upper()] - VALOR[m.peca:upper()]) or 0)
                + (m.promo and VALOR[m.promo:upper()] or 0)
    end
    table.sort(ms, function(a, b) return a.ordem > b.ordem end)
end

local ctx

local function negamax(e, prof, alfa, beta, ply)
    ctx.nos = ctx.nos + 1
    if ctx.nos % 400 == 0 then
        if ctx.yield then coroutine.yield() end
        if ctx.prazo and ctx.agora() > ctx.prazo then ctx.abortou = true end
    end
    if ctx.abortou then return 0 end
    local ms = R.legais(e)
    if #ms == 0 then return R.emXeque(e, e.vez) and (-MATE + ply) or 0 end
    if e.meio >= 100 or R.materialInsuficiente(e) then return 0 end
    if prof == 0 then return IA.avaliar(e) end
    ordenar(ms)
    for _, m in ipairs(ms) do
        local v = -negamax(R.aplicar(e, m), prof - 1, -beta, -alfa, ply + 1)
        if ctx.abortou then return 0 end
        if v >= beta then return beta end
        if v > alfa then alfa = v end
    end
    return alfa
end

-- exato = true avalia cada lance da raiz sem poda (usado no fácil para sortear entre lances bons).
local function raiz(e, prof, ms, exato)
    local melhor, melhorV, alfa, avaliados = nil, -math.huge, -math.huge, {}
    for _, m in ipairs(ms) do
        local v = -negamax(R.aplicar(e, m), prof - 1, -math.huge, exato and math.huge or -alfa, 1)
        if ctx.abortou then return nil end
        avaliados[#avaliados + 1] = { m = m, v = v }
        if v > melhorV then melhor, melhorV = m, v end
        if v > alfa then alfa = v end
    end
    return melhor, melhorV, avaliados
end

-- opc: { yield = bool, agora = função de tempo em segundos (padrão os.clock) }
function IA.escolher(e, nivel, opc)
    opc = opc or {}
    local cfg = IA.NIVEIS[nivel]
    local ms = R.legais(e)
    if #ms == 0 then return nil end
    ordenar(ms)
    ctx = { nos = 0, yield = opc.yield, agora = opc.agora or os.clock, abortou = false }
    if cfg.tempo then ctx.prazo = ctx.agora() + cfg.tempo end

    if cfg.aleatorio then
        local _, melhorV, av = raiz(e, cfg.prof, ms, true)
        local cand = {}
        for _, a in ipairs(av) do if a.v >= melhorV - cfg.aleatorio then cand[#cand + 1] = a.m end end
        return cand[math.random(#cand)]
    end

    local escolhido = ms[1]
    for p = 1, cfg.prof do
        local m = raiz(e, p, ms, false)
        if not m then break end   -- tempo acabou: fica com a última profundidade completa
        escolhido = m
        for i, x in ipairs(ms) do
            if x == m then table.remove(ms, i); table.insert(ms, 1, m); break end
        end
    end
    return escolhido
end

return IA
