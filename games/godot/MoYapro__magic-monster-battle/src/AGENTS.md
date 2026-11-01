# AGENTS.md — Wand Magic

Godot 4.x roguelite (GDScript). Turn-based wand combat with a directed spell graph, alchemy fusion, and procedural enemy encounters.

## Running & Testing

**Run the game:** Open in Godot editor (`/usr/bin/godot`) and press Play. Main scene is `scenes/world/path_selection_screen.tscn`.

**Run tests (GUT):**
```
# CLI — from project root
/usr/bin/godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```
Tests live in `tests/` and extend `GutTest`. No `npm`/`make`/CI runner — GUT is the only test framework.

## Architecture at a Glance

```
GameState (Autoload)
    └─ passed via read/write between scenes

Game loop: LootScreen → BattleScene → LevelUpScreen → PathSelectionScreen → LootScreen …
           (on all mages dead: → GameOverScreen)

BattleScene
  ├─ BattleHistory        ← action log; replay = initial_state + apply all actions
  │    └─ BattleState     ← plain data snapshot (pure; no Nodes)
  ├─ BattleSetup          ← immutable setup data (enemies, wands, mages, max_mana)
  ├─ Actions              ← ActionZapWand / ActionAddMana / ActionRemoveMana / ActionEndTurn
  │    └─ each: action.apply(state, setup) → new BattleState
  ├─ EnemyGrid            ← display + hit-test node
  ├─ WandDisplay(×3)      ← per-mage wand UI
  └─ MageDisplay(×3)      ← per-mage HP/mana UI
```

## Core Design Patterns

### Immutable state + action log (event sourcing)
`BattleHistory` stores the initial state and an ordered list of `BattleAction` objects. `current_state()` replays all actions from scratch every call. **Never mutate state directly**; always return a `state.duplicate()` from `apply()`. This is what makes undo (Ctrl+Z) free.

### Pure actions
Every `BattleAction` subclass implements one method:
```gdscript
func apply(state: BattleState, setup: BattleSetup) -> BattleState
```
Actions must not read scene nodes or call `get_tree()`. All randomness is seeded from the action's own stored seed (see `ActionEndTurn._rng_seed`).

### Spell definitions: static factory methods
All spells are plain `SpellData` instances built by a `static func create() -> SpellData` on a class named after the spell. No inheritance from `SpellData` — just static factories.

```gdscript
# Adding a new spell:
class_name SpellMySpell
static func create() -> SpellData:
    var s := SpellData.new("My Spell", "Ms", ["tag"], Color.RED, [], "", 5, 2, "desc")
    s.spell_id = "my_spell"
    s.spell_type = "projectile"  # projectile | catalyst | modifier | tip | alchemy
    s.on_hit_effects = [{"type": "fire", "stacks": 2}]
    return s
```
Register new lootable spells in `SpellRegistry` and in `WandGenerator._pick_body_spell()` / `_pick_tip_spell()`.

### Monster definitions: subclass + _init
Each monster extends `EnemyData` and configures itself in `_init()`:
```gdscript
class_name MyMonster extends EnemyData
func _init() -> void:
    super("my_monster_1", "My Monster", 20, Vector2i(1, 1), Color.BLUE)
    difficulty_rating = 15
    action_pool = [MonsterActionAttack.new("Slash", 4)]
    traits = [MonsterTraitArmor.new(3)]
    drop_pool = [SpellEmber.create()]
```
Add the class reference (not an instance) to the relevant `BiomeData.monster_pool`.

### Status effects: polymorphic hooks
`StatusData` base class has hooks that subclasses override:
- `on_add_status(target, incoming)` — cross-type interactions (e.g., wet cancels fire)
- `on_turn_end(target, setup)` — tick damage / decay
- `on_zap(target, setup)` — fires when the mage zaps (e.g., VineSnare)
- `on_mana_spent(target, setup)` — fires per mana spent (e.g., Leech)
- `blocks_action() -> bool` — return true to prevent enemy/mage action

`StatusTarget` wraps a `(BattleState, mage_index|enemy_id)` pair and provides `get_statuses()` so status code is agnostic about whether it targets a mage or enemy.

### Monster traits: end-of-round hooks
`MonsterTraitData.apply_end_of_round(state, setup, enemy_id) -> BattleState` is called after all intents resolve. Traits are defined on `EnemyData.traits`.

## Key Data Structures

### Slot charge keys
Charges and webbed slots use composite string keys: `"mage_index/slot_id"` (e.g., `"0/s0_0"`, `"1/tip"`).

### Enemy / obstacle IDs
Format: `"display_name_snake_case_N"` (e.g., `"goblin_1"`, `"goblin_2"`). IDs are assigned at encounter-build time by `BattleComposer` / `BattleSetup`. Enemies absent from `state.enemy_hp` are dead.

### WandEvaluator rules (non-obvious)
- **Consecutive identical `spell_id`s multiply**: two Frost spells (damage 5) → `5^2 = 25`. Three → `5^3 = 125`.
- **A modifier between two identical spells breaks the merge.**
- **Trailing modifiers apply back to the last group**, not discarded.
- **Alchemy fusion is NOT done at cast time.** `WandEvaluator` fires catalyst spells as plain projectiles. Fusion happens at the loot screen when slots are placed.
- The `corrupted` modifier consumes target's existing status stacks as bonus damage and converts push/bounce effects to raw damage. The `reactive` modifier branches on the target's current statuses at hit time.

