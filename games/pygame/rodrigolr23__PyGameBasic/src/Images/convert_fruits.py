import os
from PIL import Image

ORIGEM = os.path.join(os.path.expanduser("~"), "Downloads", "fruits pygame.avif")
DESTINO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fruits")
os.makedirs(DESTINO, exist_ok=True)

NOMES = [
    ["maca", "melancia", "banana"],
    ["laranja", "cereja", "abacaxi"],
    ["uva", "limao", "morango"],
]

LIMIAR_BRANCO = 228


def remover_fundo(imagem):
    imagem = imagem.convert("RGBA")
    largura, altura = imagem.size
    pixels = imagem.load()

    def eh_branco(x, y):
        r, g, b, a = pixels[x, y]
        return a > 0 and r >= LIMIAR_BRANCO and g >= LIMIAR_BRANCO and b >= LIMIAR_BRANCO

    pilha = []
    for x in range(largura):
        pilha.append((x, 0))
        pilha.append((x, altura - 1))
    for y in range(altura):
        pilha.append((0, y))
        pilha.append((largura - 1, y))

    visitados = set()
    while pilha:
        x, y = pilha.pop()
        if (x, y) in visitados or x < 0 or y < 0 or x >= largura or y >= altura:
            continue
        visitados.add((x, y))
        if not eh_branco(x, y):
            continue
        r, g, b, _ = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)
        pilha.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
    return imagem


def recortar_conteudo(imagem):
    caixa = imagem.getbbox()
    if caixa:
        return imagem.crop(caixa)
    return imagem


def main():
    original = Image.open(ORIGEM)
    print("Tamanho original:", original.size)
    sem_fundo = remover_fundo(original)
    largura, altura = sem_fundo.size
    passo_x = largura // 3
    passo_y = altura // 3

    for linha in range(3):
        for coluna in range(3):
            celula = sem_fundo.crop((coluna * passo_x, linha * passo_y, (coluna + 1) * passo_x, (linha + 1) * passo_y))
            celula = recortar_conteudo(celula)
            nome = NOMES[linha][coluna]
            caminho = os.path.join(DESTINO, nome + ".png")
            celula.save(caminho)
            print("[OK]", nome, celula.size)

    print("Frutas salvas em:", DESTINO)


if __name__ == "__main__":
    main()
