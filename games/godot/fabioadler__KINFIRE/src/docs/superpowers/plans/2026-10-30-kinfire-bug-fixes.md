# KINFIRE Bug Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all reported bugs in KINFIRE: tutorial progression, quest system, skill tree layout/connections, inventory paper doll, HUD consumables, character status panel, and quest tracker.

**Architecture:** Fix each bug in its respective file with minimal, targeted changes. Each fix is independent and can be tested separately. The bugs span 5 files: `prologue.gd`, `quest_log.gd`, `skill_tree_panel.gd`, `inventory_panel.gd`, `hud.gd`, and `character_panel.gd`.

**Tech Stack:** Godot 4.7.2, GDScript

**Spec:** Bug reports from user + code analysis in conversation

## Global Constraints

- Godot 4.7.2 (Flatpak) headless execution for testing
- No breaking changes to save format or public APIs
- Preserve existing signal connections and cleanup patterns
- Follow existing code style (UTF-8, 4-space indent, Portuguese comments)
- All fixes must pass existing test: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`

## Review Focus

1. **Tutorial flag timing** - Quest must start on `tut_inicio`, advance on each `tut_*` flag, complete on `tut_espelho`
2. **Quest stage advancement** - New stage's pre-satisfied FLAG/COLLECT objectives must auto-complete
3. **Skill tree layout** - Root nodes (no prereqs) on LEFT, dependents flow RIGHT; connections point left-to-right
4. **Inventory paper doll** - Hero sprite centered in doll, equipment slots around it, updates on equip/unequip
5. **Quest tracker method** - `tracked_quest()` must return QuestData or null, not crash

---

### Task 1: Fix Tutorial Progression & Quest Stage Advancement

**Files:**
- Modify: `/media/f/HD/KINFIRE/scripts/core/quest_log.gd:118-167, 222-235`
- Modify: `/media/f/HD/KINFIRE/scripts/game/prologue.gd:158, 220-222` (verify only)

**Interfaces:**
- Consumes: `Game.quest_log.notify_flag(flag_name)`, `Game.flags` dictionary
- Produces: Correct quest stage advancement, `quest_advanced` signal, `quest_completed` signal

- [ ] **Step 1: Write failing test for tutorial quest flow**

```gdscript
# In test script - verify quest starts on tut_inicio and advances through all 7 stages
func test_tutorial_quest_flow():
    Game.new_prologue()
    await get_tree().process_frame
    # Simulate tutorial steps
    Game.quest_log.notify_flag(&"tut_inicio")
    var q = DB.quest(&"prologo_tutorial")
    assert Game.quest_log.is_active(q.id)
    assert Game.quest_log.stage_of(q) == 0
    # ... advance through each flag
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: Tutorial phase fails or gets stuck

- [ ] **Step 3: Fix `_event()` in quest_log.gd to recheck FLAG objectives on quest start**

In `_event()` (line 136-167), after `start(q)` is called for FLAG type, immediately call `_recalc(q)` to check if any FLAG objectives in the new first stage are already satisfied.

```gdscript
# In _event(), after line 123 (start(q)) add:
if type == QuestObjective.Type.FLAG:
    _recalc(q)  # Check if new stage has pre-satisfied FLAG objectives
```

- [ ] **Step 4: Fix `_check_stage()` to recalc new stage objectives**

In `_check_stage()` (line 223-235), after advancing stage (line 231-232), add `_recalc(q)` to auto-complete any FLAG/COLLECT objectives already satisfied in the new stage.

```gdscript
if st + 1 < q.stages.size():
    Game.quests[q.id]["stage"] = st + 1
    Game.quests[q.id]["prog"] = []
    _recalc(q)  # NEW: check new stage for pre-satisfied objectives
    quest_advanced.emit(q.id, st + 1)
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: Tutorial phase passes, 50/50 levels

- [ ] **Step 6: Commit**

```bash
git add scripts/core/quest_log.gd
git commit -m "fix: tutorial quest progression - recalc FLAG objectives on stage advance"
```

---

### Task 2: Add Missing `tracked_quest()` Method to QuestLog

**Files:**
- Modify: `/media/f/HD/KINFIRE/scripts/core/quest_log.gd:13-16` (add method after `tracked` property)

**Interfaces:**
- Consumes: `tracked` property, `DB.quest()`
- Produces: `tracked_quest()` returning `QuestData` or `null`

- [ ] **Step 1: Write failing test for quest tracker**

```gdscript
func test_tracked_quest_method():
    var q = Game.quest_log.tracked_quest()
    assert q == null or q is QuestData
    # Start a quest, verify it returns the tracked one
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: HUD `_update_quest_tracker()` crashes on `tracked_quest()` call

- [ ] **Step 3: Implement `tracked_quest()` method in quest_log.gd**

