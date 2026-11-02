# Serpente New York - Projeto da Faculdade

Projeto desenvolvido por mim, Rodrigo Lima Rodrigues, e por meu colega, Matheus Assis.

Um jogo da cobrinha (Snake) feito em **Python** com **Pygame**, com tema
visual de Nova York. É Trabalho acadêmico da disciplina de Algoritimos e Programação do Prof. Filipo Novo Mór.

O código-fonte está em `game/main.py`.

- **ENTER** ou **ESPAÇO** — inicia a partida e reinicia depois de perder/vencer.
- **ESC** — sai do jogo.

**Objetivo:** comer as frutas para pontuar, desviar das paredes (obstáculos) e
do próprio corpo, chegar até a **fase 10** e comer todas as frutas finais para
vencer.

---

## Requisitos

- Python 3
- Pygame

## Como clonar e executar

1. Clone o repositório:

```bash
git clone https://github.com/rodrigolr23/PyGameBasic.git
cd PyGameBasic
```

2. (Recomendado) Crie e ative um ambiente virtual:

```bash
python -m venv .venv
# Windows (PowerShell):
.\.venv\Scripts\Activate.ps1
# Linux / macOS:
source .venv/bin/activate
```

3. Instale a dependência:

```bash
pip install -r requirements.txt
```

> No PyCharm, ao abrir o projeto ele detecta o `requirements.txt` e oferece
> instalar a dependência automaticamente. Se preferir, `pip install pygame`
> tem o mesmo efeito. Caso esteja no Python 3.14 e o `pygame` não instale, use
> o `pygame-ce` (mesma API, drop-in): `pip install pygame-ce`.

4. Execute o jogo:

```bash
python game/main.py
```

---

## Estrutura do projeto

```
PyGameBasic/
├── game/
│   └── main.py          # todo o jogo
├── Images/
│   └── fruits/          # sprites das frutas (.png)
├── sounds/              # efeitos sonoros (.wav)
├── recorde.txt          # recorde salvo automaticamente
└── README.md
```

---

## Como o jogo funciona (o que foi implementado)

### Tabuleiro e tamanhos

O tabuleiro é uma grade de células. Cada célula tem 48 pixels, e a grade
tem 21 colunas × 14 linhas. A janela é montada a partir disso: a área de
jogo (1008 × 672) mais margens laterais e um espaço no topo (150 px) reservado
para o título e o placar. Mudar o tamanho da célula (CELL) aumenta ou diminui
proporcionalmente todos os elementos e a janela inteira.

> **No código:** esses tamanhos são **variáveis constantes** no topo do arquivo
> (`CELL = 48`, `COLS = 21`, `ROWS = 14`). O tamanho da janela não é fixo: é
> **calculado** a partir delas, tipo `PLAY_W = COLS * CELL`. Por isso mudar só o
> `CELL` recalcula tudo sozinho.

As teclas não movem a cobra na hora: elas entram numa fila de direções
(buffer de até 3), aplicada no próximo passo. Isso deixa os controles mais
responsivos e evita perder comandos rápidos.

> **No código:** o jogo inteiro vive dentro de um **loop `while rodando:`** (o
> loop principal), que repete até a variável `rodando` virar falsa. As teclas
> viram um par de números `(dx, dy)` que entra numa fila (`deque`), e um
> **`while acumulador >= intervalo`** dá os passos da cobra em tempo fixo,
> independente do FPS.

### Velocidade e dificuldade

- A cobra começa em 7 células por segundo.
- Cada fruta comida acelera +0,25.
- A velocidade tem teto de 25 e piso de 4.
- A cada 150 pontos (um marco / troca de fase) a velocidade sofre um
alívio de −1,0 e abre-se uma janela de 100 pontos sem acelerar, para
o jogo não ficar impossível logo após subir de fase.

> **No código:** a velocidade fica na variável `velocidade`. Ao comer, ela sobe
> com `velocidade = min(velocidade + GANHO_POR_FRUTA, VEL_MAXIMA)` — o `min`
> garante o teto de 25. Um **`if`** verifica a janela de pausa antes de acelerar
> e outro **`if`** (`score % MARCO_PENALIDADE == 0`) aplica o alívio ao bater um
> marco de 150 pontos.

