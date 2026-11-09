-- Xadrez em Lua + LÖVE
-- Telas: menu -> jogo (com diálogos de promoção e de fim de partida)

local T = require("src.tabuleiro")
local R = require("src.regras")
local IA = require("src.ia")
local Partida = require("src.partida")
local Relogio = require("src.relogio")
local Pecas = require("src.pecas")
local Sons = require("src.sons")

local W = 1000
local CASA = 80
local BX, BY = 30, 30      -- canto do tabuleiro
local PX, PW = 690, 290    -- painel lateral

local COR = {
    fundo    = { 0.08, 0.09, 0.14 },
    painel   = { 0.14, 0.16, 0.24 },
    botao    = { 0.20, 0.23, 0.34 },
    hover    = { 0.30, 0.35, 0.52 },
    texto    = { 0.95, 0.95, 0.97 },
    suave    = { 0.58, 0.62, 0.72 },
    destaque = { 1.00, 0.78, 0.30 },
    erro     = { 0.92, 0.36, 0.40 },
    clara    = { 0.86, 0.82, 0.74 },
    escura   = { 0.45, 0.52, 0.62 },
    ultimo   = { 1.00, 0.85, 0.35, 0.45 },
    selecao  = { 0.32, 0.78, 0.52, 0.55 },
    marca    = { 0.10, 0.10, 0.10, 0.35 },
}

local testando = false
local fonte = {}
local tela = "menu"
local opcoes = { modo = "ia", cor = "brancas", nivel = "medio", relogio = 0 }
local partida, selecionada, destinos, promocao, pensando
local esperaIA, rolagem, somFim = 0, 0, false
local botoes = {}

---------------------------------------------------------------- utilidades
local function dentro(mx, my, b) return mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h end

