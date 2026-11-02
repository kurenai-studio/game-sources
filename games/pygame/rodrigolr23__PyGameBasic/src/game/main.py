import pygame
import sys
import random
import os
from collections import deque

pygame.init()
pygame.mixer.init()
pygame.font.init()

# --- Dimensoes do tabuleiro e da janela (em pixels) ---
CELL = 48            # tamanho de cada celula da grade
COLS = 21            # numero de colunas do tabuleiro
ROWS = 14            # numero de linhas do tabuleiro
PLAY_W = COLS * CELL
PLAY_H = ROWS * CELL
MARGEM_X = 30        # margem lateral entre o tabuleiro e a borda da janela
PLAY_TOP = 150       # espaco reservado no topo para o titulo e o placar
LARGURA_TELA = PLAY_W + 2 * MARGEM_X
ALTURA_TELA = PLAY_TOP + PLAY_H + 90
TITULO = "Serpente - New York"

# --- Paleta de cores do tema (cenario art-deco de Nova York) ---
COR_CEU_TOPO = (150, 32, 32)
COR_CEU_BASE = (52, 12, 16)
COR_PREDIO = (16, 12, 18)
COR_JANELA = (228, 196, 110)
COR_FEIXE = (236, 226, 150)
COR_CREME = (233, 224, 202)
COR_OURO = (201, 162, 75)
COR_PAINEL = (17, 14, 20)
COR_GRADE = (38, 30, 40)
COR_TEXTO = (233, 224, 202)
COR_CARTELA = (12, 9, 13)

# --- Cores da cobra ---
COR_CORPO = (28, 82, 48)
COR_CORPO_CLARO = (54, 124, 70)
COR_CORPO_ESCURO = (10, 36, 22)
COR_OLHO = (245, 224, 86)
COR_PUPILA = (150, 16, 16)
COR_PRESA = (240, 236, 222)

# --- Cores dos obstaculos (blocos de pedra cinza) ---
COR_OBSTACULO = (104, 106, 112)        # cinza pedra (base)
COR_OBSTACULO_CLARO = (146, 148, 154)  # cinza pedra (reflexo)
COR_OBSTACULO_BORDA = (58, 60, 66)     # contorno escuro de pedra

# --- Cores do efeito de piscar na troca de fase e na vitoria ---
COR_FLASH_VERMELHO = (214, 40, 48)
COR_FLASH_AZUL = (46, 92, 220)

# --- Parametros de dificuldade (velocidade e pontuacao) ---
VEL_INICIAL = 7.0            # celulas por segundo no inicio
GANHO_POR_FRUTA = 0.25       # aceleracao a cada fruta comida
PENALIDADE_VELOCIDADE = 1.0  # alivio de velocidade ao bater um marco
MARCO_PENALIDADE = 150       # pontos que definem a troca de fase
PONTOS_PAUSA = 100           # janela de pontos sem acelerar apos o marco
VEL_MAXIMA = 25.0
VEL_MINIMA = 4.0
PONTOS_POR_FRUTA = 10
FASE_FINAL = 10              # fase 10 e a ultima; comer todas as frutas vence
FRUTAS_FINAIS = 5           # frutas da fase final que precisam ser comidas
MAX_FRUTAS = 4              # maximo de frutas simultaneas no tabuleiro
MAX_OBSTACULOS = 3         # maximo de obstaculos simultaneos
MAX_TAMANHO_OBSTACULO = 3  # maximo de celulas que um obstaculo ocupa

# --- Parametros do efeito de piscar (troca de fase) ---
FLASH_SEGMENTO = 120       # duracao de cada cor do pisca (ms)
FLASH_SEGMENTOS = 6        # 3 vermelhos + 3 azuis = pisca 3x
FLASH_DURACAO = FLASH_SEGMENTO * FLASH_SEGMENTOS

# --- Caminhos de arquivos (assets e recorde) ---
# O arquivo fica em game/, entao a raiz do projeto e a pasta de cima.
PASTA_RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PASTA_FRUTAS = os.path.join(PASTA_RAIZ, "Images", "fruits")
ARQUIVO_RECORDE = os.path.join(PASTA_RAIZ, "recorde.txt")


def achar_pasta(*nomes):
    """Retorna a primeira pasta existente entre os nomes dados
    (tolera variacoes de escrita)."""
    for nome in nomes:
        caminho = os.path.join(PASTA_RAIZ, nome)
        if os.path.isdir(caminho):
            return caminho
    return os.path.join(PASTA_RAIZ, nomes[0])


PASTA_SONS = achar_pasta("Sounds", "Sons")

tela = pygame.display.set_mode((LARGURA_TELA, ALTURA_TELA))
pygame.display.set_caption(TITULO)
relogio = pygame.time.Clock()
fonte_titulo = pygame.font.SysFont(
    "bahnschrift,arialblack,arial", 54, bold=True)
