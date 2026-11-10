# MECANICAS — KINFIRE (Documento Técnico Canônico)

> Como cada sistema **funciona** por dentro. Regras de jogabilidade (o que o jogador pode/não pode) estão em `REGRAS_DO_JOGO.md`. História em `LORE.md`.
> **Canonicidade:** em caso de conflito entre este doc e o código, este doc vence e o código é corrigido no commit seguinte.

---

## 1. Princípios de engenharia

1. **Docs primeiro** — toda mecânica nova é descrita aqui antes de virar código.
2. **Data-driven** — conteúdo (biomas, territórios, diálogos, quests, loot, vendors) vive em Resources `.tres` ou JSON; scripts só contêm lógica.
3. **Tipagem estática total** em GDScript; zero números mágicos (constantes nomeadas).
4. **Sinais para decoupling** — lógica de jogo nunca referencia UI diretamente.
5. **Determinismo por semente** — tudo que é procedural deriva de `world_seed`; nada de `randi()` global no gerador.
6. **Save versionado** — bump de versão + função de migração; retrocompatível.

## 2. Mundo aberto procedural (existente — documentado)

- **Chunks** de 32×32 células (`OverworldGen.CHUNK`), tile de mundo por célula; `LOAD_RADIUS = 1` (3×3 chunks ativos), `UNLOAD_RADIUS = 2` (descarta e limpa nós).
- **Semente** por partida (`Game.world_seed = randi()` no novo jogo; salvo no save).
- **Biomas por 3 ruídos** — temperatura, umidade, corrupção → 7 biomas:
  Planícies, Floresta Sussurrante, Areias Escaldantes, Tundra Congelada, Pântano Pútrido, Ermos Vulcânicos, Terras Corrompidas.
- **Água** por ruído com margens automáticas; é obstáculo (a menos que futura mecânica de nado — backlog).
- **Perigo por distância** — `danger(célula)` cresce com a distância do acampamento inicial; nível da região = `clampi(1 + danger * 0.9, 1, 60)`.
- **Ciclo de dia/noite** — `DAY_LENGTH = 360s`; `Game.world_time ∈ [0,1)` persiste no save e avança na Fase 5 (dependência: rotação de estoque de vendors).
- **Persistência de mundo** — baús/santuários usados salvos em `Game.world_opened[persist_id]`; fogueiras registradas como waypoints (viagem rápida).

## 3. Territórios Raciais (NOVO — Fase 2)

- **14 capitais**, uma por raça, posicionadas proceduralmente pela semente: ~N células de distância entre si (espaçamento mínimo garantido), ajustadas para não caírem em água; a capital da raça do jogador fica mais próxima da origem (o "acampamento inicial" atual é promovido a capital da raça escolhida na criação).
- **Zona neutra central** — o Vale do Centro com a **Kinfire apagada** (arena-memorial da Fogueira dos Laços); território de todos = de ninguém.
- **Atribuição por Voronoi**: célula → território do capital mais próximo; a cell de bioma também define o "tema" visual do território (elfos da floresta em bioma floresta, anões em montanha/vulcânico etc.). Mapping raça↔bioma de preferência em `TerritoryData` (.tres): a semente tenta colocar cada capital em seu bioma preferido.
- **Escala de nível dos territórios**: nível base = distância do Vale do Centro; inimigos, loot e preços escalam por território.
- **Capital contém**: praça central com a Chama racial (apagada — religável nas quests do Ato 3), NPC chefe/líder racial, 3–6 NPCs comuns com diálogos e ganho-de-vida (§LORE.10), vendor especializado (§10), taberneiro com rumores (hooks de quest), tabuleiro de avisos com missões repetíveis.
- **Segurança**: dentro do perímetro da capital, inimigos não spawnam e os que entram são expulsos (repel radius).

## 4. Masmorras (existente — documentado)

