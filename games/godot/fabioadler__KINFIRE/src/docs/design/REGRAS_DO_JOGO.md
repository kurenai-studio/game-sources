**REGRAS DO JOGO — KINFIRE (Documento Canônico)**  
***O que o jogador pode e não pode.*** *Como cada sistema funciona por dentro: `MECANICAS.md`. História: `LORE.md`.*  
   
***Canonicidade:*** *em caso de conflito entre este doc e o código, este doc vence; o código é corrigido no commit seguinte.*  
   
***Auditoria Fase 0.2 (2026-10-25): concluída.*** *Todos os `[VERIFICAR]` foram conferidos contra o código: itens confirmados ganharam `✓`; divergências foram registradas na §16 e corrigidas no código no commit seguinte.*  
   
---  
**1. Atributos e criação de personagem**  
- **6 atributos:** FOR (força), DES (destreza), CON (constituição), INT (inteligência), SAB (sabedoria), CAR (carisma).  
- **Compra de pontos (D&D 5e):** 27 pontos; custos 8=0, 9–13=1, 14=2, 15=3; mínimo 8, máximo 15 antes de bônus raciais.  
- **Bônus raciais** aplicam-se após a compra (ex.: Anão da Montanha +2 CON +2 FOR −1 DES). ✓ conferido em `data/races/*.tres`  
- **Modificador** = `(valor − 10) / 2` (arredondado para baixo).  
- **Antecedente:** escolhido na criação (Soldado, Acólito, Criminoso, Sábio, Nobre, Forasteiro, Artesão de Guilda, Herói do Povo); dá item inicial + ganho narrativo (diálogos com tag). ✓ 8 antecedentes em `db.gd`  
- **Fluxo obrigatório (prólogo):** raça → classe → distribuição de pontos → nome. Nenhum passo é pulável; gerador "Aleatório" existe.  
- **Nomes:** gerador por raça; nome manual limitado a 16 caracteres.  
**2. Progressão**  
- **Nível máximo: 9999** (limitado pela escala de `danger()` do mundo).  
- **XP:** monstro dá XP base × multiplicador de raridade (§6); missões dão XP fixo por ato (§10).  
  - **Regra canônica:** XP para o próximo nível = `20 × nível^1.5` (níveis 1–60). ✓ (código legado usava `80 × nível^1.6` — corrigido na Fase 0.4)  
- **Ao subir de nível:** +HP, +recurso e +1 ponto de atributo a cada 4 níveis (1, 5, 9, 13…). ✓ (código legado dava +1 por nível — corrigido na Fase 0.4)  
- **Habilidades:** 6 por classe, desbloqueadas por nível de classe; slot de 4 equipáveis + racial. ✓ (84 skills / 14 classes em `data/skills/`)
- **Ignorância:** o herói começa com `ignorance = 10` (após o prólogo); decai ao completar passos de tutorial, missões e primeiros-diálogos; nunca sobe. Afeta apenas textos de diálogo (nunca atributos).
- **Árvore de Habilidades (Fase 10.4):** +1 ponto de árvore por nível; **não respeitável** (escolhas permanentes). Cada classe tem árvore própria com **4 skills novas** (desbloqueiam skills inéditas) + **melhorias (ranks)** nas skills base. Ranks: +15% dano / −7% cooldown por rank (máx. 3–5 ranks por nó). Nó verde = disponível; dourado = desbloqueado; cinza = bloqueado (pré-requisitos não atendidos). Dados em `scripts/data/skill_trees.gd` (GDScript, data-driven). UI no painel unificado (tecla **B**).
- **Pontos de Status (Fase 10.2):** +2 pontos por nível (livres, respeitáveis a qualquer momento); base por classe não respeitável, sobe automaticamente com o nível.
**3. Combate**
- **Dano de arma** = base do item × (1 + (atributo relevante − 10) × 0.05) × bônus de raridade (aplicado na geração do item). ✓ conferido em `hero.gd` (`damage_multiplier`)  
- **Crítico:** chance base por raça/classe/afixos (ex.: Halfling 5% de chance dobrada); dano crítico padrão ×2.  
- **Esquiva (dodge):** consumível com i-frames curtos; cancela a recuperação do ataque; recharge 0.8s.  
- **Bloqueio:** classes com escudo reduzem X% do dano frontal; Paladino gera Fé ao bloquear.  
- **Status effects:** atordoar (2s), lentidão (40%, 5s), confusão (ataca aliados, 6s), medo (foge, 4s), maldição (+dano recebido), veneno (DoT 5s), fogo (DoT + visual). ✓ stun/lentidão/confusão/medo/maldição confirmados em `skill_executor.gd`; veneno/fogo como DoT — cobertura completa conferida na Fase 3.  
- **Elementos e resistências:** Fogo, Gelo, Raio, Sagrado, Sombrio, Veneno. Resistências vêm de raça (ex.: Draconato imune a fogo), afixos e santuários. Vulnerabilidades: mortos-vivos levam ×1.5 de Sagrado, demônios ×1.5 Sagrado e −25% Sombrio? **Regra canônica:** demônios são imunes a Sombrio e fracos a Sagrado (lore: não têm laço).  
- **Knockback:** padrão; imune: Anões da Montanha, afixo TELÚRICO, chefes.  
- **Elite+ não pode ser empurrado para fora da arena de chefe.**  
**4. Recursos de classe**  
Definidos por classe (Fúria, Mana, Energia, Vigor, Fé, Essência, Concentração, Chi, Pacto, Espírito, Inspiração, Carga Arcana, Fluxo). Regras de gasto/regeneração são propriedade do `ClassData` (`resource_max`, `resource_regen`). ✓ conferido em `hero.gd`/`class_data.gd` Regra transversal: nenhuma classe fica sem recurso em repouso por mais de 10s (evita "esperar mana").  
**5. Morte, renascimento e hardcore**  
- **Morte:** respawn na última fogueira acesa; HP cheio; perde 10% do ouro carregado (Normal) / 20% (Difícil) / 30% (Pesadelo e Inferno). ✓ (código legado aplicava 10% fixo — corrigido na Fase 0.4)  
- **Hardcore:** morte é permanente — o save vira lápide (somente leitura do resumo); sem second chances.  
- **Fogueira:** acender define respawn, cura total, salva o jogo, permite dormir até o amanhecer (avança o relógio para 06:00).  
**6. Raridades de monstros e drops (NOVO)**  
  