Add after line 16 (after `tracked` property):

```gdscript
## Retorna a QuestData da quest rastreada (para HUD tracker)
func tracked_quest() -> QuestData:
	if tracked == &"":
		return null
	return DB.quest(tracked)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: HUD quest tracker works, no crash

- [ ] **Step 5: Commit**

```bash
git add scripts/core/quest_log.gd
git commit -m "feat: add tracked_quest() method to QuestLog for HUD tracker"
```

---

### Task 3: Fix Skill Tree Layout Algorithm (Depth Calculation)

**Files:**
- Modify: `/media/f/HD/KINFIRE/scripts/ui/skill_tree_panel.gd:141-175`

**Interfaces:**
- Consumes: `_tree.nodes`, `node.requires`, `_tree.get_dependent_nodes()`
- Produces: `depths` Dictionary with correct left-to-right column assignment

- [ ] **Step 1: Write failing test for skill tree layout**

```gdscript
func test_skill_tree_depths():
    var tree = DB.get_skill_tree(&"bruxo")
    var panel = SkillTreePanel.new()
    panel.setup(hud, hero)
    var depths = panel._calculate_depths()
    # Root nodes (no requires) should have lowest depth (0)
    for n in tree.nodes:
        if n.requires.is_empty():
            assert depths[n.id] == 0
        else:
            # Dependents should have higher depth than prereqs
            for req in n.requires:
                assert depths[n.id] > depths[req]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: Skill tree nodes layout inverted (prereqs on right)

- [ ] **Step 3: Fix `_calculate_depths()` algorithm**

The bug: prerequisites pushed with `depth - 1`, dependents with `depth + 1`. 
Fix: prerequisites should be at LOWER depth (more left), dependents at HIGHER depth (more right).

```gdscript
func _calculate_depths() -> Dictionary:
	var depths: Dictionary[StringName, int] = {}
	var visited: Dictionary[StringName, bool] = {}
	var stack: Array[Dictionary] = []
	
	# Começa dos nós raiz (sem pré-requisitos) - profundidade 0 (esquerda)
	for n in _tree.nodes:
		if n.requires.is_empty():
			stack.append({"node_id": n.id, "depth": 0})
	
	while stack.size() > 0:
		var item: Dictionary = stack.pop_back()
		var node_id: StringName = item.node_id
		var depth: int = item.depth
		
		if visited.has(node_id):
			depths[node_id] = max(depths[node_id], depth)
			continue
		visited[node_id] = true
		depths[node_id] = depth
		
		var node := _tree.get_node(node_id)
		if not node:
			continue
		
		# PRÉ-REQUISITOS: vão para a ESQUERDA (depth - 1)
		for req_id in node.requires:
			stack.append({"node_id": req_id, "depth": depth - 1})
		
		# DEPENDENTES: vão para a DIREITA (depth + 1)
		for dep in _tree.get_dependent_nodes(node_id):
			stack.append({"node_id": dep.id, "depth": depth + 1})
	
	# Normaliza para começar em 0 (shift all to positive)
	var min_depth := INF
	for d in depths.values():
		if d < min_depth:
			min_depth = d
	if min_depth < 0:
		for k in depths.keys():
			depths[k] -= min_depth
	
	return depths
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: Skill tree lays out left-to-right correctly

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/skill_tree_panel.gd
git commit -m "fix: skill tree layout - correct depth calculation for left-to-right flow"
```

---

### Task 4: Fix Skill Tree Connection Lines

**Files:**
- Modify: `/media/f/HD/KINFIRE/scripts/ui/skill_tree_panel.gd:436-482`

**Interfaces:**
- Consumes: `_nodes_ui`, `node.requires`, `hero.tree_unlocked`
- Produces: Correct bezier curves from prerequisite (left) to node (right)

- [ ] **Step 1: Verify connection lines after layout fix**

After Task 3, connections should naturally point left-to-right since prerequisites are now at lower depth (left) and nodes at higher depth (right). The existing `_canvas_draw()` draws FROM node TO prerequisite, which with correct layout will draw right-to-left. We need to reverse or keep as-is depending on visual preference.

- [ ] **Step 2: Adjust `_canvas_draw()` if needed**

Current code draws from node (from_pos) to prerequisite (to_pos). With fixed layout:
- `from_pos` = node position (right side)
- `to_pos` = prerequisite position (left side)
- Line goes right-to-left (correct visual flow)

No change needed if layout is fixed. But verify the bezier curve control points create a nice curve.

