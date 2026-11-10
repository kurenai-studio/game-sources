# Drag-and-Drop de Equipamento e Validação do Tutorial - Plano de Implementação

> **Para agentes executores:** REQUISITO DE SUB-SKILL: Use `superpowers:subagent-driven-development` (recomendado) ou `superpowers:executing-plans` para implementar este plano tarefa por tarefa. Passos usam sintaxe de checkbox (`- [ ]`) para acompanhamento.

**Goal:** Implementar drag-and-drop completo e livre (qualquer item → qualquer slot da grade ou de equipamento, em qualquer direção, com troca e desequipação), adicionar drop de itens do inventário para abrir espaço, e validar o fluxo do tutorial/prólogo (Cinzento → Ithariel reveal → criação de personagem).

**Architecture:** Estender `InventoryPanel` com estado de arraste (`is_dragging`, origem do arraste, item arrastado, posição fantasma) compartilhado entre `_GridView` e `_EquipView`, mantendo intacto todo o comportamento existente de clique. O tutorial já está implementado conforme a lore; a validação consiste em confirmar a quest `prologo_tutorial.tres` (7 estágios + estágio final do espelho) e rodar o headless audit.

**Tech Stack:** GDScript (Godot 4.7.2), sistema de inventário `InventoryPanel`, quest log `QuestLog`, prologue `Prologue`.

**Spec:** Este plano (docs/superpowers/plans/2026-10-30-drag-drop-equipment-and-tutorial-verification.md) + arquivos lidos: `scripts/ui/inventory_panel.gd`, `scripts/game/prologue.gd`, `data/quests/prologo_tutorial.tres`, `tests/test_full_playthrough_audit.gd`.

## Global Constraints

- Godot 4.7.2 (Flatpak) headless para testes: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
- Não quebrar sinais existentes: `hero.inventory.changed`, `hero.stats_changed`, `hero.gold_changed`, `Game.quest_log.quest_advanced`, `Prologue.tutorial_step_done`
- Não alterar o comportamento de clique atual (esquerdo/direito) — drag-and-drop é uma camada adicional compatível
- Item arrastado para slot ocupado: swap automático — equipa o novo e o antigo retorna à mochila (ou vai pro chão se a mochila estiver cheia), sem precisar desequipar manualmente antes
- Drop de item: arrastar item para fora da grade ou fora do painel, soltar para jogar o item no chão (LootDrop), liberando espaço na mochila
- Arraste em qualquer direção: o item segue o cursor livremente; validação apenas de compatibilidade de slot
- Zero erros de compilação e zero warnings audit pass ao final
- Teste de auditoria deve reportar: FASE 2 Tutorial e Prólogo ✅ PASS

## Review Focus

| Entrada/condição de falha | Comportamento esperado | Teste que fixa |
|---|---|---|
| Arrastar item para slot ocupado | Trocar automático: item equipado volta à mochila e o novo é equiparado (sem desequipar manualmente) | task-2 drop_in_slot (swap) |
| Arrastar item para slot incompatível (arma no slot de cabeça) | Rejeitar, mostrar mensagem, item volta ao ponto de origem sem alterar estado | task-2 drop_in_slot invalid |
| Arrastar item equipado para mochila cheia | Rejeitar arraste, item permanece equipado | task-2 drop_in_slot full inventory |
| Arrastar item para fora da grade/painel (drop no chão) | Jogar item no chão via LootDrop, liberando espaço na mochila | task-2 test_drop_to_floor |
| Arrastar e cancelar (soltar sobre o próprio item arrastado) | Cancelar, nenhum efeito | task-2 cancel drag |
| Tutorial atinge NÍVEL 1 sem ter concluído os 7 passos | Espelho recusa e sussurra "O espelho espera. Termine o que a névoa pediu." | test_full_playthrough_audit: FASE 2 |
| Tutorial concluído (CAMPFIRE) → portão aberto, lobos nascem | Wolves spawn após `_open_gate` | audit phase 2 |
| Espelho usado após DONE + nível 1 | Fade to black 1.2s → `Game.change_scene(Game.CHARACTER_CREATION)` | audit phase 3 |

---

## Task 1: Estado de arraste no InventoryPanel

**Files:**
- Modify: `scripts/ui/inventory_panel.gd:1-180` (variáveis de estado de arraste)

