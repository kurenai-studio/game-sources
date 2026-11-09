-- Relógio de xadrez: tempo de cada lado, sem incremento.
local Relogio = {}
Relogio.__index = Relogio

function Relogio.novo(minutos)   -- minutos = nil -> sem relógio
    local s = (minutos or 0) * 60
    return setmetatable({ ativo = minutos ~= nil, tempo = { brancas = s, pretas = s } }, Relogio)
end

function Relogio:atualizar(dt, vez)
    if self.ativo then self.tempo[vez] = math.max(0, self.tempo[vez] - dt) end
end

function Relogio:esgotado(cor) return self.ativo and self.tempo[cor] <= 0 end
function Relogio:copia() return { brancas = self.tempo.brancas, pretas = self.tempo.pretas } end
function Relogio:restaurar(t) self.tempo.brancas, self.tempo.pretas = t.brancas, t.pretas end

function Relogio.formatar(seg)
    seg = math.ceil(seg)
    return string.format("%d:%02d", math.floor(seg / 60), seg % 60)
end

return Relogio
