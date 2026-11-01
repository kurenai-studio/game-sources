# Wand Magic

A 2D turn-based roguelite where mages wield wands loaded with spell graphs to fight through a series of battles.

## Gameplay Loop

```
Battle → Loot → Level Up → Path Selection → Battle → ...
```

- **Battle** — clear all monsters to continue; all mages die = run over
- **Loot** — pick up spells or wands dropped after the battle
- **Path Selection** — choose the next battle location (e.g. desert, water, forest)

**Run structure:** No win condition — the goal is to survive as many battles as possible. When all mages are dead the run ends and a new one can begin.

## Game Screens

### Battle View
```
+---------------------------+
|      Enemy Board (3x5)    |  ← enemies placed here
+---------------------------+
|     Mage Row              |  ← player's mages with their wands
+---------------------------+
|     Items & Mana          |  ← resources to spend each turn
+---------------------------+
```
Mages and monsters alternate taking actions. Goal: clear the board.

### Loot Screen
After each battle the player sees three areas:
- **New loot** — items dropped from the battle
- **Backpack** — currently stored wands and spells (limited space)
- **Mage wands** — the three equipped wands with their spell slots

The player freely moves loot between all three areas. Anything left in the loot area when the phase ends is lost. The phase ends explicitly when the player confirms they are done.

### Path Selection
After loot, the player picks the next battle from a random subset of currently unlocked biomes. The player is always shown **2 choices**; as more biomes unlock this may grow to **3**. 
The phase ends explicitly when the player confirms their selection.

**Biomes:**
- 18 biomes in **4 layers**: 5 starters → 9 mid biomes → 3 endgame biomes → The Source
- The **5 starter biomes** are available from the beginning and form an element cycle: Fire (Desert) > Ice (Tundra) > Nature (Forest) > Poison (Swamp) > Earth (Mountain) > Fire
- Each biome has its own monster roster and obstacle pool; some monsters are shared across biomes
- Monsters drop monster specific loot with per-monster drop chances
- Difficulty within each biome scales independently — the player can revisit easier biomes but they will outscale other biomes if they are battled more often
- Cross-biome synergy: spells looted in one biome can counter enemies in another (e.g. water spells block poison used by graveyard enemies)
- After ~10 battles in a biome a **boss fight** triggers
- The boss should combine some of the mechanics / actions / traits seen earlier in this biome 
- Defeating a boss unlocks the biome's children in the next layer
- Layer 2 and 3 biomes unlock when **any one** of their parents' bosses is beaten; The Source requires **all three** layer 3 bosses
- Path selection always shows a random subset of unlocked biomes
- Biomes sit on a 2D world map (hot/dry ↔ wet/cold, real ↔ fantasy); nearby biomes may lend stray monsters to each other

**Biome progression:**
```
Layer 1 (starters)   Layer 2                          Layer 3 (any one parent)
Desert    →          Pyramids, Coast
Tundra    →          Glacial Temple, Frozen Shipwreck
Forest    →          Jungle, Graveyard
Swamp     →          Ruins, Coast, Graveyard
Mountain  →          Cave, Volcano

                     Graveyard | Ruins | Volcano        →  Hell
                     Glacial Temple | Pyramids | Jungle  →  Astral Plane
                     Coast | Frozen Shipwreck | Cave     →  Underwater

Layer 4: Hell + Astral Plane + Underwater  →  The Source
```

## Core Systems

### Wand & Spell Graph
A wand holds between 2 (starter) and ~10 (end game) spell slots arranged as a **directed graph**. All edges point toward the tip — the tip is the graph's single endpoint (sink). On their turn, the player picks mana from the mana pool and places it onto spell slots. Each slot has a mana cost — when a slot has enough mana it is "charged". Once one or more slots are charged, the wand can be zapped at a target enemy.

**Wand Tip**
The tip is the sink of the graph and holds a tip spell that defines the hit pattern on the board. Examples:
- Single field
- Two horizontal
- Three vertical
- Area patterns

