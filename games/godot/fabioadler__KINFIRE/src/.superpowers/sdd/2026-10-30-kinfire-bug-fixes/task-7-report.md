# Task 7 Report: Fix HUD Consumable Slots Refresh

## Status: DONE

## Commits Made
- **Hash**: `e783d2b`
- **Message**: "Task 7: Connect hero.inventory.changed signal to refresh consumable slots"

## Changes Made
Modified `/media/f/HD/KINFIRE/scripts/ui/hud.gd` in the `_build_bottom_bar()` function:

Added connection to `hero.inventory.changed` signal after the consumable slots creation loop (after line 185):

```gdscript
# Conecta refresh dos slots de consumíveis quando inventário muda
hero.inventory.changed.connect(func():
    for i in _consumable_slots.size():
        _consumable_slots[i].queue_redraw()
)
```

This ensures all 9 consumable slots (mapped to keys 1-9) refresh their display via `queue_redraw()` whenever the inventory changes (via pickup, purchase, consumption, or other means).

## Test Summary
**Test Command**: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`

**Result**: ✅ **PASSED**

- Total execution time: 0.08s
- 50 levels completed successfully
- 0 Errors
- 0 Critical issues
- 0 Bugs reported
- 5 Warnings (expected: "Monge não sabe usar Espada" - class restriction working correctly)
- Equipment tests: 9 passed, 0 failed
- Final status: "✅ TESTE PASSOU SEM ERROS CRÍTICOS"

## Concerns / Follow-up
None. The change is minimal, targeted, and follows existing code patterns (Portuguese comments, 4-space indent with tabs, proper signal connection syntax). The test passes without any new issues introduced.