# Task 2 Brief: Add Missing `tracked_quest()` Method to QuestLog

## Task Description
Add the missing `tracked_quest()` method to QuestLog that the HUD quest tracker calls. Currently `_update_quest_tracker()` in hud.gd calls `Game.quest_log.tracked_quest()` but this method doesn't exist.

## Files to Modify
- `/media/f/HD/KINFIRE/scripts/core/quest_log.gd` (add method after line 16, after `tracked` property)

## Changes Required

### Add new method after line 16:
```gdscript
## Retorna a QuestData da quest rastreada (para HUD tracker)
func tracked_quest() -> QuestData:
	if tracked == &"":
		return null
	return DB.quest(tracked)
```

## Test to Verify
Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: HUD quest tracker works, no crash on `tracked_quest()` call

## Global Constraints
- Godot 4.7.2 (Flatpak) headless execution for testing
- No breaking changes to save format or public APIs
- Preserve existing signal connections and cleanup patterns
- Follow existing code style (UTF-8, 4-space indent, Portuguese comments)

## Report File
Write report to: `/media/f/HD/KINFIRE/.superpowers/sdd/2026-10-30-kinfire-bug-fixes/task-2-report.md`