- Gerador procedural por andar; **chefe a cada 3 profundidades** (rodízio Ogro/Putrefato/Azkhar, a expandir com chefes demoníacos na Fase 4 conforme LORE); baús, mímicos, santuários, armadilhas de espinhos, escadas.
- Entradas espalhadas no mundo com nome/nível próprios (`DUNGEON_NAMES`).
- **NOVO na Fase 4:** masmorras "Chama" — uma masmorra-chefe por bioma guardando a **Chama** daquele bioma (missão principal do Ato 3); layout usa o gerador existente com tileset do bioma.

## 5. Inimigos e Raridades

### 5.1 Comportamentos (existente)
`SWARM` (enxame, 4–7 por pack), padrão (2–4 por pack); habitats por bioma; `spawn_weight` pondera a escolha; `min_depth` limita aparição.

### 5.2 Raridade de monstro (NOVO — Fase 3; substitui `elite: bool`)
Enum `Rarity { COMUM=0, ELITE=1, CAMPEAO=2, LENDARIO=3, CHEFE=4 }`. Save retrocompatível: `elite=true` carrega como `ELITE`.

| Raridade | Chance (spawn de pack) | HP | Dano | XP/Ouro | Visual |
|---|---|---|---|---|---|
| Comum | — | ×1 | ×1 | ×1 | normal |
| Elite | 8% + 1%/nível | ×2.5 | ×1.3 | ×3 | contorno azul (atual) |
| Campeão | 2% | ×5 | ×1.8 + 1–2 afixos | ×6 | contorno roxo + aura pulsante + nome com título |
| Lendário | 0.3% | ×10 | ×2.5 + 2–3 afixos | ×15 | contorno laranja-brasa, aura de partículas, beam de luz, música/aviso de spawn |
| Chefe | roteirizado | ×20–30 | tabelado | ×25 | barra de chefe no topo + arena |

**Afixos de Campeão/Lendário** (estilo Diablo): `FURIOSO` (+30% vel. ataque), `ESCUDO ARCANO` (absorve X a cada 5s), `TELÚRICO` (imune a knockback), `VENENOSO` (ataque aplica veneno), `FANTASMA` (20% de esquiva), `MESTRE-DE-ENXAME` (invoca 3 lacaios ao chegar a 50% HP), `ARDENTE` (deixa piso em fogo), `CAMPEÃO-DAS-SOMBRAS` (teleporta a cada 6s). Sorteados sem repetição por RNG do chunk (determinístico pela semente).

### 5.3 Loot por raridade (NOVO — ver `REGRAS_DO_JOGO.md` §8–9 para fórmulas)
- **LootTableData** (.tres) por par (inimigo × raridade): pools de itens com pesos, quantidade, chance de essência, itens únicos garantidos para Lendário/Chefe.
- Lendários e chefes sempre dropam ≥1 item Lendário/Único + ≥1 **Essência** (moeda rara da economia).
- **Dropbeam** por cor de raridade já existe — estender às cores novas.

## 6. Combate (existente — resumo técnico)
`SkillExecutor` executa 15 tipos de SkillData; projéteis, FX, damage numbers; status: atordoamento, lentidão, confusão, medo, maldição; knockback (imune se afixo TELÚRICO); esquiva do jogador com cancelamento de recuperação; bloqueio com escudo. Elemental: fogo/gelo/raio/sombrio/sagrado/veneno com resistências por raça e afixos.

## 7. Diálogo e NPCs (NOVO — Fase 2)

- **DialogueData** (.tres): grafo de nós — `id, texto (ou array para paginar), retrato, escolhas[]`. Cada escolha: `próximo_id, condição, efeito` (set flag, dar item/ouro/quest, alterar reputação/ignorância).
- **Condições** (expression-like, avaliadas por um resolver): `flag X`, `raça = elfo`, `classe`, `reputação ≥ n`, `ignorância > n`, `quest em estágio k`, `possui item`.
- **Ignorância (mecânica central do usuário)**: `hero.ignorance` começa em 10 e decai ao completar tutoriais, missões e primeiros diálogos; nós de diálogo têm versão "leigo" (condição `ignorance > 5`) e "instruído" (`ignorance <= 5`) — NPCs estranham ("como você não sabe o que é uma guilda?") e depois param de estranhar. A UI mostra isso sutilmente (os NPCs tratam você diferente), não como número.
- **Retratos**: silhueta para o Cinzento; sprites de rosto por raça/sexo gerados do tileset.
- **Sussurros do Cinzento**: durante o prólogo e nos atos, o Cinzento aparece como sombra nos Marcos de Cinza (pedras marcadas) para dar dicas — nunca em cutscene longa, sempre jogável.