### Pontuação e fases

- Cada fruta vale 10 pontos.
- Uma fase nova a cada 150 pontos (fase = pontos ÷ 150 + 1).
- A fase 10 é a final (1350 pontos).
- O número de frutas no tabuleiro cresce com a fase: começa com 1 e vai até
4 frutas ao mesmo tempo.

> **No código:** o placar fica na variável `score`, somando 10 por fruta. A fase
> é calculada com `return score // MARCO_PENALIDADE + 1` (divisão inteira). Um
> **`if nova_fase > fase`** detecta a troca de fase e dispara o efeito de piscar
> e o som de nível.

### Crescimento da cobra

Para o jogo ser vencível (chegar até a fase 10 sem a cobra ficar
gigante), ela só cresce a cada 5 frutas comidas. Nas outras frutas, ela
pontua e acelera normalmente, mas a cauda sai para manter o tamanho.

> **No código:** a cada passo, uma nova cabeça é inserida na frente da lista com
> `corpo_cobra.insert(0, nova_cabeca)`. Um **`if frutas_comidas % 5 != 0`**
> decide se a cauda sai (`corpo_cobra.pop()`) ou fica: quando o resto da divisão
> por 5 é zero, a cauda **não** sai e a cobra cresce.

### Obstáculos (paredes) e aleatoriedade

- Não há obstáculos na fase 1; eles aparecem a partir da fase 2.
- A quantidade cresce 1 por fase, até no máximo 3 obstáculos.
- O tamanho de cada obstáculo cresce com a fase, até 3 células cada.
- Os obstáculos são posicionados aleatoriamente (horizontais ou verticais),
sempre longe do corpo da cobra, das 3 casas à frente da cabeça e das
frutas — para nunca criar uma morte injusta.
- Eles trocam de lugar a cada 5 frutas comidas e a cada troca de fase.

> **No código:** os obstáculos ficam na lista `lista_obstaculos`. Um **loop
> `while`** (com limite de tentativas) tenta posicioná-los, e um
> **`if random.random() < 0.5`** sorteia se é horizontal ou vertical (o `else`
> trata o outro caso). Antes de aceitar a posição, um `if` confere se ela não
> bate na cobra, nas casas à frente da cabeça nem nas frutas.

### Frutas e aleatoriedade

- As frutas aparecem em células livres escolhidas aleatoriamente (sem cobra,
sem outra fruta e sem obstáculo).
- O tipo de fruta (maçã, melancia, banana, laranja, cereja, abacaxi, uva,
limão, morango) também é sorteado.
- Cada sprite é carregado da pasta Images/fruits e redimensionado para caber
na célula. Se faltar a imagem de alguma fruta, o jogo desenha um quadradinho
de reserva no lugar (não quebra).

> **No código:** as frutas ficam na lista `lista_frutas`. Um **loop `while`**
> preenche o tabuleiro até a quantidade da fase. As células livres saem de uma
> **list comprehension** que usa `if` para descartar as ocupadas; o tipo e a
> posição vêm de `random.choice`. Ao desenhar, um **`if`/`else`** decide entre
> mostrar o sprite ou o quadradinho de reserva.

### Fase final e vitória

Ao chegar na fase 10, o tabuleiro para de repor frutas e solta as
5 frutas finais. O jogador precisa comer todas para vencer. A tela de
vitória fica piscando entre vermelho e azul para comemorar.

> **No código:** um **`if fase < FASE_FINAL`** decide se o tabuleiro repõe
> frutas; o **`elif not lista_frutas`** (senão, e se não sobrou nenhuma) muda a
> variável `estado` para `"vitoria"`. O piscar alterna a cor a cada intervalo de
> tempo com uma conta de resto (`% 2`).

### Formas de morrer

A cobra morre (e toca o som de morte) se:

- bater em uma parede da borda;
- bater no próprio corpo (a cauda que vai sair no mesmo passo é ignorada);
- bater em um obstáculo;
- tentar virar 180° (apertar a direção oposta à que ela segue).

