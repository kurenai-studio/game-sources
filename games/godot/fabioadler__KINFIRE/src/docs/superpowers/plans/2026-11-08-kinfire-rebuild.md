# KINFIRE Rebuild — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement task-by-task.

**Goal:** Corrigir 5 bugs-raiz de bloqueio, reconstruir inventário/skill-tree/HUD do zero, integrar lore isekai fundido ao cânone Sete Chamas, e reorganizar pastas em camadas.

**Architecture:** Abordagem B — correção de root-causes primeiro, reescrita de UI sobre UIKit existente, reorg mecânica de res:// (24 strings + 23 ext_resource), lore ativado via LoreInitializer existente. Nenhuma nova dependência externa.

**Tech Stack:** Godot 4.7.2 (flatpak), GDScript, UIKit (scripts/ui/ui_kit.gd), InventoryGrid (scripts/items/inventory_grid.gd), headless smoke test.

**Spec:** docs/superpowers/plans/2026-11-08-kinfire-rebuild.md (este arquivo)

## Global Constraints

- Godot 4.7.2.stable.flathub — sem APIs de versões futuras.
- Teste de verificação: `flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . scenes/test_full_playthrough_audit.tscn` → 0 erros, 50 níveis.
- Commits em Conventional Commit PT-BR (`fix:`/`feat:`/`refactor(ui):`/`chore:`).
- Ponytail full: menor diff que funciona; sem abstrações especulativas.
- Nenhum `uid://` em `.tscn`/`.tres` — verificado; manter assim.
- `UIKit` (scripts/ui/ui_kit.gd) é o design system da casa — usar sempre.
- Não alterar `scripts/data/`, `scripts/core/`, `scripts/items/`, `scripts/combat/` sem razão explícita.

## Review Focus

- Fogueira não acende em headless (mouse em 0,0) → `_try_interact()` deve usar proximidade do jogador.
- `get_tile_data()` retorna null quando SHEET=null → crash em `_alt()`.
- Ícones de habilidade `S_*` vão para `SpritePreview` mas ela só faz frames de personagem → warning 28x.
- Inventário: arrastar item e fechar painel deve devolver item ao inventário sem perda.
- Save version 4 → qualquer mudança em campos de save deve incrementar ou migrar.

---

### Task 0: Fase 0 — Preparar ambiente, Arquivar docs canônicos, Smoke-quick

**Files:**
- Modify: `tests/smoke_test.gd` (adicionar --smoke-quick)
- Modify: `scripts/autoload/game.gd:161-162` (detectar --smoke-quick)
- Create: `docs/lore/LORE.md`, `docs/design/REGRAS_DO_JOGO.md`, `docs/design/MECANICAS.md`, `docs/design/DESIGN_SYSTEM.md`, `docs/design/PLANO.md`
- Create: `docs/audits/` (mover TXTs da raiz)
- Delete: variantes `*_modern.gd` (1.574 linhas mortas)
- Delete: `data/trees/*.tres` (14 arquivos — peso morto)

**Interfaces:**
- Produces: flag `--smoke-quick` que termina em <30s com `get_tree().quit(0)` ao final de `_test_overworld()`, antes do loop de 14 classes. Usado em todos os task-done subsequentes.

- [ ] **Step 1: Desfazer stage de deleções de docs canônicos**

```bash
git restore --staged LORE.md REGRAS_DO_JOGO.md MECANICAS.md DESIGN_SYSTEM.md PLANO.md LORE_PLAYTEST.md AUDIT_PRELIMINARY_REPORT.md AUDIT_QUICK_START.md AUDIT_README.md RELEASE_v1.0.md STATUS_FINAL.md
```

- [ ] **Step 2: Criar estrutura docs/ e mover arquivos**