## 8. Sistema de Missões (NOVO — Fase 4)

- **QuestData** (.tres): `id, título, descrição, estágios[]`. Estágio: `objetivos[]` (matar N, coletar item, falar com NPC, chegar a local, religar Chama), `diálogo de entrega`, `recompensas` (XP, ouro, item com raridade mínima garantida, reputação, flags), `pré-requisitos` (quests/flags/reputação).
- **QuestLog** no `Game` (autoload): estado ativo/estágio atual/contadores; persistido no save; sinal `quest_updated` para HUD.
- **Tracker no HUD**: até 3 quests marcadas; objetivo atual com progresso (7/10 lobos).
- **Cadeia principal**: 20 quests nos 3 atos (listadas em `LORE.md` §11–13); um Fragmento de verdade nunca vem da principal — só das laterais (regra do usuário: final verdadeiro exige secundárias).
- **Fragmentos da Verdade**: 8 itens-quest; ao colecionar todos, destrava o estágio final alternativo da quest "O Fogo dos Laços" (final verdadeiro).
- **Missões repetíveis** nos tabuleiros de avisos (fetch/kill) — fonte de renda infinita mas com XP decrescente.

## 9. UI/UX — DIREÇÃO VISUAL MODERNA (NOVO — prioridade do usuário)

### 9.1 Linguagem visual: "dark fantasy premium"
Sensação: **linterna sobre pergaminho à noite** — escuro acolhedor, dourado quente, brasa viva. Referências de tom: Diablo 4 (clareza de estado), Hades (legibilidade), GRIS/Bastion (não — só na suavidade das transições).

**Design tokens (UIKit):**

| Token | Valor | Uso |
|---|---|---|
| `BG_BASE` | `#0B0908` | fundo do jogo/menus |
| `PANEL_BG` | `rgba(22,17,13, 0.86)` + blur 4px | painéis "vidro escuro" |
| `PANEL_BORDER` | `rgba(240,192,96, 0.25)` 1px | contorno dourado sutil |
| `ACCENT_GOLD` | `#F0C060` | destaques, títulos, seleção |
| `ACCENT_EMBER` | `#E06C2A` | brasa: XP, fogo, aviso |
| `TEXT_MAIN` | `#E8E2D6` | texto principal (bege claro) |
| `TEXT_DIM` | `#9A917F` | texto secundário |
| `HP_RED / MANA_BLUE / …` | por recurso de classe | barras |
| Raridades | `#B8B8B8 / #5B8DFF / #C65CFF / #FF9A3C` | Comum/Mágico/Raro/Lendário (+ formas para daltônismo: círculo/losango/triângulo/estrela) |
| `RADIUS` | 8px (botões), 12px (painéis) | cantos |
| `SPACING` | 4/8/12/16/24 | grade de 4 |
| Fontes | **Cinzel** (títulos), **Alegreya** (corpo) | já no projeto |
| Sombra | `0 4px 16px rgba(0,0,0,0.5)` | elevação de painéis |

### 9.2 HUD moderna (layout)

```
┌───────────────────────────────────────────────────────────┐
│ [Buff strip: ícones com anel de tempo]        [Minimapa ⬤] │
│                                                            │
│                 (espaço de jogo limpo)                     │
│                                                            │
│ TR tracker                                          ORB/   │
│ quests recolhível          [Barra de vida segmentada] vida│
│  ▸ A Fome é Mestra          [Barra de recurso]   recurso   │
│    4/6                      [Emblema nível + anel XP]     │
│ [chips: 🪙ouro ◆essência]   [skill][skill][skill][skill][R]│
└───────────────────────────────────────────────────────────┘
```

