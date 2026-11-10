# Task 5 Report: Fix Inventory Paper Doll (Character Sprite)

## Status: DONE

## Commits Made
- **8da54d0**: Fix Task 5: Add hero sprite to inventory paper doll center

## Changes Made
Modified `/media/f/HD/KINFIRE/scripts/ui/inventory_panel.gd`:

### Change 1: In `setup()` function (after line 42, after `scroll.add_child(doll)`)
Added hero sprite to the center of the doll:
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

### Change 2: In `refresh()` function (after line 104, after equip views queue_redraw loop)
Added hero sprite update on refresh:
```gdscript
# Atualiza sprite do boneco (pode mudar com equip visual no futuro)
var doll := _grid_view.get_parent().get_child(0)  # primeiro child do scroll é o doll
var hero_sprite := doll.get_node_or_null("HeroSprite")
if hero_sprite:
    hero_sprite.texture = DB.icon(hero.sprite_base())
    hero_sprite.modulate = hero.tint * hero.race.tint
```

## Test Summary
Ran: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`

**Result: PASS**
- Duration: 0.07s
- 50 levels completed successfully
- 9 equipment tests passed, 0 failed
- **Errors: 0**
- **Critical issues: 0**
- Warnings: 5 (expected class restriction warnings for Monk not using Swords)
- Final audit status: ✅ TESTE PASSOU SEM ERROS CRÍTICOS

## Concerns / Follow-up
None. The implementation follows the brief exactly, uses existing code patterns (Portuguese comments, 4-space indent, UTF-8), and all tests pass. The hero sprite will now be visible in the center of the equipment slots in the inventory panel, positioned behind the equipment slots (z_index = -1) so equipment overlays render on top.