|  |  |  |  |  |  |  |  
| - | - | - | - | - | - | - |  
| **Raridade** |  **Chance por pack** |  **HP** |  **Dano** |  **XP/Ouro** |  **Drops garantidos** |  
| Comum |  — |  ×1 |  ×1 |  ×1 |  ouro pequeno; 10% item Comum |  
| Elite |  8% +1%/nível |  ×2.5 |  ×1.3 |  ×3 |  ≥1 item Mágico + ouro |  
| Campeão |  2% |  ×5 |  ×1.8 |  ×6 |  ≥1 Raro + chance 20% Lendário + 50% Essência |  
| Lendário |  0,3% |  ×10 |  ×2.5 |  ×15 |  ≥1 Lendário/Único + ≥1 Essência |  
| Chefe |  roteirizado |  ×20–30 |  tabelado |  ×25 |  ≥2 itens (≥1 Raro+) + Essência ×2 + item único possível |  
  
   
- **Afixos** (Campeão 1–2; Lendário 2–3): FURIOSO, ESCUDO ARCANO, TELÚRICO, VENENOSO, FANTASMA, MESTRE-DE-ENXAME, ARDENTE, CAMPEÃO-DAS-SOMBRAS (`MECANICAS.md` §5.2).  
- **Drop beam** por cor de raridade; Lendário anuncia spawn com sting + beam visível de longe.  
- **Dificuldade por região:** nível do monstro = nível da região (`1 + danger×0.9`, máx 60); XP escala com o nível do monstro, não do jogador.  
- **Noite (21:00–05:00):** mortos-vivos têm +50% de peso de spawn em biomas sombrios; todos os monstros ganham +10% de agressividade (raio de aggro).  
**7. Dificuldades do jogo**  
Sistema estilo Diablo (multiplicadores em `db.gd` → `DIFFICULTIES`). ✓ conferido e canônico:  
  
|  |  |  |  |  |  |  |  
| - | - | - | - | - | - | - |  
| **Modo** |  **HP dos inimigos** |  **Dano dos inimigos** |  **Bônus de loot** |  **XP** |  **Penalidade de morte** |  
| Normal |  ×1.0 |  ×1.0 |  — |  ×1.0 |  −10% ouro |  
| Difícil |  ×1.6 |  ×1.35 |  +8% chance de raridade |  ×1.25 |  −20% ouro |  
| Pesadelo |  ×2.5 |  ×1.8 |  +16% chance de raridade |  ×1.6 |  −30% ouro |  
| Inferno |  ×4.0 |  ×2.5 |  +28% chance de raridade |  ×2.0 |  −30% ouro; elites+ ganham +1 afixo (regra da §6, aplicada na Fase 3) |  
  
   
Hardcore é um toggle sobre qualquer dificuldade.  
**8. Itens e equipamento**  
- **7 slots:** elmo, amuleto, arma, armadura, mão secundária, anel, botas. Armas de duas mãos ocupam arma + mão secundária.  
- **Proficiência:** por classe; itens não-proficientes não equipam (Mago não empunha machado de duas mãos do Bárbaro).  
- **Raridades de item:** Comum (0 afixos) → Mágico (1–2) → Raro (3–4) → Lendário (5 + nome épico). ✓ conferido em `db.gd` (`n_affixes = [0, 1–2, 3–4, 5]`)  
- **Nível necessário:** item até 3 níveis acima equipa só para Meio-Elfo (passiva).  
- **Valor de venda** = `(5 + item_level × 3) × (1 + raridade × 2)` × condição × demanda (§9). Vendor compra a 40% do valor.  
- **Identificação:** itens Raro+ dropam já identificados (sem minigame de identify — decisão: fricção sem diversão).  
**9. Ouro e essência**  
- Ouro dropa de monstros (valor base da região × raridade), baús, quests e vendas.  
- **Essência:** só de Campeão/Lendário/Chefe; moeda "dura" da economia — usada em lances especiais da casa de leilões e (backlog) re-forja.  
- Tudo é visível nos chips da HUD (§MECANICAS 9.2).  
**10. Economia e mercado (NOVO)**  
- **Preço de compra** = valor base × fator de demanda da categoria × (1 + escassez regional) × (1 − desconto de reputação).  
- **Oferta/demanda:** vender N itens de uma categoria reduz o preço pago em 3% por item (recupera 5%/dia); comprar reduz o estoque e eleva o preço. Demanda ∈ \[0.6, 1.5\].  
- **Rotas comerciais:** cada território paga mais pelo que não produz e menos pelo que produz (especialidades do `VendorData`).  
- **Reputação (0–4):** Estranho → Conhecido → Respeitado → Honrado → Laço. Descontos 0/5/10/15/20%. Ganha-se por quests e favores; nunca decai (decisão: fricção sem diversão).  
- **Casa de leilões:** 6 slots/dia de itens Raro+; lance mínimo sobe 10% por lance rival simulado; essência aceita em lances especiais.  
- **Trapaça econômica anti-exploit:** ganho por quest repetível tem XP decrescente (−20% por repetição, mín. 20%).  
**11. Territórios e reputação**  
- 14 territórios raciais + zona neutra do Vale do Centro (`MECANICAS.md` §3). Dentro de capital: seguro (sem spawn, repel radius).  
- Nível da região = distância do Vale do Centro + modificador do território.  
- **Atravessar território inimigo em guerra (Ato 1):** guards hostis nas fronteiras até a quest de paz correspondente; após a paz, viram neutros. (Conflito é o estado inicial — não grind de faction genérico.)  
**12. Quests**  
- Principais (20) sempre disponíveis na ordem dos 3 atos; não podem ser abandonadas.  
- Laterais opcionais; **8 cadeias de mistério** rendem 1 **Fragmento da Verdade** cada (misterio_1..8).  
- **Regra do final (Lore System v1.0):** 
  - Com **todas 7 Fragmentos dos Guardiões** (misterio_1..7): **Final Dourado** ("O Fogo dos Laços") — Kinfire renasce, 7 Guardiões em paz, Ithariel reconhece o jogador como "Guardião Remanescente".
  - Sem todos os 7 (ex: apenas 6): **Final Cinzento** — Fenda selada, Cinzento e jogador selam juntos, mundo permanece reescrito. Jogador é avisado na quest final que "há verdades que você ainda não conhece" (sem spoiler).
  - Cinzento é revelado como **Ithariel**, o 8º Guardião, após completar misterio_7 (Act 3).