fonte_placar = pygame.font.SysFont("bahnschrift,arial", 24, bold=True)
fonte_pequena = pygame.font.SysFont("bahnschrift,arial", 18, bold=True)
fonte_fim = pygame.font.SysFont("bahnschrift,arialblack,arial", 72, bold=True)

NOMES_FRUTAS = [
    "maca", "melancia", "banana", "laranja", "cereja",
    "abacaxi", "uva", "limao", "morango",
]


def carregar_frutas():
    """Carrega e redimensiona os sprites das frutas.

    Retorna um dicionario nome -> imagem.
    """
    catalogo = {}
    for nome in NOMES_FRUTAS:
        try:
            caminho = os.path.join(PASTA_FRUTAS, nome + ".png")
            imagem = pygame.image.load(caminho).convert_alpha()
        except (FileNotFoundError, pygame.error):
            continue  # ignora frutas sem arquivo de imagem
        largura, altura = imagem.get_size()
        alvo = CELL - 6
        escala = alvo / max(largura, altura)
        nova_largura = max(1, int(largura * escala))
        nova_altura = max(1, int(altura * escala))
        imagem = pygame.transform.scale(imagem, (nova_largura, nova_altura))
        catalogo[nome] = imagem
    return catalogo


def carregar_som(nome):
    """Carrega um efeito sonoro; devolve None se o arquivo nao existir."""
    try:
        return pygame.mixer.Sound(os.path.join(PASTA_SONS, nome))
    except (FileNotFoundError, pygame.error):
        return None


def carregar_recorde():
    """Le o recorde salvo em disco; devolve 0 se nao houver."""
    try:
        with open(ARQUIVO_RECORDE, "r", encoding="utf-8") as arquivo:
            return int(arquivo.read().strip())
    except (FileNotFoundError, ValueError):
        return 0


def salvar_recorde(valor):
    """Grava o recorde em disco, ignorando erros de escrita."""
    try:
        with open(ARQUIVO_RECORDE, "w", encoding="utf-8") as arquivo:
            arquivo.write(str(valor))
    except OSError:
        pass


def interpolar_cor(cor_a, cor_b, fator):
    """Mistura duas cores conforme um fator de 0.0 a 1.0.

    Usado no gradiente do ceu.
    """
    return tuple(int(a + (b - a) * fator) for a, b in zip(cor_a, cor_b))


def desenhar_gradiente(superficie):
    """Pinta o ceu como um degrade vertical, linha a linha."""
    for y in range(ALTURA_TELA):
        fator = y / (ALTURA_TELA - 1)
        cor = interpolar_cor(COR_CEU_TOPO, COR_CEU_BASE, fator)
        pygame.draw.line(superficie, cor, (0, y), (LARGURA_TELA, y))


