import math
import os
import struct
import wave

TAXA = 44100
PASTA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sounds")
os.makedirs(PASTA, exist_ok=True)


def salvar_onda(nome, amostras):
    caminho = os.path.join(PASTA, nome)
    with wave.open(caminho, "w") as arquivo:
        arquivo.setnchannels(1)
        arquivo.setsampwidth(2)
        arquivo.setframerate(TAXA)
        quadros = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in amostras)
        arquivo.writeframes(quadros)
    print("[OK]", caminho)


def tom(frequencia, duracao, volume=0.6, decaimento=True):
    total = int(TAXA * duracao)
    saida = []
    for i in range(total):
        envelope = (1.0 - i / total) if decaimento else 1.0
        saida.append(volume * envelope * math.sin(2 * math.pi * frequencia * i / TAXA))
    return saida


def gerar_comer():
    salvar_onda("comer.wav", tom(880, 0.07) + tom(1320, 0.05))


def gerar_nivel():
    salvar_onda("nivel.wav", tom(660, 0.08, decaimento=False) + tom(880, 0.08, decaimento=False) + tom(1320, 0.12))


def gerar_morte():
    total = int(TAXA * 0.5)
    saida = []
    for i in range(total):
        frequencia = 440 - (330 * i / total)
        envelope = 1.0 - i / total
        saida.append(0.6 * envelope * math.sin(2 * math.pi * frequencia * i / TAXA))
    salvar_onda("morte.wav", saida)


if __name__ == "__main__":
    gerar_comer()
    gerar_nivel()
    gerar_morte()
    print("sounds gerados em:", PASTA)