- Recompensa padrão de quest principal: XP = `40 × nível da quest × ato` + ouro proporcional + 1 item (raridade mínima = ato: Mágico/Raro/Lendário).  
- **Fragmentos da Verdade**: Drops de misterio_1..7 (1 por quest); coletados automaticamente ao completar quest; desbloqueiam Bonds e gating de ato3_1.  
**13. Prólogo (regras)**  
- O jogador é **Aldeão nível 0** com ataque básico; sem classe/raça até o nível 1.  
- XP do prólogo é acelerado (chega ao nível 1 em \~5 minutos de jogo: 2 lutas + coleta + equipar).  
- Nada do prólogo carrega para o mundo (itens do tutorial não saem da Reminiscência; o Cinzento explica: "o que pertence ao sonho fica no sonho").  
- Ao atingir nível 1: cutscene do espelho sem reflexo → criação obrigatória → acampamento da raça escolhida.  
**14. Luz, noite e horário (regras de jogabilidade)**  
- 1 dia = 360s reais; relógio na HUD (`MECANICAS.md` §14.1).  
- 06:00: vendors re-estocam. 21:00–05:00: noite (spawns §6, lanterna acesa, contatos noturnos de quest). 00:00: autosave ("A Vela Virou").  
- Dormir na fogueira: pula para 06:00; buffs de descanso expiram ao dormir.  
- Luz sagrada atravessa paredes; luz sombria não projeta sombra (regra temática — curiosidade em LORE §16).  
**15. Save**  
- `user://kinfire_save.json`, versão atual 3 → v4 com prólogo/quests/reputação/fragmentos/territórios; migrações encadeadas preservam saves antigos.  
- Autosave ao: acender fogueira, 00:00, entrar/sair de masmorra, concluir quest.  
- 1 slot (decisão: sem multi-slot até demanda).  
**16. Auditoria da Fase 0.2 (RESOLVIDA — 2026-10-25)**  
**Confirmados no código (nenhuma ação necessária):**  
- Bônus raciais em `data/races/*.tres` (§1) — ex.: Anão da Montanha +2 CON +2 FOR −1 DES  
- 8 antecedentes em `db.gd` (§1)  
- 6 habilidades por classe, 84 skills / 14 classes (§2)  
- Fórmula de dano em `hero.gd` → `damage_multiplier()` (§3)  
- Status effects stun/lentidão/confusão/medo/maldição em `skill_executor.gd` (§3)  
- Recursos de classe (`resource_max`, `resource_regen`) em `ClassData` (§4)  
- Afixos por raridade `[0, 1–2, 3–4, 5]` em `db.gd` (§8)  
- Multiplicadores de dificuldade em `db.gd` → `DIFFICULTIES` (§7 — tabela acima ajustada ao código real)  
**Divergências — doc vence, código corrigido na Fase 0.4:**  
- XP por nível: código `80 × nível^1.6` → canônico `20 × nível^1.5`  
- Nível máximo: código 30 → canônico 60  
- Pontos de atributo: código +1/nível (+2 a cada 4º) → canônico +1 a cada 4 níveis (níveis 1, 5, 9, 13…)  
- Penalidade de morte: código 10% fixo → canônico 10/20/30/30% por dificuldade  
**Pendência remanejada:**  
- Definir valores-base de ouro por região em `world.gd` (documentar na §9) — junto à Fase 3 (raridade/loot), onde as tabelas de ouro por raridade entram.  

---

## 17. Guildas e Organizações (NOVO — Fase 11)

### 17.1 Tipos de Guilda

| Guilda | Foco | Requisito Entrada | Benefício Principal |
|--------|------|-------------------|---------------------|
| **Guilda dos Aventureiros** | Contratos, party, rank | Nível 5 + 50 ouro | Quadro de contratos, recrutamento party, ranking F-S |
| **Guilda dos Mercadores** | Comércio, rotas, leilão | Nível 10 + 200 ouro + Rep "Respeitado" em 2 territórios | Taxas reduzidas (-50%), slots extra no leilão, rotas exclusivas |
| **Guilda dos Artesãos** | Crafting, forja, alquimia | Nível 15 + profissão nível 5 | Acesso a forjas/mesas avançadas, receitas exclusivas, materiais raros |
| **Guilda das Sombras** | Contratos sombrios, PvP futuro | Nível 20 + reputação "Honrado" + quest secreta | Contratos de alto risco/recompensa, safehouses |
| **Guilda Criada pelo Jogador** | Personalizada | Nível 25 + 5.000 ouro + 3 fundadores | Nome, brasão, regras, banco compartilhado, hall, território |

### 17.2 Guilda dos Aventureiros (Base)

- **Localização**: Porto Franco (capital humana) — Mestre da Guilda: *Gareth*
- **Adesão**: Paga 50 ouro → vira **Membro** (rank F inicial)
- **Contratos procedurais** (quadro na guilda):
  - *Caça*: "Mate N inimigos do tipo X na região Y" → Ouro + XP + Rep
  - *Coleta*: "Traga N itens do tipo Z" → Ouro + Rep + Essência (raro)
  - *Exploração*: "Descubra/marque localização X" → XP + Fragmento chance
  - *Escolta*: "Proteja NPC até destino" → Ouro alto + Rep
- **Contrato ativo**: 1 por vez (Membro), 2 (Oficial), 3 (Mestre)
- **Tempo limite**: 2 horas reais; falha = -Rep, sem penalidade de ouro
- **Rank da Guilda** (separado do Rank F-S do jogador):
  - F → E → D → C → B → A → S (por contratos concluídos + rep)
  - Desbloqueia: contratos melhores, NPCs recrutáveis raros, itens exclusivos

### 17.3 Guilda dos Mercadores (Comércio)

- **Localização**: Porto Franco (distrito do mercado) — Mestre: *Lady Valéria*
- **Adesão**: Nível 10 + 200 ouro + Rep "Respeitado" em 2 territórios
- **Benefícios**:
  - Taxa de venda para vendors: 40% → **60%** do valor
  - Slots no leilão: 6 → **10** por dia
  - **Rotas exclusivas**: acesso a rotas comerciais de alto lucro (risco alto)
  - **Empréstimos**: até 10.000 ouro (juros 5%/semana real; inadimplência = -Rep + caça-recompensa)
  - **Câmbio**: Essência ↔ Ouro a taxa fixa (1 Essência = 500 ouro base)
  - **Contratos de caravana**: escolta de NPC mercador entre capitais (party recomendada)
- **Rank Mercador**: Comerciante → Negociante → Magnata → Príncipe Mercador
  - Por volume de ouro movido + contratos de caravana concluídos

### 17.4 Guilda dos Artesãos (Profissões)

- **Localização**: Capital Anã (Forja Primordial) — Mestre: *Tharn Martelo-Fundo*
- **Adesão**: Nível 15 + qualquer profissão (Ferreiro/Alquimista/Domador) nível 5
- **Benefícios por profissão**:
  - **Ferreiro**: Forja Avançada (itens Lendários), reciclagem 100% materiais, afixos garantidos
  - **Alquimista**: Mesa Primordial (elixires permanentes), transmutação materiais, poções em massa
  - **Domador**: Curral Mestre (até 4 pets), feras raras, evolução de pets
- **Projetos de Guilda**: Contribuição de materiais/essência → desbloqueia benefícios para todos membros
  - Ex: "Forja da Guilda Nível 2" → -10% custo de craft para todos membros

### 17.5 Guilda das Sombras (Endgame / PvP Futuro)

- **Localização**: Oculta (acesso via quest "O Sussurro no Escuro" — Ato 3)
- **Adesão**: Nível 20 + Rep "Honrado" + quest secreta concluída
- **Contratos Sombrios**: Assassinato de alvos (NPCs nomeados), roubo de itens de facções, espionagem
- **Recompensas**: Ouro altíssimo, itens Únicos sombrios, Essência ×5
- **Risco**: Falha = caçadores de recompensa spawnam no mundo do jogador (single + multiplayer)
- **Safehouses**: Pontos de viagem rápida ocultos, armazenamento seguro, cura gratuita

### 17.6 Guilda Criada pelo Jogador (Player Guild)

> **Requisitos**: Nível 25 + 5.000 ouro + 3 fundadores (outros jogadores ou NPCs recrutados)

**Criação**:
1. Fala com *Cartógrafo da Guilda* em Porto Franco
2. Define: **Nome** (único, 20 chars), **Brasão** (escolhe ícone + cor), **Tag** (3-5 letras)
3. Paga 5.000 ouro → Guilda criada (Fundador = Mestre da Guilda)

