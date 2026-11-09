-- Regras do xadrez: geração de lances, ataques, aplicação de lance e fim de partida.
local T = require("src.tabuleiro")
local R = {}

local col, lin = T.col, T.lin
local CAVALO = { { 1, 2 }, { 2, 1 }, { -1, 2 }, { -2, 1 }, { 1, -2 }, { 2, -1 }, { -1, -2 }, { -2, -1 } }
local REI = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
local RETAS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
local DIAG = { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
local PROMOS = { "Q", "R", "B", "N" }

function R.outra(cor) return cor == "brancas" and "pretas" or "brancas" end

local function desloc(c, dc, dl)
    local nc, nl = col(c) + dc, lin(c) + dl
    if nc < 1 or nc > 8 or nl < 1 or nl > 8 then return nil end
    return T.casa(nc, nl)
end
R.desloc = desloc

-- A casa c é atacada por alguma peça da cor `por`?
function R.atacada(e, c, por)
    local s = e.casas
    local b = por == "brancas"
    local function letra(x) return b and x or x:lower() end
    local dl = b and -1 or 1
    for _, dc in ipairs({ -1, 1 }) do
        local o = desloc(c, dc, dl)
        if o and s[o] == letra("P") then return true end
    end
    for _, d in ipairs(CAVALO) do
        local o = desloc(c, d[1], d[2])
        if o and s[o] == letra("N") then return true end
    end
    for _, d in ipairs(REI) do
        local o = desloc(c, d[1], d[2])
        if o and s[o] == letra("K") then return true end
    end
    local function raio(dirs, p1, p2)
        for _, d in ipairs(dirs) do
            local o = desloc(c, d[1], d[2])
            while o do
                local p = s[o]
                if p ~= "." then
                    if p == p1 or p == p2 then return true end
                    break
                end
                o = desloc(o, d[1], d[2])
            end
        end
        return false
    end
    return raio(RETAS, letra("R"), letra("Q")) or raio(DIAG, letra("B"), letra("Q"))
end

function R.reiCasa(e, cor)
    local k = cor == "brancas" and "K" or "k"
    for c = 1, 64 do if e.casas[c] == k then return c end end
end

function R.emXeque(e, cor)
    local c = R.reiCasa(e, cor)
    return c ~= nil and R.atacada(e, c, R.outra(cor))
end

local function add(lista, e, de, para, extra)
    local alvo = e.casas[para]
    local m = { de = de, para = para, peca = e.casas[de], captura = alvo ~= "." and alvo or nil }
    if extra then for k, v in pairs(extra) do m[k] = v end end
    lista[#lista + 1] = m
end

-- Lances sem checar se o próprio rei fica em xeque (o roque já é checado aqui).
function R.pseudo(e)
    local s, lista, cor = e.casas, {}, e.vez
    local b = cor == "brancas"
    for c = 1, 64 do
        local p = s[c]
        if p ~= "." and T.cor(p) == cor then
            local t = p:upper()
            if t == "P" then
                local dir = b and 1 or -1
                local linPromo = b and 8 or 1
                local function addPeao(para)
                    if lin(para) == linPromo then
                        for _, pr in ipairs(PROMOS) do add(lista, e, c, para, { promo = b and pr or pr:lower() }) end
                    else
                        add(lista, e, c, para)
                    end
                end
                local f = desloc(c, 0, dir)
                if f and s[f] == "." then
                    addPeao(f)
                    if lin(c) == (b and 2 or 7) then
                        local f2 = desloc(f, 0, dir)
                        if s[f2] == "." then add(lista, e, c, f2, { duplo = true }) end
                    end
                end
                for _, dc in ipairs({ -1, 1 }) do
                    local a = desloc(c, dc, dir)
                    if a then
                        if s[a] ~= "." and T.cor(s[a]) ~= cor then
                            addPeao(a)
                        elseif a == e.ep then
                            add(lista, e, c, a, { ep = true, captura = b and "p" or "P" })
                        end
                    end
                end
            elseif t == "N" or t == "K" then
                for _, d in ipairs(t == "N" and CAVALO or REI) do
                    local o = desloc(c, d[1], d[2])
                    if o and T.cor(s[o]) ~= cor then add(lista, e, c, o) end
                end
            else
                local dirs = (t == "R" and RETAS) or (t == "B" and DIAG) or REI
                for _, d in ipairs(dirs) do
                    local o = desloc(c, d[1], d[2])
                    while o do
                        if s[o] == "." then
                            add(lista, e, c, o)
                        else
                            if T.cor(s[o]) ~= cor then add(lista, e, c, o) end
                            break
                        end
                        o = desloc(o, d[1], d[2])
                    end
                end
            end
        end
    end
    -- roque
    local adv = R.outra(cor)
    local l = b and 1 or 8
    local rei = T.casa(5, l)
    if s[rei] == (b and "K" or "k") and not R.atacada(e, rei, adv) then
        local torre = b and "R" or "r"
        local function livre(...) for _, x in ipairs({ ... }) do if s[T.casa(x, l)] ~= "." then return false end end return true end
        local function segura(...) for _, x in ipairs({ ... }) do if R.atacada(e, T.casa(x, l), adv) then return false end end return true end
        if e.roque[b and "K" or "k"] and s[T.casa(8, l)] == torre and livre(6, 7) and segura(6, 7) then
            add(lista, e, rei, T.casa(7, l), { roque = "K" })
        end
        if e.roque[b and "Q" or "q"] and s[T.casa(1, l)] == torre and livre(2, 3, 4) and segura(3, 4) then
            add(lista, e, rei, T.casa(3, l), { roque = "Q" })
        end
    end
    return lista
end

-- Devolve um NOVO estado com o lance aplicado.
function R.aplicar(e, m)
    local n = T.copiar(e)
    local s = n.casas
    local b = e.vez == "brancas"
    s[m.para] = m.promo or m.peca
    s[m.de] = "."
    if m.ep then s[desloc(m.para, 0, b and -1 or 1)] = "." end
    if m.roque then
        local l = b and 1 or 8
        if m.roque == "K" then
            s[T.casa(6, l)], s[T.casa(8, l)] = s[T.casa(8, l)], "."
        else
            s[T.casa(4, l)], s[T.casa(1, l)] = s[T.casa(1, l)], "."
        end
    end
    local r = n.roque
    if m.peca == "K" then r.K, r.Q = false, false elseif m.peca == "k" then r.k, r.q = false, false end
    local function tocou(c)
        if c == 1 then r.Q = false elseif c == 8 then r.K = false
        elseif c == 57 then r.q = false elseif c == 64 then r.k = false end
    end
    tocou(m.de); tocou(m.para)
    n.ep = m.duplo and desloc(m.de, 0, b and 1 or -1) or nil
    n.meio = (m.peca:upper() == "P" or m.captura) and 0 or e.meio + 1
    if not b then n.numero = e.numero + 1 end
    n.vez = R.outra(e.vez)
    return n
end

function R.legais(e)
    local out = {}
    for _, m in ipairs(R.pseudo(e)) do
        if not R.emXeque(R.aplicar(e, m), e.vez) then out[#out + 1] = m end
    end
    return out
end

function R.perft(e, d)
    local ms = R.legais(e)
    if d == 1 then return #ms end
    local n = 0
    for _, m in ipairs(ms) do n = n + R.perft(R.aplicar(e, m), d - 1) end
    return n
end

local function corCasa(c) return (col(c) + lin(c)) % 2 end

function R.materialInsuficiente(e)
    local pecas = {}
    for c = 1, 64 do
        local p = e.casas[c]
        if p ~= "." and p:upper() ~= "K" then pecas[#pecas + 1] = { p = p, c = c } end
    end
    if #pecas == 0 then return true end
    if #pecas == 1 then
        local t = pecas[1].p:upper()
        return t == "B" or t == "N"
    end
    if #pecas == 2 and pecas[1].p:upper() == "B" and pecas[2].p:upper() == "B"
        and T.cor(pecas[1].p) ~= T.cor(pecas[2].p) then
        return corCasa(pecas[1].c) == corCasa(pecas[2].c)
    end
    return false
end

function R.soRei(e, cor)
    for c = 1, 64 do
        local p = e.casas[c]
        if p ~= "." and T.cor(p) == cor and p:upper() ~= "K" then return false end
    end
    return true
end

-- "mate" | "afogamento" | "material" | "cinquenta" | nil (repetição é tratada em Partida)
function R.situacao(e, legais)
    legais = legais or R.legais(e)
    if #legais == 0 then return R.emXeque(e, e.vez) and "mate" or "afogamento" end
    if R.materialInsuficiente(e) then return "material" end
    if e.meio >= 100 then return "cinquenta" end
    return nil
end

return R