### on_hit_effects dictionary keys
| key | meaning |
|-----|---------|
| `type` | `"fire"`, `"wet"`, `"poison"`, `"freeze"`, `"stun"`, `"blind"`, `"push"`, `"shield"`, `"cleanse_poison"`, `"bounce"` |
| `stacks` | integer stack count |
| `stacks_from_damage` | bool; if true, stack count = total damage dealt |
| `turns` | for stun/blind |
| `amount` | for shield |
| `distance` / `distance_per_cast` | for push |
| `per_cast` | for bounce |
| `damage` | collision damage for push |

### AlchemyTable lookup
Key format: `"catalyst_id|sorted_reactant_a|sorted_reactant_b"`. Wildcard `*` in one reactant position matches anything. Reactant IDs are always sorted alphabetically before lookup.

## Project Structure

```
scripts/
  game_state.gd              ← Autoload; persists mages/wands/backpack/loot between scenes
  battle/
    battle_state.gd          ← Pure data snapshot (no Nodes)
    battle_setup.gd          ← Immutable encounter data
    battle_history.gd        ← Action log + replay
    battle_scene.gd          ← Top-level scene controller
    battle_composer.gd       ← Procedural encounter builder (budget-based)
    wand_evaluator.gd        ← Cast-time spell resolution (static methods only)
    wand_generator.gd        ← Procedural wand builder (static methods only)
    alchemy_table.gd         ← Static lookup: catalyst trio → AlchemyResult
    actions/                 ← ActionZapWand, ActionAddMana, ActionRemoveMana, ActionEndTurn
    spells/                  ← One file per spell; all static create() factories
    statuses/                ← StatusData base + per-status subclasses
    monsters/                ← One file per monster; extends EnemyData
    monster_actions/         ← MonsterActionData subclasses (attack, cleave, summon, etc.)
    monster_traits/          ← MonsterTraitData subclasses (armor, block, regen, etc.)
    obstacles/               ← ObstacleData subclasses; many biome-specific variants
  world/
    biome_data.gd            ← Biome definition (monster_pool, obstacle_pool, unlock chain)
    biomes_data.gd           ← Registry of all biomes; BiomesData.all() → Array[BiomeData]
  loot/loot_screen.gd        ← Drag-and-drop loot management + alchemy fusion UI
  level_up/level_up_screen.gd
  world/path_selection_screen.gd

scenes/                      ← .tscn files mirror the scripts/ structure
tests/                       ← GUT test files; one file per system under test
```

## Conventions & Gotchas

- **`_on_` prefix** for all signal handlers; `PascalCase` for class names; `snake_case` for variables/functions.
- **`class_name` at top of every script** that is referenced by name elsewhere — Godot 4 needs this for type safety and autocompletion.
- **`.uid` files** are Godot-generated; never edit them manually. They exist beside every `.gd` file.
- **Static-only classes** (`WandEvaluator`, `WandGenerator`, `AlchemyTable`, `BattleComposer`) use only static methods and hold no instance state — treat them as namespaced functions.
- **`BattleSetup` is read-only** after construction. Enemy positions that change mid-battle (push, TakeCover) are stored in `BattleState.enemy_positions`, not `BattleSetup`. `BattleSetup.get_enemy_pos(i, state)` resolves the effective position.
- **Grid coordinates**: `Vector2i(col, row)` where col 0 = left/front of enemy board, row 0 = top. Grid is 5 cols × 7 rows (`EnemyGrid.COLS/ROWS`).
- **`difficulty_rating`** on `EnemyData` (1–100) is the only thing `BattleComposer` uses to budget encounters. HORDE battles draw from the cheaper half of the pool; ELITE from the harder half.
- **`MonsterRole.Type`** enum drives placement bias (TANK → front column, ARTILLERY → back column). Set `main_role` and optionally `off_role` on new monsters.
- **`StatusData.stacks = -1`** is the default "uninitialized / unlimited" sentinel; statuses with `stacks == 0` after a tick should set themselves to 0 and the system will filter them on next access — check existing status subclasses for the exact pattern.
- **Mana key `mage_mana_spent`** tracks per-mage spending this turn; `setup.mages[i].mana_allowance` is the cap. Both reset to 0 in `ActionEndTurn`.
- **Win condition** is detected in `BattleScene._apply_state`: if `state.enemy_hp.is_empty()` AND `_history.can_undo()` (i.e., at least one action was taken), battle is won.

## Adding New Content Checklist

### New spell
1. Create `scripts/battle/spells/spell_my_spell.gd` with `static func create() -> SpellData`.
2. Set `spell_id` (lowercase snake) and `spell_type`.
3. Add to `SpellRegistry.all_body_spells()` or `all_tip_spells()`.
4. Add to `WandGenerator._pick_body_spell()` or `_pick_tip_spell()` if it should appear in generated wands.

### New monster
1. Create `scripts/battle/monsters/my_monster.gd` extending `EnemyData`.
2. Add class reference to the relevant `BiomeData.monster_pool` in `scripts/world/biomes_data.gd`.

### New monster action
1. Create `scripts/battle/monster_actions/monster_action_my_action.gd` extending `MonsterActionData`.
2. Implement `execute(state, setup, enemy_id, target_mage) -> BattleState` and `check_preconditions(state, setup, enemy_id) -> bool`.
3. Attach to monster's `action_pool` in its `_init()`.

### New status effect
1. Create `scripts/battle/statuses/status_my_effect.gd` extending `StatusData`.
2. Override relevant hooks. Cross-type interactions go in `on_add_status`.
3. Emit the status from `on_hit_effects` (e.g. `{"type": "my_type", "stacks": 2}`) and handle it in `ActionZapWand._apply_on_hit_effects()`.

### New alchemy recipe
Add an `_add(catalyst_id, r1_id, r2_id, fn)` call inside `AlchemyTable._build_table()`. The spell returned by `fn` should have `spell_type = "alchemy"`.
