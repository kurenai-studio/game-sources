-- Uma partida: estado atual, histórico, repetições, relógio, resultado e desfazer.
local T = require("src.tabuleiro")
local R = require("src.regras")
local Notacao = require("src.notacao")
local Relogio = require("src.relogio")

local Partida = {}
Partida.__index = Partida

local MOTIVOS = { afogamento = "afogamento", material = "material insuficiente", cinquenta = "regra dos 50 lances" }

-- cfg: { modo = "ia"|"dois", corHumano = "brancas"|"pretas", nivel = "facil"|"medio"|"dificil", minutos = nil|5|10, fen = nil }
function Partida.nova(cfg)
    local p = setmetatable({
        cfg = cfg,
        estado = cfg.fen and T.deFEN(cfg.fen) or T.novo(),
        historico = {},   -- { estado, lance, san, tempo }
        repeticoes = {},
        chaves = {},
        relogio = Relogio.novo(cfg.minutos),
        pausado = false,
        resultado = nil,  -- { vencedor = cor|nil, motivo = texto }
    }, Partida)
    p:registrar()
    return p
end

-- Atualiza lances legais, conta a repetição e verifica fim de partida.
function Partida:registrar()
    local e = self.estado
    self.legais = R.legais(e)
    local temEp = false
    for _, m in ipairs(self.legais) do if m.ep then temEp = true break end end
    local k = T.chave(e, temEp)
    self.repeticoes[k] = (self.repeticoes[k] or 0) + 1
    self.chaves[#self.chaves + 1] = k
    local sit = R.situacao(e, self.legais)
    if sit == "mate" then
        self.resultado = { vencedor = R.outra(e.vez), motivo = "xeque-mate" }
    elseif sit then
        self.resultado = { motivo = MOTIVOS[sit] }
    elseif self.repeticoes[k] >= 3 then
        self.resultado = { motivo = "repetição tripla" }
    end
end

function Partida:vezDaIA()
    return self.cfg.modo == "ia" and not self.resultado and self.estado.vez ~= self.cfg.corHumano
end

function Partida:lancesDe(casa)
    local out = {}
    for _, m in ipairs(self.legais) do if m.de == casa then out[#out + 1] = m end end
    return out
end

function Partida:jogar(m)
    local antes = self.estado
    local san = Notacao.lance(antes, m, self.legais)
    self.historico[#self.historico + 1] = { estado = antes, lance = m, san = san, tempo = self.relogio:copia() }
    self.estado = R.aplicar(antes, m)
    self:registrar()
    return san
end

function Partida:desfazer()
    local n = 1
    if self.cfg.modo == "ia" and self.estado.vez == self.cfg.corHumano then n = 2 end
    for _ = 1, n do
        local h = table.remove(self.historico)
        if not h then break end
        local k = table.remove(self.chaves)
        self.repeticoes[k] = self.repeticoes[k] - 1
        self.estado = h.estado
        self.relogio:restaurar(h.tempo)
    end
    -- recalcula lances do estado restaurado sem recontar a repetição
    self.legais = R.legais(self.estado)
    self.resultado = nil
end

function Partida:atualizar(dt)
    if self.resultado or self.pausado then return end
    local vez = self.estado.vez
    self.relogio:atualizar(dt, vez)
    if self.relogio:esgotado(vez) then
        local adv = R.outra(vez)
        if R.soRei(self.estado, adv) then
            self.resultado = { motivo = "tempo esgotado sem material para vencer" }
        else
            self.resultado = { vencedor = adv, motivo = "tempo esgotado" }
        end
    end
end

function Partida:desistir(cor)
    self.resultado = { vencedor = R.outra(cor), motivo = "desistência" }
end

return Partida
