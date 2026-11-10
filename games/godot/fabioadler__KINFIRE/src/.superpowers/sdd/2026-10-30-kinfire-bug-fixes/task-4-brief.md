# Task 4 Brief: Fix Skill Tree Connection Lines

## Task Description
Verify and fix the `_canvas_draw()` function in `skill_tree_panel.gd` (lines 436-482) that draws connection lines between skill tree nodes. After Task 3's depth fix, prerequisites are now on the LEFT (lower depth) and dependents on the RIGHT (higher depth). The current code draws FROM node TO prerequisite, which with the corrected layout should draw right-to-left (from dependent to prerequisite). Verify this creates correct visual flow.

## Files to Modify
- `/media/f/HD/KINFIRE/scripts/ui/skill_tree_panel.gd` (lines 436-482) - verify and adjust if needed

## Current Code Analysis
The `_canvas_draw()` function:
- Iterates through each node in `_nodes_ui`
- For each prerequisite (`node.requires`), draws a bezier curve FROM the node (`from_pos`) TO the prerequisite (`to_pos`)
- With Task 3 fix: node (dependent) is on RIGHT, prerequisite is on LEFT
- Line goes from RIGHT to LEFT (dependent → prerequisite)

This is actually the CORRECT visual flow - lines should point from prerequisites to dependents (left to right), but since we're drawing from node to its prerequisites, we get right-to-left lines. This is fine visually as long as the arrow/flow direction is clear.

## Required Action
1. Verify the current connection lines look correct with the new layout
2. If needed, adjust the bezier curve control points for better visual appearance
3. The color coding is already correct:
   - `line_color_locked` (gray) for locked connections
   - `line_color_active` (green) when both prereq and node are unlocked
   - `line_color_available` (gold) when prereq unlocked but node available

## Test to Verify
Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: Skill tree connections render correctly, test passes

## Global Constraints
- Godot 4.7.2 (Flatpak) headless execution for testing
- No breaking changes to save format or public APIs
- Preserve existing signal connections and cleanup patterns
- Follow existing code style (UTF-8, 4-space indent, Portuguese comments)

## Report File
Write report to: `/media/f/HD/KINFIRE/.superpowers/sdd/2026-10-30-kinfire-bug-fixes/task-4-report.md`