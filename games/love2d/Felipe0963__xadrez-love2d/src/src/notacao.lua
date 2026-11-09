-- Notação algébrica em português: R (rei), D (dama), T (torre), B (bispo), C (cavalo).
local T = require("src.tabuleiro")
local R = require("src.regras")
local Notacao = {}

local NOMES = { K = "R", Q = "D", R = "T", B = "B", N = "C" }

-- e: estado ANTES do lance; legais: R.legais(e)
function Notacao.lance(e, m, legais)
    local txt
    if m.roque then
        txt = m.roque == "K" and "O-O" or "O-O-O"
    else
        local t = m.peca:upper()
        local destino = T.nome(m.para)
        if t == "P" then
            txt = m.captura and (string.char(96 + T.col(m.de)) .. "x" .. destino) or destino
            if m.promo then txt = txt .. "=" .. NOMES[m.promo:upper()] end
        else
            local amb, mesmaCol, mesmaLin = false, false, false
            for _, o in ipairs(legais) do
                if o.peca == m.peca and o.para == m.para and o.de ~= m.de then
                    amb = true
                    if T.col(o.de) == T.col(m.de) then mesmaCol = true end
                    if T.lin(o.de) == T.lin(m.de) then mesmaLin = true end
                end
            end
            local d = ""
            if amb then
                if not mesmaCol then d = string.char(96 + T.col(m.de))
                elseif not mesmaLin then d = tostring(T.lin(m.de))
                else d = T.nome(m.de) end
            end
            txt = NOMES[t] .. d .. (m.captura and "x" or "") .. destino
        end
    end
    local n = R.aplicar(e, m)
    if R.emXeque(n, n.vez) then
        txt = txt .. (#R.legais(n) == 0 and "#" or "+")
    end
    return txt
end

return Notacao