**Estrutura**:
- **Mestre** (1): Convida, expulsa, promove, define regras, declara guerra/aliância
- **Oficiais** (até 5): Convidam, expulsam, gerenciam banco, contratam NPCs
- **Membros** (até 50): Acessam banco, hall, contratos de guilda

**Recursos da Guilda**:
- **Banco Compartilhado**: 50 slots (expansível com ouro/essência) — itens/ouro/essência
- **Hall da Guilda**: Instância privada (entrada no distrito da guilda em Porto Franco)
  - Baú pessoal por membro, forja/mesa básica, fogueira, NPCs de serviço
  - Upgrade: Nível 1 (básico) → Nível 5 (portal para capitais, buff semanal, arena treino)
- **Território**: Conquista de região (PvE endgame) → bônus passivos para membros
  - Ex: "Vale Cinzento controlado por <Guilda>" → +10% drop raro na região para membros
- **Contratos de Guilda**: Missões cooperativas (requer 3+ membros online)
  - Raids semanais (chefes especiais), defesa de território, guerra de guilda (futuro)

**Progressão da Guilda**:
- **XP de Guilda**: Contratos concluídos + doações + PvP futuro
- **Níveis**: 1→10 (cada nível = +5 slots banco, +1 oficial, +buff passivo)
- **Ranking de Guildas**: Semanal (XP ganho) → recompensas para top 3

**Multiplayer**: Guildas persistem entre sessões; membros podem jogar single-player e progresso conta para guilda (doações, contratos solo de guilda).

### 17.7 Regras Gerais de Guilda

- **Uma guilda principal por personagem** (Aventureiros/Mercadores/Artesãos/Sombras) — **exceto** Guilda do Jogador (pode pertencer a uma principal + sua própria)
- **Troca de guilda principal**: Custa 1.000 ouro + perde 50% Rep da guilda antiga + cooldown 7 dias reais
- **Expulsão**: Perde benefícios imediatamente; itens no banco ficam disponíveis por 24h para resgate
- **Inatividade**: Membro sem login 30 dias → removido automaticamente (configurável pelo Mestre)
- **Alianças/Guerras**: Entre guildas de jogadores (futuro PvP); guildas NPCs têm relações fixas por lore

### 17.8 Saída de Guilda do Dono (Mestre)

> Quando o jogador é o **Mestre (dono)** de uma guilda e deseja sair, ele **não pode simplesmente abandonar**. O sistema exige uma das duas opções abaixo:

| Opção | Requisito | Efeito |
|-------|-----------|--------|
| **Passar posse para um Oficial** | Guilda tem pelo menos 1 Oficial ativo | O Oficial vira o novo Mestre; o jogador vira Membro comum (ou sai se quiser) |
| **Passar posse para um NPC** | Guilda tem NPCs recrutados (ex.: Mestre de Guilda, Cartógrafo) | Um NPC da guilda vira Mestre permanente; a guilda continua funcionando com IA |
| **Dissolver a guilda** | Banco vazio, sem membros, sem território ativo | Guilda é removida do jogo; nome fica livre para recriar; ouro do banco é distribuído aos membros |

**Bloqueio de saída**: Se o jogador for Mestre e não escolher nenhuma das opções, o botão "Sair da Guilda" fica desabilitado com a mensagem: *"Você é o Mestre. Passe a posse para um Oficial/NPC ou dissolva a guilda antes de sair."*

**Sucessão automática por inatividade**: Se o Mestre ficar inativo 30 dias e houver Oficiais, o Oficial mais antigo herda a posse automaticamente. Se não houver Oficiais, a guilda entra em "falência": banco congelado, contratos cancelados, e é dissolvida após 60 dias.

### 17.9 Tamanhos de Guilda (Padrão e Expandida)

| Tamanho | Requisito Desbloqueio | Slots Banco | Membros Máx | Oficiais Máx | Hall | Território |
|---------|----------------------|-------------|-------------|--------------|------|------------|
| **Padrão** | Criação (5.000 ouro) | 50 | 20 | 3 | Básico (instância simples) | Não |
| **Expandida** (Maior que o padrão) | Nível de guilda 5 + 10.000 ouro + 10 membros | 100 | 50 | 5 | Avançado (forja/mesa, arena, portal) | Sim (conquista regional) |

- **Padrão**: Disponível para qualquer jogador que crie uma guilda. Limitada a 20 membros, 3 oficiais, hall básico, sem território.
- **Expandida**: Desbloqueada ao atingir nível 5 de guilda, pagar 10.000 ouro e ter pelo menos 10 membros. Dobra o banco, permite 50 membros, 5 oficiais, hall avançado com forja/mesa/arena e direito a conquistar território regional.

---

---

## 18. Sistema de Rank F-S (NOVO — Fase 11)

### 18.1 Definição
Rank **F → E → D → C → B → A → S** representa o **reconhecimento mundial** do herói (fama, perigo, influência). Não é nível — é **status social/combatente**.

### 18.2 Requisitos por Rank

| Rank | Nível Mín | Conquistas Obrigatórias | Benefícios |
|------|-----------|-------------------------|------------|
| **F** | 1 | — (inicial) | Acesso básico à Guilda dos Aventureiros |
| **E** | 5 | 3 contratos Guilda concluídos | Contratos rank E; título "Novato" |
| **D** | 15 | 10 contratos + 1 chefe derrotado | Contratos rank D; recruta NPC raro; -10% taxa leilão |
| **C** | 30 | 25 contratos + 3 chefes + 1 mistério concluído | Contratos rank C; slot party +1; título "Veterano" |
| **B** | 50 | 50 contratos + 6 chefes + 2 mistérios + Rep "Honrado" 1 território | Contratos rank B; acesso Guilda Mercadores; -20% taxa vendors |
| **A** | 75 | 100 contratos + 10 chefes + 4 mistérios + 1 Fragmento da Verdade | Contratos rank A; título "Campeão"; safehouse Guilda Sombras |
| **S** | 100 | 200 contratos + 20 chefes + 8 mistérios (todos) + 3 Fragmentos + Final Dourado | Título "Lenda Viva"; aura visual única; acesso a conteúdo S-rank; -50% taxa leilão |

### 18.3 Mecânicas

- **Progressão automática**: Ao atender requisitos → notificação "Você alcançou o Rank X!" + efeito visual + chat system
- **Título visível**: Acima do nome no mundo + HUD + painel Personagem + chat
- **Não decai**: Rank só sobe (exceto pena por exploit confirmado — admin only)
- **Multiplayer**: Rank é individual; party vê ranks dos membros; matchmaking futuro por rank

---

## 19. Party / Grupo (NOVO — Fase 11)

### 19.1 Formação

- **Onde**: Guilda dos Aventureiros (quadro "Recrutar") ou convite direto (`/party invite <nome>`)
- **Tamanho**: Máximo **4** (1 líder + 3 membros)
- **Composição**:
  - **Jogadores** (multiplayer LAN): Entram com seus heróis próprios
  - **NPCs Recrutáveis**: Disponíveis na guilda (custo ouro/dia ou Rep)
    - Marn (Guerreiro, tanque) — 10 ouro/dia ou Rep "Respeitado" grátis
    - Bree (Clérigo, cura) — 15 ouro/dia ou Rep "Honrado" grátis
    - + 5-8 NPCs únicos por classe (desbloqueados por Rank da Guilda/contratos)