**Body Slots**
All other slots hold spells. Their position in the graph determines how they combine when fired together:
- *Sequential (in-line)* — spells on the same path to the tip interact **multiplicatively**
- *Parallel (branching)* — spells on separate branches merging toward the tip interact **additively**

This makes the graph layout and mana placement the core strategic decisions.

### Spell Types

**Projectile Spells** deal damage and may apply on-hit effects (e.g. Fireball, Magic Missile, Lightning Bolt). These are the primary offensive units.

**Spell Modifiers** alter the behaviour of the next projectile spell in the resolved cast sequence. They do not fire on their own. Effects include: extra on-hit effects, mana refund, damage multipliers.

**Alchemy Spells** are secret result spells produced by successful alchemy fusions. They cannot be found as loot — they must be discovered through experimentation.

### Wand Evaluation (Two-Pass at Cast Time)

When a wand is zapped the spell sequence (root → tip) is evaluated in two passes:

**Pass 1 — Alchemy Fusion (left-to-right)**

Scan for catalyst trios: a **catalyst spell** immediately followed by two **projectile spells**.

- The trio `(catalyst, reactant_1, reactant_2)` is looked up in the **Alchemy Table** (reactant order does not matter).
- The trio is replaced by the outcome and scanning resumes from the next unprocessed spell.
- If the catalyst is not in the leading position the three spells fire individually (no fusion).
- If no entry exists in the Alchemy Table the three spells act normally (they cast individual hits).

Grouping rules:
- Solo projectile → fires normally.
- Two projectiles in sequence → both fire as separate projectiles in one cast.
- Three with catalyst first → fusion attempted.
- Three without catalyst first → all three fire individually.
- Four projectiles in sequence → first three fuse (if valid catalyst), fourth fires normally.

**Pass 2 — Modifier Application (left-to-right)**

Each modifier applies its effect to the immediately next spell in the flattened post-fusion sequence.
- Modifier before a fizzle: consumed silently (wasted).
- Modifier before a backfire: **amplifies** the backfire.

The final output is an ordered list of projectile spells that are zapped at the target simultaneously.

### Alchemy Table

A static lookup table mapping `(catalyst, reactant_1, reactant_2)` → outcome. Every entry has one of three outcome types:

| Outcome | Effect |
|---|---|
| **Success** | A secret alchemy spell fires. On first creation it is marked as discovered in save data. |
| **Fizzle** | Nothing fires; mana is wasted. A fizzle visual plays. |
| **Backfire** | A negative effect triggers on the caster (e.g. self-damage, status effect). A backfire visual plays. |

**Example entries:**
- `fire, water, fire` → Steam *(blinds enemies in the area or conceals the caster)*
- `force_push, water, frost` → Ice Cube *(high damage + freeze)*
- `force_push, water, bone` → Soap *(cleanses poison)*
- `fire, water, frost` → Fizzle *(fire cannot combine water and frost)*
- `force_push, lightning, *` → Backfire *(hits the casting mage)*

### Catalysts

A small fixed set (~5–8). Each defines *how* reactants combine. A catalyst must be compatible with the chosen reactants — an incompatible pairing results in a fizzle or backfire (defined explicitly in the Alchemy Table).

Examples:
- **Fire** — heats reactants; works with combustible/thermal ingredients.
- **Force Push** — smashes reactants together; works with physical/dense ingredients.

### Visual Feedback

Cast-time visuals signal all three outcomes (success, fizzle, backfire). Because battles support undo, players can experiment with combinations safely in real battles.

### Discovery System *(planned)*

A codex screen lists all spells (drops + alchemy), biomes, and monsters. Discovered entries show a full description; undiscovered entries show only a silhouette/outline.

**Line of Sight**
A target cannot be hit if a monster or obstacle (tree, stone, wall, etc.) occupies a cell in front of it.

### Mages
The player controls three mages. Mages are lost permanently if killed in battle.

Each mage:
- Has one wand equipped for the current battle
- Has a **focus element** (a lootable, swappable item) that generates mana every round
- May carry additional wands and spells in a **backpack** (not usable mid-battle, rearranged in loot phase)