local function botao(texto, x, y, w, h, acao, opc)
    opc = opc or {}
    local mx, my = love.mouse.getPosition()
    local b = { x = x, y = y, w = w, h = h, acao = acao }
    local hover = not opc.desabilitado and dentro(mx, my, b)
    local cor = opc.selecionado and COR.destaque or (hover and COR.hover or COR.botao)
    love.graphics.setColor(cor[1], cor[2], cor[3], opc.desabilitado and 0.4 or 1)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    local f = opc.fonte or fonte.media
    love.graphics.setFont(f)
    love.graphics.setColor(opc.selecionado and COR.fundo or COR.texto)
    if opc.desabilitado then love.graphics.setColor(COR.suave) end
    love.graphics.print(texto, x + (w - f:getWidth(texto)) / 2, y + (h - f:getHeight()) / 2)
    if not opc.desabilitado then botoes[#botoes + 1] = b end
end

local function centralizado(texto, f, y, cor)
    love.graphics.setFont(f); love.graphics.setColor(cor or COR.texto)
    love.graphics.print(texto, (W - f:getWidth(texto)) / 2, y)
end

local function nomeCor(c) return c == "brancas" and "Brancas" or "Pretas" end

local function girado() return partida and partida.cfg.modo == "ia" and partida.cfg.corHumano == "pretas" end

local function posCasa(c)
    local col, lin = T.col(c), T.lin(c)
    if girado() then col, lin = 9 - col, 9 - lin end
    return BX + (col - 1) * CASA, BY + (8 - lin) * CASA
end

local function casaEm(x, y)
    local col = math.floor((x - BX) / CASA) + 1
    local lin = 8 - math.floor((y - BY) / CASA)
    if col < 1 or col > 8 or lin < 1 or lin > 8 then return nil end
    if girado() then col, lin = 9 - col, 9 - lin end
    return T.casa(col, lin)
end

---------------------------------------------------------------- ações
local function novaPartida()
    local cor = opcoes.cor
    if cor == "aleatoria" then cor = math.random(2) == 1 and "brancas" or "pretas" end
    partida = Partida.nova({ modo = opcoes.modo, corHumano = cor, nivel = opcoes.nivel,
                             minutos = opcoes.relogio > 0 and opcoes.relogio or nil })
    selecionada, destinos, promocao, pensando = nil, {}, nil, nil
    esperaIA, rolagem, somFim = 0, 0, false
    tela = "jogo"
end

local function executar(m)
    local san = partida:jogar(m)
    selecionada, destinos, rolagem = nil, {}, 0
    if partida.resultado then return end   -- o som de fim é tocado no update
    if san:find("[+#]") then Sons.tocar("xeque")
    elseif m.roque or m.promo then Sons.tocar("especial")
    elseif m.captura then Sons.tocar("captura")
    else Sons.tocar("lance") end
end

local function podeDesfazer()
    if not partida or pensando or promocao then return false end
    if partida.cfg.modo == "ia" then
        -- precisa haver um lance do humano para desfazer, e não durante a vez da IA
        local minimo = partida.cfg.corHumano == "pretas" and 2 or 1
        return #partida.historico >= minimo and not partida:vezDaIA()
    end
    return #partida.historico > 0
end

local function desfazer()
    if not podeDesfazer() then return end
    partida:desfazer()
    selecionada, destinos, esperaIA, somFim = nil, {}, 0, false
end

local function desistir()
    local cor = partida.cfg.modo == "ia" and partida.cfg.corHumano or partida.estado.vez
    partida:desistir(cor)
    pensando, promocao = nil, nil
end

local function cliqueTabuleiro(x, y)
    if partida.resultado or promocao or partida:vezDaIA() then return end
    local c = casaEm(x, y)
    if not c then return end
    if selecionada then
        local possiveis = {}
        for _, m in ipairs(destinos) do if m.para == c then possiveis[#possiveis + 1] = m end end
        if #possiveis == 1 then executar(possiveis[1]) return end
        if #possiveis > 1 then promocao = possiveis return end   -- 4 opções de promoção
    end
    local p = partida.estado.casas[c]
    if p ~= "." and T.cor(p) == partida.estado.vez then
        selecionada, destinos = c, partida:lancesDe(c)
    else
        selecionada, destinos = nil, {}
    end
end

---------------------------------------------------------------- desenho: menu
local function grupo(titulo, y, itens, chave)
    love.graphics.setFont(fonte.media); love.graphics.setColor(COR.suave)
    love.graphics.print(titulo, 250, y)
    local w = 500 / #itens
    for i, it in ipairs(itens) do
        botao(it[2], 250 + (i - 1) * w + 4, y + 28, w - 8, 44,
              function() opcoes[chave] = it[1] end, { selecionado = opcoes[chave] == it[1] })
    end
end

local function desenharMenu()
    Pecas.desenhar("K", 300, 30, 80)
    Pecas.desenhar("k", 620, 30, 80)
    centralizado("Xadrez", fonte.titulo, 45)
    grupo("Modo", 150, { { "ia", "Contra IA" }, { "dois", "2 jogadores" } }, "modo")
    if opcoes.modo == "ia" then
        grupo("Suas peças", 250, { { "brancas", "Brancas" }, { "pretas", "Pretas" }, { "aleatoria", "Aleatória" } }, "cor")
        grupo("Dificuldade", 350, { { "facil", "Fácil" }, { "medio", "Médio" }, { "dificil", "Difícil" } }, "nivel")
    end
    grupo("Relógio", 450, { { 0, "Sem relógio" }, { 5, "5 min" }, { 10, "10 min" } }, "relogio")
    botao("Jogar", 400, 570, 200, 56, novaPartida, { fonte = fonte.grande })
    centralizado("Z desfaz  ·  M liga/desliga o som  ·  Esc volta ao menu", fonte.pequena, 660, COR.suave)
end

---------------------------------------------------------------- desenho: jogo
local function desenharTabuleiro()
    local e = partida.estado
    local h = partida.historico[#partida.historico]
    local ultimo = h and h.lance
    local reiXeque = R.emXeque(e, e.vez) and R.reiCasa(e, e.vez) or nil

    for c = 1, 64 do
        local x, y = posCasa(c)
        love.graphics.setColor((T.col(c) + T.lin(c)) % 2 == 1 and COR.clara or COR.escura)
        love.graphics.rectangle("fill", x, y, CASA, CASA)
        if ultimo and (c == ultimo.de or c == ultimo.para) then
            love.graphics.setColor(COR.ultimo); love.graphics.rectangle("fill", x, y, CASA, CASA)
        end
        if c == selecionada then
            love.graphics.setColor(COR.selecao); love.graphics.rectangle("fill", x, y, CASA, CASA)
        end
        if c == reiXeque then
            love.graphics.setColor(COR.erro[1], COR.erro[2], COR.erro[3], 0.75)
            love.graphics.circle("fill", x + CASA / 2, y + CASA / 2, CASA * 0.48)
        end
    end

    for c = 1, 64 do
        local p = e.casas[c]
        if p ~= "." then
            local x, y = posCasa(c)
            Pecas.desenhar(p, x, y, CASA)
        end
    end

    local vistos = {}
    for _, m in ipairs(destinos) do
        if not vistos[m.para] then
            vistos[m.para] = true
            local x, y = posCasa(m.para)
            love.graphics.setColor(COR.marca)
            if m.captura then
                love.graphics.setLineWidth(6)
                love.graphics.circle("line", x + CASA / 2, y + CASA / 2, CASA * 0.44)
                love.graphics.setLineWidth(1)
            else
                love.graphics.circle("fill", x + CASA / 2, y + CASA / 2, CASA * 0.15)
            end
        end
    end

    love.graphics.setFont(fonte.pequena); love.graphics.setColor(COR.suave)
    for i = 1, 8 do
        local col = girado() and 9 - i or i
        love.graphics.print(string.char(96 + col), BX + (i - 1) * CASA + CASA / 2 - 4, BY + 8 * CASA + 4)
        local lin = girado() and i or 9 - i
        love.graphics.print(tostring(lin), BX - 18, BY + (i - 1) * CASA + CASA / 2 - 8)
    end
end

local function desenharRelogio(cor, y)
    local ativo = partida.estado.vez == cor and not partida.resultado
    love.graphics.setColor(ativo and COR.hover or COR.botao)
    love.graphics.rectangle("fill", PX, y, PW, 56, 8, 8)
    Pecas.desenhar(cor == "brancas" and "K" or "k", PX + 4, y + 4, 48)
    local rotulo = nomeCor(cor)
    if partida.cfg.modo == "ia" then rotulo = rotulo .. (cor == partida.cfg.corHumano and " · você" or " · IA") end
    love.graphics.setFont(fonte.media); love.graphics.setColor(COR.texto)
    love.graphics.print(rotulo, PX + 58, y + 17)
    if partida.relogio.ativo then
        local seg = partida.relogio.tempo[cor]
        local t = Relogio.formatar(seg)
        love.graphics.setFont(fonte.grande)
        love.graphics.setColor(seg < 30 and COR.erro or COR.texto)
        love.graphics.print(t, PX + PW - 10 - fonte.grande:getWidth(t), y + 12)
    end
end

local function desenharHistorico(y0, altura)
    love.graphics.setColor(COR.painel)
    love.graphics.rectangle("fill", PX, y0, PW, altura, 8, 8)
    love.graphics.setFont(fonte.media)
    local h, linhas, i = partida.historico, {}, 1
    while i <= #h do
        local num = h[i].estado.numero
        if h[i].estado.vez == "brancas" then
            linhas[#linhas + 1] = { num, h[i].san, h[i + 1] and h[i + 1].san }
            i = i + 2
        else
            linhas[#linhas + 1] = { num, "...", h[i].san }
            i = i + 1
        end
    end
    if #linhas == 0 then
        love.graphics.setColor(COR.suave)
        love.graphics.print("Nenhum lance ainda", PX + 12, y0 + 10)
        return
    end
    local lh = 26
    local cabem = math.floor((altura - 16) / lh)
    rolagem = math.min(rolagem, math.max(0, #linhas - cabem))
    local primeiro = math.max(1, #linhas - cabem + 1 - rolagem)
    for k = 0, cabem - 1 do
        local l = linhas[primeiro + k]
        if not l then break end
        local y = y0 + 8 + k * lh
        love.graphics.setColor(COR.suave); love.graphics.print(l[1] .. ".", PX + 12, y)
        love.graphics.setColor(COR.texto); love.graphics.print(l[2], PX + 70, y)
        if l[3] then love.graphics.print(l[3], PX + 180, y) end
    end
end

local function desenharPainel()
    local topo = girado() and "brancas" or "pretas"
    desenharRelogio(topo, 30)
    desenharHistorico(100, 420)
    desenharRelogio(topo == "brancas" and "pretas" or "brancas", 534)

    local status = {}
    if partida:vezDaIA() then status[#status + 1] = "IA pensando…" end
    if Sons.mudo then status[#status + 1] = "som desligado" end
    love.graphics.setFont(fonte.pequena); love.graphics.setColor(COR.suave)
    love.graphics.print(table.concat(status, "  ·  "), PX, 596)

    botao("Desfazer", PX, 620, 90, 44, desfazer, { desabilitado = not podeDesfazer(), fonte = fonte.pequena })
    botao("Desistir", PX + 100, 620, 90, 44, desistir, { desabilitado = partida.resultado ~= nil or promocao ~= nil, fonte = fonte.pequena })
    botao("Menu", PX + 200, 620, 90, 44, function() tela = "menu"; pensando = nil end, { fonte = fonte.pequena })
end

local function sombraTabuleiro()
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", BX, BY, 8 * CASA, 8 * CASA)
end

local function desenharPromocao()
    sombraTabuleiro()
    local w = 4 * 90 + 30
    local x0, y0 = BX + (8 * CASA - w) / 2, BY + 4 * CASA - 80
    love.graphics.setColor(COR.painel); love.graphics.rectangle("fill", x0, y0, w, 160, 12, 12)
    love.graphics.setFont(fonte.media); love.graphics.setColor(COR.texto)
    local t = "Promover para:"
    love.graphics.print(t, x0 + (w - fonte.media:getWidth(t)) / 2, y0 + 12)
    for i, m in ipairs(promocao) do
        local bx = x0 + 20 + (i - 1) * 90
        botao("", bx, y0 + 46, 80, 96, function() promocao = nil; executar(m) end)
        Pecas.desenhar(m.promo, bx, y0 + 54, 80)
    end
end

local function desenharFim()
    local r = partida.resultado
    local titulo
    if not r.vencedor then titulo = "Empate"
    elseif partida.cfg.modo == "ia" then titulo = r.vencedor == partida.cfg.corHumano and "Você venceu!" or "A IA venceu"
    else titulo = nomeCor(r.vencedor) .. " vencem" end
    local w, h = 420, 190
    local x0, y0 = BX + (8 * CASA - w) / 2, BY + 4 * CASA - h / 2
    love.graphics.setColor(COR.painel[1], COR.painel[2], COR.painel[3], 0.96)
    love.graphics.rectangle("fill", x0, y0, w, h, 12, 12)
    love.graphics.setFont(fonte.grande); love.graphics.setColor(COR.destaque)
    love.graphics.print(titulo, x0 + (w - fonte.grande:getWidth(titulo)) / 2, y0 + 22)
    local sub = "por " .. r.motivo
    love.graphics.setFont(fonte.media); love.graphics.setColor(COR.suave)
    love.graphics.print(sub, x0 + (w - fonte.media:getWidth(sub)) / 2, y0 + 64)
    botao("Jogar de novo", x0 + 30, y0 + 116, 170, 48, novaPartida)
    botao("Menu", x0 + 220, y0 + 116, 170, 48, function() tela = "menu" end)
end

---------------------------------------------------------------- callbacks LÖVE
function love.load(args)
    for _, a in ipairs(args or {}) do
        if a == "--testes" then
            testando = true
            -- pcall: sem janela, um erro não tratado deixaria o processo preso na tela de erro
            local exec, ok = pcall(require, "testes")
            if not exec then print("ERRO: " .. tostring(ok)) end
            love.event.quit((exec and ok) and 0 or 1)
            return
        end
    end
    math.randomseed(os.time())
    love.graphics.setBackgroundColor(COR.fundo)
    fonte.titulo = love.graphics.newFont(48)
    fonte.grande = love.graphics.newFont(26)
    fonte.media = love.graphics.newFont(18)
    fonte.pequena = love.graphics.newFont(14)
    Sons.carregar()
end

function love.update(dt)
    if testando or tela ~= "jogo" then return end
    partida.pausado = promocao ~= nil
    partida:atualizar(dt)

    if partida.resultado and not somFim then Sons.tocar("fim"); somFim = true end

    if not partida:vezDaIA() then
        pensando, esperaIA = nil, 0
        return
    end
    esperaIA = esperaIA + dt
    if not pensando and esperaIA >= 0.4 then   -- pequena pausa para o lance não parecer instantâneo
        local e, nivel = partida.estado, partida.cfg.nivel
        pensando = coroutine.create(function()
            return IA.escolher(e, nivel, { yield = true, agora = love.timer.getTime })
        end)
    end
    if pensando then
        local limite = love.timer.getTime() + 0.012
        repeat
            local ok, m = coroutine.resume(pensando)
            if not ok then error(m) end
            if coroutine.status(pensando) == "dead" then
                pensando, esperaIA = nil, 0
                if m then executar(m) end
                break
            end
        until love.timer.getTime() > limite
    end
end

function love.draw()
    if testando then return end
    botoes = {}
    if tela == "menu" then
        desenharMenu()
    else
        desenharTabuleiro()
        desenharPainel()
        if promocao then desenharPromocao() end
        if partida.resultado then desenharFim() end
    end
end

function love.mousepressed(x, y, b)
    if testando or b ~= 1 then return end
    for i = #botoes, 1, -1 do   -- o último desenhado está por cima
        if dentro(x, y, botoes[i]) then
            Sons.tocar("clique")
            botoes[i].acao()
            return
        end
    end
    if tela == "jogo" then cliqueTabuleiro(x, y) end
end

function love.keypressed(k)
    if testando then return end
    if k == "m" then Sons.mudo = not Sons.mudo end
    if tela == "jogo" then
        if k == "escape" then
            if promocao then promocao = nil else tela = "menu"; pensando = nil end
        elseif k == "z" then
            desfazer()
        end
    end
end

function love.wheelmoved(_, dy)
    if tela == "jogo" then rolagem = math.max(0, rolagem + dy) end
end