### 19.2 NPCs de Party (IA)

- **IA Simples**: Segue líder (offset), ataca alvo do líder ou mais próximo
- **Skills**: Usa 2 skills equipadas em cooldown (prioridade: cura > buff > dano)
- **Comportamento por classe**:
  - Tanque: `taunt` + posiciona na frente
  - Curandeiro: Cura < 50% HP → cura; buffs fora de combate
  - DPS: Foca alvo do líder; esquiva de ataques telegrafados
- **Compartilhamento**:
  - **XP**: 50% jogador líder, 50% dividido entre membros (NPCs não ganham XP — nivelam por "dias de serviço")
  - **Loot**: Round-robin configurável (líder define: livre / need-greed / round-robin / líder)
  - **Quest progress**: Compartilhado (KILL/TALK/REACH contam para todos na party)

### 19.3 Party Multiplayer (Drop-in)

- Host = Líder da party
- Guests entram com **seus heróis** (validados no handshake — §16 do Anti-Cheat Design)
- Party UI: Retratos + HP/Recurso + buffs/debuffs (lado esquerdo HUD)
- **Desconexão**: Hero fica "AFK" (IA assumo) por 60s; depois retorna ao próprio mundo com delta de progresso

### 19.4 Liderança e Configuração

- Líder: Define loot mode, expulsa, transfere liderança, dissolve party
- **Party persistente**: Salva no save do líder; re-forma ao logar (convida membros online)

---

## 20. Multiplayer LAN — Co-op Drop-in (NOVO — Fase 12)

### 20.1 Conceito

> **Host** abre seu mundo. **Guests** entram com **seus próprios heróis** (progresso single-player preservado). Mundo = simulação do host; heróis = importados + sincronizados.

### 20.2 Fluxo de Entrada

1. Host: Menu → **Multiplayer** → **Hostear Partida** → Escolhe save → "Abrir para LAN"
2. Guest: Menu → **Multiplayer** → **Entrar via LAN** → Lista broadcasts → Seleciona → **Escolhe seu herói** (lista de saves locais)
3. Handshake: Guest envia **Hero Summary** (level, class, stats hash, skills hash, inventory hash, quest flags hash, machine_id, save checksum)
4. Host valida (**§16 Anti-Cheat Design**) → Aceita ou Rejeita com motivo
5. Spawn: Herói do guest aparece no mundo do host (perto do líder/party)
6. Sessão: Jogam juntos; progresso (XP, loot, quests) **volta para o save do guest** ao sair

### 20.3 Regras de Sincronização

| Sistema | Autoridade | Como Funciona |
|---------|------------|---------------|
| Movimento/Combate | **Host** | Inputs → Host simula → Snapshot 20Hz |
| Inventário/Itens | **Host** | Pickup/use/trade validados no host |
| Quest Progress | **Host** | Flags/notificações broadcast |
| XP/Level/Gold | **Host** | Ganhos calculados no host → delta aplicado no save do guest ao sair |
| Skills/Árvore | **Host** (validação) | Guest não pode usar skill não destravada |
| Tempo/Clima | **Host** | Sincronizado no snapshot |
| Chat | **Host** (relay) | Canais LOCAL/PARTY/GUILD/WHISPER |

### 20.4 Persistência Cross-Session

- **Host**: Save do host = mundo + seu herói + estado da sessão
- **Guests**: Ao sair (ou host fechar), recebem **Delta de Progresso** (XP, gold, itens, quest flags, skills) → aplicam no próprio save → continuam single-player
- **Nenhum dupe**: Inventário no host é cópia autoritativa; desconexão não duplica
- **Machine ID**: Banido no host = não entra em nenhuma sessão desse host

### 20.5 Limitações da Fase Inicial (MVP)

- ✅ Movimento + combate básico + chat + party
- ✅ Handshake + validação de herói + anti-cheat básico
- 🔄 Skills completas + árvore + consumíveis (commit seguinte)
- 🔄 Quest sync completo + world state (portas, bosses, eventos)
- 🔄 Comércio/Guildas/Party NPCs multiplayer
- ❌ PvP / Arena / Guerras de Guilda (Fase futura)

---

## 21. Contratos de Guilda (NOVO — Fase 11)

### 21.1 Estrutura de Contrato

**ContractData** (Resource em `data/contracts/*.tres`):
- **id**: identificador único (ex: `guilda_aventureiros_combate_1`)
- **guilda_id**: qual guilda oferece (StringName: aventureiros/mercadores/artesaos/sombras)
- **tipo**: COMBATE / COLETA / ESCOLTA / INVESTIGACAO
- **titulo**: "Derrote os Goblin da Caverna" / "Colete 5 Cogumelos Raros" / etc
- **descricao**: contexto narrativo
- **requisitos**: nível mínimo, reputação com a guilda
- **recompensas**: ouro, XP, item (raridade mínima), promoção de rank (se último da cadeia)

### 21.2 Tipos de Contrato

| Tipo | Objetivo | Duração | Recompensa Base |
|------|----------|---------|-----------------|
| **COMBATE** | Kill X inimigos ou 1 chefe | 30 min | ×3 ouro, ×2 XP |
| **COLETA** | Gather Y itens (drop ou baús) | 45 min | ×1.5 ouro, ×1 XP, item raro |
| **ESCOLTA** | Proteger NPC da ponto A→B | 60 min | ×2 ouro, rank +1, item de defesa |
| **INVESTIGACAO** | Explorar zona, falar NPCs, resolver enigma | 90 min | ×1 ouro, ×3 XP, título único |

### 21.3 Aceitação e Progresso

- **Aceitar**: Diálogo com Mestre da Guilda → contrato aparece no painel Missões como **aba separada "Contratos"**
- **Progresso**: Real-time (kill counter, item counter, NPC check)
- **Falha**: Timeout ou morte voltar ao Mestre (penalidade: −10% rep, sem recompensa)
- **Sucesso**: Entrega automática ao completar; recompensas creditadas; unlock contrato seguinte da cadeia (se existir)

### 21.4 Cadeias de Contrato

Contratos de uma guilda formam cadeias (ex: Aventureiros: 1→2→3→4):
- **Contrato 1** (E-rank): Derrote 3 Lobos Sombrios
- **Contrato 2** (D-rank): Derrote 8 Esqueletos (pré-req: contrato 1 concluído)
- **Contrato 3** (C-rank): Derrote Chefe Lendário (pré-req: contrato 2 concluído)
- **Contrato 4** (B-rank): Investigue Torre Arcana (pré-req: contrato 3 concluído)

Cada conclusão promove 1 rank na guilda (até rank 5).

### 21.5 Casa de Leilões (Auction House — Guilda Humana)

**Localização**: Porto Franco (capital humana), Quarteirão da Guilda.