- **Barras de vida/recurso** (não orbes pesados): barras horizontais segmentadas com "tick marks" a cada 25%, gradiente interno sutil, brilho na ponta quando cheia, tremor + flash vermelho na borda ao tomar dano; quando o recurso da classe é especial (Fúria), a barra "fervilha" (ondulação).
- **Emblema de nível** circular com **anel de XP** preenchendo ao redor; sobe `float` + partícula ao subir de nível.
- **Skill bar**: slots quadrados 48px, **cooldown radial** (varredura em cone escura + número de segundos), badge da tecla no canto, ícone cinza quando sem recurso; hover mostra tooltip completo.
- **Chips de moeda** no canto inferior esquerdo: ouro com ícone de moeda, essência com losango; animação de contagem ao ganhar (+12 flutua).
- **Buff strip** no topo esquerdo: ícones com anel de tempo; expira com fade.
- **Tracker de quests** à direita (recolhível por clique): objetivos com progresso; ao concluir objetivo, *check* com som + shake suave de recompensa.
- **Minimapa redondo** (máscara circular) no canto superior direito, com borda dourada e ping animado em waypoints.
- **Barras de inimigos** flutuantes: cor por raridade (§5.2), ornameto de coroa para campeão+; barra de chefe no topo da tela com nome e retrato.
- **Mensagens de HUD** viram **toasts** empilháveis no topo-centro, entrando com slide+fade.

### 9.3 Interface do player e menus
- **Painel de personagem unificado** com abas: Personagem | Inventário | Habilidades | Quests | (Comércio quando aberto via vendor). Abas com underline dourado animado; teclas I/C/K continuam abrindo direto na aba.
- **Tooltips ricos**: nome por raridade, tipo, requisito (vermelho se não cumpre), atributos, afixos (verde), lore de itens únicos (itálico bege), preço.
- **Comparador**: com tooltip aberto, painel fantasma do item equipado ao lado; setas ▲▼ verdes/vermelhas por atributo.
- **Inventário**: grid de slots, item com glow de raridade no slot; drag & drop com fantasma do ícone; shift-click = equipar/usar; ctrl-click = vender (com vendor aberto).
- **Menu principal**: logo com shader de névoa (existe) + partículas de brasa subindo, título com leve float; botões em cards horizontais com hover lift e som; versão e seed no rodapé; "Continuar" mostra o resumo do save atual.
- **Micro-interações globais** (UIKit): hover = lift 2px + glow dourado; press = scale 0.96; foco teclado = anel dourado 2px; painéis abrem/fecham com tween 0.18s back-ease; sons discretos de hover/click (bus SFX).

### 9.4 Checklist de audit (gate de aceite da Fase 6)
- [ ] Contraste mínimo 4.5:1 em todo texto sobre painel
- [ ] Todo estado de botão tem idle/hover/press/focus/disabled visíveis
- [ ] Navegação por teclado em 100% dos painéis (Tab/Enter/Esc/setas)
- [ ] Raridades distinguíveis sem cor (formas/ícones)
- [ ] Tooltips nunca cobrem o alvo do clique nem saem da tela
- [ ] Feedback sonoro e visual para: dano, cura, drop raro+, level up, quest update, compra/venda, erro
- [ ] UI scale 0.75–1.5 sem quebra de layout
- [ ] Toques em 60fps (tweens sem stutter) e pausa correta de animações de UI quando o jogo pausa
- [ ] Coerência: mesmo componente nunca aparece com 2 estilos

## 10. Economia e Mercado (NOVO — Fase 5)