**Interfaces:**
- Consumes: nenhum estado externo
- Produces: variável `var _drag: Dictionary` com chaves: `source` ("grid"|"equip"), `item` (Item), `slot` (String ou Vector2i), `start_pos` (Vector2), `ghost_visible` (bool) + métodos `is_dragging()` e `drag_clear()`

- [ ] **Step 1: Escrever o teste de falha**

```gdscript
# tests/test_full_playthrough_audit.gd
func test_drag_state_init():
	var panel = InventoryPanel.new()
	assert(panel._drag.source == null)
	panel.cleanup()
	panel.free()
```

- [ ] **Step 2: Rodar teste para verificar que falha**

Executar FASE 5 do audit.
Esperado: FAIL com "_drag not defined" ou `panel._drag.source == null` falhando.

- [ ] **Step 3: Implementar variáveis de estado de arraste em `scripts/ui/inventory_panel.gd`**

Na classe `InventoryPanel`, após `_gold_callback`, adicionar:

```gdscript
var _drag: Dictionary = {"source": null, "item": null, "slot": null, "start_pos": Vector2.ZERO, "ghost_visible": false}
func is_dragging() -> bool: return _drag != null and _drag.source != null
func drag_clear() -> void: _drag = {"source": null, "item": null, "slot": null, "start_pos": Vector2.ZERO, "ghost_visible": false}
```

- [ ] **Step 4: Rodar teste para verificar que passa**

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/inventory_panel.gd
git commit -m "feat: add _drag state fields to InventoryPanel for drag-and-drop layer"
```

## Task 2: Métodos auxiliares de arraste para grid e equipamento

**Files:**
- Modify: `scripts/ui/inventory_panel.gd:220-300`

**Interfaces:**
- Consumes: `hero.inventory.add/replace/remove`, `hero.equip/unequip`, `LootDrop.drop_item`, `HUD.show_message`, `Sfx.play`
- Produces: `func drag_from_grid(item: Item, cell: Vector2i, mouse_pos: Vector2) -> void`, `func drag_from_equip(slot: String, mouse_pos: Vector2) -> void`, `func drop_in_grid(item: Item, cell: Vector2i) -> void`, `func drop_in_slot(item: Item, slot: String) -> void`, `func drop_to_floor(item: Item) -> void`

- [ ] **Step 1: Escrever os testes de comportamento**

```gdscript
func test_drop_to_floor():
	"""Arrastar item para fora do painel (celula fora dos limites) -> solta no chão via LootDrop"""
	var panel = _make_test_panel()
	var it = DB.create_item(&"wood_sword", 1, Item.Rarity.COMMON)
	panel.hero.inventory.add(it)
	panel.drag_from_grid(it, Vector2i(0, 0), Vector2(200, 200))
	panel.drop_in_grid(it, Vector2i(-1, -1))  # fora dos limites da grade = drop no chão
	# o item deve ir para o chão (LootDrop) e não estar mais no inventário nem segurado
	assert(panel.hero.inventory.get(it) == null)
	panel.drag_clear()
	panel.cleanup()
	panel.free()
```

- [ ] **Step 2: Rodar teste para verificar que falha**

Rodar FASE 5 do audit.
Esperado: FAIL — métodos não existem.

- [ ] **Step 3: Implementar métodos em `scripts/ui/inventory_panel.gd`**

Após `drop_held_to_world()` (linha ~218), adicionar:

```gdscript
func drop_in_grid(item: Item, cell: Vector2i) -> void:
	if not hero.inventory.in_bounds(item, cell):
		# fora da grade: solta no chão (drop)
		drop_to_floor(item)
		return
	if not hero.inventory.can_add(item):
		hud.show_message("Inventário cheio", Color(1, 0.5, 0.4))
		_drag_clear()
		return
	var over := hero.inventory.overlapping(item, cell)
	if over.size() == 1:
		var other: Item = over[0]
		hero.inventory.remove(other)
		hero.inventory.place(item, cell)
		held = other
		Sfx.play(&"drop")
	elif hero.inventory.add(item):
		hero.inventory.replace(item, cell)
		held = null
		Sfx.play(&"drop")
	_drag_clear()

func drop_to_floor(item: Item) -> void:
	LootDrop.drop_item(hud.world, hud.world.player.global_position, item)
	Sfx.play(&"drop")
	hud.show_message("Item jogado fora: %s" % item.name, Color(0.8, 0.3, 0.3))
	_drag_clear()