**Slots**: 6 itens/dia Raro+ rotativos + 1 slot ESSÊNCIA (moeda dura).
- **Rotação**: Determinística por hash(`"leilao|dia"`); mesmo dia = mesmo lote
- **Raridade**: 70% Raro, 25% Lendário, 5% Relíquia (Lendário +3 níveis)
- **Nível**: Sempre relevante (herói nível +1)

**Lances**:
- **Lance inicial**: valor × 1.2 (prêmio de leilão)
- **Contra-lances**: Rivais simulados (1–3 por slot, determinísticos por dia+slot)
  - Cada contra-lance eleva o mínimo ×1.10
  - Cobrança automática ao vencer (não há taxa de listagem)
- **Slot Essência**: Leilão em ◆ (moeda dura); cobrança em essência, não ouro

**Vitória**: Heróis ganham acesso prioritário a itens Lendário+ e essência sem farm.

---

## 22. Anti-Cheat — Resumo das Regras para Jogadores (NOVO)

> Detalhe técnico em `docs/ANTICHEAT_DESIGN.md` (arquivo interno). Aqui: o que o jogador **percebe**.

### 21.1 O que é Protegido

- **Vida/Mana/Recursos**: Não podem ser congelados ou editados (host corrige em <1s)
- **Dano**: Calculado só no host; "one-hit kill" impossível
- **Velocidade/Teleporte**: Movimento autoritativo; speedhack = rubber-band imediato
- **Itens/Ouro**: Inventário validado no host; dupe = impossível (trade atômico + ledger)
- **XP/Level/Quest**: Só host concede; save editado é detectado no handshake
- **Skills/Cooldowns**: Validados no host; spam = drop + flag

### 21.2 O que Acontece se Trapar

| Gravidade | Exemplos | Consequência |
|-----------|----------|--------------|
| **Leve** | Spam de botão, lag anômalo | Warning no chat, throttle temporário |
| **Média** | Speedhack leve, script modificando CD | Kick da sessão, ban temporário (30 min) |
| **Grave** | Godmode, one-hit, gold dupe, save editado | Kick + ban permanente (Machine ID + IP), log forense |

### 21.3 Machine ID

- Identificador único por máquina (HWID + hostname + specs) — **não sai do seu PC**
- Usado só para: ban persistente entre sessões, anti-dupe cross-save
- Não compartilhado com outros jogadores; não enviado para servidores externos

### 21.4 Fair Play

- **Single-player**: Sem anti-cheat invasivo (jogue como quiser no seu mundo)
- **Multiplayer**: Proteção ativa para proteger **todos** na sessão
- **Relato**: `/report <jogador> <motivo>` → log forense + revisão pelo host

---

## 22. Cidades e Assentamentos no Mapa (NOVO — Fase 10/11)

> O mundo de KINFIRE possui **14 territórios raciais + zona neutra do Vale do Centro**. Cada território tem sua **capital** (cidade principal) e **assentamentos menores** (vilas, postos avançados, acampamentos). Cidades são hubs seguros, com NPCs, serviços e quests.

### 22.1 Hierarquia de Assentamentos

| Tipo | Quantidade | Segurança | Serviços | Exemplo |
|------|------------|-----------|----------|---------|
| **Capital** | 14 (1 por território) | 100% seguro (sem spawn, guards imunes) | Vendors T3, Leilão, Guilda(s), Forja/Mesa, Taverna, Templo, Porto/Estábulo, Banco | Porto Franco (Humano), Karak-Azul (Anão Montanha) |
| **Cidade Média** | 28 (2 por território) | 90% seguro (guards patrulham) | Vendors T2, Guilda satélite, Ferreiro/Alquimista básico, Taverna, Templo | Vale Cinzento (aldeia inicial), Porto Verde (costa) |
| **Vila** | 42+ (3+ por território) | 70% seguro (guards em horário) | Vendors T1, Posto de Guilda, NPC básico, Fogueira | Acampamento dos Lenhadores, Vila Pescadora |
| **Posto Avançado** | 20+ (fronteiras/masmorras) | 50% seguro (área perigosa) | Vendor de suprimentos, Fogueira, Reparo rápido, Teleporte de retorno | Posto da Fronteira, Acampamento Mineração |
| **Acampamento Itinerante** | Dinâmico (eventos) | 30% seguro | NPC mercador raro, cura, rumores | Caravana Mercadora, Acampamento de Caçadores |

### 22.2 Capitais (14 — Uma por Território)

| Território | Raça | Capital | Especialidade | Guildas Presentes |
|------------|------|---------|---------------|-------------------|
| **Vale do Centro** | Neutro | **Porto Franco** | Comércio, diplomacia, porto marítimo | Aventureiros, Mercadores, Artesãos, Sombras (oculta) |
| **Montanhas de Ferro** | Anão Montanha | **Karak-Azul** | Mineração, forja, engenharia | Aventureiros, Artesãos |
| **Colinas Verdes** | Anão Colina | **Pedra Branca** | Agricultura, cerâmica, comércio terrestre | Aventureiros, Mercadores |
| **Floresta Antiga** | Elfo da Floresta | **Sylvaris** | Arco, alquimia, lore antiga | Aventureiros, Artesãos |
| **Floresta Crepuscular** | Elfo Crepuscular | **Umbra-Lin** | Furtividade, venenos, arcano sombrio | Aventureiros, Sombras |
| **Planícies Douradas** | Humano Planície | **Aurora** | Cavalaria, comércio, diplomacia | Aventureiros, Mercadores |
| **Deserto Ardente** | Humano Deserto | **Zarath** | Sobrevivência, vidro, rotas caravanas | Aventureiros, Mercadores, Sombras |
| **Pântano Sombrio** | Meio-Orc | **Gor'Thak** | Ferreiro brutal, venenos, caça | Aventureiros, Artesãos |
| **Ilhas do Vento** | Halfling | **Brisa Leve** | Navegação, pesca, culinária | Aventureiros, Mercadores |
| **Terras Altas** | Draconato | **Pico Escamoso** | Magia elemental, forja de escamas | Aventureiros, Artesãos |
| **Floresta Negra** | Tiefling | **Cinzas Eternas** | Pacto, magia de fogo, contratos | Aventureiros, Sombras |
| **Tundra Congelada** | Goliath | **Gelo Perene** | Resistência, caça, runas | Aventureiros, Artesãos |
| **Selva Primordial** | Tabaxi | **Jade Vivo** | Agilidade, alquimia, feras | Aventureiros, Artesãos, Domadores |
| **Cavernas Profundas** | Svirfneblin | **Luz Profunda** | Gemas, engenharia profunda, ilusão | Aventureiros, Mercadores, Artesãos |

### 22.3 Serviços por Nível de Cidade