```bash
mkdir -p docs/lore docs/design docs/audits tests/tools
git mv LORE.md docs/lore/LORE.md
git mv LORE_PLAYTEST.md docs/lore/LORE_PLAYTEST.md
git mv REGRAS_DO_JOGO.md docs/design/REGRAS_DO_JOGO.md
git mv MECANICAS.md docs/design/MECANICAS.md
git mv DESIGN_SYSTEM.md docs/design/DESIGN_SYSTEM.md
git mv PLANO.md docs/design/PLANO.md
git mv AUDIT_DELIVERY.txt docs/audits/AUDIT_DELIVERY.txt 2>/dev/null || true
git mv CORREÇÕES_APLICADAS.txt docs/audits/CORRECOES_APLICADAS.txt 2>/dev/null || true
git mv README_AUDIT.txt docs/audits/README_AUDIT.txt 2>/dev/null || true
git mv RELATÓRIO_FINAL_AUDITORIA.txt docs/audits/RELATORIO_FINAL_AUDITORIA.txt 2>/dev/null || true
git mv RELATORIO_FINAL_CORRECOES.txt docs/audits/RELATORIO_FINAL_CORRECOES.txt 2>/dev/null || true
git mv START_AUDIT.txt docs/audits/START_AUDIT.txt 2>/dev/null || true
git mv run_audit_test.sh tests/tools/run_audit_test.sh 2>/dev/null || true
git mv test_audit_simulator.py tests/tools/test_audit_simulator.py 2>/dev/null || true
git mv AUDIT_PRELIMINARY_REPORT.md docs/audits/ 2>/dev/null || true
git mv AUDIT_QUICK_START.md docs/audits/ 2>/dev/null || true
git mv AUDIT_README.md docs/audits/ 2>/dev/null || true
git mv RELEASE_v1.0.md docs/audits/ 2>/dev/null || true
git mv STATUS_FINAL.md docs/audits/ 2>/dev/null || true
```

- [ ] **Step 3: Deletar variantes *_modern.gd (1.574 linhas mortas, zero referências externas)**

```bash
git rm scripts/ui/hud_modern.gd scripts/ui/hud_responsive.gd
git rm scripts/ui/character_panel_modern.gd scripts/ui/dialogue_box_modern.gd
git rm scripts/ui/uikit_modern.gd scripts/menus/main_menu_modern.gd
```