```

- [ ] **Step 4: Rodar teste para verificar que passa**

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/inventory_panel.gd
git commit -m "feat: add drop_to_floor + in_bounds check to drop_in_grid"
```

## Task 3: Slot ocupado = swap automático em drop_in_slot

**Files:**
- Modify: `scripts/ui/inventory_panel.gd` (método `drop_in_slot`)

**Interfaces:**
- Consumes: `drop_in_slot` criado na Task 2
- Produces: `drop_in_slot` com swap automático (novo equipa, item antigo vai pra mochila ou chão se cheia)

- [ ] **Step 1: Escrever teste de swap**

```gdscript
func test_drop_in_slot_swap():
	"""Item equipado + novo arrastado -> swap automatico: antigo volta pra mochila"""
	var panel = _make_test_panel()
	var old = DB.create_item(&"chainmail", 1, Item.Rarity.COMMON)
	var new = DB.create_item(&"wood_sword", 1, Item.Rarity.COMMON)
	panel.hero.equip(old)
	panel.drag_from_grid(new, Vector2i(0, 0), Vector2(200, 200))
	panel.drop_in_slot(new, "chest")
	assert(panel.hero.equipment.chest == new)
	assert(panel.hero.inventory.get(old) != null)
	panel.drag_clear()
	panel.free()
```

- [ ] **Step 2: Rodar teste para verificar que falha**

- [ ] **Step 3: Implementar swap em `drop_in_slot`**

```gdscript
func drop_in_slot(item: Item, slot: String) -> void:
	# slot livre: equipa direto
	if not slot in hero.equipment or hero.equipment[slot] == null:
		equip_from_inventory(item)
		return
	# slot ocupado: swap automatico - equipa novo, antigo vai pra mochila (ou chao se cheio)
	var problem := hero.equip_problem(item)
	if problem != "":
		hud.show_message(problem, Color(1, 0.5, 0.4))
		_drag_clear()
		return
	var old: Item = hero.equipment[slot]
	hero.equip(item)
	if not hero.inventory.add(old):
		LootDrop.drop_item(hud.world, hud.world.player.global_position, old)
	Sfx.play(&"equip")
	hud.show_message("Equipado: %s" % item.name, Color(0.4, 1, 0.4))
	_drag_clear()
```

- [ ] **Step 4: Rodar teste para verificar que passa**

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/inventory_panel.gd
git commit -m "feat: drop_in_slot auto-swaps occupied slots (old item returns to inventory)"
```

## Task 4: Intercalar camadas de clique e arraste em _GridView

**Files:**
- Modify: `scripts/ui/inventory_panel.gd:274-352` (classe `_GridView`)

**Interfaces:**
- Consumes: `panel.is_dragging()`, `panel._drag`, `panel.drag_from_grid()`, `panel.drop_in_grid()`, `panel.hero.inventory`
- Produces: `_GridView._gui_input` com comportamento combinado clique+arraste

- [ ] **Step 1: Escrever testes de interação**

```gdscript
func test_grid_drag_drop():
	"""Segurar na grade + arrastar + soltar em celula livre -> item na celula"""
	var panel = _make_test_panel()
	var it = DB.create_item(&"wood_sword", 1, Item.Rarity.COMMON)
	panel.hero.inventory.add(it)
	panel.drag_from_grid(it, Vector2i(0, 0), Vector2(300, 300))
	panel.drop_in_grid(it, Vector2i(1, 1))
	assert(panel.hero.inventory.get_item_at(Vector2i(1, 1)) != null)
	panel.drag_clear()
	panel.free()
