# MeanFall — CLAUDE.md

RPG educacional estilo Tibia para ensinar estatística, feito com Phaser 3 + JavaScript vanilla. O jogador explora mapas tile-based, combate monstros respondendo questões de estatística e evolui desbloqueando novas áreas.

Na última área — a **Cripta do Interpretador** — o combate muda de forma: os monstros exigem **código Python executável**, rodado de verdade no navegador via Pyodide.

Jogo publicado em **[meanfall.pro](https://www.meanfall.pro)**.

---

## Stack Tecnológica

- **Phaser 3.60.0** (via CDN) — engine de jogo
- **JavaScript ES6 modules** — sem bundler, sem framework
- **HTML5 / CSS3** — layout 3 colunas + HUD DOM
- **Web Audio API** — música e efeitos sonoros procedurais (zero arquivos externos)
- **Pyodide 0.27.7** (via CDN, sob demanda) — CPython no navegador para os desafios de código
- **LocalStorage** — sistema de save (3 slots)

---

## Estrutura de Arquivos

```
/
├── index.html
├── CLAUDE.md
├── css/
│   └── style.css
├── icon/
│   ├── meanfallfav.png
│   └── banner.svg
└── js/
    ├── main.js              Entry point — inicializa Phaser com todas as cenas
    ├── py/
    │   └── pyodideWorker.js  Web Worker com o interpretador Python + harness de testes
    ├── constants.js         Config global, XP table, tile types, element matrix
    ├── utils/
    │   ├── EventBus.js      Pub/sub de eventos entre sistemas
    │   ├── Draw.js          Geração procedural de texturas (sprites, tiles, UI)
    │   ├── MusicSystem.js   Música procedural via Web Audio API (por área/estado)
    │   ├── SoundSystem.js   Efeitos sonoros procedurais (hit, levelup, dialogTick, etc.)
    │   ├── DayNight.js      Ciclo dia/noite acelerado derivado do relógio real (12 min/ciclo)
    │   ├── RichText.js      Renderização de texto colorido inline com markup {{tag:texto}}
    │   └── CodeEditor.js     Editor de código DOM (overlay dos desafios de Python)
    ├── systems/
    │   ├── CombatSystem.js        Cálculo de dano, itens, equipamentos, drops
    │   ├── QuestionEngine.js      Seleção adaptativa de questões, checagem de resposta
    │   ├── QuestionGenerator.js   Geração procedural de questões numéricas (média, var, etc.)
    │   ├── PythonRuntime.js       Ponte com o worker do Pyodide (boot, pacotes, timeout, reboot)
    │   ├── CodeChallengeEngine.js Seleção adaptativa e correção dos desafios de código
    │   ├── XPSystem.js            XP, level up, pontos de atributo, mastery por área
    │   ├── SaveSystem.js          Save/load LocalStorage (3 slots + autosave)
    │   ├── MapManager.js          Renderização de mapa, colisão, minimapa
    │   ├── QuestSystem.js         Rastreamento de objetivos e recompensas de quests
    │   ├── BountySystem.js        Bounties diárias rotativas por área desbloqueada
    │   ├── ShopSystem.js          Compra/venda de itens com mercadores por área
    │   ├── SkillSystem.js         Árvore de habilidades passivas (13 habilidades)
    │   ├── BookSystem.js          Biblioteca in-world com tomos que concedem bônus permanentes
    │   ├── InferenceSystem.js     Geração de testes de hipótese para Mimics (Dungeon)
    │   ├── StatusEffectSystem.js  Efeitos de status elementais aplicados em combate
    │   ├── CompanionSystem.js     Outlier: estágio/bônus do wisp companheiro (por maestria média)
    │   └── TutorialSystem.js      Tutorial guiado para novos jogadores
    ├── scenes/
    │   ├── BootScene.js           Gera texturas, transita para MainMenu
    │   ├── IntroScene.js          Animação de intro com lore do mundo
    │   ├── MainMenuScene.js       Menu principal, 3 slots de save, help overlay
    │   ├── CharacterCreationScene.js  Criação de personagem (nome, aparência)
    │   ├── WorldScene.js          Mundo, movimento, NPCs, portais, interiores de casas
    │   ├── UIScene.js             HUD DOM: barras HP/Focus/XP, chat log, minimapa
    │   ├── CombatScene.js         UI de combate por turnos + questões + efeitos elementais
    │   ├── GameOverScene.js       Tela de morte com estatísticas e opções de respawn/menu
    │   ├── InventoryScene.js      Inventário, equipamentos (7 slots), uso de consumíveis
    │   ├── CharacterScene.js      Atributos, level, XP, gasto de pontos de stat
    │   ├── QuestScene.js          Diário de missões com objetivos e recompensas
    │   ├── SkillScene.js          Árvore de habilidades passivas
    │   ├── ShopScene.js           Interface de compra/venda com mercadores
    │   ├── BookScene.js           Leitura de tomos da biblioteca
    │   ├── CompendiumScene.js     Codex elemental com informações de monstros
    │   ├── InferenceScene.js      Mini-jogo de teste de hipótese para Mimics
    │   ├── DialogScene.js         Diálogos com NPCs: typewriter effect, retrato, paginação automática, branching choices
    │   ├── GambleScene.js         Os Dados do Vex: apostas com probabilidade e valor esperado exibidos (gold sink pedagógico)
    │   └── ScratchpadScene.js     Calculadora + bloco de notas arrastáveis (persistem entre sessões)
    ├── entities/
    │   ├── Player.js      Sprite, movimento, vitals, passos por terreno
    │   ├── Monster.js     Sprite, patrulha/chase, barra de HP, aura elemental, variantes Elite (15%) e Cintilante (2%, 5× ouro)
    │   └── NPC.js         Sprite, ciclo de diálogos, interação
    └── data/
        ├── questions.js   243 questões (6 tópicos, 3 dificuldades, 3 tipos)
        ├── pyChallenges.js 38 desafios de código Python (6 tópicos, 141 casos de teste)
        ├── monsters.js    52 monstros (24 elementais + 6 chefes/especiais + 4 guardiões + 12 da Cripta + hard por área)
        ├── items.js       58 itens (consumíveis, equipamentos, scrolls, 6 materiais de forja, 2 ferramentas, Anel da Significância)
        ├── maps.js        17 mapas tile-based (6 superfícies + 3 casas + 6 profundezas + Câmara da Hipótese Nula + Cripta do Interpretador)
        ├── quests.js      10 missões principais com objetivos e recompensas
        ├── skills.js      13 habilidades passivas na árvore de habilidades
        ├── books.js       18 tomos com lore e bônus permanentes
        ├── shops.js       3 mercadores com estoques por área
        ├── bounties.js    Pools de bounties diárias por área
        ├── lore.js        Lore expandido do mundo
        ├── appearance.js  Opções de aparência para criação de personagem
        └── npcReactions.js  Linhas de diálogo reativas ao progresso (1× cada, playerData.seenReactions)
```

---

## Áreas do Mundo

| Área       | Tópico                    | Elemento | Nível Sugerido | Requisito de Desbloqueio |
|------------|---------------------------|----------|----------------|--------------------------|
| Village    | Tipos de Dados            | Normal   | 1              | —                        |
| Meadows    | Média/Mediana/Moda        | Terra    | 3              | 60% mastery no Village   |
| Forest     | Variância/Desvio Padrão   | Gelo     | 5              | —                        |
| Plains     | Probabilidade             | Fogo     | 8              | —                        |
| Mountains  | Distribuições             | Água     | 12             | —                        |
| Dungeon    | Testes de Hipótese        | Trevas   | 15             | 70% mastery em 3 áreas   |
| Codex      | Python e Ciência de Dados | vários   | 18             | 60% mastery no Dungeon   |

### Profundezas (subsolo)

Cada área de superfície tem um subterrâneo (`<area>_depths`) acessado por um **buraco semi-escondido** (tile 24) no mapa; a volta é pela **escada** (tile 25). Sem requisito de desbloqueio — os monstros mais fortes são o gate natural.

- **Escuridão estilo Tibia**: visão limitada a um círculo de luz ao redor do jogador (RenderTexture + erase de `light_radial`, com flicker); saídas têm luz fraca própria
- **Paredes secretas** (tile 26): visual de parede com rachadura sutil; SPACE adjacente abre a passagem (persistido em `playerData.secretsFound`, aplicado pelo MapManager na carga)
- Cada profundeza tem: 1 sala secreta murada com baú, 1 baú comum, 1 pergaminho críptico (`scroll_depths_*` em lore.js) com dica velada do segredo, e 6-7 monstros dos tiers mais altos da área
- Baús das profundezas pagam 1.8× o ouro da superfície
- Combate no subsolo conta para a maestria da **área-pai** (`parentArea()` em constants.js)
- Música própria (`underground`, dissonante) + ambiência de goteiras
- Os mapas foram gerados/validados por script (BFS de conectividade); bolsões secretos são inalcançáveis sem abrir a parede

### Ferramentas de exploração (estilo Tibia)

- **Pá do Escavador** (`shovel`, loja da Vila e do Ferreiro) abre **montes de terra** (tile 27 → vira buraco 24); **Picareta de Ferro** (`pickaxe`, loja do Ferreiro) quebra **rochas rachadas** (tile 28 → vira o chão da área). Itens `type: 'tool'`, nunca se gastam
- Interação: SPACE adjacente, como paredes secretas; sem a ferramenta, o chat dá a dica do que é preciso. Persistência em `playerData.dugSites` (`area:x:y`), aplicada pelo MapManager na carga
- 3 baús selados atrás de rochas: Grutas dos Prados (3,1), Fornalha Soterrada (3,1) e Abismo Alagado (15,1)

### Câmara da Hipótese Nula (Julgamento — quest épica estilo Annihilator)

- Entrada **enterrada** no canto sudeste do Calabouço (15,12; requer pá); dica na "Ata do Último Concílio" (scroll no Calabouço). Área `sanctum_depths`, sem monstros errantes
- O **altar** (tile 29) oferece o **Julgamento**: 4 combates consecutivos (`SANCTUM_GAUNTLET` em monsters.js — Guardião da Mediana/terra, de Sigma/gelo, do Acaso/fogo e A Hipótese Nula/trevas, todos só questões hard), **sem itens** (`rules.noItems`), sem cura entre lutas; fuga aborta o gauntlet (encadeamento em `WorldScene._onCombatEnd`)
- Recompensa única (`playerData.sanctumCleared`): **Anel da Significância** — relíquia `first_error_forgiven`: o 1º erro de cada combate não causa dano e preserva o streak (α = 0,05). Revanches pagam ouro. Conquista "Além do Alfa" + reação do Oráculo

---

## Cripta do Interpretador — desafios de código

Última área, ligada ao Calabouço por um portal em (11,13). Os monstros de lá têm
`questionKind: 'code'`: em vez de múltipla escolha, pedem uma função Python que é
**executada de verdade** contra casos de teste.

- **Execução**: `js/py/pyodideWorker.js` é um Web Worker clássico que carrega o Pyodide
  da CDN sob demanda — quem nunca entra na Cripta não paga o download. Rodar em worker
  é o que permite matar um laço infinito do jogador (`worker.terminate()`) sem travar o jogo;
  o timeout padrão de execução é 10s e o interpretador reboota sozinho depois.
- **Correção**: o harness Python (constante `HARNESS` no worker) executa `setup` → código do
  jogador → cada caso, com comparação tolerante ciente de float, numpy e pandas
  (`assert_frame_equal`/`allclose`). Cada caso roda com uma cópia limpa do dataset.
- **Testes ocultos**: casos com `hidden: true` não aparecem no enunciado e só rodam no envio —
  é o que impede resolver por tentativa e erro contra os exemplos.
- **Editor**: `js/utils/CodeEditor.js` é DOM em `position: fixed` sobre a página (o canvas de
  544×480 escalado não comporta digitação). Tab/Shift+Tab indentam, Enter auto-indenta depois
  de `:`, Ctrl+Enter roda os exemplos. O overlay **engole os eventos de teclado** e a CombatScene
  desliga `input.keyboard` das cenas Combat e World — senão cada letra digitada viraria atalho.
  Rascunhos ficam em `localStorage` por desafio (`meanfall_code_draft_<id>`).
- **Dano**: todos os testes passando = acerto normal (dano cheio, streak, maestria). Passar
  parte deles é **acerto parcial**: o jogador arranha o monstro (`base × ratio × 0.4`) e o
  contra-ataque é amortecido em `ratio × 50%`, mas a sequência zera. Zero testes ou desistência
  = erro cheio, com a solução de referência revelada no editor.
- **Tópicos → elementos** (`CODE_TOPIC_TO_ELEMENT` em constants.js): `py_basics`→normal,
  `py_structures`→trevas, `py_stats`→gelo, `py_numpy`→água, `py_pandas`→terra, `py_ml`→fogo.
  Reaproveitar os seis elementos mantém matchup, maestria elemental, essências e forja valendo.
- **Sem interpretador** (offline, navegador antigo, CDN fora do ar): a criatura recorre à
  questão teórica do elemento dela — o combate nunca trava.
- **Validação do banco**: `node tools/validate_py_challenges.mjs` roda todo desafio contra o
  mesmo harness do jogo e falha se um gabarito não passar ou se o esqueleto já passar.
  Requer `python3` com numpy e pandas. **Rode isso ao adicionar desafios.**

## Imersão (dia/noite, clima, companheiro, troféus)

- **Ciclo dia/noite** (`utils/DayNight.js`): derivado do relógio real, ciclo de 12 min (~7 dia / 1,5 anoitecer / 3 noite / 0,5 amanhecer), sem estado salvo. Mensagens de chat nas transições
- **Iluminação global**: retângulo `MULTIPLY` (depth 39) com cor interpolada por `DayNight.lightColor()` — amanhecer dourado, dia neutro, entardecer âmbar, noite azul. Só nas superfícies
- **Sombras suaves**: `entity_shadow` é gradiente radial (canvas); `WorldScene._updateShadows()` desloca/estica/apaga as sombras conforme o sol (`DayNight.shadowParams()`). Sombras de contato nos tiles: `SHADOW_CASTERS` no MapManager projeta `shadow_soft_h/v` no tile abaixo e à direita de tiles altos
- **Luzes pontuais** (blend `ADD`, depth 40, alpha ∝ darkness): janelas de casas, portais, buracos, baús e lanterna do jogador; tocha âmbar fixa nas profundezas (depth 41, acima da escuridão). Brasas/motas/vagalumes usam ADD
- **Vinheta** (`vignette`, depth 45): alpha 0.15 de dia → 0.4 à noite; 0.3 fixo em interiores/profundezas
- **Monstros Noturnos**: à noite, 18% de chance de spawn na superfície (exclusivo com Elite/Cintilante); 1.25× HP, 2.5× XP, 2× ouro, tint/aura violeta, nome `☾ ... Noturno`; ao amanhecer somem com fade e a versão comum respawna
- **Clima por área** (partículas, depth 38): pólen (Prados), neve (Floresta), brasas subindo (Planícies), chuva (Montanhas), motas de sombra (Calabouço), vagalumes só à noite (Vila, depth 41). Texturas `particle_dot`/`particle_streak` em Draw.js
- **Outlier, o companheiro** (`systems/CompanionSystem.js`): wisp que segue o jogador no mundo e assiste ao combate no painel; comemora acertos e murcha nos erros. Evolui pela maestria média das 6 áreas (estágio 2 ≥30%: +3% XP; estágio 3 ≥65%: +6% XP); estágio salvo em `playerData.companionStage`
- **NPCs reativos** (`data/npcReactions.js`): falas condicionais ao progresso (chefes, segredos, maestria, ouro, forja) prependadas ao diálogo normal; cada uma dispara 1× (`playerData.seenReactions`)
- **Troféus de chefes**: na casa da Anciã, 6 placas na parede (suportes vazios até derrotar cada chefe); gema pulsante na cor do chefe; SPACE adjacente mostra o flavor text

## UX (itens em combate, tracker, viagem rápida, pausa)

- **Itens em combate**: botão `✚ ITEM [E]` na barra inferior abre painel de consumíveis (usa `CombatSystem.useItem`); disponível fora do turno de resposta e durante a pausa da correção; usar item **zera o streak**
- **Rastreador de missão**: `#quest-tracker` no HUD DOM (painel esquerdo) mostra a missão ativa e progresso via `questProgress/questTarget`; completa → verde com "fale com <NPC>"
- **Viagem rápida**: Círculo Rúnico na Vila (tile 9,13); pisar abre Dialog com choices das áreas de superfície já visitadas (`discoveredTiles`); teleporta via `_doPortalTransition`
- **Menu de pausa**: ESC no mundo → Continuar / Salvar / Menu Principal; ao fechar, `_escKey.reset()` evita reabrir no mesmo pressionamento

## Sistema de Combate

- **Dano do jogador**: `floor(10 + level×1.5 + INT×0.5 + STR×0.3 + min(streak×2, 20)) × elemental × crítico − defesa`
- **Matchup elemental**: matrix 6×6 com multiplicadores 0.75× / 1.0× / 1.5×
- **Streak / Fever Mode**: acertos consecutivos aumentam dano; a partir de 5 acertos entra em Fever Mode (+40% dano, música intensificada)
- **Efeitos de status elementais** aplicados ao jogador em respostas erradas:
  - `queimadura` (fogo) — próximo erro causa +70% dano
  - `congelado` (gelo) — bloqueia uso de dica no turno
  - `enraizado` (terra) — tolerância numérica = 0
  - `encharcado` (água) — próximo erro +40% dano e tolerância = 0
  - `maldito` (trevas) — próximo erro causa dano dobrado
- **Variantes Elite**: 15% de chance de spawn; 2× HP, 3× ouro, aura visual única; o consumível Incenso do Caos força os próximos 3 spawns como Elite
- **Cintilante (shiny)**: 2% de chance; 5× ouro, 3× XP, 2 materiais garantidos, tint dourado
- **Mimics** (Dungeon): ativam `InferenceScene` — jogador faz um teste de hipótese (p-valor) antes do combate
- **Maestria elemental no dano**: +2% de dano por nível de maestria do elemento da arma (cap +30%)

---

## Loop de Farm

- **Materiais de forja**: monstros dropam `essence_<elemento>` (base 25%, +1%/nível de maestria do elemento, dobrado em Fever Mode; Elite garante 1, Cintilante garante 2)
- **Forja** (aba FORJAR na loja do Ferreiro Brom, Prados): aprimora equipamento até +3; cada nível custa ouro + materiais do elemento do item (`CombatSystem.forgeElement`) e escala os bônus em +25%/nível; nível salvo em `playerData.upgrades[itemId]`
- **Baús diários**: `openedChests[id]` guarda a data (YYYY-MM-DD) — reabrem todo dia com ouro + 45% de material do elemento da área + 12% de consumível
- **Bounty semanal**: Contrato da Semana (25 kills do elemento da área mais avançada) persiste pela semana ISO em `bountyLog.week`; recompensa inclui materiais
- **Fever Mode no loot**: streak 5+ concede +1 roll de loot e dobra a chance de material
- **Cassino do Vex** (Planícies): apostas de dados com P e valor esperado exibidos; compara saldo real × teórico da sessão

---

## Sistema de Questões

- **243 questões** em 6 tópicos: `data_types`, `mean_median_mode`, `spread`, `probability`, `distributions`, `inference`
- **38 desafios de código** em 6 tópicos: `py_basics`, `py_structures`, `py_stats`, `py_numpy`, `py_pandas`, `py_ml` (ver Cripta do Interpretador acima)
- **Geradores procedurais devem retornar `explanation` própria** — a da questão base cita os números originais e ficaria errada para o dataset gerado
- **3 tipos**: múltipla escolha, verdadeiro/falso, resposta numérica (com tolerância decimal configurável)
- **3 dificuldades**: easy, medium, hard — cada monstro filtra por dificuldade conforme seu nível
- **Aprendizado adaptativo**: `QuestionEngine` prioriza tópicos com menor taxa de acerto do jogador (60% de viés para questões erradas anteriormente)
- **Geração procedural**: `QuestionGenerator` cria questões numéricas únicas de média, variância, moda e probabilidade com datasets aleatórios

---

## Sistema de Eventos (EventBus)

Todos os sistemas se comunicam via `EventBus`. Eventos principais:

| Evento                  | Emitido por          | Escutado por       |
|-------------------------|----------------------|--------------------|
| `chat`                  | qualquer sistema     | UIScene            |
| `player-hp-change`      | CombatSystem         | UIScene            |
| `player-focus-change`   | CombatSystem         | UIScene            |
| `player-xp-change`      | XPSystem             | UIScene            |
| `player-level-up`       | XPSystem             | UIScene            |
| `player-stats-changed`  | XPSystem             | UIScene            |
| `area-changed`          | WorldScene           | UIScene            |
| `minimap-update`        | MapManager           | UIScene            |
| `combat-end`            | CombatScene          | WorldScene         |
| `quest-update`          | QuestSystem          | UIScene, QuestScene|
| `bounty-complete`       | BountySystem         | UIScene            |
| `fever-start`           | CombatScene          | UIScene, MusicSystem|
| `fever-end`             | CombatScene          | UIScene, MusicSystem|

---

## Convenções do Código

- **Sem bundler**: todos os imports são ES6 modules relativos
- **playerData** é o objeto central passado entre cenas via `scene.registry` ou `scene.settings.data`
- Texturas são geradas proceduralmente em `Draw.js` — não há imagens externas além do favicon e banner SVG
- `RichText` usa markup `{{tag:texto}}` para texto colorido em combate (ex: `{{damage:-15}}`, `{{xp:+50 XP}}`)
- Mensagens no chat usam classes CSS: `.system`, `.combat-hit`, `.combat-miss`, `.xp`, `.levelup`, `.portal`, `.dialog`
- Idioma do jogo: **Português**
- Questões ficam exclusivamente em `data/questions.js`; geração procedural em `systems/QuestionGenerator.js`
- Desafios de código ficam em `data/pyChallenges.js`; todo desafio precisa de `solution` (é o gabarito mostrado ao errar e o que o validador executa)
- Monstros derrotados são rastreados por `instanceId` em `playerData.defeatedMonsters`
- Música muda por área via `MusicSystem` — cada area tem uma track definida em `TRACKS`

---

## Dimensões do Jogo

- Canvas: **544 × 480 px**
- Tile: **32 × 32 px**
- Grid: **17 colunas × 15 linhas**
- Minimap: **180 × 180 px** (canvas separado no DOM)

---

## Sistema de Diálogo (DialogScene)

`DialogScene` é lançada via `scene.launch('Dialog', data)` e aceita os seguintes parâmetros:

| Parâmetro  | Tipo | Descrição |
|------------|------|-----------|
| `speaker`  | string | Nome exibido na tag acima da caixa |
| `npcId`    | string | ID do NPC para selecionar o retrato (`sprite_npc_<npcId>`). Opcional — fallback por `role` |
| `lines`    | string[] | Linhas de diálogo. Suporta markup `{{tag:valor}}`. Paginação automática: linhas longas são divididas em páginas de 4 linhas × 50 chars |
| `role`     | string | `'quest'` / `'shop'` / `'lore'` — define cor da tag e retrato padrão |
| `action`   | object | `{ label, kind }` — botão de ação na última linha (ex: abrir loja) |
| `choices`  | object[] | `[{ label, onSelect }]` — exibe caixa de escolhas acima do diálogo na última linha; navegação com `↑↓`, confirmação com `SPACE`/`ENTER`, cancelar com `ESC` |
| `onClose`  | fn | Callback ao fechar sem action/choice |
| `onAction` | fn | Callback ao acionar o botão `action` |

**Controles do jogador:**
- `SPACE` / `ENTER` / clique: pula digitação → avança linha → confirma choice
- `↑` / `↓`: navega choices
- `ESC`: fecha (ou seleciona último choice quando choices visíveis)

**Fluxo interno:** `_startTyping` (texto plano, char a char, com `Sound.dialogTick()`) → `_finishTyping` (renderiza tokens coloridos com fade) → `_showChoices` (se `choices` presente).

---

## Status Atual do Projeto

**~95% completo.** Modo código (Cripta do Interpretador) adicionado na v0.10.0. Todas as cenas, sistemas e dados estão implementados. O jogo está em produção em `meanfall.pro`.

**Áreas de trabalho contínuo:**
- Adição de novas questões (especialmente dificuldade hard em todas as áreas)
- Balanceamento de dificuldade e progressão de nível
- Polimento de UX (feedback visual, animações)
- Conteúdo adicional de quests e lore