- **VendorData** (.tres): raça, especialidades (categorias com bônus de preço), slots de estoque, orçamento de raridades.
- **Estoque rotativo**: por dia do mundo (`world_time` inteiro), re-sorteia N itens do pool do vendor (RNG = semente + dia + id do vendor → determinístico, verificável).
- **Preço dinâmico**: cada categoria tem `demanda ∈ [0.6, 1.5]`, iniciando 1.0; **vender** reduz a demanda da categoria em 3% por item (recupera 5%/dia); **comprar** aumenta. Comprar barato num território e vender caro noutro é o lucro do mercador-jogador (rotas emergem naturalmente).
- **Reputação** (`hero.reputation: Dictionary[race -> int 0..4]`): ganha por quests e entrega de itens de favor; descontos 0/5/10/15/20% por tier (`Estranho, Conhecido, Respeitado, Honrado, Laço`).
- **Casa de leilões** (Guilda dos Aventureiros, capital humana): 6 slots diários de itens Raro+; lance mínimo sobe 10% por lance rival (simulado por NPCs); itens únicos de chefes podem aparecer raramente.
- **Essência**: dropada só por Campeão/Lendário/Chefe; moeda para lances especiais e re-forja (backlog).
- Fórmulas de preço em `REGRAS_DO_JOGO.md` §10.

## 11. Prólogo / Tutorial (NOVO — Fase 1)

- **Enquadramento narrativo** (LORE §9): a "vila do tutorial" é a **Reminiscência** de Vale Cinzento — memória do jogador guiada pelo Cinzento. Justifica: (a) por que o jogador é aldeão; (b) por que ele conhece o básico do corpo (mover/atacar) mas não o mundo (guildas, territórios, moedas).
- **Máquina de estados do tutorial**: `TutStep` enum com sinal `step_done(id)`; passos: mover → atacar espantalho → coletar drop → equipar → poção → fogueira. Gate físico (cerca de névoa) até concluir tudo.
- **Nível 1** dispara a transição: espelho do quarto mostra **nenhum reflexo** (o Véu roubou o reflexo) → tela de criação (raça → classe → atributos → nome, obrigatórios) → cutscene curta → acampamento da raça escolhida.
- O herói de prólogo é um `Hero` válido com classe "Aldeão" e raça "Humano" ocultos — reutiliza todo o combate; ao criar o personagem de verdade, o objeto é **reconstruído** (nível 1, pontos redistribuídos).

## 12. Save / Migrações

- v3 (atual) → **v4**: adiciona `phase`, `ignorance`, `reputation`, `quests`, `fragmentos`, `territory_seed_info`; `elite` → `rarity` na serialização de inimigos é derivada em runtime (inimigos não são salvos, só o mundo persistente).
- Regra: `load_game()` chama `_migrate(data)` encadeado por versão; testes garantem que um save v3 abre sem perda.

## 14. Renderização, Luz, Sombra e Atmósfera (NOVO — Fase 7)

> **Nota técnica (honestidade de engenharia):** o pedido incluía *ray tracing* e *DLSS*. RT é técnica de renderização 3D (no Godot 4 é SDFGI/clustered lights, só na cena 3D) e DLSS é upscaler proprietário NVIDIA sem integração no Godot ("DLSS 5" não existe — o SDK atual é o 4). Nenhum dos dois se aplica a um jogo 2D pixel-art. O pacote abaixo entrega o **intento** do pedido — iluminação premium e escala moderna — com o que o 2D do Godot 4.7 realmente oferece.

### 14.1 Relógio na HUD e ciclo de dia/noite rico
- 1 dia de Eldara = **360s reais** (6 min, `DAY_LENGTH`); `Game.world_time ∈ [0,1)` é a fonte da verdade, avança em tempo real (pausa quando o jogo pausa).
- **Chip de relógio na HUD** (ao lado do minimapa): `HH:MM` de Eldara em 24h + ícone sol/lua com arco de progresso do dia; meia-noite = `24:00`/`00:00` exato na virada.
- Dormir na fogueira = fast-forward com fade até o amanhecer (06:00).
- **Color grading por keyframes** (interpolação suave, sem saltos) sobre `CanvasModulate` + ajustes de ambiente:

| Hora | Tom do mundo | Efeito |
|---|---|---|
| 00:00 | azul-profundo, brilho 0.55 | vagalumes, spawns noturnos |
| 05:30 | madrugada cinza-azul | silêncio de pássaros |
| 06:30 | amanhecer âmbar | galo; vendors re-estocam às 06:00 |
| 12:00 | neutro (referência) | — |
| 17:30 | dourado de fim de tarde | sombras longas |
| 19:00 | crepúsculo lilás | lanterna do herói acende sozinha |
| 21:00 | noite | mortos-vivos +50% de peso em biomas sombrios |

- **Eventos por hora via signal `hour_changed(h)`**: 06:00 re-estoque de vendors (§10), 00:00 tick de autosave ("A Vela Virou"), quests com janelas de horário (contatos noturnos dos mistérios).

### 14.2 Sombras dinâmicas 2D (o "ray tracing" do 2D)
- `PointLight2D` com `shadow_enabled`, `shadow_filter` PCF5 (Médio) / **PCF13 (Alto)**; cada luz com cor/energia/oscilação termostada por fonte (fogueira oscila, lava pulsa, tocha crepita).
- `LightOccluder2D` em: árvores, paredes de masmorra, tendas, lápides, muros de capital → **sombras reais que se movem** conforme as luzes.
- **Lanterna do herói**: PointLight2D quente (raio ~90px) que acende sozinha no crepúsculo; visível no sprite (item visual).
- **Orçamento de luz**: máx ~8 luzes com sombra ativas na tela; além disso degrada para sem sombra; preset Baixo desliga sombras. Meta: 60fps.
- Máscaras temáticas: luz **sagrada** ignora oclusores (cura atravessa paredes); luz **sombria** não projeta sombra (lore LORE §16: "luz sem laço não projeta sombra").

### 14.3 Materiais e pós-processo 2D
- **Normal maps** nos sprites-chave (herói por raça, chefes, props grandes) → speculares direcionais (rim light dourado perto da fogueira).
- **Bloom/Glow** via WorldEnvironment (`glow_enabled` + HDR 2D): fogo, lava, orbes, feixes de loot Raro+, auras de Campeão/Lendário.
- **Vinheta e temperatura por bioma** (shader fullscreen): Tundra fria-azul, Areias quente, Pântano esverdeado, Terras Corrompidas dessaturadas + vinheta roxa.

### 14.4 Clima e partículas ambientais
- Por bioma (GPUParticles2D): folhas (floresta), neve (tundra), cinzas (vulcânico), esporos brilhantes (pântano), poeira/areia (planícies/deserto), vagalumes noturnos (planícies/floresta).
- **Névoa volumétrica fake** (shader de camadas parallax) no pântano e Terras Corrompidas; mais densa à noite.
- **Chuva ocasional global**, determinística (semente+dia), com som ambiente; relâmpago = flash de CanvasModulate + trovão.

### 14.5 Sistema de Vento e Movimento Ambiental (NOVO — decisão do usuário)
> **Princípio:** o mundo *respira*. Vento não é decoração — é **informação** (direção do perigo, mudança de tempo, presença de chefes) e **mecânica** (afeta projéteis, som, partículas, navegação).

#### 14.5.1 Campo de vento global (WindField)
- **WindField** (resource autoload): vetor de vento global `Vector2 direction` + `float strength` (0.0–1.0), atualizado a cada **tick de 10s** com ruido Perlin 2D (semente do mundo + tempo) → **vento coerente espacial e temporalmente** (não muda abrupto).
- Variação por **bioma** (offset no noise):
  - Planícies: vento constante Oeste→Leste, força média 0.4
  - Floresta: turbulento, redemoinhos locais, força 0.3
  - Areias: ventania forte Norte→Sul, força 0.6, tempestades de areia (evento)
  - Tundra: vento gelado constante, força 0.5, *wind chill* visual
  - Pântano: calmo, bolhas de gás sobem (vento vertical leve)
  - Vulcânico: ascensão térmica (vento para cima), força 0.4
  - Corrompidas: vento *errático*, muda direção aleatoriamente, força 0.3