```

- [ ] **Step 2: Rodar teste para verificar que falha**

Esperado: FAIL — `_GridView` não tem lógica de arraste.

- [ ] **Step 3: Implementar `_GridView._gui_input` com camadas combinadas**

Substituir o bloco `InputEventMouseButton` do `GRID VIEW` (linhas ~287-323) por:

```gdscript
func _gui_input(event: InputEvent) -> void:
	var inv := panel.hero.inventory
	if event is InputEventMouseMotion:
		var mp := get_local_mouse_position()
		var cell := _cell_at(mp)
		_hover_cell = cell
		var held_item := panel._drag.item if panel.is_dragging() else null
		panel.show_tooltip(inv.item_at(cell) if held_item == null else held_item)
		queue_redraw()

	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var cell := _cell_at(event.position)
			# cancela arraste em celula vazia
			if panel.is_dragging() and panel._drag.source == "grid" and inv.item_at(cell) == null:
				panel.drag_clear()
				accept_event()
				return
			if panel.is_dragging() and panel._drag.source == "grid":
				panel.drop_in_grid(panel._drag.item, cell)
				accept_event()
				return
			var it := inv.item_at(cell)
			if panel.is_dragging() and it != null:
				panel.drop_in_grid(panel._drag.item, cell)
				accept_event()
				return
			if it == null:
				return
			if panel.held == null:
				inv.remove(it)
				panel.held = it
				panel.hide_tooltip()
				Sfx.play(&"cloth")
				accept_event()
				return
			var pos := _anchor_for(panel.held, event.position)
			if inv.in_bounds(panel.held, pos):
				var over := inv.overlapping(panel.held, pos)
				if over.size() == 0:
					inv.place(panel.held, pos)
					panel.held = null
					Sfx.play(&"drop")
				elif over.size() == 1:
					var other: Item = over[0]
					inv.remove(other)
					inv.place(panel.held, pos)
					panel.held = other
					Sfx.play(&"drop")
				accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT and panel.held == null and not panel.is_dragging():
			var it := inv.item_at(cell)
			if it:
				if Input.is_key_pressed(KEY_SHIFT):
					panel._sell(it)
					panel.hud.show_message("Vendido: %s" % it.name, Color(1, 0.9, 0.4))
				else:
					panel.equip_from_inventory(it)
				accept_event()

	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and panel.is_dragging():
			panel.drag_clear()
			queue_redraw()
			accept_event()

	# inicia arraste: item clicado na grade com botao esquerdo
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var cell := _cell_at(event.position)
			var it := inv.item_at(cell)
			if it and panel._drag.source == null:
				panel.drag_from_grid(it, cell, event.global_position)
				queue_redraw()
		accept_event()
```

e atualizar `_draw()` para desenhar o fantasma do arraste:

```gdscript
func _draw() -> void:
	var inv := panel.hero.inventory
	var cs := InventoryPanel.CELL
	for x in inv.cols:
		for y in inv.rows:
			var r: Rect2 = Rect2(x * cs, y * cs, cs, cs)
			draw_rect(r.grow(-1), Color(0.08, 0.06, 0.05))
			draw_rect(r.grow(-1), Color(0.22, 0.17, 0.12), false, 1.0)
	for it in inv.items:
		panel._draw_item(self, it, Rect2(Vector2(it.grid_pos) * cs, Vector2(it.size) * cs))
	if panel.held:
		var mouse := get_local_mouse_position()
		if Rect2(Vector2.ZERO, size).has_point(mouse):
			var pos := _anchor_for(panel.held, mouse)
			var ok := inv.in_bounds(panel.held, pos) and inv.overlapping(panel.held, pos).size() <= 1
			draw_rect(Rect2(Vector2(pos) * cs, Vector2(panel.held.size) * cs), Color(0.2, 0.8, 0.2, 0.25) if ok else Color(0.8, 0.1, 0.1, 0.25))
	if panel.is_dragging() and panel._drag.source == "grid" and panel._drag.ghost_visible:
		var mouse := get_local_mouse_position()
		var pos := Vector2i(panel._drag.slot) if panel._drag.slot is Vector2i else Vector2i(floori(mouse.x / cs), floori(mouse.y / cs))
		var s := panel._drag.item.size * cs
		draw_rect(Rect2(mouse - s * 0.5, s), Color(0.3, 0.3, 0.3, 0.25))
		panel._draw_item(self, panel._drag.item, Rect2(mouse - s * 0.5, s))
```

- [ ] **Step 4: Rodar teste para verificar que passa**

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/inventory_panel.gd
git commit -m "feat: grid view integrates click + drag layer (pick/place/swap preserved)"
```

## Task 5: Intercalar camadas de clique e arraste em _EquipView

**Files:**
- Modify: `scripts/ui/inventory_panel.gd:354-421` (classe `_EquipView`)

**Interfaces:**
- Consumes: `panel.is_dragging()`, `panel._drag`, `panel.hero.equipment`, `panel.drop_in_slot()`, `panel.hero.inventory`, `panel.hero.unequip`
- Produces: `_EquipView._gui_input` e `_draw()` com suporte a arrastar item do slot para mochila

- [ ] **Step 1: Escrever testes**

