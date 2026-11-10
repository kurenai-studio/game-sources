# Task 7 Brief: Fix HUD Consumable Slots Refresh

## Task Description
The consumable slots (1-9 keys) in the HUD bottom bar don't update when inventory changes via pickup, purchase, or other means. They only refresh when the held item changes. Need to connect the `hero.inventory.changed` signal to refresh all consumable slots.

## Files to Modify
- `/media/f/HD/KINFIRE/scripts/ui/hud.gd` (in `_build_bottom_bar()` after line 185, and potentially in `_process()`)

## Required Changes

### Change 1: In `_build_bottom_bar()`, after creating consumable slots (after line 185)
Add connection to inventory changed signal:

```gdscript
	# Conecta refresh dos slots de consumíveis quando inventário muda
	hero.inventory.changed.connect(func():
		for i in _consumable_slots.size():
			_consumable_slots[i].queue_redraw()
	)
```

### Change 2: Verify `_process()` doesn't need changes
The `_process()` function (lines 365-380) already handles the held item icon, but consumable slots should also reflect current inventory state. The connection above should handle this.

## Test to Verify
Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: Test passes, consumable slots update correctly

## Global Constraints
- Godot 4.7.2 (Flatpak) headless execution for testing
- No breaking changes to save format or public APIs
- Preserve existing signal connections and cleanup patterns
- Follow existing code style (UTF-8, 4-space indent, Portuguese comments)

## Report File
Write report to: `/media/f/HD/KINFIRE/.superpowers/sdd/2026-10-30-kinfire-bug-fixes/task-7-report.md`