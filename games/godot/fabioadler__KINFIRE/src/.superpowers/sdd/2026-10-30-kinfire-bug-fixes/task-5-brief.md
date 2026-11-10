# Task 5 Brief: Fix Inventory Paper Doll (Character Sprite)

## Task Description
Add the hero sprite to the center of the "paper doll" (equipment layout) in the inventory panel. Currently the equipment slots are positioned around where the character sprite SHOULD be, but the sprite itself is never drawn.

## Files to Modify
- `/media/f/HD/KINFIRE/scripts/ui/inventory_panel.gd` (lines 38-62 in `setup()`, and `refresh()` function)

## Required Changes

### Change 1: In `setup()` function, after creating `doll` Control (after line 42)
Add hero sprite to the center of the doll:

```gdscript
	# Sprite do personagem no centro do boneco (paper doll)
	var hero_sprite := Sprite2D.new()
	hero_sprite.name = "HeroSprite"
	hero_sprite.texture = DB.icon(hero.sprite_base())
	hero_sprite.modulate = hero.tint * hero.race.tint
	hero_sprite.position = Vector2(CELL * 4.25, CELL * 2.75)  # Centro do doll (8.5x5.5 cells)
	hero_sprite.z_index = -1  # Atrás dos slots de equipamento
	doll.add_child(hero_sprite)
```

### Change 2: In `refresh()` function (after line 104)
Update the hero sprite when refreshing:

```gdscript
	# Atualiza sprite do boneco (pode mudar com equip visual no futuro)
	var doll := _grid_view.get_parent().get_child(0)  # primeiro child do scroll é o doll
	var hero_sprite := doll.get_node_or_null("HeroSprite")
	if hero_sprite:
		hero_sprite.texture = DB.icon(hero.sprite_base())
		hero_sprite.modulate = hero.tint * hero.race.tint
```

## Test to Verify
Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: Hero sprite visible in center of equipment slots, test passes

## Global Constraints
- Godot 4.7.2 (Flatpak) headless execution for testing
- No breaking changes to save format or public APIs
- Preserve existing signal connections and cleanup patterns
- Follow existing code style (UTF-8, 4-space indent, Portuguese comments)

## Report File
Write report to: `/media/f/HD/KINFIRE/.superpowers/sdd/2026-10-30-kinfire-bug-fixes/task-5-report.md`