- [ ] **Step 3: Test and commit**

Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`

```bash
git add scripts/ui/skill_tree_panel.gd
git commit -m "fix: skill tree connections - verify lines with corrected layout"
```

---

### Task 5: Fix Inventory Paper Doll (Character Sprite)

**Files:**
- Modify: `/media/f/HD/KINFIRE/scripts/ui/inventory_panel.gd:38-62`

**Interfaces:**
- Consumes: `hero.sprite_base()`, `hero.tint`, `hero.race.tint`
- Produces: Sprite2D of hero centered in `doll` Control

- [ ] **Step 1: Write failing test for paper doll**

```gdscript
func test_inventory_paper_doll():
    var panel = InventoryPanel.new()
    panel.setup(hud, hero)
    # Verify doll has a Sprite2D child with hero sprite
    var doll = panel.get_node_or_null("ScrollContainer/Control")  # the doll control
    assert doll != null
    var sprite = doll.get_node_or_null("HeroSprite")
    assert sprite != null
    assert sprite.texture != null
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: No character sprite in inventory center

- [ ] **Step 3: Add hero sprite to doll Control**

In `setup()`, after creating `doll` (line 39-42), add:

```gdscript
	# Sprite do personagem no centro do boneco (paper doll)
	var hero_sprite := Sprite2D.new()
	hero_sprite.name = "HeroSprite"
	hero_sprite.texture = DB.icon(hero.sprite_base())  # ou hero.portrait se existir
	hero_sprite.modulate = hero.tint * hero.race.tint
	hero_sprite.position = Vector2(CELL * 4.25, CELL * 2.75)  # Centro do doll (8.5x5.5 cells)
	hero_sprite.z_index = -1  # Atrás dos slots de equipamento
	doll.add_child(hero_sprite)
```

Also need to update sprite on refresh when equipment changes (for visual feedback):

In `refresh()` (line 99-104), add:
```gdscript
	# Atualiza sprite do boneco (pode mudar com equip visual no futuro)
	var doll := _grid_view.get_parent().get_child(0)  # primeiro child do scroll é o doll
	var hero_sprite := doll.get_node_or_null("HeroSprite")
	if hero_sprite:
		hero_sprite.texture = DB.icon(hero.sprite_base())
		hero_sprite.modulate = hero.tint * hero.race.tint
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: Hero sprite visible in center of equipment slots

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/inventory_panel.gd
git commit -m "feat: inventory paper doll - add hero sprite centered in equipment slots"
```

---

### Task 6: Fix `_sell_junk()` in Inventory Panel

**Files:**
- Modify: `/media/f/HD/KINFIRE/scripts/ui/inventory_panel.gd:172-185`

**Interfaces:**
- Consumes: `hero.inventory.items`, `hero.inventory.remove()`, `hero.add_gold()`
- Produces: Correct gold gain, inventory updated, signal emitted once

- [ ] **Step 1: Write failing test for sell junk**

```gdscript
func test_sell_junk():
    hero.inventory.add(DB.create_item(&"wood_sword", 1, Item.Rarity.COMMON))
    hero.inventory.add(DB.create_item(&"iron_sword", 1, Item.Rarity.MAGIC))
    hero.inventory.add(DB.create_item(&"legendary_sword", 1, Item.Rarity.LEGENDARY))
    var gold_before = hero.gold
    panel._sell_junk()
    assert hero.gold > gold_before
    assert hero.inventory.items.size() == 1  # only legendary remains
```

- [ ] **Step 2: Run test to verify it fails**

Current bug: manual `hero.inventory.changed.emit()` after loop is redundant and may cause double refresh.

- [ ] **Step 3: Fix `_sell_junk()`**

```gdscript
func _sell_junk() -> void:
	var to_sell: Array[Item] = []
	for it in hero.inventory.items:
		if it.rarity <= Item.Rarity.MAGIC:
			to_sell.append(it)
	var total := 0
	for it in to_sell:
		total += int(it.sell_value() * hero.sell_multiplier())
		hero.inventory.remove(it)  # This already emits 'changed' signal
	if total > 0:
		hero.add_gold(total)
		# REMOVED: hero.inventory.changed.emit()  # redundant
		Sfx.play(&"coins")
		hud.show_message("Vendido por %d de ouro" % total, Color(1, 0.85, 0.3))
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/inventory_panel.gd
git commit -m "fix: inventory _sell_junk - remove redundant signal emit"
```

---

### Task 7: Fix HUD Consumable Slots Refresh

**Files:**
- Modify: `/media/f/HD/KINFIRE/scripts/ui/hud.gd:176-185` (setup), `365-380` (_process)

**Interfaces:**
- Consumes: `hero.inventory.changed` signal
- Produces: Consumable slots update when inventory changes

- [ ] **Step 1: Write failing test for consumable slots**

```gdscript
func test_consumable_slots_refresh():
    # Add potion to slot 1
    hero.inventory.add(DB.create_item(&"health_potion", 1, Item.Rarity.COMMON))
    # Verify slot 1 shows potion
    # Remove potion
    # Verify slot 1 shows empty
```