> **No código:** cada colisão vira uma **variável verdadeiro/falso**
> (`bateu_parede`, `bateu_corpo`, `bateu_obstaculo`). Um único
> **`if bateu_parede or bateu_corpo or bateu_obstaculo`** muda o `estado` para
> `"fim"` e toca o som. A virada de 180° é pega por uma função `eh_oposta`, que
> compara as direções.

### Sons

Três efeitos sonoros, carregados da pasta sounds:

- comer.wav — ao comer uma fruta;
- morte.wav — ao morrer;
- nivel.wav — ao subir de fase.

Se algum arquivo de som não existir, o jogo continua funcionando normalmente,
apenas sem aquele efeito.

> **No código:** cada som vira uma variável (`som_mordida`, `som_morte`,
> `som_nivel`). Se o arquivo não existe, a variável fica como `None`. Por isso,
> antes de tocar, sempre há um **`if som_morte:`** — só toca se o som foi
> carregado, evitando erro.

### Recorde

O maior placar é salvo automaticamente em recorde.txt e recarregado toda vez
que o jogo abre, aparecendo no canto do placar.

> **No código:** o recorde fica na variável `recorde`, lida do arquivo ao abrir
> o jogo. A cada fruta, um **`if score > recorde`** atualiza a variável e chama
> a função que grava o novo valor em `recorde.txt`.

---

## Gráficos e visual (tudo desenhado em código)

Quase tudo na tela é desenhado por código, não são imagens prontas
(exceto os sprites das frutas):

- Céu em degradê — pintado linha a linha, interpolando duas cores.
- Feixes de luz translúcidos saindo do topo (estilo holofotes).
- Skyline de prédios, com silhuetas e janelas acesas
distribuídas aleatoriamente. O cenário usa uma semente fixa de aleatoriedade
para o desenho dos prédios ficar sempre igual entre partidas.
- Moldura dourada em volta da área de jogo, com detalhes nos cantos.
- Grade sutil marcando as células do tabuleiro.
- A cobra é desenhada com polígonos: a cabeça gira conforme a direção,
tem olhos e presas, e ao morrer os olhos viram "X". O corpo tem um
losango central para dar textura.
- Obstáculos desenhados como blocos de pedra cinza (para não se
confundirem com frutas).
- Efeito de flash na troca de fase: o cenário de fora pisca 3 vezes
entre vermelho e azul, deixando a área de jogo livre.
- HUD (placar superior) mostrando SCORE, FASE x/10, VELOCIDADE e
RECORDE, cada um numa cartela com moldura dourada.
- Telas de início, game over e vitória sobrepostas ao tabuleiro.

Para desempenho, o fundo e os sprites da cobra são montados uma única vez
antes do loop e apenas reaproveitados a cada quadro.

> **No código:** o degradê do céu é feito com um **loop `for y in range(...)`**
> que pinta uma linha por vez. As linhas da grade e as janelas dos prédios
> também saem de loops `for`, e um **`if`** com sorteio (`random`) decide quais
> janelas acendem. Todo esse fundo é montado uma vez e guardado numa variável de
> imagem, só copiada a cada quadro.

---

## Créditos e direitos dos assets

- **Sons** (`sounds/*.wav`): eu mesmo gerei por código, através do script
  `sounds/generate_sounds.py` (síntese de ondas senoidais). São de autoria
  própria, sem direitos de terceiros.
- **Sprites das frutas** (`Images/fruits/*.png`): recortei de uma imagem que
  encontrei em uma busca na web, e não consegui identificar o autor nem a
  licença. Os direitos pertencem ao(s) autor(es) original(is); usei aqui apenas
  para fins educacionais e sem fins lucrativos, no contexto deste trabalho
  acadêmico. O script `Images/convert_fruits.py` só recorta e trata a imagem
  original.
- **Fontes** (Bahnschrift, Arial): são fontes do sistema operacional, que apenas
  referencio em tempo de execução; não distribuo nenhum arquivo de fonte neste
  repositório.
- Todo o **código-fonte** é de minha autoria.