- **Eventos de vento** (determinísticos por seed+dia):
  - **Calmaria** (força <0.1): partículas param, som de vento cessa, *presságio* — 30% chance de chefe spawnar nas próximas 2h.
  - **Ventania** (força >0.8): som de vento uivante, partículas densas, projéteis desviados (±15°), *buff* de velocidade de movimento a favor do vento (+10%).
  - **Mudança de frente** (direção vira >90° em <1h): *storm front* visual (nuvens rápidas), chuva segue em 10min.

#### 14.5.2 Vegetação reativa (shader de vento nos sprites)
- **Shader `wind_sway.gdshader`** aplicado a: árvores, grama alta, arbustos, cipós, flores, culturas, bandeiras, tendas, cabelos/penas de NPCs.
- Uniformes por instância: `wind_strength`, `wind_direction`, `flexibility` (0.0–1.0), `phase_offset` (para não sincronizar tudo).
- **LOD de vento**: perto da câmera (200px) = shader completo com vértices; longe = apenas *texture offset* leve; fora da tela = desligado.
- **Interação do jogador**: andar através da grama = *empurra* a grama (ripple local no shader via `player_wind_ripple` uniform); rolar/esquivar = ripple maior.
- **Interação de projéteis**: flechas/feitiços de vento (Classe Caçador, Mago) criam *vórtice local* momentâneo.
- **Chefe spawn**: vento *para* num raio de 50m ao redor do chefe (calmaria sobrenatural) — *cue visual/auditiva gratuita*.

#### 14.5.3 Partículas transportadas pelo vento
- GPUParticles2D (folhas, cinzas, neve, pólen, esporos, fagulhas) herdam `WindField.direction * WindField.strength * particle_mass_factor`.
- **Massa da partícula** define sensibilidade: folha leve = 1.0, cinza = 0.7, neve = 0.5, fagulha = 0.3.
- **Emissores de partículas** (fogões, lareiras, forjas, vulcões) emitem *na direção do vento* (cone alinhado).

#### 14.5.4 Efeitos mecânicos do vento
| Mecânica | Efeito |
|---|---|
| **Projéteis físicos** (flechas, dardos, lanças) | Desvio angular = `wind_strength * 15° * (1 - projectile_mass_norm)`; flecha leve desvia mais. |
| **Projéteis mágicos** | Só afetados se *tag* `wind_affected` (ex.: `Arcane Missile` sim, `Holy Bolt` não). |
| **Som** | `WindField.strength` controla volume do bus `Ambience` (vento) e *pitch* do som de vento (mais agudo = mais forte). |
| **Navegação (A*)** | Custo de mover *contra* vento +5%; *a favor* -5% (sutil, incentiva rotas). |
| **Cheiro/Rastreamento** (Caçador, Lobo) | Rastro de cheiro *dispersa* com o vento — tracker mostra direção *a favor do vento* como mais nítida. |
| **Velas/Fogueiras** | Chama da fogueira inclina no shader; vento forte (>0.7) *apaga* tochas não protegidas (mecânica de masmorra). |
| **Roupas/Capas/Capuzes** | Shader de *cloth simulation* leve nos sprites de equipamento (capa, capuz, saia, cabelos longos). |

#### 14.5.5 WindField como *gameplay* (integração com lore)
- **Mistério 1 (Sussurro nos Mapas)**: vento *sopra na direção* da próxima página do diário (dica sutil — partículas brilham mais nessa direção).
- **Caçador (Classe)**: habilidade **"Ler o Vento"** = mostra vetor de vento no minimapa por 30s + projéteis ignoram desvio por 10s.
- **Xamã/Druida**: forma de **Coruja** = voa *com* o vento (velocidade 2× a favor, 0.5× contra).
- **Masmorras**: salas de **ventilação** (corredores com vento forte) — empurram jogador/inimigos; puzzles de *fechar portas* para mudar fluxo.
- **Chefe de Mundo (Azkhar, Senhor das Tempestades)**: *controla o WindField* na arena — muda direção a cada fase, cria tornados locais.

