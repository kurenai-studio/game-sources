-- Efeitos sonoros gerados por código (síntese simples), sem arquivos de áudio.
local Sons = { mudo = false }

local TAXA = 44100

local function sintetizar(notas, duracao, forma, volume)
    local total = math.floor(TAXA * duracao)
    local dados = love.sound.newSoundData(total, TAXA, 16, 1)
    local porNota = total / #notas
    for i = 0, total - 1 do
        local freq = notas[math.min(#notas, math.floor(i / porNota) + 1)]
        local onda = math.sin(2 * math.pi * freq * i / TAXA)
        if forma == "quadrada" then onda = onda > 0 and 1 or -1 end
        local pos = (i % porNota) / porNota
        local env = math.min(1, pos * 40) * (1 - pos) ^ 1.5
        dados:setSample(i, onda * env * volume)
    end
    return love.audio.newSource(dados, "static")
end

function Sons.carregar()
    Sons.lista = {
        clique   = sintetizar({ 1400 }, 0.04, "seno", 0.2),
        lance    = sintetizar({ 520 }, 0.07, "seno", 0.35),
        captura  = sintetizar({ 300, 220 }, 0.14, "quadrada", 0.15),
        xeque    = sintetizar({ 880, 1175 }, 0.22, "seno", 0.35),
        especial = sintetizar({ 660, 880, 1100 }, 0.25, "seno", 0.3),
        fim      = sintetizar({ 523, 659, 784, 1047 }, 0.7, "seno", 0.35),
    }
end

function Sons.tocar(nome)
    local s = Sons.lista and Sons.lista[nome]
    if s and not Sons.mudo then s:stop(); s:play() end
end

return Sons
