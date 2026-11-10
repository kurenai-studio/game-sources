# Task 1 Brief: Fix Tutorial Progression & Quest Stage Advancement

## Task Description
Fix the tutorial quest progression bug where the quest doesn't advance properly through stages. The issue is in `quest_log.gd`:
1. When a quest starts via FLAG (`tut_inicio`), the new stage's FLAG objectives that are already satisfied don't get auto-completed
2. When a quest advances to the next stage, the new stage's FLAG/COLLECT objectives that are already satisfied don't get auto-completed

## Files to Modify
- `/media/f/HD/KINFIRE/scripts/core/quest_log.gd` (lines 118-167, 222-235)

## Changes Required

### Change 1: In `_event()` function (after line 123 where `start(q)` is called)
Add `_recalc(q)` call after starting a quest from a FLAG event to check if the new first stage has pre-satisfied FLAG objectives.

### Change 2: In `_check_stage()` function (after line 232 where `Game.quests[q.id]["prog"] = []`)
Add `_recalc(q)` call after advancing to a new stage to auto-complete any FLAG/COLLECT objectives already satisfied in the new stage.

## Test to Verify
Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: Tutorial phase passes, 50/50 levels completed

## Global Constraints
- Godot 4.7.2 (Flatpak) headless execution for testing
- No breaking changes to save format or public APIs
- Preserve existing signal connections and cleanup patterns
- Follow existing code style (UTF-8, 4-space indent, Portuguese comments)

## Report File
Write report to: `/media/f/HD/KINFIRE/.superpowers/sdd/2026-10-30-kinfire-bug-fixes/task-1-report.md`