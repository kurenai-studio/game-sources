-- Estado do tabuleiro: casas 1..64 (a1=1, h8=64), vez, roque, en passant, contadores.
local T = {}

T.INICIAL = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

function T.casa(col, lin) return (lin - 1) * 8 + col end
function T.col(c) return (c - 1) % 8 + 1 end
function T.lin(c) return math.floor((c - 1) / 8) + 1 end
function T.nome(c) return string.char(96 + T.col(c)) .. T.lin(c) end
function T.deNome(s) return T.casa(s:byte(1) - 96, tonumber(s:sub(2, 2))) end

function T.cor(p)
    if p == "." then return nil end
    return p:match("%u") and "brancas" or "pretas"
end

function T.deFEN(fen)
    local partes = {}
    for p in fen:gmatch("%S+") do partes[#partes + 1] = p end
    local e = { casas = {} }
    for i = 1, 64 do e.casas[i] = "." end
    local lin, col = 8, 1
    for ch in partes[1]:gmatch(".") do
        if ch == "/" then
            lin, col = lin - 1, 1
        elseif ch:match("%d") then
            col = col + tonumber(ch)
        else
            e.casas[T.casa(col, lin)] = ch
            col = col + 1
        end
    end
    e.vez = partes[2] == "b" and "pretas" or "brancas"
    local r = partes[3] or "-"
    e.roque = { K = r:find("K") ~= nil, Q = r:find("Q") ~= nil, k = r:find("k") ~= nil, q = r:find("q") ~= nil }
    e.ep = (partes[4] and partes[4] ~= "-") and T.deNome(partes[4]) or nil
    e.meio = tonumber(partes[5] or "0")
    e.numero = tonumber(partes[6] or "1")
    return e
end

function T.novo() return T.deFEN(T.INICIAL) end

function T.copiar(e)
    local c = {}
    for i = 1, 64 do c[i] = e.casas[i] end
    local r = e.roque
    return { casas = c, vez = e.vez, roque = { K = r.K, Q = r.Q, k = r.k, q = r.q },
             ep = e.ep, meio = e.meio, numero = e.numero }
end

-- Chave para repetição: posição + vez + roque (+ en passant só se a captura for possível).
function T.chave(e, comEp)
    local r = e.roque
    return table.concat(e.casas) .. e.vez
        .. (r.K and "K" or "") .. (r.Q and "Q" or "") .. (r.k and "k" or "") .. (r.q and "q" or "")
        .. ((comEp and e.ep) and tostring(e.ep) or "-")
end

return T