```gdscript
func test_drag_from_equip_to_inventory():
	"""Arrastar item equipado para grade -> desequipa e coloca na mochila"""
	var panel = _make_test_panel()
	var it = DB.create_item(&"chainmail", 1, Item.Rarity.COMMON)
	panel.hero.equip(it)
	panel.drag_from_equip("chest", Vector2(300, 300))
	panel.drop_in_grid(it)
	assert(panel.hero.inventory.get(it) != null)
	assert(panel.hero.equipment.chest == null)
	panel.drag_clear()
	panel.free()

func test_equip_from_grid_drag():
	"""Arrastar item da mochila para slot -> equipa (swap se ocupado)"""
	var panel = _make_test_panel()
	var it = DB.create_item(&"chainmail", 1, Item.Rarity.COMMON)
	panel.hero.inventory.add(it)
	panel.drag_from_grid(it, Vector2i(0, 0), Vector2(300, 300))
	panel.drop_in_slot(it, "chest")
	assert(panel.hero.equipment.chest == it)
	panel.drag_clear()
	panel.free()
```

- [ ] **Step 2: Rodar teste para verificar que falha**

Esperado: FAIL — `_EquipView` não tem estado de arraste nem chama `drag_from_equip`/`drop_in_slot`.

- [ ] **Step 3: Implementar `_EquipView._gui_input`**

Substituir o bloco `InputEventMouseButton` do `EQUIP VIEW` (linhas ~366-395):

```gdscript
func _gui_input(event: InputEvent) -> void:
	var hero := panel.hero
	if event is InputEventMouseMotion:
		var equipped: Item = hero.equipment.get(slot) if slot in hero.equipment else null
		panel.show_tooltip(equipped if not panel.is_dragging() else panel._drag.item)
		queue_redraw()

	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if panel.is_dragging() and panel._drag.source == "grid":
				panel.drop_in_slot(panel._drag.item, slot)
				accept_event()
				return
			if panel.held:
				if panel.held.slot != slot:
					panel.hud.show_message("Este item não vai neste espaço", Color(1, 0.5, 0.4))
				elif hero.equip_problem(panel.held) != "":
					panel.hud.show_message(hero.equip_problem(panel.held), Color(1, 0.5, 0.4))
				else:
					var out := hero.equip(panel.held)
					panel.held = out.pop_front() if not out.is_empty() else null
					for extra in out:
						if not hero.inventory.add(extra):
							LootDrop.drop_item(panel.hud.world, panel.hud.world.player.global_position, extra)
					Sfx.play(&"equip")
				accept_event()
				return
			var equipped: Item = hero.equipment.get(slot) if slot in hero.equipment else null
			if equipped:
				panel.drag_from_equip(slot, event.global_position)
				accept_event()
				return
		elif event.button_index == MOUSE_BUTTON_RIGHT and panel.held == null and not panel.is_dragging():
			var equipped: Item = hero.equipment.get(slot) if slot in hero.equipment else null
			if equipped:
				if hero.inventory.add(equipped):
					hero.unequip(slot)
					Sfx.play(&"cloth")
				else:
					panel.hud.show_message("Inventário cheio", Color(1, 0.5, 0.4))
			accept_event()

	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and panel.is_dragging():
			panel.drag_clear()
			queue_redraw()
			accept_event()

	queue_redraw()
```

e atualizar `_draw()`:

```gdscript
func _draw() -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	var is_drag_source := panel.is_dragging() and panel._drag.source == "equip" and panel._drag.slot == slot
	var highlight := panel.held != null and panel.held.slot == slot or is_drag_source
	draw_rect(r, UIKit.GOLD if highlight else UIKit.GOLD_DIM, false, 2.0)
	var it: Item = panel.hero.equipment.get(slot) if slot in panel.hero.equipment else null
	if it and not is_drag_source:
		panel._draw_item(self, it, r.grow(-3))
	if is_drag_source and panel._drag.ghost_visible:
		var mp := get_local_mouse_position()
		panel._draw_item(self, panel._drag.item, Rect2(mp.x - size.x * 0.5, mp.y - size.y * 0.5, size.x, size.y))
	if not it and not is_drag_source:
		var f := UIKit.FONT_BODY
		var txt: String = DB.SLOT_NAMES.get(slot, slot)
		if txt == "Mão Secundária": txt = "Secundária"
		elif txt == "Acessório 1": txt = "Acess. 1"
		elif txt == "Acessório 2": txt = "Acess. 2"
		elif txt == "Acessório 3": txt = "Acess. 3"
		draw_string(f, Vector2(0, size.y * 0.5 + 4), txt, HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color(0.45, 0.4, 0.35))
```