- [ ] **Step 4: Deletar data/trees/*.tres (peso morto — DB.get_skill_tree usa scripts/data/skill_trees.gd)**

```bash
git rm data/trees/*.tres
```

- [ ] **Step 5: Adicionar --smoke-quick em game.gd e smoke_test.gd**

Em `scripts/autoload/game.gd:161-162`, adicionar detecção de `--smoke-quick`:
```gdscript
if "--smoke" in OS.get_cmdline_user_args() or "--smoke-quick" in OS.get_cmdline_user_args():
    add_child(load("res://tests/smoke_test.gd").new())
```

Em `tests/smoke_test.gd`, ao final de `_test_overworld()`, adicionar:
```gdscript
if "--smoke-quick" in OS.get_cmdline_user_args():
    print("[smoke] SMOKE-QUICK OK")
    get_tree().quit(0)
    return
```

- [ ] **Step 6: Verificar que smoke-quick termina em < 60s**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | tail -20`
Expected: linha `[smoke] SMOKE-QUICK OK` e exit 0 (ou timeout sem crash).

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "chore: arquiva docs canonicos, remove codigo morto e adiciona --smoke-quick"
```

---

### Task 1: Restaurar texturas do Overworld (SHEET e OW_SHEET)

**Files:**
- Modify: `scripts/game/overworld.gd:11` — restaurar preload
- Modify: `scripts/game/interactable.gd:16` — restaurar preload
- Modify: `scripts/game/overworld.gd:410-411` — guard null em `_alt()`

**Interfaces:**
- Consumes: `assets/sprites/overworld/roguelike_sheet.png` (existe, 968×526px confirmado)
- Produces: `Overworld._src.texture` não-null; `Interactable.ow_texture()` retorna AtlasTexture com atlas válido; 0 erros `Cannot create tile`

- [ ] **Step 1: Escrever teste de regressão no audit**

Adicionar em `tests/test_full_playthrough_audit.gd` ou verificar via grep no log:
Critério: `grep -c "Cannot create tile" /tmp/smoke_q.log` deve ser 0.

- [ ] **Step 2: Confirmar que o bug está presente (rodar com --smoke-quick antes da fix)**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | grep -c "Cannot create tile" | head -5`
Expected: número > 0 (confirma que o bug existe).

- [ ] **Step 3: Restaurar SHEET em overworld.gd**

```gdscript
# linha 11 de scripts/game/overworld.gd — de:
const SHEET := null  # Carregado dinamicamente em _ready()
# para:
const SHEET := preload("res://assets/sprites/overworld/roguelike_sheet.png")
```

- [ ] **Step 4: Restaurar OW_SHEET em interactable.gd**

```gdscript
# linha 16 de scripts/game/interactable.gd — de:
const OW_SHEET := null  # Carregado dinamicamente em _ready()
# para:
const OW_SHEET := preload("res://assets/sprites/overworld/roguelike_sheet.png")
```

- [ ] **Step 5: Adicionar guard null em _alt() (overworld.gd:410-411)**

Substituir bloco após `create_alternative_tile`:
```gdscript
var alt := _src.create_alternative_tile(coords)
var td := _src.get_tile_data(coords, alt)
if td == null:
    _tiles[key] = alt
    return alt
td.modulate = mod
```

- [ ] **Step 6: Verificar zero erros de tile**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | tee /tmp/smoke_q.log | grep -c "Cannot create tile" || true`
Expected: 0

- [ ] **Step 7: Commit**

```bash
git add scripts/game/overworld.gd scripts/game/interactable.gd
git commit -m "fix(game): restaura texturas do overworld (SHEET/OW_SHEET) e corrige null em _alt()"
```

---

### Task 2: Corrigir _try_interact() — proximidade do jogador

**Files:**
- Modify: `scripts/game/player.gd:551-583`

**Interfaces:**
- Consumes: `world.get_tree().get_nodes_in_group("interactables")`, `global_position`
- Produces: interactable mais próximo do **jogador** (não do mouse) é selecionado; headless funciona; `smoke_test.gd:315-317` passa

- [ ] **Step 1: Confirmar falha atual**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | grep -E "Assertion failed|tut_step|CAMPFIRE" | head -10`
Expected: linha de asserção em smoke_test.gd:317.

- [ ] **Step 2: Implementar _try_interact() com proximidade do jogador**

Substituir a função `_try_interact()` inteira em `scripts/game/player.gd:551`:
```gdscript
## Interagir (E) - contextual: fogueira, baú, NPC, portal, item no chão
## Prioridade: LootDrop > Interactable > Portal — todos por dist. do jogador
func _try_interact() -> void:
    var ppos := global_position
    var range := 64.0

    # 1. LootDrop mais próximo do jogador
    var best_loot: LootDrop = null
    var best_dist := range
    for n in world.get_tree().get_nodes_in_group("interactables"):
        if n is LootDrop:
            var d := n.global_position.distance_to(ppos)
            if d < best_dist:
                best_dist = d
                best_loot = n
    if best_loot:
        best_loot.interact(self)
        return

    # 2. Interactable mais próximo do jogador (fogueira, baú, NPC, etc.)
    var best_interactable: Node2D = null
    best_dist = range
    for n in world.get_tree().get_nodes_in_group("interactables"):
        if (n is Interactable or n is Npc) and not (n is LootDrop):
            var d := n.global_position.distance_to(ppos)
            if d < best_dist:
                best_dist = d
                best_interactable = n
    if best_interactable:
        best_interactable.interact(self)
        return

    # 3. Portal/transição de área
    for n in world.get_tree().get_nodes_in_group("area_transitions"):
        if n.global_position.distance_to(ppos) < 40.0:
            n.activate(self)
            return
```

- [ ] **Step 3: Verificar que a asserção :317 passa**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | tee /tmp/smoke_q2.log | grep -E "SMOKE-QUICK OK|Assertion failed" | head -10`
Expected: `[smoke] SMOKE-QUICK OK` sem `Assertion failed` em :317.

- [ ] **Step 4: Commit**

```bash
git add scripts/game/player.gd
git commit -m "fix(player): usa proximidade do jogador em _try_interact (corrige fogueira headless)"
```

---

### Task 3: Corrigir Npc.display_name() — travessão em vez de hífen

**Files:**
- Modify: `scripts/game/npc.gd:71`

**Interfaces:**
- Produces: `Npc.display_name()` retorna `"Nome — Papel"` com travessão (U+2014); `smoke_test.gd:506` passa

- [ ] **Step 1: Confirmar falha**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | grep -E "Assertion failed.*506|display_name" | head -5`
Expected: falha em :506 com " - " vs " — ".

- [ ] **Step 2: Corrigir separador**

Em `scripts/game/npc.gd:71` mudar:
```gdscript
return "%s - %s" % [data.display_name, data.role]
```
para:
```gdscript
return "%s — %s" % [data.display_name, data.role]
```

- [ ] **Step 3: Verificar**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | grep -E "SMOKE-QUICK OK|506" | head -10`
Expected: `SMOKE-QUICK OK` sem falha em :506.

- [ ] **Step 4: Commit**

```bash
git add scripts/game/npc.gd
git commit -m "fix(npc): usa travessao em display_name conforme spec de UI"
```

---

### Task 4: Corrigir ícones na árvore de habilidades (DB.icon fallback + TextureRect)

**Files:**
- Modify: `scripts/autoload/db.gd:375-385` (fallback gracioso)
- Modify: `scripts/ui/skill_tree_panel.gd:55-65, 235-245` (TextureRect em vez de SpritePreview)
- Modify: `scripts/data/skill_trees.gd` (remapear 22 ícones faltantes para existentes)

**Interfaces:**
- Consumes: `DB.icon(name)` → `Texture2D`; `SkillNodeData.icon: String`
- Produces: 0 warnings `Sprite não encontrado: S_*`; nós de habilidade exibem TextureRect com fallback para `S_Sword01` se ícone não existe em disco

- [ ] **Step 1: Confirmar warnings**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | grep -c "Sprite não encontrado" || true`
Expected: número > 0.

- [ ] **Step 2: Adicionar fallback em DB.icon()**

Em `scripts/autoload/db.gd`, substituir `func icon()`:
```gdscript
func icon(icon_name: String) -> Texture2D:
    if icon_name.is_empty():
        icon_name = "S_Sword01"
    if _icon_cache.has(icon_name):
        return _icon_cache[icon_name]
    var path := "res://assets/icons/%s.png" % icon_name
    var tex: Texture2D
    if ResourceLoader.exists(path):
        tex = load(path)
    else:
        # shortcut: fallback para S_Sword01; quando família nova chegar, adicionar PNG
        tex = load("res://assets/icons/S_Sword01.png")
    _icon_cache[icon_name] = tex
    return tex
```

- [ ] **Step 3: Substituir SpritePreview por TextureRect nos nós de skill tree**

Em `scripts/ui/skill_tree_panel.gd`:
- Na função `_build_tree_header()` (linha ~55-65): onde cria `SpritePreview` para o ícone da classe, substituir por `TextureRect` usando `DB.icon(cls.icon)`.
- Na função `_create_node_ui()` (linha ~238-245): substituir `SpritePreview.new()` + `set_sprite()` por:
```gdscript
var icon := TextureRect.new()
icon.custom_minimum_size = Vector2(48, 48)
icon.position = Vector2(8, 8)
icon.texture = DB.icon(node.icon)
icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
btn.add_child(icon)
```

- [ ] **Step 4: Remapear ícones faltantes em skill_trees.gd**

Buscar todas as ocorrências de ícones sem arquivo em `scripts/data/skill_trees.gd` e substituir:
- `S_Boot01`, `S_Boot02` → `S_Buff01`
- `S_Hammer01`, `S_Hammer02` → `S_Axe01`
- `S_Lightning01`, `S_Lightning03` → `S_Holy01`
- `S_Shield01`, `S_Shield02`, `S_Shield03` → `S_Buff04`
- `S_Sound01`, `S_Sound02`, `S_Sound03` → `S_Buff06`
- `S_Summon01`, `S_Summon02`, `S_Summon03`, `S_Summon04` → `S_Holy02`
- `S_Nature01..05` → `S_Earth01..05` (já existem)
- `S_Dagger01` → `S_Dagger02`

- [ ] **Step 5: Verificar zero warnings de sprite**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | grep -c "Sprite não encontrado" || true`
Expected: 0.

- [ ] **Step 6: Commit**

```bash
git add scripts/autoload/db.gd scripts/ui/skill_tree_panel.gd scripts/data/skill_trees.gd
git commit -m "fix(skills): usa TextureRect e DB.icon com fallback na arvore de habilidades"
```

---

### Task 5: Smoke-quick completo verde — portão de qualidade das fases anteriores

**Files:**
- Test only — sem modificação de código

**Interfaces:**
- Consumes: Tasks 0-4 completas
- Produces: `--smoke-quick` termina com `SMOKE-QUICK OK`, exit 0, 0 erros críticos, 0 `Cannot create tile`, 0 `Sprite não encontrado`, asserções :317 e :506 passam

- [ ] **Step 1: Rodar smoke-quick completo**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | tee /tmp/smoke_gate.log; echo "EXIT=$?"`
Expected: `SMOKE-QUICK OK` e EXIT=0.

- [ ] **Step 2: Verificar ausência de erros críticos**

Run: `grep -cE "Cannot create tile|Sprite não encontrado|Assertion failed|SCRIPT ERROR" /tmp/smoke_gate.log || echo "0"`
Expected: 0.

- [ ] **Step 3: Rodar audit completo (50 níveis)**

Run: `timeout 60 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . scenes/test_full_playthrough_audit.tscn 2>&1 | tail -10`
Expected: 50 níveis, 9/9 equipamentos, 0 erros.

- [ ] **Step 4: Commit de checkpoint**

```bash
git commit --allow-empty -m "test: smoke-quick e audit 50 niveis passando — portao fases 0-4 verde"
```

---

### Task 6: Reescrita do Inventário (InventoryPanel)

**Files:**
- Modify: `scripts/ui/inventory_panel.gd` (reescrita — manter interface pública)

**Interfaces:**
- Consumes: `UIKit`, `Hero.inventory: InventoryGrid`, `Hero.equipment: Dictionary`, `DB.icon()`, `DB.EQUIP_SLOTS`, `InventoryPanel.CELL = 40`, `InventoryPanel.held: Item`, `InventoryPanel.setup(hud, hero)`, `InventoryPanel.refresh()`, `InventoryPanel.show_tooltip(it)`, `InventoryPanel.hide_tooltip()`, `InventoryPanel.drop_held_to_world()`, `InventoryPanel.drag_from_grid()`, `InventoryPanel.drag_from_equip()`, `InventoryPanel.is_dragging() -> bool`
- Produces: layout lado a lado (grade à esquerda, boneco+slots à direita), drag-and-drop por proximidade, shift+clique equipa/desequipa instantaneamente, tooltip com comparação, zero perda de item ao fechar painel

**Notas de implementação:**
- Preservar TODA a interface pública listada em Consumes — `hud.gd` usa diretamente.
- `SpritePreview` continua para o boneco de papel (exibe sprite de personagem — uso correto).
- A grade é redesenhada via `_draw()` em subclasse `Control`, igual ao padrão atual.
- Shift+clique chama `hero.equip(it)` ou `hero.unequip(slot)` diretamente (sem drag).
- Fechar painel com `held != null` → `hero.inventory.add(held)` ou `drop_held_to_world()` (já existe em `hud.gd:564-568`).

- [ ] **Step 1: Verificar interface pública atual (não quebrar hud.gd)**

```bash
grep -n "inventory\." scripts/ui/hud.gd | grep -v "^#"
```
Expected: lista de chamadas que devem continuar funcionando.

- [ ] **Step 2: Reescrever inventory_panel.gd mantendo interface pública**

Implementar layout limpo:
```
┌─ Inventário ──────────────────────────────────────────────────────┐
│ [Mochila]                    │ [Equipamento]                       │
│  grade 10×6, CELL=40         │  boneco de papel centralizado       │
│  drag-and-drop + shift+click │  9 slots ao redor do sprite         │
│  [Ouro: N] [Vender Comuns]   │  DPS: N  Arm.: N  Vida: N           │
│  Arraste / Shift+clique       │                                     │
└───────────────────────────────────────────────────────────────────┘
```

- [ ] **Step 3: Teste de regressão — drag-and-drop não perde item**

No smoke test, após `_test_overworld()`: abrir inventário, equipar item via shift+clique, fechar, verificar que `hero.equipment.weapon != null`. Adicionar assert simples ou verificar via log.

- [ ] **Step 4: Verificar smoke-quick verde**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | grep -E "SMOKE-QUICK OK|Assertion failed" | head -10`
Expected: `SMOKE-QUICK OK`.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/inventory_panel.gd
git commit -m "refactor(ui): reescreve inventario com layout diablo limpo e shift+clique equipar"
```

---

### Task 7: Reescrita da Árvore de Habilidades (SkillTreePanel)

**Files:**
- Modify: `scripts/ui/skill_tree_panel.gd` (reescrita)

**Interfaces:**
- Consumes: `DB.get_skill_tree(cls.id) -> SkillTreeData`, `SkillNodeData.{id,display_name,description,icon,requires,max_rank,is_available()}`, `Hero.{tree_unlocked,tree_points,get_tree_node_rank(),spend_tree_point(),respec_tree()}`, `DB.icon()`, `UIKit`
- Produces: `SkillTreePanel.setup(hud, hero)`, `SkillTreePanel.refresh()` — mesmas assinaturas; canvas com linhas procedurais conectando nós; nós com `TextureRect`; zoom 0.75-1.5×; scroll/pan com mouse

- [ ] **Step 1: Mapear chamadas externas de skill_tree_panel**

```bash
grep -n "skill_tree\." scripts/ui/hud.gd
```

- [ ] **Step 2: Reescrever skill_tree_panel.gd**

Estrutura:
- `SubViewport` ou `Control` com `clip_contents=true` para o canvas de nós.
- `_draw()` em subclasse para linhas de conexão (Dourado=desbloqueado, Cinza=bloqueado).
- Cada nó: `Button` + `TextureRect` (via `DB.icon`) + label de rank `0/N`.
- Barra superior: "Pontos: N" + botão "Respec (custo: N ouro)".
- Pan: arrastar com botão do meio/direito do mouse.
- Zoom: roda do mouse, range 0.75–1.5.

- [ ] **Step 3: Verificar smoke-quick verde**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | grep -E "SMOKE-QUICK OK|Assertion failed" | head -10`
Expected: `SMOKE-QUICK OK`.

- [ ] **Step 4: Commit**

```bash
git add scripts/ui/skill_tree_panel.gd
git commit -m "refactor(ui): reescreve arvore de habilidades com canvas procedural e TextureRect"
```

---

### Task 8: Reescrita do HUD (hud.gd — fix de bugs, sem mudar estrutura geral)

**Files:**
- Modify: `scripts/ui/hud.gd`

**Interfaces:**
- Consumes: todos os painéis via preload em `scripts/ui/`; `Game.settings.ui_scale`; `Game.quest_log`
- Produces: todas as funções públicas existentes preservadas; tracker de missão exibe missão do prólogo desde o 1º segundo; teclas corretas no help (Tab/P/H/B/M em vez de I/C/K/J)

**Notas:**
- Corrigir `main_menu.gd:315` que ainda anuncia I/C/K/J (teclas antigas).
- O tracker (`_setup_quest_tracker`, `_update_quest_tracker`) já funciona — só garantir que `Game.quest_log.tracked = &"prologo_tutorial"` está setado antes de `hud._build()`.
- Respeitar `Game.settings.ui_scale` em `_layout()`.

- [ ] **Step 1: Corrigir teclas no help do main_menu**

Em `scripts/menus/main_menu.gd:315`, substituir:
```
Painéis   I inventário - C personagem - K habilidades - Esc menu
```
por:
```
Painéis   Tab inventário - P personagem - H habilidades - B árvore - M missões - Esc menu
```

- [ ] **Step 2: Garantir que prologue seta quest_log.tracked antes do HUD**

Em `scripts/game/prologue.gd:_setup_tutorial()`, após `notify_flag(&"tut_inicio")`:
```gdscript
Game.quest_log.tracked = &"prologo_tutorial"
```

- [ ] **Step 3: Corrigir ui_scale em _layout() se ausente**

Em `scripts/ui/hud.gd:_layout()`, verificar se o tamanho de fonte/escala respeita `Game.settings.ui_scale`. Se não, adicionar após `_root.get_viewport_rect()`:
```gdscript
var scale_factor := Game.settings.get("ui_scale", 1.0)
```

- [ ] **Step 4: Verificar smoke-quick verde**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | grep -E "SMOKE-QUICK OK|Assertion failed" | head -10`
Expected: `SMOKE-QUICK OK`.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/hud.gd scripts/game/prologue.gd scripts/menus/main_menu.gd
git commit -m "fix(hud): corrige teclas no help, garante tracker de missao no prologo e ui_scale"
```

---

### Task 9: Integração do Lore (LoreInitializer + scripts/lore/)

**Files:**
- Modify: `scripts/autoload/lore_initializer.gd` (ativa LoreSystemManager)
- Create: `scripts/lore/` (renomear `scripts/systems/` via git mv)
- Modify: `project.godot` (atualizar class_name paths se necessário)

**Interfaces:**
- Consumes: `BondsSystem`, `BrasaSystem`, `GuardianSpawner` em `scripts/lore/`
- Produces: `LoreInitializer` instancia `LoreSystemManager`; `Game.ignorance` decrementado por diálogos NPCs; `BrasaSystem.brasa_level` aplicado aos bônus do herói

**Notas:**
- `git mv scripts/systems/ scripts/lore/` — só 5 arquivos, nenhuma ref externa.
- `lore_initializer.gd` vira o autoload que liga o sistema.
- Os `class_name` (BondsSystem, BrasaSystem, etc.) não mudam — Godot resolve por `class_name`, não por path.

- [ ] **Step 1: Mover scripts/systems/ para scripts/lore/**

```bash
git mv scripts/systems scripts/lore
```

- [ ] **Step 2: Verificar que nenhuma ref externa quebrou**

```bash
grep -rn "scripts/systems" --include=*.gd --include=*.tscn --include=*.tres . | grep -v "\.uid"
```
Expected: 0 resultados.

- [ ] **Step 3: Ativar LoreSystemManager em lore_initializer.gd**

```gdscript
class_name _LoreInitializer
extends Node

var _lore: LoreSystemManager

func _ready() -> void:
    _lore = LoreSystemManager.new()
    add_child(_lore)
    print("[OK] Lore system initialized — lacos=%d brasa=%d" % [
        _lore.bonds_system.active_bonds.size(),
        _lore.brasa_system.brasa_level
    ])
```

- [ ] **Step 4: Verificar que o jogo inicia sem erro**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | grep -E "SMOKE-QUICK OK|ERROR|Lore system" | head -10`
Expected: `[OK] Lore system initialized` e `SMOKE-QUICK OK`.

- [ ] **Step 5: Commit**

```bash
git add scripts/lore/ scripts/autoload/lore_initializer.gd project.godot
git commit -m "feat(lore): move systems para scripts/lore e ativa LoreSystemManager no autoload"
```

---

### Task 10: Reorganização de data/narrative/ e migração de res:// strings

**Files:**
- Rename (git mv): `data/dialogues/` → `data/narrative/dialogues/`
- Rename (git mv): `data/quests/` → `data/narrative/quests/`
- Rename (git mv): `data/npcs/` → `data/narrative/npcs/`
- Modify: `scripts/autoload/db.gd` (3 strings de path)
- Modify: `scripts/autoload/guilds.gd` (paths de guild se necessário)

**Interfaces:**
- Consumes: `DB.dialogue(id)`, `DB.npc(id)`, `DB.quests`
- Produces: mesmas funções funcionando com novos paths; zero `Failed loading resource`

- [ ] **Step 1: Mover pastas via git mv**

```bash
mkdir -p data/narrative
git mv data/dialogues data/narrative/dialogues
git mv data/quests data/narrative/quests
git mv data/npcs data/narrative/npcs
```

- [ ] **Step 2: Atualizar strings em db.gd**

Substituir:
- `"res://data/quests/%s.tres"` → `"res://data/narrative/quests/%s.tres"`
- `"res://data/dialogues/%s.tres"` → `"res://data/narrative/dialogues/%s.tres"`
- `"res://data/npcs/%s.tres"` → `"res://data/narrative/npcs/%s.tres"`

- [ ] **Step 3: Verificar zero "Failed loading resource" no smoke**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | grep -E "Failed loading|SMOKE-QUICK OK" | head -20`
Expected: `SMOKE-QUICK OK` sem `Failed loading`.

- [ ] **Step 4: Rodar audit completo**

Run: `timeout 60 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . scenes/test_full_playthrough_audit.tscn 2>&1 | tail -15`
Expected: 50 níveis, 0 erros.

- [ ] **Step 5: Commit**

```bash
git add data/narrative/ scripts/autoload/db.gd
git commit -m "refactor: move data/dialogues,quests,npcs para data/narrative com migracao res://"
```

---

### Task 11: Validação Final — Smoke Completo + Audit

**Files:**
- Test only

**Interfaces:**
- Consumes: todas as Tasks 0-10 completas
- Produces: `--smoke-quick` verde, audit 50 níveis verde, 0 erros críticos, lista de rulings e deferred minors

- [ ] **Step 1: Smoke-quick final**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . -- --smoke-quick 2>&1 | tee /tmp/smoke_final.log; echo "EXIT=$?"`
Expected: EXIT=0 e `SMOKE-QUICK OK`.

- [ ] **Step 2: Audit 50 níveis**

Run: `timeout 90 flatpak run --filesystem=$PWD org.godotengine.Godot --headless --path . scenes/test_full_playthrough_audit.tscn 2>&1 | tee /tmp/audit_final.log | tail -20`
Expected: 50/50 níveis, 9/9 equipamentos, 0 erros críticos.

- [ ] **Step 3: Contagem de erros residuais**

Run: `grep -cE "SCRIPT ERROR|ERROR:" /tmp/smoke_final.log /tmp/audit_final.log || echo "0"`
Expected: somente warns esperados (nenhum `SCRIPT ERROR`).

- [ ] **Step 4: Commit final**

```bash
git add -A
git commit -m "release: KINFIRE rebuild completo — bugs corrigidos, UI reescrita, lore integrado"
```
