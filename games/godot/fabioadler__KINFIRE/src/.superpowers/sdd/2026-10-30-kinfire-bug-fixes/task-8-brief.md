# Task 8 Brief: Fix Character Panel Status Tab Minus Button

## Task Description
Verify and fix the minus button logic in the Character Panel Status tab. The minus button should allow decreasing a status attribute down to (but not below) the base value (class base + level growth). The current implementation may have a bug where it allows going below base.

## Files to Review/Modify
- `/media/f/HD/KINFIRE/scripts/ui/character_panel.gd` (lines 135-146 for minus button callback, lines 252-253 for disable logic)

## Current Code Analysis

### Minus button callback (lines 135-146):
```gdscript
minus.pressed.connect(func():
	# Respec individual: devolve 1 ponto se acima da base
	var base: int = hero.cls.base_status.get(s, 10)
	var growth: int = hero.cls.status_growth.get(s, 0)
	if hero.level > 1:
		base += growth * (hero.level - 1)
	if hero.status[s] > base:
		hero.status[s] -= 1
		hero.status_points += 1
		hero.stats_changed.emit()
		Sfx.play(&"click")
)
```

### Disable logic in refresh() (lines 252-253):
```gdscript
row.minus.disabled = gasto <= 0
row.minus.modulate.a = 1.0 if gasto > 0 else 0.0
```

Where `gasto = total - base` (line 245).

## Issue
The logic appears correct:
- `base` includes class base + level growth (for level > 1)
- Minus button only works if `hero.status[s] > base`
- Disable logic uses `gasto = total - base`, so button is disabled when `gasto <= 0` (i.e., at or below base)

This looks correct. The task is to VERIFY it works and fix ONLY if there's an actual bug.

## Required Action
1. Read the current code
2. Verify the logic is correct
3. If bug found, fix it
4. If no bug, document that it's already correct
5. Test by running the full audit

## Test to Verify
Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: Test passes

## Global Constraints
- Godot 4.7.2 (Flatpak) headless execution for testing
- No breaking changes to save format or public APIs
- Preserve existing signal connections and cleanup patterns
- Follow existing code style (UTF-8, 4-space indent, Portuguese comments)

## Report File
Write report to: `/media/f/HD/KINFIRE/.superpowers/sdd/2026-10-30-kinfire-bug-fixes/task-8-report.md`