- [ ] **Step 4: Rodar teste para verificar que passa**

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/inventory_panel.gd
git commit -m "feat: equip view integrates click + drag layer (equip/drag-back-to-inventory)"
```

## Task 6: Atualizar ajuda de UI e testes de auditoria

**Files:**
- Modify: `scripts/ui/inventory_panel.gd:72` (hint text)
- Modify: `tests/test_full_playthrough_audit.gd` (adicionar validação do inventário)

- [ ] **Step 1: Atualizar hint de controles**

Linha 72, trocar:
```gdscript
var hint := UIKit.label("Esq: mover | Dir: equipar | Shift+Dir: vender", 12, UIKit.TEXT_DIM)
```
por:
```gdscript
var hint := UIKit.label("Arraste: segurar item | Soltar: equipar/trocar | Voltar: arraste de volta", 12, UIKit.TEXT_DIM)
```

- [ ] **Step 2: Adicionar teste de drag-and-drop ao audit (FASE 5)**

Na classe principal `TestFullPlaythroughAudit`, adicionar:

```gdscript
func _audit_inventory_drag_drop():
	AuditLog.write("FASE 5b: Drag-and-Drop bidirecional + drop no chão")
	var panel = InventoryPanel.new()
	# 1. arrastar item da mochila para slot vazio -> equipa
	var it = DB.create_item(&"wood_sword", 1, Item.Rarity.COMMON)
	panel.hero.inventory.add(it)
	panel.drag_from_grid(it, Vector2i(0, 0), Vector2(0, 0))
	panel.drop_in_slot(it, "weapon")
	var ok1 := panel.hero.equipment.weapon == it
	panel.drag_clear()
	# 2. swap: slot ocupado recebe novo item, antigo volta à mochila
	var old = DB.create_item(&"chainmail", 1, Item.Rarity.COMMON)
	var new = DB.create_item(&"steel_sword", 1, Item.Rarity.COMMON)
	panel.hero.equip(old)
	panel.drag_from_grid(new, Vector2i(0, 0), Vector2(0, 0))
	panel.drop_in_slot(new, "chest")
	var ok2 := panel.hero.equipment.chest == new and panel.hero.inventory.get(old) != null
	panel.drag_clear()
	# 3. arrastar equipado de volta à grade
	var it2 = DB.create_item(&"chainmail", 1, Item.Rarity.COMMON)
	panel.hero.equip(it2)
	panel.drag_from_equip("chest", Vector2(0, 0))
	panel.drop_in_grid(it2)
	var ok3 := panel.hero.inventory.get(it2) != null and panel.hero.equipment.chest == null
	panel.drag_clear()
	# 4. slot incompatível rejeita
	var weapon = DB.create_item(&"wood_sword", 1, Item.Rarity.COMMON)
	panel.hero.inventory.add(weapon)
	panel.drag_from_grid(weapon, Vector2i(0, 0), Vector2(0, 0))
	var before = panel.hero.equipment.helm
	panel.drop_in_slot(weapon, "helm")
	var ok4 := panel.hero.equipment.helm == before
	panel.drag_clear()
	# 5. drop no chão: item fora da grade vai pro chão, não pro inventário
	var junk = DB.create_item(&"rubble", 1, Item.Rarity.COMMON)
	panel.hero.inventory.add(junk)
	panel.drag_from_grid(junk, Vector2i(0, 0), Vector2(0, 0))
	var drops_before = get_tree().get_nodes_in_group("loot_drops").size()
	panel.drop_in_grid(junk, Vector2i(-1, -1))
	var ok5 = panel.hero.inventory.get(junk) == null and get_tree().get_nodes_in_group("loot_drops").size() > drops_before
	panel.drag_clear()
	panel.cleanup()
	panel.free()
	if ok1 and ok2 and ok3 and ok4 and ok5:
		AuditLog.info("inventory", "drag-and-drop + drop no chão: 5/5 OK")
		return
	AuditLog.error("inventory", "falhou: ok1=%s ok2=%s ok3=%s ok4=%s ok5=%s" % [ok1, ok2, ok3, ok4, ok5])