def desenhar_feixes(superficie):
    """Desenha os feixes de luz translucidos que saem do topo da tela."""
    feixes = pygame.Surface((LARGURA_TELA, ALTURA_TELA), pygame.SRCALPHA)
    topo = (LARGURA_TELA // 2, -30)
    pygame.draw.polygon(feixes, (*COR_FEIXE, 42), [
        topo,
        (LARGURA_TELA * 0.02, ALTURA_TELA * 0.72),
        (LARGURA_TELA * 0.28, ALTURA_TELA * 0.78),
    ])
    pygame.draw.polygon(feixes, (*COR_FEIXE, 42), [
        topo,
        (LARGURA_TELA * 0.72, ALTURA_TELA * 0.78),
        (LARGURA_TELA * 0.98, ALTURA_TELA * 0.72),
    ])
    pygame.draw.polygon(feixes, (*COR_FEIXE, 26), [
        topo,
        (LARGURA_TELA * 0.40, ALTURA_TELA),
        (LARGURA_TELA * 0.60, ALTURA_TELA),
    ])
    superficie.blit(feixes, (0, 0))


def desenhar_skyline(superficie, base_y, altura_min, altura_max, gerador):
    """Gera uma silhueta de predios ao longo da largura.

    As janelas acesas sao distribuidas aleatoriamente.
    """
    x = -10
    while x < LARGURA_TELA:  # avanca preenchendo predios ate cobrir a largura
        largura_predio = gerador.randint(42, 92)
        altura_predio = gerador.randint(altura_min, altura_max)
        topo = base_y - altura_predio
        pygame.draw.rect(
            superficie, COR_PREDIO,
            (x, topo, largura_predio, base_y - topo))
        # degraus que estreitam o topo do predio (estilo art-deco)
        passo_largura = largura_predio
        topo_passo = topo
        for _ in range(2):
            passo_largura = int(passo_largura * 0.6)
            centro = x + (largura_predio - passo_largura) // 2
            topo_passo -= 11
            pygame.draw.rect(
                superficie, COR_PREDIO,
                (centro, topo_passo, passo_largura, 13))
        pygame.draw.rect(
            superficie, COR_PREDIO,
            (x + largura_predio // 2 - 2, topo_passo - 16, 4, 18))
        # janelas acesas distribuidas pela fachada
        for janela_y in range(topo + 9, base_y - 4, 11):
            for janela_x in range(x + 6, x + largura_predio - 5, 10):
                if gerador.random() < 0.55:
                    superficie.fill(COR_JANELA, (janela_x, janela_y, 3, 4))
        x += largura_predio + gerador.randint(2, 10)


def desenhar_moldura(superficie):
    """Desenha a moldura dourada art-deco em volta da area de jogo."""
    x0 = MARGEM_X - 12
    y0 = PLAY_TOP - 12
    largura = PLAY_W + 24
    altura = PLAY_H + 24
    pygame.draw.rect(superficie, COR_OURO, (x0, y0, largura, altura), 4)
    pygame.draw.rect(
        superficie, COR_CREME,
        (x0 - 6, y0 - 6, largura + 12, altura + 12), 2)
    cantos = [
        (x0, y0), (x0 + largura, y0),
        (x0, y0 + altura), (x0 + largura, y0 + altura),
    ]
    for canto_x, canto_y in cantos:
        pygame.draw.rect(
            superficie, COR_OURO, (canto_x - 8, canto_y - 8, 16, 16))
        pygame.draw.rect(
            superficie, COR_CEU_BASE, (canto_x - 4, canto_y - 4, 8, 8))
    centro_x = LARGURA_TELA // 2
    for i in range(-3, 4):
        pygame.draw.line(
            superficie, COR_OURO,
            (centro_x, y0 - 10), (centro_x + i * 16, y0 - 34), 2)


def criar_segmento_corpo():
    """Cria uma vez o sprite de um segmento do corpo, com losango central."""
    segmento = pygame.Surface((CELL, CELL), pygame.SRCALPHA)
    pygame.draw.rect(segmento, COR_CORPO_ESCURO, (1, 1, CELL - 2, CELL - 2))
    pygame.draw.rect(segmento, COR_CORPO, (3, 3, CELL - 6, CELL - 6))
    centro = CELL // 2
    losango = [
        (centro, 7), (CELL - 7, centro),
        (centro, CELL - 7), (7, centro),
    ]
    pygame.draw.polygon(segmento, COR_CORPO_CLARO, losango)
    pygame.draw.polygon(segmento, COR_CORPO_ESCURO, losango, 1)
    return segmento


def centro_y(deslocamento):
    """Posicao vertical relativa ao centro da celula.

    Auxilia no desenho das presas.
    """
    return CELL // 2 + deslocamento


def criar_cabeca(morta=False):
    """Cria o sprite da cabeca; se morta=True, olhos viram 'X'."""
    cabeca = pygame.Surface((CELL, CELL), pygame.SRCALPHA)
    pygame.draw.rect(cabeca, COR_CORPO_ESCURO, (1, 1, CELL - 2, CELL - 2))
    pygame.draw.rect(cabeca, COR_CORPO, (3, 3, CELL - 6, CELL - 6))
    pygame.draw.rect(cabeca, COR_CORPO_CLARO, (CELL - 12, 8, 7, CELL - 16))
    if morta:
        for cima in (11, CELL - 11):
            pygame.draw.line(
                cabeca, COR_PUPILA,
                (CELL - 22, cima - 4), (CELL - 10, cima + 4), 3)
            pygame.draw.line(
                cabeca, COR_PUPILA,
                (CELL - 22, cima + 4), (CELL - 10, cima - 4), 3)
    else:
        olho_superior = [
            (CELL - 23, 7), (CELL - 8, 11),
            (CELL - 11, 18), (CELL - 24, 14),
        ]
        olho_inferior = [
            (CELL - 23, CELL - 7), (CELL - 8, CELL - 11),
            (CELL - 11, CELL - 18), (CELL - 24, CELL - 14),
        ]
        pygame.draw.polygon(cabeca, COR_OLHO, olho_superior)
        pygame.draw.polygon(cabeca, COR_OLHO, olho_inferior)
        pygame.draw.polygon(cabeca, COR_PUPILA, [
            (CELL - 14, 11), (CELL - 8, 12), (CELL - 10, 17),
        ])
        pygame.draw.polygon(cabeca, COR_PUPILA, [
            (CELL - 14, CELL - 11), (CELL - 8, CELL - 12),
            (CELL - 10, CELL - 17),
        ])
        pygame.draw.line(
            cabeca, COR_CORPO_ESCURO, (CELL - 26, 9), (CELL - 8, 4), 3)
        pygame.draw.line(
            cabeca, COR_CORPO_ESCURO,
            (CELL - 26, CELL - 9), (CELL - 8, CELL - 4), 3)
    pygame.draw.polygon(cabeca, COR_PRESA, [
        (CELL - 5, centro_y(-7)), (CELL - 1, centro_y(-4)),
        (CELL - 7, centro_y(-2)),
    ])
    pygame.draw.polygon(cabeca, COR_PRESA, [
        (CELL - 5, centro_y(7)), (CELL - 1, centro_y(4)),
        (CELL - 7, centro_y(2)),
    ])
    return cabeca


# Angulo de rotacao da cabeca conforme a direcao (dx, dy) atual.
ANGULOS = {(1, 0): 0, (0, -1): 90, (-1, 0): 180, (0, 1): -90}


def construir_fundo():
    """Monta uma unica vez a imagem de fundo.

    Inclui ceu, predios, titulo, grade e moldura.
    """
    fundo = pygame.Surface((LARGURA_TELA, ALTURA_TELA))
    desenhar_gradiente(fundo)
    desenhar_feixes(fundo)
    desenhar_skyline(fundo, PLAY_TOP, 60, 138, random.Random(7))
    desenhar_skyline(fundo, ALTURA_TELA, 40, 92, random.Random(23))
    # titulo com sombra deslocada para dar profundidade
    sombra = fonte_titulo.render("SERPENTE", True, (18, 8, 10))
    titulo = fonte_titulo.render("SERPENTE", True, COR_CREME)
    fundo.blit(sombra, (LARGURA_TELA // 2 - titulo.get_width() // 2 + 3, 27))
    fundo.blit(titulo, (LARGURA_TELA // 2 - titulo.get_width() // 2, 24))
    subtitulo = fonte_pequena.render("N E W   Y O R K", True, COR_OURO)
    fundo.blit(
        subtitulo, (LARGURA_TELA // 2 - subtitulo.get_width() // 2, 84))
    # area de jogo e linhas da grade
    pygame.draw.rect(fundo, COR_PAINEL, (MARGEM_X, PLAY_TOP, PLAY_W, PLAY_H))
    for coluna in range(COLS + 1):
        x = MARGEM_X + coluna * CELL
        pygame.draw.line(
            fundo, COR_GRADE, (x, PLAY_TOP), (x, PLAY_TOP + PLAY_H))
    for linha in range(ROWS + 1):
        y = PLAY_TOP + linha * CELL
        pygame.draw.line(
            fundo, COR_GRADE, (MARGEM_X, y), (MARGEM_X + PLAY_W, y))
    desenhar_moldura(fundo)
    return fundo


def desenhar_cartela(texto, centro, cor):
    """Desenha uma cartela do HUD (texto dentro de uma moldura dourada)."""
    superficie = fonte_placar.render(texto, True, cor)
    retangulo = superficie.get_rect(center=centro)
    moldura = retangulo.inflate(22, 12)
    pygame.draw.rect(tela, COR_CARTELA, moldura)
    pygame.draw.rect(tela, COR_OURO, moldura, 2)
    tela.blit(superficie, retangulo)


def celula_para_pixel(coluna, linha):
    """Converte coordenadas de grade (coluna, linha) em pixels na tela."""
    return MARGEM_X + coluna * CELL, PLAY_TOP + linha * CELL


# Carrega assets e cria os sprites uma vez so (fora do loop principal).
frutas = carregar_frutas()
som_mordida = carregar_som("comer.wav")
som_morte = carregar_som("morte.wav")
som_nivel = carregar_som("nivel.wav")
fundo_estatico = construir_fundo()
segmento_corpo = criar_segmento_corpo()
cabeca_viva = criar_cabeca(False)
cabeca_morta = criar_cabeca(True)
recorde = carregar_recorde()

# --- Estado do jogo (reiniciado a cada partida) ---
corpo_cobra = []  # celulas [coluna, linha]; indice 0 = cabeca
direcao = (1, 0)  # direcao atual de movimento (dx, dy)
fila_direcoes = deque(maxlen=3)  # buffer das proximas direcoes (responsivo)
score = 0
frutas_comidas = 0
fase = 1
velocidade = VEL_INICIAL
pausa_ate = 0
acumulador = 0.0  # tempo acumulado para o passo de movimento fixo
estado = "jogando"
lista_frutas = []  # frutas no tabuleiro: (posicao, nome)
lista_obstaculos = []  # celulas [coluna, linha] que sao paredes
flash_ativo = False  # se o pisca de troca de fase esta em andamento
flash_tempo = 0.0  # tempo decorrido do pisca atual (ms)


def fase_atual():
    """Calcula a fase a partir do score.

    Uma fase nova a cada MARCO_PENALIDADE pontos.
    """
    return score // MARCO_PENALIDADE + 1


def quantidade_frutas():
    """Frutas no tabuleiro, crescendo com a fase (ate MAX_FRUTAS)."""
    return min(MAX_FRUTAS, 1 + fase_atual() // 2)


def adicionar_frutas(alvo):
    """Adiciona frutas em celulas livres ate o tabuleiro ter 'alvo' frutas."""
    while len(lista_frutas) < alvo:
        ocupadas = [list(posicao) for posicao, _ in lista_frutas]
        # livres = celulas sem cobra, sem outras frutas e sem obstaculos
        livres = [(c, r) for c in range(COLS) for r in range(ROWS)
                  if [c, r] not in corpo_cobra
                  and [c, r] not in ocupadas
                  and [c, r] not in lista_obstaculos]
        if not livres:
            return  # tabuleiro cheio, nada a fazer
        posicao = random.choice(livres)
        nome = random.choice(list(frutas.keys())) if frutas else None
        lista_frutas.append((posicao, nome))


def repor_frutas():
    """Reabastece o tabuleiro ate ter a quantidade de frutas da fase."""
    adicionar_frutas(quantidade_frutas())


def preparar_fase_final():
    """Coloca as ultimas frutas da fase final no tabuleiro.

    A partir daqui o tabuleiro nao e mais reabastecido: o jogador precisa
    comer todas as FRUTAS_FINAIS frutas restantes para vencer o jogo.
    """
    adicionar_frutas(FRUTAS_FINAIS)


def quantidade_obstaculos(fase_alvo):
    """Quantidade de obstaculos da fase (0 antes da fase 2, ate 3)."""
    if fase_alvo < 2:
        return 0
    return min(MAX_OBSTACULOS, fase_alvo - 1)


def tamanho_obstaculo(fase_alvo):
    """Comprimento em celulas de cada obstaculo, crescendo com a fase."""
    return min(MAX_TAMANHO_OBSTACULO, 1 + (fase_alvo - 2) // 2)


def gerar_obstaculos():
    """Regenera as paredes-obstaculo conforme a fase atual.

    Sao redesenhadas a cada troca de fase; a quantidade e o tamanho
    crescem com a fase (limitados a MAX_OBSTACULOS e ao tamanho maximo).
    """
    lista_obstaculos.clear()
    fase_agora = fase_atual()
    quantidade = quantidade_obstaculos(fase_agora)
    if quantidade == 0:
        return
    tamanho = tamanho_obstaculo(fase_agora)
    # celulas proibidas: a cobra e ate 3 casas a frente da cabeca
    proibidas = [list(parte) for parte in corpo_cobra]
    cabeca = corpo_cobra[0]
    for passo in range(1, 4):
        c = cabeca[0] + direcao[0] * passo
        r = cabeca[1] + direcao[1] * passo
        proibidas.append([c, r])
    proibidas += [list(posicao) for posicao, _ in lista_frutas]
    alvo = quantidade * tamanho
    tentativas = 0
    while len(lista_obstaculos) < alvo and tentativas < 200:
        tentativas += 1
        if random.random() < 0.5:  # obstaculo horizontal
            coluna = random.randint(0, COLS - tamanho)
            linha = random.randint(0, ROWS - 1)
            celulas = [[coluna + i, linha] for i in range(tamanho)]
        else:  # obstaculo vertical
            coluna = random.randint(0, COLS - 1)
            linha = random.randint(0, ROWS - tamanho)
            celulas = [[coluna, linha + i] for i in range(tamanho)]
        livre = True
        for cel in celulas:
            if cel in proibidas or cel in lista_obstaculos:
                livre = False
                break
        if livre:
            lista_obstaculos.extend(celulas)


def iniciar_partida():
    """Reinicia todo o estado do jogo para comecar uma nova partida."""
    global corpo_cobra, direcao, score, frutas_comidas, fase
    global velocidade, pausa_ate, acumulador, estado
    global flash_ativo, flash_tempo
    meio_coluna = COLS // 2
    meio_linha = ROWS // 2
    # cobra inicial com tres segmentos, centralizada e apontando a direita
    corpo_cobra = [
        [meio_coluna, meio_linha],
        [meio_coluna - 1, meio_linha],
        [meio_coluna - 2, meio_linha],
    ]
    direcao = (1, 0)
    fila_direcoes.clear()
    score = 0
    frutas_comidas = 0
    fase = 1
    velocidade = VEL_INICIAL
    pausa_ate = 0
    acumulador = 0.0
    estado = "jogando"
    flash_ativo = False
    flash_tempo = 0.0
    lista_frutas.clear()
    gerar_obstaculos()  # fase 1 nao tem obstaculos, entao limpa a lista
    repor_frutas()


def desenhar_frutas():
    """Desenha cada fruta do tabuleiro (sprite ou um quadrado de reserva)."""
    for posicao, nome in lista_frutas:
        x, y = celula_para_pixel(*posicao)
        centro = (x + CELL // 2, y + CELL // 2)
        if nome and nome in frutas:
            sprite = frutas[nome]
            tela.blit(sprite, sprite.get_rect(center=centro))
        else:
            pygame.draw.rect(
                tela, (220, 60, 60), (x + 6, y + 6, CELL - 12, CELL - 12))


def desenhar_obstaculos():
    """Desenha as paredes-obstaculo como blocos vermelhos bem chamativos."""
    for coluna, linha in lista_obstaculos:
        x, y = celula_para_pixel(coluna, linha)
        pygame.draw.rect(
            tela, COR_OBSTACULO, (x + 2, y + 2, CELL - 4, CELL - 4))
        pygame.draw.rect(
            tela, COR_OBSTACULO_CLARO,
            (x + 6, y + 6, CELL - 12, CELL - 12))
        pygame.draw.rect(
            tela, COR_OBSTACULO_BORDA, (x + 2, y + 2, CELL - 4, CELL - 4), 2)


def desenhar_flash(cor):
    """Pinta o cenario de fora (tudo menos a area de jogo) com uma cor.

    Usada no efeito de piscar da troca de fase: um veu colorido cobre a
    moldura e o cenario, deixando um buraco transparente sobre o tabuleiro
    para nao atrapalhar a partida.
    """
    veu = pygame.Surface((LARGURA_TELA, ALTURA_TELA), pygame.SRCALPHA)
    veu.fill((*cor, 150))
    veu.fill((0, 0, 0, 0), (MARGEM_X, PLAY_TOP, PLAY_W, PLAY_H))
    tela.blit(veu, (0, 0))


def desenhar_cobra():
    """Desenha a cobra: a cabeca gira conforme a direcao e os
    segmentos formam o corpo."""
    for indice, parte in enumerate(corpo_cobra):
        x, y = celula_para_pixel(parte[0], parte[1])
        if indice == 0:
            base = cabeca_morta if estado == "fim" else cabeca_viva
            tela.blit(pygame.transform.rotate(base, ANGULOS[direcao]), (x, y))
        else:
            tela.blit(segmento_corpo, (x, y))


def desenhar_hud():
    """Desenha o placar superior: score, fase, velocidade e recorde."""
    desenhar_cartela(f"SCORE {score}", (140, 122), COR_CREME)
    desenhar_cartela(
        f"FASE {fase_atual()}/{FASE_FINAL}", (360, 122), COR_CREME)
    desenhar_cartela(
        f"VEL {velocidade:.2f}", (LARGURA_TELA - 360, 122), COR_CREME)
    desenhar_cartela(f"RECORDE {recorde}", (LARGURA_TELA - 140, 122), COR_OURO)


def desenhar_fim():
    """Desenha a tela de fim de jogo (GAME OVER) por cima do tabuleiro."""
    cortina = pygame.Surface((LARGURA_TELA, ALTURA_TELA), pygame.SRCALPHA)
    cortina.fill((6, 4, 8, 200))
    tela.blit(cortina, (0, 0))
    centro_x = LARGURA_TELA // 2
    sombra = fonte_fim.render("GAME OVER", True, (10, 4, 6))
    titulo = fonte_fim.render("GAME OVER", True, (196, 48, 48))
    tela.blit(
        sombra,
        (centro_x - titulo.get_width() // 2 + 3, ALTURA_TELA // 2 - 117))
    tela.blit(
        titulo,
        (centro_x - titulo.get_width() // 2, ALTURA_TELA // 2 - 120))
    info_score = fonte_placar.render(f"Pontuacao: {score}", True, COR_CREME)
    info_recorde = fonte_placar.render(f"Recorde: {recorde}", True, COR_OURO)
    info_reinicio = fonte_pequena.render(
        "ENTER ou ESPACO para jogar de novo    -    ESC para sair",
        True, COR_CREME)
    tela.blit(
        info_score,
        (centro_x - info_score.get_width() // 2, ALTURA_TELA // 2 - 20))
    tela.blit(
        info_recorde,
        (centro_x - info_recorde.get_width() // 2, ALTURA_TELA // 2 + 14))
    tela.blit(
        info_reinicio,
        (centro_x - info_reinicio.get_width() // 2, ALTURA_TELA // 2 + 64))


def desenhar_vitoria():
    """Desenha a tela de vitoria (fase final alcancada) sobre o tabuleiro.

    A tela inteira fica piscando entre vermelho e azul para comemorar.
    """
    # alterna a cor a cada FLASH_SEGMENTO ms, deixando tudo piscando
    segmento = (pygame.time.get_ticks() // FLASH_SEGMENTO) % 2
    cor_fundo = COR_FLASH_VERMELHO if segmento == 0 else COR_FLASH_AZUL
    cortina = pygame.Surface((LARGURA_TELA, ALTURA_TELA), pygame.SRCALPHA)
    cortina.fill((*cor_fundo, 180))
    tela.blit(cortina, (0, 0))
    centro_x = LARGURA_TELA // 2
    sombra = fonte_fim.render("VOCÊ VENCEU", True, (6, 20, 10))
    titulo = fonte_fim.render("VOCÊ VENCEU", True, COR_CREME)
    tela.blit(
        sombra,
        (centro_x - titulo.get_width() // 2 + 3, ALTURA_TELA // 2 - 117))
    tela.blit(
        titulo,
        (centro_x - titulo.get_width() // 2, ALTURA_TELA // 2 - 120))
    info_score = fonte_placar.render(
        f"Chegou a fase {FASE_FINAL} com {score} pontos!", True, COR_CREME)
    info_recorde = fonte_placar.render(f"Recorde: {recorde}", True, COR_OURO)
    info_reinicio = fonte_pequena.render(
        "ENTER ou ESPACO para jogar de novo    -    ESC para sair",
        True, COR_CREME)
    tela.blit(
        info_score,
        (centro_x - info_score.get_width() // 2, ALTURA_TELA // 2 - 20))
    tela.blit(
        info_recorde,
        (centro_x - info_recorde.get_width() // 2, ALTURA_TELA // 2 + 14))
    tela.blit(
        info_reinicio,
        (centro_x - info_reinicio.get_width() // 2, ALTURA_TELA // 2 + 64))


def desenhar_inicio():
    """Desenha a tela inicial (menu de abertura) por cima do tabuleiro."""
    cortina = pygame.Surface((LARGURA_TELA, ALTURA_TELA), pygame.SRCALPHA)
    cortina.fill((6, 4, 8, 200))
    tela.blit(cortina, (0, 0))
    centro_x = LARGURA_TELA // 2
    # titulo de abertura com sombra deslocada para dar profundidade
    sombra = fonte_fim.render("SERPENTE", True, (10, 4, 6))
    titulo = fonte_fim.render("SERPENTE", True, COR_OURO)
    tela.blit(
        sombra,
        (centro_x - titulo.get_width() // 2 + 3, ALTURA_TELA // 2 - 157))
    tela.blit(
        titulo,
        (centro_x - titulo.get_width() // 2, ALTURA_TELA // 2 - 160))
    # instrucoes de controle e objetivo, uma linha por dica
    dicas = [
        "Setas ou W A S D para mover a cobra",
        "Coma as frutas e desvie das paredes",
        f"Chegue a fase {FASE_FINAL} e coma todas as frutas para vencer",
    ]
    for indice, texto in enumerate(dicas):
        info = fonte_placar.render(texto, True, COR_CREME)
        pos = (centro_x - info.get_width() // 2,
               ALTURA_TELA // 2 - 40 + indice * 34)
        tela.blit(info, pos)
    # chamada para iniciar a partida
    info_inicio = fonte_pequena.render(
        "ENTER ou ESPACO para comecar    -    ESC para sair",
        True, COR_OURO)
    tela.blit(
        info_inicio,
        (centro_x - info_inicio.get_width() // 2, ALTURA_TELA // 2 + 84))


def eh_oposta(uma, outra):
    """Indica se duas direcoes sao opostas.

    Evita a cobra virar 180 graus sobre si mesma.
    """
    return uma[0] == -outra[0] and uma[1] == -outra[1]


iniciar_partida()
# o tabuleiro ja fica montado, mas a partida so comeca no ENTER/ESPACO
estado = "inicio"

# --- Loop principal do jogo ---
rodando = True
while rodando:
    # tempo do quadro em ms (limitado para evitar saltos bruscos)
    dt = min(relogio.tick(60), 100)

    # Trata os eventos de teclado e fechamento da janela.
    for evento in pygame.event.get():
        if evento.type == pygame.QUIT:
            rodando = False
        elif evento.type == pygame.KEYDOWN:
            if evento.key == pygame.K_ESCAPE:
                rodando = False
            elif estado == "inicio":
                if evento.key in (pygame.K_RETURN, pygame.K_SPACE):
                    # tabuleiro ja esta pronto, so libera o movimento
                    estado = "jogando"
            elif estado in ("fim", "vitoria"):
                if evento.key in (pygame.K_RETURN, pygame.K_SPACE):
                    iniciar_partida()
            else:
                # converte a tecla em uma direcao desejada
                if evento.key in (pygame.K_LEFT, pygame.K_a):
                    desejada = (-1, 0)
                elif evento.key in (pygame.K_RIGHT, pygame.K_d):
                    desejada = (1, 0)
                elif evento.key in (pygame.K_UP, pygame.K_w):
                    desejada = (0, -1)
                elif evento.key in (pygame.K_DOWN, pygame.K_s):
                    desejada = (0, 1)
                else:
                    desejada = None
                # enfileira a direcao desejada, ignorando a oposta (virar 180
                # graus sobre si mesma) e a repetida
                if desejada:
                    referencia = (
                        fila_direcoes[-1] if fila_direcoes else direcao)
                    if not eh_oposta(desejada, referencia) and desejada != referencia:
                        fila_direcoes.append(desejada)

    if estado == "jogando":
        # Passo de tempo fixo: a cobra anda em intervalos regulares,
        # independente do FPS.
        acumulador += dt
        intervalo = 1000.0 / velocidade
        while estado == "jogando" and acumulador >= intervalo:
            acumulador -= intervalo
            # aplica a proxima direcao da fila, se valida
            if fila_direcoes:
                proxima = fila_direcoes.popleft()
                if not eh_oposta(proxima, direcao):
                    direcao = proxima
            # calcula a nova posicao da cabeca
            nova_cabeca = [
                corpo_cobra[0][0] + direcao[0],
                corpo_cobra[0][1] + direcao[1],
            ]
            bateu_parede = (
                nova_cabeca[0] < 0 or nova_cabeca[0] >= COLS
                or nova_cabeca[1] < 0 or nova_cabeca[1] >= ROWS)
            # ignora a cauda (ultimo segmento), que vai sair nesta jogada
            bateu_corpo = nova_cabeca in corpo_cobra[:-1]
            bateu_obstaculo = nova_cabeca in lista_obstaculos
            if bateu_parede or bateu_corpo or bateu_obstaculo:
                estado = "fim"
                if som_morte:
                    som_morte.play()
            else:
                corpo_cobra.insert(0, nova_cabeca)  # cresce pela frente
                # verifica se a cabeca caiu sobre alguma fruta
                indice_comida = None
                for indice, (posicao, _) in enumerate(lista_frutas):
                    if tuple(nova_cabeca) == posicao:
                        indice_comida = indice
                        break
                if indice_comida is not None:
                    lista_frutas.pop(indice_comida)
                    frutas_comidas += 1
                    score += PONTOS_POR_FRUTA
                    if som_mordida:
                        som_mordida.play()
                    # a cobra so cresce a cada 5 frutas; nas outras, a
                    # cauda sai para manter o tamanho
                    if frutas_comidas % 5 != 0:
                        corpo_cobra.pop()
                    # acelera, exceto na janela de pausa apos um marco
                    if score > pausa_ate:
                        velocidade = min(
                            velocidade + GANHO_POR_FRUTA, VEL_MAXIMA)
                    # ao bater um marco, alivia a velocidade e abre
                    # a janela de pausa
                    if score % MARCO_PENALIDADE == 0:
                        velocidade = max(
                            velocidade - PENALIDADE_VELOCIDADE, VEL_MINIMA)
                        pausa_ate = score + PONTOS_PAUSA
                    if score > recorde:
                        recorde = score
                        salvar_recorde(recorde)
                    # a cada 5 frutas as paredes trocam de posicao
                    if frutas_comidas % 5 == 0:
                        gerar_obstaculos()
                    # avanca de fase (o pisca do cenario acompanha a troca)
                    nova_fase = fase_atual()
                    if nova_fase > fase:
                        fase = nova_fase
                        flash_ativo = True
                        flash_tempo = 0.0
                        # na fase final coloca as ultimas frutas e para de
                        # repor; fora dela o pisca so marca a troca
                        if fase >= FASE_FINAL:
                            preparar_fase_final()
                        if som_nivel:
                            som_nivel.play()
                    # so reabastece antes da fase final; na fase final o
                    # jogador precisa comer todas as frutas para vencer
                    if fase < FASE_FINAL:
                        repor_frutas()
                    elif not lista_frutas:
                        estado = "vitoria"
                else:
                    # sem comer: remove a cauda (mantem o tamanho)
                    corpo_cobra.pop()
            # recalcula caso a velocidade tenha mudado nesta jogada
            intervalo = 1000.0 / velocidade

    # Desenha o quadro: fundo, obstaculos, frutas, cobra, HUD e telas.
    tela.blit(fundo_estatico, (0, 0))
    desenhar_obstaculos()
    desenhar_frutas()
    desenhar_cobra()
    desenhar_hud()
    # pisca o cenario de fora (3x vermelho/azul) durante a troca de fase
    if flash_ativo:
        flash_tempo += dt
        if flash_tempo >= FLASH_DURACAO:
            flash_ativo = False
        else:
            indice_flash = int(flash_tempo // FLASH_SEGMENTO)
            cor_flash = (COR_FLASH_VERMELHO if indice_flash % 2 == 0
                         else COR_FLASH_AZUL)
            desenhar_flash(cor_flash)
    if estado == "inicio":
        desenhar_inicio()
    elif estado == "fim":
        desenhar_fim()
    elif estado == "vitoria":
        desenhar_vitoria()

    pygame.display.flip()

pygame.quit()
sys.exit()
