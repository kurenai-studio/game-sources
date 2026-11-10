# Kinfire

**v1.0.2-beta** — RPG de ação 2D top-down em **Godot 4.7** (Flatpak).  
14 raças × 14 classes, inspirado em **D&D 5e / Baldur's Gate** + combate **estilo Diablo 3** (itens com afixos, raridades, build diversity). Mundo aberto procedural infinito com lore profunda (Sete Chamas, Véu da Discórdia, dois finais).

Criado por [MichaelDCA](https://github.com/MichaelDouglasCA) e [fabioadler](https://github.com/fabioadler).

---

## Como jogar (PT-BR)

Abra o projeto no Godot 4.7 (Flatpak) e aperte **F5**:

```bash
flatpak run --filesystem=$PWD org.godotengine.Godot --path .
```

| Ação | Controle (remapeável em Opções → Controles) |
|---|---|
| Andar | WASD / setas ou clique esquerdo no chão |
| Atacar | Clique esquerdo no inimigo (segure para continuar) |
| Atacar parado | Shift + clique esquerdo |
| Habilidade secundária | Clique direito |
| Habilidades 1–4 | Z, X, C, V |
| Cura simples (Q) | Q |
| Interagir (fogueira, baú, NPC, portal, item) | E |
| Habilidade racial (ex.: Sopro do Draconato) | R |
| Esquiva (cancela a recuperação do ataque) | Espaço |
| Inventário | I |
| Personagem | P |
| Habilidades | K |
| Árvore de habilidades | B |
| Missões | J |
| Consumíveis 1–9 | 1 … 9 |
| Mostrar itens no chão | Alt |
| Menu / fechar painéis | Esc |
| Chat local / party / guilda | Enter / Y / G |

---

## Mundo aberto procedural infinito

Cada partida usa uma **semente única** e gera um mundo aberto infinito em **chunks 32×32** determinísticos (estilo Minecraft). Perto do centro fica o **Vale do Centro** — zona neutra com a **Kinfire apagada** (a Fogueira dos Laços).

### 7 biomas (temperatura + umidade + corrupção via Voronoi)

| Bioma | Visual | Dificuldade base |
|---|---|---|
| **Planícies** | Grama, rios, vilas | 1–5 |
| **Floresta Sussurrante** | Árvores densas, folhas ao vento | 2–8 |
| **Areias Escaldantes** | Dunas, cactos, oásis | 2–10 |
| **Tundra Congelada** | Pinheiros, neve, lagos gelados | 3–12 |
| **Pântano Pútrido** | Água turva, vitórias-régias, névoa | 3–15 |
| **Ermos Vulcânicos** | Lava, cinzas, rochas | 4–18 |
| **Terras Corrompidas** | Lápides, árvores mortas, nevoa roxa | 5–25 |

- **Rios e lagos** por ruído, com margens automáticas (obstáculo).
- **Nível da região** = distância do Vale do Centro (0,0) + modificador do território → `clampi(1 + danger × 0.9, 1, 60)`.
- **Fogueiras** = respawn, cura total, viagem rápida entre fogueiras descobertas, dormir até 06:00.
- **Masmorras** procedurais (nomes próprios, andares, chefe a cada 3, escada de volta, baús, santuários, armadilhas).
- **Baús, santuários, chefes de mundo** (Ogro, Putrefato, Azkhar + raros).
- **Ciclo dia/noite** (360 s = 6 min reais): 06:00 vendors re-estocam; 21:00–05:00 noite (mortos-vivos +50% de peso de spawn, aggro +10%); 00:00 autosave ("A Vela Virou").
- **Minimapa** redondo: biomas, água, fogueiras, masmorras, mercador, inimigos, waypoints, vetor do vento.

---

## Territórios & capitais (14 raças)

O mundo é dividido em **14 territórios raciais** (Voronoi por semente + raça do jogador) + a zona neutra do Vale do Centro. Cada território tem sua **capital** — zona 100% segura (sem spawn de inimigos; repel radius), com líder NPC + plebeus com diálogos próprios, economia própria, fogueira principal (waypoint) e Pedra Marco do Cinzento. A capital da raça escolhida vira o acampamento inicial do prólogo.

| Raça | Capital | Líder |
|---|---|---|
| Humano | Porto Franco | Guildmaster Eleanor Vane |
| Alto Elfo | Torres de Prata | Arquimaga Lyrielle |
| Elfo da Floresta | Raiz-Mãe | Anciã Sylwen |
| Drow | Cidade-Eco | Matriarca Vaelora |
| Anão da Montanha | Forja-Coração | Thane Brynjar |
| Anão das Colinas | Colheita-Funda | Mestra Cervejeira Hela |
| Halfling | Vale dos Sete Ventos | Prefeita Mira Pé-Leve |
| Meio-Orc | Cicatrizz | Chefe Kargan |
| Tiefling | Cinzas-Vivas | Embaixadora Xal'atath |
| Draconato | Escama-Eterna | Senhor do Vulcão Kragoth |
| Gnomo | Engrenagem | Grão-Mestre Tinker |
| Meio-Elfo | Ponte-dos-Mundos | Embaixador-Duplo |
| Tabaxi | Selva-de-Seda | Caçadora-Nata Jinx |
| Golias | Pico-Que-Toca-O-Céu | Ancião da Pedra |

Dados em `data/territories/*.tres` (capital, líder, economia, cultura, bioma preferido, fala do Cinzento na 1ª fogueira).

---

## Inimigos: raridades & afixos

37 tipos de monstro base (`data/enemies/*.tres`), cada um com habitats (masmorra + biomas) e `spawn_weight`. **Raridade por pack** (determinístico por chunk + dificuldade):

| Raridade | Chance | HP | Dano | XP/Ouro | Drops | Afixos |
|---|---|---|---|---|---|---|
| Comum | base | ×1 | ×1 | ×1 | 10% item Comum | — |
| **Elite** | 8% + 1%/nível | ×2.5 | ×1.3 | ×3 | ≥1 Mágico + ouro | 0 |
| **Campeão** | 2% | ×5 | ×1.8 | ×6 | ≥1 Raro + 20% Lendário + 50% Essência | 1–2 |
| **Lendário** | 0,3% | ×10 | ×2.5 | ×15 | ≥1 Lendário/Único + ≥1 Essência | 2–3 |
| Chefe | roteirizado | ×20–30 | tabelado | ×25 | ≥2 itens (≥1 Raro+) + Essência ×2 + único | — |

**Afixos (Campeão 1–2, Lendário 2–3):** FURIOSO · ESCUDO ARCANO · TELÚRICO (imune a knockback) · VENENOSO · FANTASMA (20% esquiva) · MESTRE-DE-ENXAME · ARDENTE · CAMPEÃO-DAS-SOMBRAS — sorteados sem repetição pelo RNG do chunk.

**Visual feedback:** contorno colorido por raridade, aura pulsante Campeão+, **beam visível de longe + sting sonoro no spawn Lendário**, kill anunciado na HUD, barra de chefe no topo.

**Elementos & resistências:** Fogo, Gelo, Raio, Sagrado, Sombrio, Veneno.
- **Mortos-vivos** (esqueleto, zumbi, fantasma, putrefato, necromante, lobo sombrio, wogol, espantalho, abóbora maldita, médico da peste): **fraqueza a Sagrado (×1.5)**.
- **Demônios** (anjo caído, chort, diabrete, caranguejo infernal, azkhar, mímico): **imunes a Sombrio, fracos a Sagrado (×1.5)** — lore: não têm laço. Não droptam ouro, droptam **Essência**. Não entram em raio de 50 m de fogueira acesa.

**Status effects:** atordoar (2 s), lentidão (40%, 5 s), confusão (6 s), medo (4 s), maldição, veneno (DoT), fogo (DoT). **Esquiva** = i-frames curtos, cancela a recuperação do ataque. **Bloqueio** com escudo reduz dano frontal (Paladino gera Fé ao bloquear). **Knockback** padrão (imune: Anões da Montanha, afixo TELÚRICO, chefes).

---

## Itens estilo Diablo

- **7 slots:** elmo, amuleto, arma, armadura, mão secundária, anel, botas (duas mãos = arma + secundária).
- **4 raridades** (`Item.Rarity`): Comum (0 afixos) → Mágico (1–2) → Raro (3–4) → Lendário (5 + nome único). Cores `#B8B8B8 / #5B8DFF / #C65CFF / #FF9A3C` + formas para daltônismo.
- **Valor de venda** = `(5 + nível×3) × (1 + raridade×2)` × demanda × reputação. Vendor compra a **40%**.
- **Identificação:** Raro+ já identificado (sem minigame).
- **Proficiência:** por classe (Mago não empunha machado 2M do Bárbaro; Meio-Elfo equipa até 3 níveis acima).
- **Essência:** moeda "dura" só de Campeão/Lendário/Chefe/demônios — lances especiais na Casa de Leilões.
- Loot por `(inimigo × raridade)` via `LootTableData` (.tres); itens únicos garantidos de Lendário/Chefe.

---

## Economia & mercado

- **14 vendors** (`data/vendors/*.tres`) com estoque rotativo diário (re-estoque 06:00, determinístico por semente+dia) e especialidades regionais.
- **Oferta/demanda por categoria** ∈ [0.6, 1.5]: vender reduz o preço pago em **3%/item** (recupera 5%/dia); comprar eleva preço e reduz estoque. Rotas comerciais emergem (comprar barato num território, vender caro noutro).
- **Reputação 0–4** por território (Estranho → Conhecido → Respeitado → Honrado → Laço): descontos **0/5/10/15/20%**. Ganha-se por quests/favores; nunca decai.
- **Casa de Leilões** (Porto Franco): 6 slots/dia de itens Raro+ rotativos (70% Raro / 25% Lendário / 5% Relíquia) + 1 slot em Essência; lance inicial = valor × 1.2; contra-lances rivais simulados sobem o mínimo ×1.10.
- **Anti-exploit:** XP de quest repetível decai −20% por repetição (mín. 20%).

---

## Quests, mistérios & finais

- **32 quests** em `data/quests/*.tres`: cadeia principal em **3 atos** (A Estranha → O Tabuleiro → A Verdade) + **8 cadeias de mistério** (`misterio_1..8`).
- Cada mistério rende **1 Fragmento da Verdade** (coletado automaticamente). **Final Dourado exige os 8 Fragmentos** (`FRAGMENTS_FOR_GOLDEN := 8`); com menos, o Final Cinzento.
- **Quest Log (J):** tracker lateral, painel com progresso, aviso de nova missão, autoflow (flag→next, objetivos KILL/TALK/REACH/COLLECT/FLAG, wildcard `any:capital_*_lider`).
- **Recompensa padrão:** XP = `40 × nível_quest × ato` + ouro + item (raridade mínima = ato: Mágico/Raro/Lendário).
- **Sistema de lore (v1.0):** **Brasa** (🔥 0–7, só na dungeon Kinfire do Ato 3: +1 por zona, −1 ao sair sem matar o boss; cada nível = +5% XP, +2% dano, −1% dano recebido) e **Laços/Bonds** (⛓️ 7 Fragmentos dos Guardiões: Mira, Ashara, Lorelyn, Theron, Kael, Khalid, Pyros — 1 por `misterio_1..7`; gateia `ato3_1` e o Final Dourado). Após `misterio_7`, o **Cinzento revela-se Ithariel**, o 8º Guardião.
- **Finais:** Cinzento (Fenda selada, mundo continua reescrito, título "Guardião Cinzento") vs. Dourado "O Fogo dos Laços" (Kinfire renasce, Véu destruído, título "Guardião Remanescente").

---

## Lore (resumo)

> *"A Kinfire não aquece. Ela lembra."* — antes do mundo havia o Frio da ausência; a **Primeira Chama** criou o reconhecimento ("nós"). Dela nasceram os **Sete Primeiros Laços** (Vínculo, Memória, Coragem, Comércio, Canção, Raiz, Chama). As raças emergiram onde cada Laço ressoava. Há 1.133 anos o **Pacto dos Laços** mantinha o Concílio das Chamas na Kinfire (Vale do Centro) — hoje **apagada há 14 anos**, com a **Véu da Discórdia** reescrevendo memórias (tratados viram traição, raças "sempre foram inimigas", mapas mudam à noite). **Maldrach, a Ausência que Anda**, abriu a Fenda e corrompeu; seus generais são os **Sete Sussurros**. O jogador é o **Laço-Vivo de Vale Cinzento** — a vila que o Véu apagou da memória de todos — imune a mentiras, reconstruindo o próprio reflexo na criação de personagem. Regra de ouro da escrita: *show, don't tell* (a mãe esquece o nome do filho na sua frente; o mapa muda quando você não olha).

---

## Guildas, contratos, party & multiplayer

- **5 tipos de guilda:** Aventureiros (contratos, party, rank F–S), Mercadores (taxas −50%, leilão extra, rotas, empréstimos, câmbio Essência↔Ouro), Artesãos (forja/alquimia/domador avançados), Sombras (contratos sombrios, safehouses, endgame) e **Guilda criada pelo jogador** (nível 25 + 5.000 ouro + 3 fundadores; nome, brasão, banco compartilhado, hall, território conquistável; padrão vs. expandida).
- **Contratos procedurais** (`data/contracts/*.tres`): COMBATE / COLETA / ESCOLTA / INVESTIGAÇÃO, em cadeias que promovem o rank da guilda (1 contrato ativo como membro, até 3 como mestre; limite 2 h reais).
- **Rank F–S** do herói (reconhecimento mundial, não decai): F→E→D→C→B→A→S por nível, contratos, chefes, mistérios e fragmentos.
- **Party** (máx. 4): jogadores LAN drop-in + NPCs recrutáveis (Marn, Bree, +5–8 únicos por classe). XP 50% líder / 50% dividido; loot round-robin configurável; progresso de quest compartilhado.
- **Multiplayer LAN co-op drop-in:** host abre o mundo, guests entram com seus próprios heróis (handshake valida level/stats/inventory/quests via hash + machine ID). Simulação autoritativa no host (movimento, dano, loot, XP, quests), snapshot 20 Hz; ao sair, o guest recebe o delta de progresso e aplica no próprio save (sem dupe). Canais de chat LOCAL/PARTY/GUILD/WHISPER com rate limit. Anti-cheat: vida/dano/velocidade/itens validados no host; ban por Machine ID.

---

## Vento, clima & som adaptativo

- **WindField** global: value-noise determinístico (ticks de 10 s, base por bioma, Corrompidas erráticas), coherent no espaço e no tempo. **Vento é informação e mecânica:** ventania = ±10% velocidade, custo de rota ±5%, projéteis físicos desviam conforme `wind_mass`, partículas herdam o vento, som do bus Ambience segue a força (calmaria −7 dB … ventania +3 dB). **Calmaria de Campeões:** vento para num raio de 320 px (cue de perigo). **Forecast/presságio** diário por (semente, dia); calmaria = 30% de chance de chefe nas próximas 2 h. Shader `wind_sway` curva vegetação/chama; ventania > 0.7 sufoca tochas. Skill "Ler o Vento" (Caçador): flechas retas + vetor no minimapa.
- **Clima:** chuva determinística por (semente, dia) ~20% dos dias; `WeatherLayer` com 7 emissores GPUParticles2D de texturas procedurais (folhas, neve, cinzas, esporos, poeira, chuva 220 gotas, **vagalumes noturnos** que florescem no glow HDR e voam contra o vento); névoa volumétrica fake (`fog_drift.gdshader`, 2 camadas parallax empurradas pelo vento, mais densa à noite); relâmpago (flash >1 no glow) + trovão procedural com atraso 0.3–1.1 s.
- **Áudio adaptativo** (autoload `Audio`) — *o jogador sente a noite antes de vê-la no relógio:* música em 5 camadas com crossfade (BASE por bioma/território, COMBATE fade-in 1.5 s ao aggro, NOITE 21:00–05:30, CHEFE, DESCANSO perto de fogueira com crackle); ambiência por bioma (7) + masmorra (reverb fake + low-pass 2.5 kHz); 16 WAVs 16-bit 22050 Hz procedurais; ducking (diálogo −6 dB na música, fogueira à noite −3 dB na ambiência); sting de spawn (Campeão = coral grave, Lendário = sino+coral); cues posicionais (packs grunhem do lado certo). Buses `Ambience`/`UI` com sliders nas Opções.

---

## Vídeo & gráficos

- **Sombras dinâmicas 2D reais** (o "ray tracing" do 2D): `PointLight2D` + oclusão por tile (`LightOccluder2D`), PCF5 (Suave) / PCF13 (Nítido), orçamento ~8 luzes com sombra ≤ 720 px, tremulação por fonte (FIRE/LAVA/TORCH). Lanterna do herói acende sozinha no crepúsculo. Luz sagrada atravessa paredes; luz sombria não projeta sombra (tema de lore).
- **Pós-processo HDR 2D** (WorldEnvironment): glow/bloom (threshold 1.05 — fogo, lava, loot Raro+, auras), rim light nos sprites, vinheta + temperatura de cor por bioma (CanvasLayer 2 entre mundo e HUD).
- **Vídeo:** FSR 2.2 nativo (escalas 1.0 / 0.77 / 0.67 / 0.5 + `fsr_sharpness 0.4`), MSAA 2×/4×, filtro `nearest` (pixel-art nítida), presets **Baixo/Médio/Alto** (sombras, FSR, MSAA, glow, partículas 50/75/100% via `Game.particle_mult()`), glow reativo em runtime via signal `quality_changed`.
- **Nota de honestidade:** o pedido original incluía *ray tracing* e *DLSS* — não se aplicam a um jogo 2D pixel-art no Godot 4 (RT é 3D; DLSS é SDK proprietário NVIDIA sem integração no Godot). O pacote acima entrega o intento com o equivalente 2D real.

---

## Raças (14) — atributos + passivas

| Raça | Atributos | Passiva |
|---|---|---|
| Humano | +1 tudo | +10% XP/ouro |
| Alto Elfo | +2 INT, +1 DES | +15% recurso máx, 20% resist mágica |
| Elfo da Floresta | +2 DES, +1 CON | +10% vel, esquiva auto a cada 10 s |
| Drow | +2 DES, +1 INT | +15% dano vs CC (atordo/lento/confusão) |
| Anão da Montanha | +2 CON, +2 FOR, −1 DES | Imune a empurrão, +10% armadura |
| Anão das Colinas | +2 CON, +1 SAB | Regen fora de combate 2×, 25% resist veneno |
| Halfling | +2 DES | Crítico 5% dobrado, hitbox menor |
| Meio-Orc | +2 FOR, +1 CON | Sobrevive a 1 golpe fatal (CD 2 min) |
| Tiefling | +2 INT, +1 FOR | 25% resist fogo, espinhos de fogo 10% |
| Draconato | +2 FOR, +1 INT | Sopro de fogo em cone (R), imune a fogo |
| Gnomo | +2 INT | −10% cooldown |
| Meio-Elfo | +2 CAR, +1 à escolha | Equipa itens até 3 níveis acima |
| Tabaxi | +2 DES | 5 acertos → +40% vel/aspd |
| Golias | +2 FOR, +2 CON, −1 INT | Inventário 30% maior, armas 2M 10% mais rápidas |

**Criação de personagem (point-buy D&D 5e):** 6 atributos (FOR, DES, CON, INT, SAB, CAR), 27 pontos, custo 8=0 / 9–13=1 / 14=2 / 15=3, mín. 8 máx. 15 antes dos bônus raciais; modificador = `(valor − 10) / 2` (para baixo). 8 antecedentes (Soldado, Acólito, Criminoso, Sábio, Nobre, Forasteiro, Artesão de Guilda, Herói do Povo) dão item inicial + diálogo. Fluxo obrigatório: raça → classe → pontos → nome (16 caracteres).

---

## Classes (14) — recurso + estilo

| Classe | Recurso | Mecânica-chave |
|---|---|---|
| Bárbaro | Fúria | Gera batendo/apanhando; Salto, Turbilhão, Grito |
| Feiticeiro | Mana | Regen alta; Fogo/Gelo/Raio; Meteoro/Nevaca |
| Ladino | Energia | Recarrega 4× após 2 s ocioso; venenos/esquivas |
| Guerreiro | Vigor | Bloqueio com escudo; golpes táticos |
| Paladino | Fé | Gera batendo/bloqueando; auras + Sagrado |
| Necromante | Essência | Ganha em mortes; esqueletos, golem, maldição |
| Caçador | Concentração | Regen só parado; arco, lobo, armadilhas, Ler o Vento |
| Monge | Chi | Todo 3º golpe = ×2 dano + stun; curas |
| Bruxo | Pacto | Magias custam vida; roubo 10%, diabretes |
| Druida | Espírito | Forma Lobo/Urso; terremoto |
| Clérigo | Mana | 15% do dano vira cura; armadura pesada |
| Bardo | Inspiração | Zonas de som: inimigos confusos se atacam |
| Mago | Carga Arcana | Gera no ataque básico; teleporte, raio, dobra temporal |
| Lâmina Arcana | Fluxo | Golpes reduzem CD das magias; magias encantam a lâmina |

**Skills:** 84 base (6 por classe, desbloqueadas por nível; 4 slots equipáveis Z/X/C/V + racial R) + **árvore de habilidades** data-driven (`scripts/data/skill_trees.gd`, 143 arquivos `.tres` em `data/skills/` no total): +1 ponto de árvore por nível, **não respeitável**, cada classe com 4 skills inéditas + ranks (+15% dano / −7% CD por rank, máx. 3–5). **Pontos de status:** +2 por nível (livres e respeitáveis). Nenhuma classe fica sem recurso em repouso por mais de 10 s.

---

## HUD & design system

- **HUD moderna:** barras de vida/recurso segmentadas (marcas a cada 25%, flash ao tomar dano), **emblema de nível com anel XP**, chips de ouro/essência, strip de buffs, **minimapa redondo**, cooldown radial nos slots de skill, tracker de quests recolhível (J), target box com afixos, damage numbers por elemento, toasts empilháveis, kill announce de Lendário.
- **Painel unificado:** Personagem / Inventário (grade w×h, drag & drop, comparador) / Habilidades / Missões / Árvore na mesma janela (I/P/K/J/B abrem direto na aba). Tooltips ricos, pop_in/pop_out em toda janela (0.18 s back-ease), navegación 100% por teclado, ESC fecha.
- **Design tokens (dark-fantasy premium — "linterna sobre pergaminho à noite"):** fundo `#0B0908`, painel `rgba(22,17,13,0.86)` + blur 4 px, borda dourada `rgba(240,192,96,0.25)`, acento ouro `#F0C060` / brasa `#E06C2A`, texto `#E8E2D6` / dim `#9A917F`; fontes **Cinzel** (títulos) e **Alegreya** (corpo); grid de espaçamento 4 px; radius 8/12 px; micro-interações hover lift + glow, press scale 0.96, foco anel dourado; contraste mínimo 4.5:1; raridades distinguíveis sem cor (formas).

---

## Prólogo

Jogador começa como **Aldeão nível 0** (ataque básico, sem classe/raça). XP acelerado → nível 1 em ~5 min (2 lutas + coleta + equipar). A vila do tutorial é a **Reminiscência** de Vale Cinzento; itens do tutorial **não saem dela** ("o que pertence ao sonho fica no sonho"). Ao nível 1: cutscene do espelho **sem reflexo** (o Véu roubou a auto-imagem) → criação obrigatória → acampamento da raça escolhida, onde o Cinzento entrega o diálogo de abertura.

---

## Dificuldades (estilo Diablo) & morte

| Modo | HP inimigos | Dano inimigos | Bônus loot | XP | Morte (ouro) |
|---|---|---|---|---|---|
| Normal | ×1.0 | ×1.0 | — | ×1.0 | −10% |
| Difícil | ×1.6 | ×1.35 | +8% raridade | ×1.25 | −20% |
| Pesadelo | ×2.5 | ×1.8 | +16% raridade | ×1.6 | −30% |
| Inferno | ×4.0 | ×2.5 | +28% raridade | ×2.0 | −30% + Elite+ ganha +1 afixo |

**Hardcore** = toggle sobre qualquer dificuldade: morte permanente, o save vira lápide somente leitura. Morte normal = respawn na última fogueira acesa com HP cheio.

---

## Progressão & save

- **XP próximo nível:** `20 × nível^1.5` (níveis 1–60; nível máx. 9999, monstros limitados a 60). XP de monstro escala com o nível do monstro.
- **Subir nível:** +HP (`hit_die + CON`/nível), +recurso (atributo primário), **+1 ponto de atributo a cada 4 níveis** (1, 5, 9, 13…).
- **Ignorância:** começa em 10 (pós-prólogo) e só decai (tutorial, quests, primeiros diálogos) — afeta apenas textos de diálogo, nunca atributos.
- **Save:** `user://kinfire_save.json` + `user://kinfire_settings.cfg`, **versão 4** (`SAVE_VERSION := 4`: prólogo, quests, reputação, fragmentos,-Ignorância, territórios), migrações encadeadas v1→…→v4 preservam saves antigos. 1 slot. Autosave: fogueira, 00:00, entrar/sair de masmorra, concluir quest.

---

## Arquitetura (data-driven, decoupled)

```
data/                      Custom Resources (.tres) — editáveis no Inspector
  races/ (14)              RaceData      — bônus, resistências, passivas, sprite
  classes/ (14 + aldeão)   ClassData     — hit_die, recurso, proficiências, skills
  skills/<classe>/         SkillData     — 15 tipos (golpe, projétil, raio, invocação, transformação…)
  enemies/ (37)            EnemyData     — comportamento, elemento, sprite, habitats
  territories/ (14+1)      TerritoryData — capital, líder, economia, cultura
  vendors/ (14)            VendorData    — estoque base, especialidades, rotas
  quests/ (32)             QuestData     — objetivos, recompensas, fragmentos
  guilds/ · contracts/     GuildData / ContractData
  dialogues/ · npcs/       DialogueData / NpcData (+ diálogos gerados por template)
  index.json               Ordem de carregamento
scripts/
  autoload/                Game (estado, save, opções, signals), Audio, Sfx, DB, LoreInitializer
  core/                    Hero, Item, InventoryGrid, QuestLog, Market, WindField, Weather, LightFx, guilds, rank
  items/                   Item, afixos, roll de raridade
  combat/                  SkillExecutor, Projectile, efeitos, Fx
  game/                    Player, Enemy, Minion, LootDrop, World (masmorra), Overworld (chunks)
  net/                     sincronização multiplayer (host autoritativo)
  ui/ · menus/             HUD, painéis, DialogueBox, OptionsPanel, MainMenu, CharacterCreation
shaders/                   hit_flash, wind_sway, fog_drift, atmosphere
tests/                     smoke_test.gd + auditorias automatizadas
```

**Princípios de engenharia:** docs primeiro; data-driven (conteúdo em `.tres`/JSON, scripts só com lógica); GDScript 100% tipado, zero números mágicos; decoupling por **signals** (lógica de jogo não referencia UI); determinismo por semente (`world_seed`); save versionado com migração; 1 arquivo = 1 responsabilidade.

---

## Testes & auditoria

```bash
# Smoke test de ponta a ponta (headless, Godot 4.7 via Flatpak)
flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke
# Screenshots do smoke:
SMOKE_SHOTS=/pasta flatpak run --filesystem=$PWD org.godotengine.Godot --path . -- --smoke

# Auditoria completa de playthrough (gera audit_report.json/.txt + log em user://)
./run_audit_test.sh
# ou direto:
flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . res://tests/test_full_playthrough_audit.gd
```

O smoke percorre: menus → opções → criação de herói de **cada classe** → todas as skills + racial → equipa itens → mata inimigos → baús → morre/ressuscita → salva → masmorra → quests/economia/diálogo/prólogo/raridades/luz/som (200+ asserts, 0 erros). A auditoria valida 6 fases (inicialização, prólogo, criação, 50 níveis, sistemas, análise) com métricas e relatório de bugs por severidade. Auditoria de código (2026-10-30): 3 críticos / 7 altos / 12 médios / 4 avisos — os críticos (equipagem via clique direito `inventory_panel.gd`, validação `can_use_category()` `hero.gd`, loop infinito potencial `dungeon_generator.gd`) foram corrigidos.

---

## Decisões de design (D1–D10)

| # | Tema | Decisão |
|---|---|---|
| D1 | UI/UX | CLI `ui-ux-pro-max-cli` ausente no ambiente → audit manual contra o checklist de UI; integração fica opcional |
| D2 | Economia | Escopo completo (mercadores, estoque rotativo, oferta/demanda, reputação, leilão); crafting/coleta no backlog |
| D3 | Docs | Documentação canônica versionada no repositório (este README) |
| D4 | Fases | 0 Higiene → 1 Prólogo → 2 Diálogos/Territórios → 3 Raridade/Loot → 4 Quests → 5 Economia → 6 UI/UX → 7 Polimento (raridade antes de quests por dependência de loot) |
| D5 | Prólogo | Cena dedicada (aldeão nível 0) → nível 1 → criação obrigatória → acampamento racial |
| D6 | Commits | Conventional Commits, 1 commit por unidade de funcionalidade |
| D7 | UI | Dark-fantasy premium desde a Fase 1 (tokens primeiro, aplicação completa na Fase 6) |
| D8 | Lore | Lore extenso e rico alimentando diálogos, quests e itens |
| D9 | Renderização | RT/DLSS não se aplicam a 2D pixel-art → entregues sombras 2D reais + FSR 2.2 + MSAA (o intento honesto) |
| D10 | Som | Áudio adaptativo em camadas; som como mecânica (radar de perigo), não decoração |

---

## Notas de versão

- **v0.3 (2026-10-26):** Fases 0–8 — mundo procedural (7 biomas, 14 territórios), prólogo, diálogo/NPCs, raridades de monstro + afixos, loot Diablo, quests 20+8, economia dinâmica, HUD moderna, sombras/glow/vento/som/clima/FSR.
- **v1.0 (2026-10-28):** Fases 9–11 — correções pós-v0.3 (Cinzento persistente, scroll nos painéis), progressão ARPG (árvore de skills data-driven, +1 pt de árvore/nível, 4 skills novas por classe com ranks), guildas & contratos, sistema de lore (7 Guardiões, Brasa 0–7, Laços, revelação de Ithariel, Final Cinzento/Dourado).
- **v1.0.2-beta (atual):** correção de todos os erros de parse/compile do GDScript (verificado com Godot 4.7 headless); save v4; unificação da documentação em um único README.

### Guia rápido de playtest (finais)

- **Final Cinzento (~1 h):** complete `misterio_1..7` mas pule ao menos um Guardião → em `ato3_8` (Maldrach) fale com o Cinzento → Fenda selada, mundo continua reescrito.
- **Final Dourado (~2 h):** complete os 7 mistérios **e** colete os 7 Guardiões (Mira, Ashara, Lorelyn, Theron, Kael, Khalid, Pyros) → dialogue do Cinzento vira revelação de Ithariel → na Kinfire colete Brasa (zonas) → derrote Maldrach → Kinfire renasce.

### Backlog (v2)

Crafting & coleta · caravanas com escolta · montarias · pets de combate não-ladino · localização EN · New Game+ · conquista de masmorras · ranking hardcore local · PvP/arena/guerras de guilda · voice acting e cutscenes dos finais.

---

## Créditos dos assets

- **Personagens, monstros, masmorra:** [0x72 — DungeonTileset II](https://0x72.itch.io/dungeontileset-ii) (CC0)
- **Ícones:** [Henrique Lazarini (7Soul1) — 496 RPG Icons](https://opengameart.org/content/496-pixel-art-icons-for-medievalfantasy-rpg) (CC0)
- **Tiles mundo, UI, sons:** [Kenney](https://kenney.nl): Roguelike RPG Pack, Tiny Dungeon, UI Pack RPG Expansion, RPG Audio, Impact Sounds (CC0)
- **Música:** "Cave Theme" (OpenGameArt, CC0) + "Dark Ambience Loop" Iwan Gabovitch (CC-BY 3.0)
- **Fontes:** Cinzel, Alegreya (SIL OFL)

Licenças completas em `assets/licenses/`.

---

## Licença

MIT — veja `LICENSE` (exceto assets com suas licenças próprias em `assets/licenses/`).