**Mage actions:** Zapping a wand is the primary action. Spell effects determine outcomes — damage, shields on one or multiple mages, stuns, blinds, kills, and other status effects that can negate incoming enemy actions.

- A mage can zap multiple times per turn if mana allows
- All three mages can act in a single player turn
- The player chooses where on the board to center the tip's hit pattern

**HP:** Each mage has their own HP value.

**Level Up Phase:** After each battle, the player upgrades one base stat of one mage. Upgradeable stats:
- Max health
- Max mana spend per round

### Enemies
Placed on a 5x7 grid. Stationary during battle. Cleared when HP reaches zero.

**Turn order (always telegraph → act → resolve, no interleaving):**
1. Each enemy rolls one of their actions and telegraphs it (target mage visible to player)
2. All mages take their turn (player acts freely across all three mages)
3. All enemy actions resolve simultaneously — unless the enemy is disabled (stunned, blinded, dead, etc.)

**Actions:** Each monster has a short list (1–3) of possible actions (attack, shield, spellcast, etc.). One is selected randomly each turn.

**Status effects:**
- *Stunned* — enemy action does not resolve this turn
- *Blinded* — enemy either misses entirely (50%) or hits a random mage instead of the telegraphed target (50%)

**Size:** Monsters can occupy multiple grid fields. Example: a shield ogre is 2 fields wide and blocks attacks for enemies behind it.

**Obstacles:** Static at battle start but can be destroyed or moved by spells.

**Scaling & Composition:**
- Starter monsters are fully predefined
- Later monsters have randomized stats, effects, and/or actions — monsters are composed from parts rather than hardcoded, to support this variety
- Difficulty increases with each successive battle

### Mana Pool
All three mages share a single mana pool that persists between battles.

- **Starting mana:** 10
- **Replenishment:** 2 mana per mage per turn (6/turn with a full party of 3)
- Each mage's focus element adds additional mana every round
- **Post-battle refill:** 50% of max mana (e.g. +5 if max is 10)
- **Mana cap** is determined by mage items (TBD — treat as a future variable in design choices until then)
- Each mage has a **max mana spend per round** stat that limits how much of the pool they can draw in a single turn; this stat is upgradeable

**On each turn:** the player freely allocates mana across any number of wands, up to each mage's spend cap. If at least one slot on a wand is fully charged, that wand can be zapped. Multiple wands can be zapped in the same turn.

## Planned Features

### Battle
- [ ] Turn-based combat loop (mages and enemies alternate)
- [ ] Enemy behaviors and actions
- [ ] Win/lose condition detection
- [ ] Mana placement on wand slots (mana cost per slot, charge system)

### Wand System
- [ ] Path traversal during casting (sequential × parallel spell interactions)
- [ ] Spell tag interactions (fire+water cancel, poison+amplify multiply, etc.)
- [ ] Wand editor / rearrangement UI

### Loot & Progression
- [ ] Loot screen with new loot / backpack / wand areas
- [ ] Free drag-and-drop of loot between areas
- [ ] Backpack space limit
- [ ] Persistent mage/wand/backpack state between battles
- [ ] Focus element slot per mage

### Path Selection
- [ ] Boss fight trigger after ~10 battles per biome (currently 10 wins count as a boss defeat)
- [ ] Biome-specific loot tables (loot currently comes only from per-monster drop pools)
- [ ] Stray monsters from nearby biomes (`stray_pool` / `stray_weight` exist but are unused)
- [ ] Assign a biome to the first battle (currently falls back to Desert and the win is not counted)
- [ ] Keep scaling or retire a biome after level 10 (level caps at 10, so a biome can be farmed indefinitely)
- [ ] Remove or hide the debug level spinbox in the battle screen

## Implemented Features

