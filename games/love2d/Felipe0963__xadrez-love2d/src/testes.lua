-- Testes em Lua puro. Rodar: lovec.exe . --testes
local T = require("src.tabuleiro")
local R = require("src.regras")
local Notacao = require("src.notacao")
local Partida = require("src.partida")
local Relogio = require("src.relogio")
local IA = require("src.ia")
local falhas, total = 0, 0

local function teste(nome, f)
    total = total + 1
    local t0 = os.clock()
    local ok, err = pcall(f)
    if ok then
        print(string.format("ok    %s (%.2fs)", nome, os.clock() - t0))
    else
        falhas = falhas + 1
        print("FALHA " .. nome .. ": " .. tostring(err))
    end
end

local function igual(obtido, esperado, msg)
    if obtido ~= esperado then
        error((msg or "valor") .. ": esperado " .. tostring(esperado) .. ", obtido " .. tostring(obtido), 2)
    end
end

teste("tabuleiro: coordenadas", function()
    igual(T.casa(1, 1), 1); igual(T.casa(8, 8), 64)
    igual(T.nome(T.casa(5, 4)), "e4")
    igual(T.deNome("h8"), 64)
end)

teste("tabuleiro: FEN inicial", function()
    local e = T.novo()
    igual(e.casas[T.deNome("e1")], "K"); igual(e.casas[T.deNome("d8")], "q")
    igual(e.casas[T.deNome("e4")], ".")
    igual(e.vez, "brancas"); igual(e.roque.K and e.roque.q, true)
    igual(e.ep, nil); igual(e.meio, 0); igual(e.numero, 1)
end)

teste("tabuleiro: FEN com en passant e cópia independente", function()
    local e = T.deFEN("4k3/8/8/3pP3/8/8/8/4K3 w - d6 3 40")
    igual(e.ep, T.deNome("d6")); igual(e.meio, 3); igual(e.numero, 40)
    igual(e.roque.K, false)
    local c = T.copiar(e)
    c.casas[1] = "Q"; c.roque.K = true
    igual(e.casas[1], "."); igual(e.roque.K, false)
    igual(T.chave(e, true) == T.chave(e, false), false)
end)

local POS = {
    inicial  = T.INICIAL,
    kiwipete = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
    pos3     = "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
    pos4     = "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1",
}
local PERFT = {
    { "inicial", { 20, 400, 8902, 197281 } },
    { "kiwipete", { 48, 2039, 97862 } },
    { "pos3", { 14, 191, 2812, 43238 } },
    { "pos4", { 6, 264, 9467 } },
}
for _, caso in ipairs(PERFT) do
    teste("perft " .. caso[1], function()
        local e = T.deFEN(POS[caso[1]])
        for d, esperado in ipairs(caso[2]) do
            igual(R.perft(e, d), esperado, caso[1] .. " profundidade " .. d)
        end
    end)
end

local function acharLance(e, uci)
    local de, para, promo = T.deNome(uci:sub(1, 2)), T.deNome(uci:sub(3, 4)), uci:sub(5, 5)
    for _, m in ipairs(R.legais(e)) do
        if m.de == de and m.para == para and (promo == "" or (m.promo and m.promo:lower() == promo)) then return m end
    end
    error("lance ilegal: " .. uci, 2)
end