```

Chamar `_audit_inventory_drag_drop()` em `do_test()` dentro da FASE 5.

- [ ] **Step 3: Executar**

```bash
flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn
```
Esperado: FASE 5 PASS com "drag-and-drop + drop no chão: 5/5 OK"; FASE 2 e FASE 3 PASS.

- [ ] **Step 4: Commit**

```bash
git add scripts/ui/inventory_panel.gd tests/test_full_playthrough_audit.gd
git commit -m "chore: update inventory hint text + add drag-drop audit tests to full playthrough"
```

## Task 7: Validação do fluxo tutorial/prólogo (conforme lore + SDD)

**Files:**
- Verify: `data/quests/prologo_tutorial.tres` (conferido abaixo — 7 estágios + estágio final do espelho ✅)
- Verify: `scripts/game/prologue.gd` (conferido abaixo ✅)

**Confirmações já feitas na análise:**
- `prologo_tutorial.tres`: start_flag=`tut_inicio`, stages = MOVE → ATTACK → COLLECT → EQUIP → POTION → CAMPFIRE → Stage_espelho ("Lute além do portão, alcance o nível 1 e olhe-se no espelho de casa")
- `prologue.gd`: CAMPFIRE → DONE → `_open_gate()` (portão aberto, lobos nascem); nível 1 → `_on_hero_leveled_up` sussurra "Volte à casa - o espelho espera"; `_on_mirror` verifica `level >= 1` e `tut_step == DONE` → flag `tut_espelho` + diálogo Cinzento→Ithariel ("Vidro vazio. O Véu levou o reflexo... uma escolha") → fade 1.2s → `Game.change_scene(Game.CHARACTER_CREATION)` (`res://scenes/menus/character_creation.tscn` existe ✅)

**Passos:**

- [ ] **Step 1: Conferir teste audit FASE 2**

Ler `tests/test_full_playthrough_audit.gd` para confirmar que FASE 2 valida: tutorial 7 passos, level 1, espelho, cena de criação. Se faltar validação do `_on_mirror`/espelho, adicionar teste similar ao do Task 6.

- [ ] **Step 2: (se necessário) Rodar build do projeto antes do headless para checar erros**

```bash
flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE --quit-after-load
```
Esperado: 0 errors, 0 warnings.

- [ ] **Step 3: Rodar audit headless e verificar FASE 2 ✅ PASS**

```bash
flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn
```
Esperado:
- FASE 1 ✅ PASS
- FASE 2 ✅ PASS (tutorial completo, espelho, CHARACTER_CREATION)
- FASE 3 ✅ PASS (criação de personagem)
- FASE 4 ✅ PASS (50/50 níveis)
- FASE 5 ✅ PASS (incluindo drag-and-drop)
- FASE 6 ✅ PASS
- Final: 50/50 levels, 9/9 equipment, 0 errors, 0 critical, 5 warnings esperados (Bruxo vs Espada)
- Status: ✅ PASSOU

- [ ] **Step 4: Commit final**

```bash
git add .
git commit -m "verify: prologue/tutorial flow matches lore - espelho → Ithariel reveal → character creation (no code changes)"
```

## Tarefas de Validação Extra (opcional)

- [ ] Testar manualmente no editor: arrastar `wood_sword` da grade para slot `weapon`, swap em slot ocupado, arrastar item equipado de volta à mochila, arrastar para slot incompatível (mensagem de erro), arrastar fora do painel (cancela), drop de item no chão
- [ ] Verificar `user://audit_report.txt` e `user://audit_report.json` por mensagens não esperadas

---

## Notas de decisão do planejador

- **Opção B escolhida** (arraste completo bidirecional com fantasma visual), conforme decisão do usuário no brainstorming.
- **Arraste livre**: o item segue o cursor em qualquer direção; validação só de compatibilidade de slot.
- **Slot ocupado**: swap automático — equipa o novo e o antigo retorna à mochila (ou vai pro chão se a mochila estiver cheia). Sem necessidade de desequipar manualmente antes.
- **Drop no chão**: arrastar item para fora da grade (célula inválida, ex. (-1,-1)) ou para fora do painel joga o item no chão via `LootDrop.drop_item`, liberando espaço — mecânica solicitada pelo usuário.
- **Compatibilidade**: clique-esquerdo e clique-direito existentes 100% preservados — o arraste só aciona quando o botão esquerdo é pressionado e mantido.
- **Tutorial**: nenhuma alteração de código necessária — o fluxo já está implementado conforme a lore e o SDD; esta fase é de *verificação*.
