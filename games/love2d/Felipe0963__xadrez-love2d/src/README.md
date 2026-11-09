# Xadrez (Lua + LÖVE)

Xadrez completo feito do zero em **Lua** com o framework **[LÖVE](https://love2d.org)**: jogue contra uma IA própria ou com um amigo no mesmo computador.

<!-- Grave uma partida curta (ex.: ScreenToGif), salve em docs/xadrez.gif e descomente a linha abaixo -->
<!-- ![Partida de xadrez](docs/xadrez.gif) -->

## Recursos
- **Todas as regras**: roque, en passant, promoção (com escolha da peça), xeque-mate, afogamento, material insuficiente, regra dos 50 lances e repetição tripla
- **IA própria** com minimax + poda alfa-beta, aprofundamento iterativo e 3 níveis (o Difícil pensa até 4 lances à frente, com limite de 2 s)
- **Relógio** (5 ou 10 min), **histórico** em notação algébrica em português (e4, Cf3, O-O, Dxf7#) e **desfazer**
- Tabuleiro gira quando você joga de pretas
- Peças **desenhadas por código** e sons **sintetizados por código**: nenhuma imagem ou áudio externo

## Como jogar

**Sem instalar nada (Windows):** baixe o `xadrez-windows.zip` na página de [Releases](../../releases), extraia e abra o `xadrez.exe`.

**Pelo código-fonte:** instale o [LÖVE 11.x](https://love2d.org) e, na pasta do projeto, rode:

```bash
love .
```

No Windows (PowerShell), se o `love` não estiver no PATH:

```powershell
& "C:\Program Files\LOVE\love.exe" .
```

**Controles:** clique para selecionar e mover · `Z` desfaz · `M` liga/desliga o som · `Esc` volta ao menu.

## Arquitetura
A lógica do xadrez é Lua puro, sem nenhuma dependência do LÖVE, e por isso pode ser testada isoladamente. A interface só desenha e trata a entrada.

| Módulo | Função |
|---|---|
| `src/tabuleiro.lua` | estado do tabuleiro e leitura de FEN |
| `src/regras.lua` | lances legais, xeque, fim de partida |
| `src/notacao.lua` | notação algébrica em português |
| `src/ia.lua` | avaliação e busca minimax / alfa-beta |
| `src/partida.lua` | histórico, repetição, desfazer, relógio |
| `main.lua`, `src/pecas.lua`, `src/sons.lua` | interface LÖVE |

## Desafios técnicos
- **Garantir que as regras estão certas.** Regras de xadrez têm muitos casos de borda: roque passando por casa atacada, en passant que deixa o rei em xeque, promoção com captura. Para validar, uso **perft**: conto todos os lances possíveis até certa profundidade em posições conhecidas e comparo com os valores de referência usados por motores de xadrez. Se um único lance estiver errado, a contagem não bate.
- **IA sem travar a tela.** A busca roda dentro de uma **corrotina** que pausa a cada poucas centenas de posições. A cada frame, o jogo dá cerca de 12 ms para a IA pensar e depois continua desenhando normalmente.
- **Estado imutável.** Cada lance gera um tabuleiro novo em vez de modificar o atual. Isso deixa o "desfazer" trivial (basta voltar ao estado anterior) e evita que a busca da IA corrompa a partida.
- **IA mais forte no mesmo tempo.** A poda alfa-beta descarta caminhos ruins mais cedo, e a ordenação de lances (capturas valiosas primeiro) faz essa poda acontecer muito mais. No nível Difícil, o aprofundamento iterativo garante que sempre há uma resposta pronta quando o tempo de 2 s acaba.

## Testes
Os testes rodam no próprio LÖVE, sem abrir janela:

```powershell
& "C:\Program Files\LOVE\lovec.exe" . --testes
```

Eles cobrem mate, afogamento, empates, notação, desfazer, relógio, IA e o **perft**:

| Posição | Profundidade | Lances |
|---|---|---|
| Inicial | 4 | 197.281 |
| Kiwipete | 3 | 97.862 |
| Posição 3 | 4 | 43.238 |
| Posição 4 | 3 | 9.467 |

## Gerar o executável
`.\build.ps1` (PowerShell) gera `dist/xadrez.love` e `dist/xadrez-windows.zip`, que é o arquivo publicado nas Releases.

## Licença
[MIT](LICENSE)