#### 14.5.6 Performance e presets
| Preset | Shader vento | Partículas transportadas | Desvio projéteis | Ripple jogador |
|---|---|---|---|---|
| Baixo | Desligado (offset textura só) | Só direção, sem força | Não | Não |
| Médio | Vértices (árvores/grama perto) | Direção + força | Sim (flechas) | Sim (perto) |
| Alto | Completo + LOD dinâmico | Física completa (massa) | Todos `wind_affected` | Sim (raio 300px) |

### 14.6 Escala e núcleo de vídeo (o "DLSS" que existe)
- **FSR 2.2** nativo do Godot 4.3+ como opção nas Opções de Vídeo: Desligado / Qualidade / Equilibrado / Desempenho.
- MSAA 2×/4×; `texture_filter` nearest preservado (pixel-art nítida).
- **Presets de qualidade**: Baixo (sem sombras, sem glow, partículas 50%), Médio (PCF5), Alto (PCF13 + glow + 100%).
- Meta de performance: 60fps com 3×3 chunks ativos + 6 luzes com sombra na tela.

### 14.6 Integração com sistemas
- Relógio alimenta: vendors (§10), spawns noturnos (§5), janelas de horário de quest (§8), Noite dos Faróis (lanternas nas capitais após quest do Ato 2).
- Luz alimenta: raridades (beam/glow por raridade §5.3), masmorras (tochas fixas + escuridão ambiente), clima (raios).

## 15. Áudio Adaptativo (NOVO — Fase 7 — decisão D10)

> Princípio: **o jogador sente a noite antes de vê-la no relógio.** Som é mecânica, não decoração.

### 15.1 Buses e mixagem
- Buses: `Master`, `Music`, `SFX` (existentes) + **`Ambience`** e **`UI`** (novos) — cada um com slider nas Opções → Áudio.
- Regra de ducking: música −6dB durante diálogo; ambience −3dB perto de fogueira à noite (aconchego audível de zona segura).

### 15.2 Música em camadas (crossfade por estado)
| Camada | Quando | Exemplo |
|---|---|---|
| BASE | sempre, definida pelo bioma/território/capital | loop do bioma; capital = motivo-melodia da raça |
| COMBATE | fade-in 1.5s ao aggro, fade-out 4s sem dano | percussão + cordas curtas |
| NOITE | 21:00–05:30 | pad grave e lento sobre a base |
| CHEFE | chefe ativo | variação intensa com tambores |
| DESCANSO | perto de fogueira acesa | tema de descanso curto + crackle da fogueira |

### 15.3 Ambiência por bioma (crossfade 3s)
Vento (Planícies) • folhas + pássaros (Floresta) • areia + abutres distantes (Areias) • vento gelado (Tundra) • gorgolejo de pântano • rumble de lava (Vulcânico) • drone dissonante + sinos distantes (Corrompidas). Masmorra: reverb fake (bus com low-pass/predelay por tipo de sala) + ping de escada distante.

### 15.4 Som como radar (cues posicionais)
- Packs fora de tela grunhem **do lado correto** (pan) — o som anuncia o perigo antes da tela.
- Morcegos noturnos: batida de asas aguda; cultistas sussurram no escuro; campeão+ = **sting de spawn** (Campeão: coral grave curto; Lendário: sino + coro) que chega antes de você vê-lo.
- Relâmpago: flash visual + trovão com delay por distância.

### 15.5 SFX de UI (integra com §9)
Hover (tick suave) • click • erro (buzz curto) • compra/venda (moedas) • quest concluída (sino) • quest update (tinte) • level up (acorde quente) • equipar (metálico por tipo de item).

## 16. Testes

- Smoke test existente cobre: menus, opções, criação das 14 classes, habilidades, loot, morte, save.
- **Extensões obrigatórias por fase** (gate de commit): prólogo ponta a ponta (1), diálogo + reputação (2), tabela de drops por raridade — asserts de drop garantido 100× sem falsos (3), quest completa com flags (4), preço dinâmico em 3 dias simulados (5), checklist UI não é automatizável — screenshots manuais no smoke com `SMOKE_SHOTS` (6).
