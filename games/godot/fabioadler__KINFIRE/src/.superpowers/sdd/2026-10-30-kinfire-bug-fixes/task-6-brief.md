# Task 6 Brief: Fix `_sell_junk()` in Inventory Panel

## Task Description
Fix the `_sell_junk()` function which has a redundant `hero.inventory.changed.emit()` call after the loop. The `hero.inventory.remove(it)` already emits the `changed` signal, so the manual emit causes double refresh.

## Files to Modify
- `/media/f/HD/KINFIRE/scripts/ui/inventory_panel.gd` (lines 172-185)

## Current Bug (lines 172-185)
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
		hero.inventory.changed.emit()  # REDUNDANT - causes double refresh
		Sfx.play(&"coins")
		hud.show_message("Vendido por %d de ouro" % total, Color(1, 0.85, 0.3))
```

## Required Fix
Remove the redundant `hero.inventory.changed.emit()` line (currently line 183):

```gdscript
func _sell_junk() -> void:
	var to_sell: Array[Item] = []
	for it in hero.inventory.items:
		if it.rarity <= Item.Rarity.MAGIC:
			to_sell.append(it)
	var total := 0
	for it in to_sell:
		total += int(it.sell_value() * hero.sell_multiplier())
		hero.inventory.remove(it)
	if total > 0:
		hero.add_gold(total)
		# REMOVED: hero.inventory.changed.emit()  # redundant
		Sfx.play(&"coins")
		hud.show_message("Vendido por %d de ouro" % total, Color(1, 0.85, 0.3))
```

## Test to Verify
Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: Test passes, no double refresh issues

## Global Constraints
- Godot 4.7.2 (Flatpak) headless execution for testing
- No breaking changes to save format or public APIs
- Preserve existing signal connections and cleanup patterns
- Follow existing code style (UTF-8, 4-space indent, Portuguese comments)

## Report File
Write report to: `/media/f/HD/KINFIRE/.superpowers/sdd/2026-10-30-kinfire-bug-fixes/task-6-report.md`