| Serviço | Capital (T3) | Cidade Média (T2) | Vila (T1) | Posto (T0) |
|---------|--------------|-------------------|-----------|------------|
| **Vendor Geral** | ✅ Completo (todas categorias) | ✅ Maioria | ✅ Básico | ✅ Suprimentos |
| **Vendor Especializado** | ✅ Armas, Armaduras, Poções, Magia, Jóias | ✅ 2-3 tipos | ❌ | ❌ |
| **Casa de Leilão** | ✅ Completa (10 slots/dia) | ✅ Básica (4 slots/dia) | ❌ | ❌ |
| **Guilda** | ✅ Principal + Satélites | ✅ Satélite (contratos básicos) | ✅ Posto (quadro simples) | ❌ |
| **Forja/Mesa Avançada** | ✅ Lendário + Reciclagem | ✅ Raro | ✅ Comum | ✅ Reparo rápido |
| **Taverna (Rumores/Quests)** | ✅ Rumores lendários + Contratos S | ✅ Rumores regionais | ✅ Rumores locais | ✅ Rumores de perigo |
| **Templo (Bênçãos/Respec)** | ✅ Respec completo + Bênçãos T3 | ✅ Bênçãos T2 | ✅ Bênção básica | ❌ |
| **Banco/Armazenamento** | ✅ Ilimitado + Guilda | ✅ Pessoal (100 slots) | ✅ Pessoal (50 slots) | ❌ |
| **Porto/Estábulo (Viagem Rápida)** | ✅ Todas capitais + rotas marítimas | ✅ Rotas terrestres regionais | ✅ Rota local | ✅ Retorno à capital |
| **Fogueira (Respawn/Save/Sono)** | ✅ Mestre (buffs) | ✅ Normal | ✅ Normal | ✅ Básica |
| **Contratador NPCs** | ✅ Todos (raros + lendários) | ✅ Comuns + 1 raro | ✅ 1 comum | ❌ |

### 22.4 Recursos Específicos por Capital

| Capital | Recurso Único | Vantagem |
|---------|---------------|----------|
| Porto Franco | **Câmbio Essência↔Ouro** (taxa fixa), Empréstimos | Hub econômico central |
| Karak-Azul | **Forja Primordial** (itens Lendários, afixos garantidos) | Melhor craft de equipamento |
| Sylvaris | **Jardim das Ervas Raras** (ingredientes alquimia T3) | Melhor alquimia |
| Umbra-Lin | **Mercado Sombrio** (itens Únicos proibidos, contratos sombrios) | Acesso Guilda das Sombras |
| Aurora | **Estábulo Real** (montarias especiais, velocidade viagem +50%) | Viagem rápida |
| Zarath | **Caravanas Seguras** (proteção garantida rotas comércio) | Rotas lucro alto |
| Gor'Thak | **Arena de Sangue** (PvE ranqueado, recompensas únicas) | Testes de build/combate |
| Brisa Leve | **Festival Sazonal** (itens cosméticos, buffs globais) | Eventos sazonais |
| Pico Escamoso | **Forja de Escamas** (armaduras de dragão, resistências elementais) | Equip elemental |
| Cinzas Eternas | **Círculo dos Pactos** (skills Únicas de Pacto, respec de skills) | Customização mágica |
| Gelo Perene | **Grande Caçada** (chefes de mundo semanais, drops Únicos) | Endgame PvE |
| Jade Vivo | **Curral Mestre** (pets raros, evolução, até 4 ativos) | Melhor Domador |
| Luz Profunda | **Mineração Profunda** (gemas/essências puras, craft de jóias) | Economia de gemas |

### 22.5 Viagem Rápida e Navegação

- **Fogueiras**: Toda cidade/vila/posto tem fogueira. Acender = respawn + save + viagem rápida entre fogueiras **descobertas** na mesma região.
- **Portos/Estábulo**: Capitais conectam entre si (marítimo + terrestre). Custo em ouro baseado em distância + reputação.
- **Teleporte de Guilda**: Guildas nível 3+ têm portal no Hall para capital da guilda.
- **Pedras de Retorno**: Consumível (craft/loja) → teleporta para última fogueira acesa (CD 10min).

### 22.6 Estados de Cidade (Dinâmicos)

| Estado | Gatilho | Efeito |
|--------|---------|--------|
| **Normal** | Padrão | Todos serviços ativos |
| **Cerco** | Quest/Ato (ex.: Ato 1 guerra) | Vendors limitados, guards hostis a facções inimigas, spawns aumentados |
| **Festa** | Evento sazonal / conquista guilda | Buffs globais, vendors especiais, quests únicas, fogos de artifício |
| **Praga** | Quest misteriosa falha / evento | NPCs doentes, cura necessária, vendors fechados, quest de cura ativa |
| **Ocupada** | PvP futuro / guerra de guilda | Guilda dona controla serviços, taxas, acesso |

---

## 25. Brasa (Ember) System — Lore Progression (NOVO — Fase Lore v1.0)

### 25.1 Definição

**Brasa** é um status effect mecânico que escala de **0 a 7**, ativo exclusivamente na dungeon **Kinfire** (Act 3 final). Representa o "calor" do fogo apagado enquanto o jogador se aproxima da Primeira Chama.

### 25.2 Mecânicas

- **Ganho**: +1 Brasa ao entrar em cada zona de Kinfire (3 zonas = 3 Brasa máximo por sessão)
- **Perda**: −1 Brasa ao sair de zona sem derrotar o boss local
- **Reset**: Brasa limpa (0/7) ao derrotar Maldrach (boss final)
- **Bonificadores**:
  - Cada nível de Brasa = +5% XP ganho, +2% dano causado, −1% dano recebido
  - Máximo Brasa (7/7) necessário para acessar **Final Dourado** (apenas com todos 7 Fragmentos)

### 25.3 Progressão em Kinfire

| Zona | Brasa Ganho | Boss | Requisito |
|------|-------------|------|-----------|
| Kinfire Outskirts | +1 (1/7) | Nenhum | Entrada Act 3 |
| Kinfire Heart | +1 (2/7) | Regional | Outskirts completo |
| Kinfire Core | +1 (3/7) | **Maldrach** (final) | Heart completo |

**Nota**: Brasa escala até 7 em teoria, mas dungeon Kinfire tem 3 zonas = 3 Brasa. Escala adicional é futuro conteúdo (DLC).

### 25.4 UI

- Indicador **🔥 Brasa: X/7** na HUD com color gradient (azul → vermelho)
- Notificações ao ganho/perda

---

## 26. Bonds (Laços) System — Guardian Connections (NOVO — Fase Lore v1.0)

### 26.1 Definição

**Bonds** (Laços) é um sistema de coleta de **7 Flame Fragments** dos Guardiões, criando uma conexão mecânica entre eles. Completo = acesso ao **Final Dourado**.

### 26.2 Sete Guardiões

| # | Nome | Território | Fragmento | Quest |
|---|------|-----------|-----------|-------|
| 1 | Mira "Pé-Leve" | Planícies | Chama das Planícies | misterio_1 |
| 2 | Ashara "Sussurra-Magia" | Floresta Crepúsculo | Chama da Floresta | misterio_2 |
| 3 | Lorelyn "Espelho-d'Água" | Águas Cristalinas | Chama das Águas | misterio_3 |
| 4 | Theron "Pedra-Ressoante" | Caverna Cristal | Chama da Pedra | misterio_4 |
| 5 | Kael "Abismo" | Caverna Obsidiana | Chama do Abismo | misterio_5 |
| 6 | Khalid "Areias-Douradas" | Deserto Ouro | Chama do Deserto | misterio_6 |
| 7 | Pyros "Chama-Ardente" | Vulcão Escarlate | Chama do Vulcão | misterio_7 |