teste("fim: afogamento", function()
    igual(R.situacao(T.deFEN("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")), "afogamento")
end)
teste("fim: material insuficiente", function()
    igual(R.situacao(T.deFEN("8/8/4k3/8/8/2K5/8/8 w - - 0 1")), "material")
    igual(R.situacao(T.deFEN("8/8/4k3/8/8/2K5/8/2B5 w - - 0 1")), "material")
    igual(R.situacao(T.deFEN("8/8/4k3/8/8/2K5/8/2N5 w - - 0 1")), "material")
    igual(R.situacao(T.deFEN("5b2/8/4k3/8/8/2K5/8/2B5 w - - 0 1")), "material")   -- bispos mesma cor
    igual(R.situacao(T.deFEN("2b5/8/4k3/8/8/2K5/8/2B5 w - - 0 1")), nil)          -- cores diferentes
    igual(R.situacao(T.deFEN("8/8/4k3/8/8/2K5/8/R7 w - - 0 1")), nil)
end)
teste("fim: regra dos 50 lances", function()
    igual(R.situacao(T.deFEN("8/8/4k3/8/8/2K5/8/R7 w - - 100 80")), "cinquenta")
end)
teste("fim: xeque-mate e en passant", function()
    local e = T.deFEN("6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1")
    igual(R.situacao(R.aplicar(e, acharLance(e, "a1a8"))), "mate")
    local e2 = T.deFEN("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
    local n = R.aplicar(e2, acharLance(e2, "e5d6"))
    igual(n.casas[T.deNome("d5")], "."); igual(n.casas[T.deNome("d6")], "P")
end)

local function san(fen, uci)
    local e = T.deFEN(fen)
    return Notacao.lance(e, acharLance(e, uci), R.legais(e))
end
teste("notação", function()
    igual(san(T.INICIAL, "g1f3"), "Cf3")
    igual(san(T.INICIAL, "e2e4"), "e4")
    igual(san(POS.kiwipete, "e1g1"), "O-O")
    igual(san(POS.kiwipete, "e1c1"), "O-O-O")
    igual(san(POS.kiwipete, "d5e6"), "dxe6")
    igual(san("4k3/8/8/8/8/8/4K3/R6R w - - 0 1", "a1d1"), "Tad1")
    igual(san("4k3/8/8/R7/8/8/4K3/R7 w - - 0 1", "a1a3"), "T1a3")
    igual(san("8/P6k/8/8/8/8/8/K7 w - - 0 1", "a7a8q"), "a8=D")
    igual(san("8/P6k/8/8/8/8/8/K7 w - - 0 1", "a7a8n"), "a8=C")
    igual(san("4k3/8/8/8/8/8/8/R3K3 w - - 0 1", "a1a8"), "Ta8+")
    igual(san("6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1", "a1a8"), "Ta8#")
    igual(san("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1", "e5d6"), "exd6")
end)

local function jogar(p, uci)
    local de, para, promo = T.deNome(uci:sub(1, 2)), T.deNome(uci:sub(3, 4)), uci:sub(5, 5)
    for _, m in ipairs(p.legais) do
        if m.de == de and m.para == para and (promo == "" or (m.promo and m.promo:lower() == promo)) then
            return p:jogar(m)
        end
    end
    error("lance ilegal: " .. uci, 2)
end

teste("partida: mate do pastor", function()
    local p = Partida.nova({ modo = "dois" })
    local ultimo
    for _, u in ipairs({ "e2e4", "e7e5", "f1c4", "b8c6", "d1h5", "g8f6", "h5f7" }) do ultimo = jogar(p, u) end
    igual(ultimo, "Dxf7#")
    igual(p.resultado.vencedor, "brancas"); igual(p.resultado.motivo, "xeque-mate")
end)

teste("partida: repetição tripla", function()
    local p = Partida.nova({ modo = "dois" })
    for _ = 1, 2 do
        for _, u in ipairs({ "g1f3", "g8f6", "f3g1", "f6g8" }) do jogar(p, u) end
    end
    igual(p.resultado and p.resultado.motivo, "repetição tripla")
end)

teste("partida: desfazer", function()
    local p = Partida.nova({ modo = "dois" })
    jogar(p, "e2e4"); jogar(p, "e7e5")
    p:desfazer()
    igual(#p.historico, 1); igual(p.estado.vez, "pretas")
    local q = Partida.nova({ modo = "ia", corHumano = "brancas", nivel = "facil" })
    jogar(q, "e2e4"); jogar(q, "e7e5")
    q:desfazer()   -- contra IA volta 2 lances
    igual(#q.historico, 0); igual(T.chave(q.estado), T.chave(T.novo()))
    igual(#q.legais, 20)
end)

teste("partida: tempo esgotado", function()
    local p = Partida.nova({ modo = "dois", minutos = 1 })
    p:atualizar(30); igual(p.resultado, nil)
    p:atualizar(31)
    igual(p.resultado.vencedor, "pretas"); igual(p.resultado.motivo, "tempo esgotado")
    local q = Partida.nova({ modo = "dois", minutos = 1, fen = "4k3/8/8/8/8/8/8/R3K3 w - - 0 1" })
    q:atualizar(61)
    igual(q.resultado.vencedor, nil)
    igual(Relogio.formatar(65.2), "1:06")
end)

teste("IA: encontra mate em 1 (todos os níveis exceto fácil)", function()
    local e = T.deFEN("6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1")
    for _, nivel in ipairs({ "medio", "dificil" }) do
        local m = IA.escolher(e, nivel)
        igual(T.nome(m.de) .. T.nome(m.para), "a1a8", nivel)
    end
end)
teste("IA: captura dama de graça e respeita o tempo", function()
    local e = T.deFEN("4k3/8/8/3q4/8/8/3R4/4K3 w - - 0 1")
    igual(T.nome(IA.escolher(e, "medio").para), "d5")
    local t0 = os.clock()
    local m = IA.escolher(T.novo(), "dificil")
    igual(m ~= nil, true)
    igual(os.clock() - t0 < 3, true, "tempo do nível difícil")
    igual(IA.escolher(T.novo(), "facil") ~= nil, true)
end)
teste("IA: avaliação simétrica", function()
    igual(IA.avaliar(T.novo()), 0)
end)

-- TESTES AQUI

teste("sanidade", function() igual(1 + 1, 2) end)

print(string.format("\n%d/%d testes passaram", total - falhas, total))
return falhas == 0