- [ ] **Step 2: Run test to verify it fails**

Slots don't update when inventory changes via other means (pickup, buy, etc.)

- [ ] **Step 3: Connect inventory changed signal to refresh consumable slots**

In `_build_bottom_bar()` after creating consumable slots (line 185), add:
```gdscript
	# Conecta refresh dos slots de consumíveis
	hero.inventory.changed.connect(func():
		for i in _consumable_slots.size():
			_consumable_slots[i].queue_redraw()
	)
```

Also in `_process()` (line 365-380), the slots are only redrawn when held item changes. They should also reflect current inventory state.

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/hud.gd
git commit -m "fix: hud consumable slots - connect to inventory changed signal"
```

---

### Task 8: Fix Character Panel Status Tab Minus Button

**Files:**
- Modify: `/media/f/HD/KINFIRE/scripts/ui/character_panel.gd:135-146`

**Interfaces:**
- Consumes: `hero.status[s]`, `hero.cls.base_status`, `hero.cls.status_growth`, `hero.level`
- Produces: Correct validation preventing status going below base

- [ ] **Step 1: Write failing test for status minus button**

```gdscript
func test_status_minus_button():
    # Set status above base
    hero.status["forca"] = 15
    hero.status_points = 0
    base = hero.cls.base_status.get("forca", 10) + hero.cls.status_growth.get("forca", 0) * (hero.level - 1)
    # Click minus
    # Verify status decreases but not below base
    # Verify status_points increases
```

- [ ] **Step 2: Run test to verify it fails**

Current code has `if hero.level > 1:` which means at level 1 growth isn't added to base - this is correct. But the minus button allows going below base because it only checks `gasto > 0` (total - base).

- [ ] **Step 3: Fix minus button validation**

The logic at line 137-145 is correct for calculating base. The issue is the minus button at line 135-146 connects to a function that does:
```gdscript
if hero.status[s] > base:
    hero.status[s] -= 1
    hero.status_points += 1
```
This IS correct - it prevents going below base. Let me re-read...

Actually the code looks correct. The `minus` button checks `gasto <= 0` to disable (line 252-253). And the pressed callback checks `hero.status[s] > base`. This should work. Let me verify by testing.

Wait - the bug might be that `base` is calculated differently in the callback vs in `refresh()`. In the callback (line 137-140):
```gdscript
var base: int = hero.cls.base_status.get(s, 10)
var growth: int = hero.cls.status_growth.get(s, 0)
if hero.level > 1:
    base += growth * (hero.level - 1)
```

In `refresh()` (line 240-243):
```gdscript
var base: int = hero.cls.base_status.get(s, 10)
var growth: int = hero.cls.status_growth.get(s, 0)
if hero.level > 1:
    base += growth * (hero.level - 1)
```

They're identical. This might already be correct. Let me mark as "verify and fix if needed".

- [ ] **Step 4: Verify and commit if fix needed**

```bash
git add scripts/ui/character_panel.gd
git commit -m "fix: character panel status minus button - validate base calculation"  # if needed
```

---

### Task 9: Integration Test & Full Playthrough Verification

**Files:**
- Test: `/media/f/HD/KINFIRE/tests/test_full_playthrough_audit.gd`
- Scene: `/media/f/HD/KINFIRE/scenes/test_full_playthrough_audit.tscn`

**Interfaces:**
- Consumes: All fixed systems
- Produces: Complete playthrough audit report

- [ ] **Step 1: Run full audit test**

Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`

- [ ] **Step 2: Verify all phases pass**

Expected output:
```
FASE 1: Validação de Inicialização ✓
FASE 2: Tutorial e Prólogo ✓
FASE 3: Criação de Personagem ✓
FASE 4: Gameplay Progressivo (50 níveis) ✓
FASE 5: Testes de Sistemas ✓
FASE 6: Análise Final ✓
STATUS: ✅ PASSOU
```

- [ ] **Step 3: Verify audit reports generated**

Check `user://audit_report.txt` and `user://audit_report.json` for:
- 0 errors, 0 critical, 0 bugs
- 50 levels completed
- 9/9 equipment tests passed

- [ ] **Step 4: Commit all changes**

```bash
git add .
git commit -m "fix: all reported bugs - tutorial, quests, skill tree, inventory, hud, character"
```

---

## Plan Complete

**Total Tasks:** 9 (8 bug fixes + 1 integration test)

**Estimated Time:** ~2-3 hours for implementation

**Execution Approach:** I recommend **Native** (single session) because:
- Tasks are mostly independent (different files)
- Each fix is small and localized
- Fast iteration with Godot headless test
- No complex interdependencies between fixes