### 26.3 Coleta e Gating

- **Ganho**: 1 Bond por Fragmento coletado (automático após misterio_N)
- **Progresso**: UI mostra **⛓️ Laços: X/7** (com color gradient gray → gold)
- **Gate**: ato3_1 bloqueada até 7/7 Bonds (mensagem: "As sete chamas ainda não estão reunidas")
- **Ithariel Reveal**: Cinzento revela-se como **Ithariel**, 8º Guardião, após misterio_7 (Act 3)

### 26.4 Ithariel — 8º Guardião

- **Localização**: Acampamento (Cinzento)
- **Reveal**: Act 3, após completar misterio_7
- **Diálogo**: Confessa ser Ithariel, guardião que falhou; jogador é o único que lembrou
- **Papel Final**: Guia na Escolha Real (Final Dourado vs Cinzento)

### 26.5 Véu da Discórdia — Antagonista Narrativo

**Não é um chefe.** É a ferramenta criada por Maldrach para reescrever o mundo.

- **Descrição**: O Véu é a encarnação viva da mentira, reescrevendo mapas, histórias e até a geografia
- **Derrota**: Não é derrotado diretamente — é **apagado** quando os 7 Laços são reunidos (Bonds completo)
- **Referências**: Mencionado em diálogos de todos Guardiões; explicado em Cinzento/Ithariel diálogos

---

## 27. Finais — Gray vs Gold (NOVO — Fase Lore v1.0)

### 27.1 Gray Ending ("O Cinzento")

**Trigado por**: Completar ato3_8 com < 7 Bonds

- **Cenário**: Fenda em Kinfire Core
- **Diálogo Cinzento**: "Você não tem as sete chamas reunidas. Juntos, selamos a Fenda."
- **Resultado**: 
  - Fenda selada permanentemente
  - Kinfire permanece apagada
  - Mundo fica reescrito (Véu não é derrotado)
  - Cinzento e jogador ligados para sempre (laço cinzento)
  - Título obtido: "Guardião Cinzento"

### 27.2 Gold Ending ("O Fogo dos Laços")

**Trigado por**: Completar ato3_8 com 7/7 Bonds + Brasa 7/7 + Maldrach derrotado

- **Cenário**: Fenda em Kinfire Core
- **Cena**: Sete chamas aparecem em círculo; jogador coloca 8ª (sua própria)
- **Diálogo Ithariel**: "Kinfire acorda. E por um momento, todos os sete guardiões pairam à sua volta, finalmente em paz."
- **Resultado**:
  - Kinfire renasce, queimando eternamente
  - Todos 7 Guardiões reconhecem o jogador (spirit forms)
  - Ithariel sorri pela primeira vez
  - Véu é destruído (dissipado na chama)
  - Título obtido: "Guardião Remanescente"
  - Achievement: "O Fogo dos Laços" (desbloqueado)

### 27.3 Aviso ao Jogador

Ao começar ato3_8, diálogo de Cinzento:
> "Há uma escolha real pela frente. Se você tem coletado as verdades, o caminho dourado se abre. Se não... bem, há sempre a cinza."

(Sem spoiler específico; apenas aviso amigável)

---

## 28. Véu da Discórdia & Maldrach — Explicação Narrativa (NOVO — Fase Lore v1.0)

### 28.1 Hierarquia

- **Maldrach**: A Ausência que Anda (entidade primária, antagonista criador)
- **Véu da Discórdia**: A ferramenta de Maldrach (mecanismo de reescrita)
- **Relação**: Maldrach sussurrou a primeira mentira → nasceu o Véu → mundo foi reescrito

### 28.2 Derrota

- **Maldrach**: Derrotado em boss fight (ato3_8)
- **Véu**: Não tem HP; é apagado automaticamente quando os 7 Laços são reunidos (Final Dourado)

### 28.3 Diálogos

Todos Guardiões mencionam Véu em seus diálogos (hints narrativos sobre reescrita de mapas, histórias, nomes).

---

**AUDITORIA FASE LORE v1.0 (2026-10-28): COMPLETA**

✅ 7 Guardiões (NPCs + Diálogos)  
✅ Brasa System (0-7, bonificadores, UI)  
✅ Bonds System (7 Fragmentos, gating ato3_1)  
✅ Ithariel Reveal (Cinzento = 8º Guardião)  
✅ Véu Narrative (antagonista conceitual)  
✅ Two Endings (Gray + Gold, condições claras)  
✅ UI Indicators (Brasa + Bonds with visuals)  
✅ Integração (autoload, quest signals, flag gating)  

**Próximas fases**: Voice acting, cutscenes, Guardian cameos (optional).

---

### 23.1 Canais

| Canal | Tecla | Alcance | Cor |
|-------|-------|---------|-----|
| **Local** | `Enter` | Raio 500px | Branco |
| **Party** | `Y` | Membros do party | Verde |
| **Guilda** | `G` | Membros da guilda online | Dourado |
| **Sussurro** | `/w nome msg` | Jogador específico | Rosa |
| **Sistema** | — | Todos (host only) | Ciano |

### 23.2 Regras

- **Rate limit**: 5 msg/10s (Local), 10/10s (Party), 8/10s (Guilda), 3/10s (Sussurro)
- **Tamanho máx**: 256 caracteres
- **Filtro**: Sanitização automática (sem comandos, URLs, chars de controle)
- **Histórico**: 200 msg por canal (persiste na sessão)
- **Bolhas no mundo**: Mensagens Local aparecem acima do personagem (8s fade)
- **Single-player**: Painel mostra log local (quests, level up, loot raro, descobertas)

---

## 24. Controles Atualizados (Fase 10)

### 23.1 Mapa de Teclas (Padrão)

| Tecla | Ação |
|-------|------|
| **WASD** | Mover |
| **Mouse Esq.** | Ataque básico (contínuo) |
| **Mouse Dir.** | Ataque pesado |
| **Q** | Magia de cura simples (15% HP, CD 8s, sem custo) |
| **E** | Interagir (fogal, baú, NPC, portal, item no chão) |
| **Tab** | Abrir/Fechar Inventário |
| **1–9** | Consumíveis (poções, comida, bombas, poções de arremesso) |
| **Espaço** | Esquiva |
| **R** | Habilidade racial |
| **Z, X, C, V** | Skills 1–4 equipadas |
| **P** | Painel Personagem (Perfil) |
| **H** | Painel Habilidades (Build/Árvore) |
| **M** | Painel Missões (Diário) |
| **B** | Painel Guilda/Party |
| **Shift + Clique** | Atacar parado |
| **Alt** | Mostrar itens no chão |
| **Esc** | Menu / Pausa |
| **Enter** | Chat (abre painel + foca input) |
| **Y** | Chat Party |
| **G** | Chat Guilda |

### 23.2 Personalização

- Menu **Opções → Controles**: Re-mapeia qualquer ação
- Presets: "Padrão", "Canhoto", "MMO" (skills em 1-4, consumíveis em F1-F4)
- Salvo em `settings.bindings` (por perfil de jogador)

---