### Battle
- [x] Enemy grid (5×7) with placement, bounds checking, multi-cell enemy support, removal, and damage
- [x] Enemy display with name and HP bar; enemies removed at 0 HP
- [x] Three mages with HP bars (MageDisplay)
- [x] Mana pool display — individual droplets that overlap when count is high
- [x] Targeting mode: click wand tip → all valid targets highlight yellow
- [x] Hover during targeting: hovered cells/enemies/mages/wands highlight red, hit pattern applied
- [x] Wand firing: deals summed spell damage to all cells in the tip's hit pattern
- [x] Turn-based combat loop — mages act, then all enemy actions resolve simultaneously
- [x] Mana slot mechanics — place mana from pool onto slots; slots charge when cost met; discharge returns mana to pool
- [x] Enemy status effects: poison (1 dmg/turn), fire (stacks dmg, halves each turn), wet (decay, interacts with fire); fire + wet cancel each other
- [x] Enemy armor (absorbs damage before HP) and block (prevents hit, consumes one charge per hit)
- [x] Mage status system — statuses are typed objects with stacks; cross-type interactions handled at add time
  - [x] Fire: damages mage each turn by stack count, stacks halve after each tick, cancelled by wet
  - [x] Wet: decays by 1/turn, no damage, cancels incoming fire
  - [x] Poison: deals 1 damage/turn regardless of stacks, stacks decay by 1/turn
  - [x] Frozen: blocks the mage's zap action; melts completely when hit by fire
  - [x] Vine Snare: penalises the mage on zap (HP cost + heals the snarer); self-removes after zap or at turn end
  - [x] Leech: heals the source enemy by 1 per mana the mage spends; self-removes at turn end
- [x] Line-of-sight blocking — obstacles and enemies block hits to cells behind them

### Wand System
- [x] Directed spell-graph wand (SpellSlotData with next_id chain toward tip)
- [x] Wand generator: randomised column layout, guaranteed single tip, all slots connected
- [x] Body spells: Ember (fire), Frost (water), Venom (poison), Amplify (amplify), Shield (no dmg)
- [x] Tip spells: Single (1 cell), Line (3 vertical), Pierce (3 horizontal), Bomb (3×3 area)
- [x] Bomb has a hand-drawn icon; other spells show element-tinted abbreviation
- [x] Spell damage: each slot contributes damage summed at fire time
- [x] Two-pass wand evaluation: alchemy fusion pass (catalyst + two projectiles → lookup) then modifier application pass
- [x] Alchemy table: catalyst trios resolve to success (secret spell), fizzle (wasted), or backfire (damages caster)
- [x] Spell modifiers: apply to the next projectile — damage multipliers, extra on-hit effects
- [x] Backfire: resolves against the casting mage; amplified if a modifier precedes it

### Monsters
- [x] Cleave: damages all mages equally; respects attack multiplier
- [x] Take Cover: monster moves behind the nearest unoccupied obstacle or ally; rejects out-of-bounds and occupied cells
- [x] Summon Skeleton: spawn count scales with drummer HP (1 at full health, up to 3 at low HP); respects grid capacity; blocks respawn of already-alive skeletons
- [x] War Drummer (boss): forces Raise Fallen when no skeletons are alive or dead; otherwise selects randomly from action pool
- [x] Wet Healing trait: heals the monster each round by its current wet stack count; does not consume wet stacks
- [x] Revenge Revive trait (Bone Caller): when a monster dies, revives the strongest dead ally at full HP in its last cell (or a random free cell); monsters with Revenge Revive cannot be revived

### Path Selection
- [x] Path selection screen showing 2 random unlocked biomes with name, tagline, and current level
- [x] 18 biomes in 4 layers (5 starters → 9 mid → 3 endgame → The Source), each with its own monster and obstacle pool
- [x] Biome unlock chain: layer 2/3 biomes unlock when any parent biome is beaten; The Source requires all three layer-3 biomes
- [x] Per-biome difficulty scaling: biome level = wins in that biome + 1 (max 10), scaling difficulty budget and elite chance
- [x] Battles composed from the selected biome's monster and obstacle pools
- [x] Codex biomes tab listing every biome and its monsters

## Architecture

See [`docs/architecture.puml`](docs/architecture.puml) for the high-level component diagram.
