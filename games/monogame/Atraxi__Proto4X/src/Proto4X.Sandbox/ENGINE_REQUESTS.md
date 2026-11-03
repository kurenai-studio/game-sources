# Engine Requests

Requests filed from `Proto4X.Sandbox` while building a minimal playable loop against `MonoGameLibrary`. Each entry: what's missing, why it came up, what was tried instead, and possible approaches. This doubles as one of Jason's TODO lists — sorted open-and-high-priority first, down to resolved/closed at the bottom. Pull items into conversation or a GitHub issue when you want to act on one.

**Sort order:** Open items first (sorted High → Medium → Low priority), then Resolved/closed items at the bottom (priority no longer drives sort once closed). Default new ideas — things Jason raises as possible enhancements without discussing urgency — to **Low** priority; only mark Medium/High when there's a concrete reason (blocks a planned mechanic, recurring pain, discussed as important).

<!-- Template:

## <short title>
**Status:** Open | Open — partial | Open — discussed | Open — worked around | Resolved | Resolved — decided against
**Priority:** High | Medium | Low

<details>
<summary>Details</summary>

**What:** what the engine can't currently do.

**Why it came up:** the specific thing in the sandbox that needed it.

**Tried instead:** any workaround attempted or considered and rejected, and why.

**Possible approaches:** rough shape of a fix, if any come to mind. Not a spec.

</details>

Keep **Status:**/**Priority:** outside the <details> block so they're visible without expanding. Leave a blank line after <summary> and between each field — GitHub only parses markdown (bold, lists) inside an HTML block if it's blank-line-separated from the tags. Re-sort the file (see Sort order above) whenever an entry's status or priority changes.

-->

## Systems can only declare one AND-mask query; no cross-archetype join/union
**Status:** Open — discussed
**Priority:** High

<details>
<summary>Details</summary>

**What:** `SystemBase.RequiredComponentProviders` is a single `ComponentTypeMask`, and `SystemScheduler` hands a system only the archetype chunks whose mask `ContainsAll` that one query. There's no way for a system to express "OR"/"NOT" over component masks, and no way to receive entities from two genuinely different archetypes (e.g. "the player" vs. "resource nodes") in the same `Update` call to relate them to each other — each system pass is scoped to one AND-query's worth of matching archetypes.

**Why it came up:** `GatherSystem` (`Proto4X.Sandbox/Systems/GatherSystem.cs`) needs to check each resource node's distance to the player. Resource nodes are `Position+Gatherable`; the player is `Position+Motion` — different archetypes, neither a subset of the other, so one `RequiredComponentProviders` mask can't select both in the same call.

**Tried instead:** queried only `Position+Gatherable` (the resource nodes) and read the player's `Position` separately via `GameWorld.GetComponentsForEntity(playerEntityId)`, the same single-entity random-access path `UserInterfaceManager` already uses for the WASD-selected entity. Works, but only because there's exactly one player; doesn't generalize to "any two groups of entities need to interact." This kind of interaction (combat, docking, trading, gathering) is central to a 4X game, so this will keep recurring.

**Possible approaches:** discussed with Jason — two different problems worth separating:

1. A query wrapper over `ComponentTypeMask` supporting AND/OR/NOT combinations. Still cheap (same bitmask-logic character `ContainsAll`/`ContainsAny` already have), and would at least let a system's *one* query express "entities with A and (B or C) but not D" — doesn't by itself solve joining across archetypes, but is a small, self-contained first step.
2. Actual join/union queries — letting one system `Update` call see entities from multiple unrelated archetypes together, or relate entities across them — is a fundamentally harder and more computationally expensive problem (more like a relational join than a bitmask test). Would be considerably more broadly useful than (1) if it can be made generic and performant, but isn't a small addition. Not scoped or committed to.

**Update 2026-08-02 — three concrete costs, now that the sandbox is a real RTS.** Building combat, gathering and production against this constraint forced three distinct workarounds, which between them are a decent argument for how much (1) alone would actually buy:

- **Padding entities with components they don't want, to force them into one query.** `CombatSystem` needs shooters and their victims in the same call, so *every* combat participant shares one component set — including unarmed miners, which carry a `Weapon` with `Range = 0` purely to be visible to the query (`Proto4X.Sandbox/Components/Weapon.cs`). It works, and declaring the whole "combat quad" as an `IDependsOnOtherComponents` dependency even makes the invariant self-enforcing, but the archetype now encodes "what queries need to see me" rather than "what I am". Note this is a case AND/OR/NOT wouldn't fix either — it's the join that's missing, not the mask expressiveness.
- **Per-frame snapshot publishing, one system per archetype.** `AsteroidIndexSystem` and `StationIndexSystem` exist only to copy positions out of an archetype into a flat `List<Vector2>` so that systems querying a *different* archetype can read them. Cheap here, and it reads fine, but it is a copy per frame per relationship.
- **Snapshots are read-only, which changed the game design.** A snapshot gives a reader no way to write back to the source archetype, so asteroids in this build are **infinite** — finite ore would need miners to decrement a `Gatherable` they can't reach. That's a design decision made by an engine limitation rather than by choice, which is the clearest signal so far that this one matters.

**Also worth noting:** the O(n²) sweep in `CombatSystem` is *inherent* to "nearest hostile", not caused by this gap — a join would remove the archetype gymnastics, not the pairwise distance test. Spatial partitioning is a separate, later problem, and not one the sandbox needs at this scale.

</details>

## Game code has no way to obtain an entity id — from a chunk, or from the entity it just created
**Status:** Open — half resolved, half open
**Priority:** Medium

<details>
<summary>Details</summary>

**What:** two halves of the same gap, which are only fatal together:

1. **No id from a chunk index.** `ArchetypeChunk` exposes `Get<T>(index)`/`GetSpan<T>()` for component data and `QueueEntityForRemovalByIndex`/`ById` for removal, but nothing maps a chunk index back to the owning entity id. `Archetype.DenseIndexToEntityId` holds exactly that mapping but is private, and `ArchetypeChunk` only holds an `IArchetype` handle narrow enough for removal.
2. **No id from creation either.** `GameWorld.AddEntity(EntityBuilder)` returns `void`, and the id isn't even assigned at call time — `Archetype.AddEntity` calls `EntityIdRegistry.GetNextFreeId()` later, inside `ProcessDeferredUpdates`. So a caller can't be handed the id, and can't predict it: which pending entity gets which id depends on `Archetype` iteration order across a `Dictionary`.

Between them, **no game-side code can obtain a valid entity id for anything it didn't hardcode.** The only ids that exist today are the "spawned first, so it must be 0" convention the previous sandbox build relied on — which is exactly what stops working the moment a game builds units at runtime.

**Why it came up:** the sandbox is now a small RTS with dozens of units built during play (`Proto4X.Sandbox/DESIGN.md`). Every natural design here wants an id: which units are selected, which enemy a fighter is shooting, which asteroid a miner is assigned to, where a station's new ship went.

**Tried instead — and this is the interesting part:** rather than hardcoding ids, the whole game was designed to **never use an entity id at all**, and it worked out better than expected:

- **Selection is component state, not a list of ids.** `Selectable.IsSelected` is a bool on the entity (`Components/Selectable.cs`). Selecting and ordering become ordinary chunk iterations, and a unit that dies stops being selected for free, with no list to invalidate. This is *more* ECS-idiomatic than the id-list version would have been and is worth keeping regardless.
- **References become proximity queries.** Combat re-picks "nearest hostile in range" every frame instead of storing a target. Miners find rocks and drop-off points by nearest-position lookup against a snapshot.
- **Spawning describes rather than creates** (see the deferred-addition entry below), so nothing needs the id of what it just built.

**So this is no longer blocking the sandbox** — but only because the game was shaped around it. Two things it still costs, which no amount of design gets around: an entity cannot hold a *stable* reference to another entity (a fighter can't keep chasing one specific target through a crowd), and nothing can be addressed from outside the world (a save file, a scripted scenario, a network message, a debugger command all need a name for an entity).

**Possible approaches:** (1) is small and self-contained — expose `ArchetypeChunk.GetEntityId(index)`, or a `ReadOnlySpan<int>` of ids alongside the component spans, backed by the `DenseIndexToEntityId` array that already exists. Read-only, no new structural-mutation surface, same cost character as `GetSpan<T>`. (2) is more awkward given ids are deliberately assigned at flush time; the honest options are to assign the id at `AddEntity` time and return it, or to hand back a deferred handle that resolves after `ProcessDeferredUpdates`. Worth noting (2) overlaps heavily with the `EntityView` design below — the generation-stamped id discussed there would answer "what do I hand back" for both.

**Update 2026-08-05 — half (1) is done.** `ArchetypeChunk.GetEntityId(index)` now forwards to `Archetype.GetEntityId`, returning `DenseIndexToEntityId[entityIndex]`. Correct: chunk indices *are* dense indices, so no translation is needed. Half (2) — learning the id of an entity you just created — is unchanged and still open, which means ids can be *read* but never *originated*.

**Not yet used by the sandbox, deliberately.** The game is built with no entity ids anywhere (see above), and that decision is still paying: selection-as-component-state and nearest-target-per-frame are both better designs than the id-based versions would have been, not merely adequate substitutes. Adopting stored ids now would reintroduce exactly the dangling-reference class the current design is immune to, so it wants to be a considered decision rather than a drive-by one. What it would unlock, if taken: stable combat targeting (focus fire, chasing a fleeing ship — the sandbox currently re-picks the nearest hostile every frame and so can do neither), and entity-to-entity relationships generally.

**Two caveats on the accessor as it stands:**

- **No bounds check against `count`.** `DenseIndexToEntityId` is capacity-sized, not count-sized, so an index at or past `EntityCount` returns a stale id belonging to a removed entity rather than failing. In-bounds by construction for anything iterating a chunk properly, and `Get<T>` has the same character, so this is consistent rather than newly dangerous — but it is a silent-wrong-answer rather than a throw.
- **Ids are only valid until `ProcessDeferredUpdates` runs.** Swap-remove reassigns dense indices at end of frame, so an id read this frame describes an entity that may not exist next frame. That's the stale-handle question the `EntityView` entry below raises, arriving via a different door — worth answering there once rather than twice.

Also worth flagging: `ArchetypeChunk` now implements `IArchetype` and forwards to the archetype it wraps. It reads slightly oddly — a chunk is a per-query view, not an archetype — and it means a chunk can be passed anywhere an `IArchetype` is expected. Harmless today, but the interface is now doing double duty as "the archetype" and "a narrow mutation handle onto one".

</details>

## No screen-space draw pass — every draw system is inside the camera transform
**Status:** Open — landed, two defects remain
**Priority:** High

<details>
<summary>Details</summary>

**What:** `SystemScheduler.Draw` wraps the entire draw loop in a single `spriteBatch.Begin(transformMatrix: camera.GetCameraTransform())` / `End()` pair. Every `IDrawSystem` therefore draws in world space, through the camera. There's no second pass, no per-system opt-out, and no hook between `Begin` and `End` — so nothing can draw in screen space: no HUD, no minimap, no fixed-position overlay, and nothing that should stay a constant size on screen while the world zooms.

**Why it came up:** the box-select rectangle is defined by two mouse positions, i.e. it is a *screen* rectangle, but it has to be drawn through a world-space camera transform.

**Tried instead:** `SelectionOverlayRenderer` transforms each of the drag rectangle's four screen corners back into world space individually and draws it as four lines. This is actually correct under camera rotation and zoom — more correct than converting to a world AABB would be — so it's a genuinely fine answer for a *shape*. It is not an answer for a HUD, and it does mean overlay line thickness scales with zoom, which is wrong for UI even though it looks fine for in-world decoration.

**Possible approaches:** a second draw list — e.g. an `IScreenDrawSystem` (or a flag on `IDrawSystem`) collected separately and drawn in its own `Begin`/`End` with no transform, after the world pass. Also worth deciding at the same time whether draw *order* should be explicit rather than "order the systems were registered in", which is what it is today (see the `Drawable` entry below).

**Implemented 2026-08-05 as `DrawSpace`.** `IDrawSystem` declares `World` or `Screen`, `SystemScheduler.Add` sorts systems into two lists at registration, and `Draw` runs two `Begin`/`End` passes — untransformed for screen, camera-transformed for world. Sorting at `Add` rather than per frame is the right call; the per-frame cost is one extra `Begin`/`End`.

**Now in use by the sandbox:** `MinimapRenderer` (a corner minimap with faction dots and a camera-position outline — the first thing in this game that genuinely could not have been faked in world space, since it must hold its position *and* its scale while the world pans and zooms) and `SelectionBoxRenderer` (the drag rectangle, now drawn from raw mouse coordinates with a constant one-pixel border instead of transforming four corners back into the world). The old combined `SelectionOverlayRenderer` split into `SelectionRingRenderer` (World) and `SelectionBoxRenderer` (Screen), since a system declares exactly one `DrawSpace`.

**Defect 1 — the screen pass draws first, so UI renders *underneath* the world.** `Draw` runs `_drawScreenSystems` before `_drawWorldSystems`, and `SortMode.Deferred` means later draws land on top. Any world sprite overlapping the minimap's corner will cover it. Swapping the two blocks fixes it. Screen space is essentially always meant to be the topmost pass.

**Defect 2 — screen systems receive world coordinates as their `viewport`.** Both passes are handed `userInterfaceManager.GetVisibleScreenBoundsAABB()`, which is the *world-space* AABB of the visible region. That's correct for the world pass (it's the culling bounds) and meaningless for the screen pass, where a system wants the actual viewport rectangle. `MinimapRenderer` works around it by taking `GraphicsDevice` in its constructor and reading `Viewport.Bounds` at draw time, which also survives a window resize. Worth noting the parameter now means two different things depending on which list a system landed in, which is exactly the kind of thing a `DrawContext` struct would let you disambiguate.

Minor: `GetVisibleScreenBoundsAABB()` is called inside the screen loop, so it recomputes (and allocates a `Vector2[4]`) once per screen system per frame. The world pass correctly hoists it above the loop.

**Known and deliberately deferred:** `_drawScreenSystems[gameLayer]` is a raw dictionary index, so a `GameWorld` with no registered screen system throws `KeyNotFoundException` on the first frame — the same shape as the "zero registered systems" entry near the bottom of this file, which `Core` currently masks for the update and world-draw lists by registering `TimerSystem` and `Renderer`. Jason's stated intent is an engine-provided default UI system registered by `Core`, on the reasoning that no real game lacks UI. The sandbox is unaffected in the meantime because it registers two screen systems of its own.

</details>

## SystemScheduler throws on a GameWorld with no system of a given kind
**Status:** Open — recurring, deferred
**Priority:** Medium

<details>
<summary>Details</summary>

**What:** `SystemScheduler.Update`/`Draw` index their dictionaries directly (`_updateSystems[gameLayer]`, `_drawWorldSystems[gameLayer]`, `_drawScreenSystems[gameLayer]`). A `GameWorld` only gets an entry the first time `Add` is called for that world *and that kind of system*, so any kind with no registered system throws `KeyNotFoundException` on the first frame rather than being treated as a no-op.

**Why it keeps coming back:** this was first hit when scaffolding a bare `Core`-derived game with no systems at all. It was masked rather than fixed — `Core.Initialize` registers `Renderer` and `TimerSystem` unconditionally, which guarantees an entry in the update and world-draw lists for every game. Adding `DrawSpace.Screen` created a third list that nothing registers by default, so the same bug reappeared immediately: a game with no screen-space system cannot start, with no useful error.

**Tried instead:** the sandbox registers screen-space systems of its own (minimap, build menu, selection box, performance graph), so it doesn't trip it. That's luck, not a fix.

**Deliberately deferred by Jason**, with the intended direction being an engine-provided default UI system registered by `Core`, on the reasoning that no real game lacks UI. Worth noting that this makes the third list behave like the other two — i.e. it masks the bug a third time rather than removing it. `TryGetValue` at all three sites would close it properly and costs nothing; the default UI system is then a feature rather than a workaround.

**Related:** the same "who registers the defaults" question is the first thing the engine-layering split runs into — see `ENGINE_LAYERING.md`.

</details>
## Camera position can only be changed by the arrow keys
**Status:** Open — blocked a feature
**Priority:** Medium

<details>
<summary>Details</summary>

**What:** `Camera` keeps `cameraMatrix` private and exposes only `GetCameraTransform()`. Everything that moves it — arrow-key pan, `Z`/`X` rotate, scroll zoom — is hardcoded inside `Camera.Update`, which is `internal`. There is no public way for game code to set or nudge the camera's position, and no way to read where it currently is other than inverting the transform by hand.

**Why it came up:** building `MinimapRenderer`. Click-to-jump on the minimap is the other half of what a minimap is *for* — see where the fight is, click, go there — and it's standard in every RTS. The rendering half works; the navigation half can't be written, because there's nothing to write it against.

**Tried instead:** nothing implemented — the minimap ships as display-only. `MinimapRenderer` already inverts `GetCameraTransform()` to work out which region is on screen for the "you are here" outline, so *reading* the position is possible if inelegant. Writing it isn't possible at all, and faking it by synthesising key presses would be worse than leaving the feature out.

**Possible approaches:** the minimum is a public `Vector2 Position { get; set; }` (or `MoveTo`/`CentreOn(Vector2 worldLocation)`) with the matrix rebuilt from position/rotation/zoom rather than accumulated by repeated `*=`. Worth noting the current implementation multiplies into `cameraMatrix` every frame, which both makes the state hard to read back and accumulates floating-point drift over a long session — storing position/rotation/zoom as fields and composing the matrix on demand would fix the accessibility problem and that one together.

Related but separable: the input handling inside `Camera.Update` is the same "engine owns the keybindings" issue already noted in a TODO comment in that file, and the same split that moved WASD out of `UserInterfaceManager` into a per-game system would apply here.

</details>

## Drawable carries no tint, scale or draw order
**Status:** Open — worked around
**Priority:** Medium

<details>
<summary>Details</summary>

**What:** `Drawable` holds a sprite id and an optional source rectangle, and `Renderer.Draw` hardcodes everything else: `Color.White`, scale `1`, `SpriteEffects.None`, `layerDepth: 1`. So an entity can't be tinted, scaled, faded, or flipped, and since the batch is `SortMode.Deferred`, `layerDepth` does nothing — draw order is purely the order systems were registered in, with no ordering *within* a system's chunk iteration.

**Why it came up:** an RTS needs faction colours (two sides, visually distinguishable at a glance) and would like damage flashes and fade-outs.

**Tried instead:** `Game/SpriteSet.cs` bakes a recoloured copy of every ship and station texture at load — `GetData`, multiply RGB by the faction tint, `SetData` into a new `Texture2D`, register each as its own `SpriteLibrary` entry. That's fine for a fixed, small palette of factions and needs no engine change at all, which is why it wasn't logged as a blocker. It does not extend to anything *dynamic*: a per-frame damage flash or a fade-on-death can't be pre-baked, and the texture count multiplies by faction count.

**Possible approaches:** add `Color Tint`, `float Scale` and a layer/order value to `Drawable` and pass them through in `Renderer`. Cheap in bytes and reads naturally, but worth a thought about whether ordering belongs on the component (a sort per frame) or stays a property of system registration order — the latter is free and has been sufficient so far.

</details>

## No way to spawn or destroy an entity from inside a running system
**Status:** Open — partial
**Priority:** Medium

<details>
<summary>Details</summary>

**What:** `Archetype` already had working deferred-queue machinery (`QueueEntityForAddition`, `QueueEntityForRemovalById`/`ByIndex`, `ProcessDeferredUpdates`, which `SystemScheduler.Update` calls after every system runs), and `GameWorld.RemoveEntity(entityId)` reached that queue — but only from outside a system's `Update`. A running `IUpdateSystem.Update` was only ever handed `List<ArchetypeChunk>`, with no reference to `GameWorld` or the owning `Archetype`.

**Why it came up:** any dynamic mechanic beyond "consume an existing entity" needs this — a projectile system spawning a shot, a resource node splitting, a health system killing an entity at 0 HP already works (removal), but nothing can spawn from inside a system yet.

**Resolution — removal:** `ArchetypeChunk` now carries an `IArchetype` and exposes `QueueEntityForRemovalById`/`QueueEntityForRemovalByIndex` as a minimal, read/write-free handle. A system can now queue removal of an entity it's currently iterating. Along the way, a real batching bug got fixed: `Archetype.ProcessDeferredUpdates` processed `DeferredEntityRemovalsByIndex` in queue order rather than descending index order, which corrupted `EntityIdToDenseIndex` for an unrelated live entity whenever two-or-more removals landed on the same archetype in one frame. The fix (`DeferredEntityRemovalsByIndex.Sort((A, B) => B - A)`) is now active.

**Update 2026-08-02 — the "describe, don't create" pattern works, and the rejection looks right.** Station production in the RTS build is exactly the case this entry predicted ("a gather system consuming a node and spawning a cargo pickup"): a station is `Position+Faction+Health+Timer+Weapon+Selectable+Station+Drawable` and the ship it builds is nothing like that shape, so forwarding to the chunk's own archetype would indeed have been wrong. `ProductionSystem` instead appends a plain `SpawnRequest` record (`Game/SpawnRequest.cs`) — ship type, faction, location — and `Sandbox.OnUpdate` drains the list through `GameWorld.AddEntity` after `SystemScheduler.Update` has returned. Costs one small allocation-free list and a few lines in the game loop, and it lands outside the systems loop, which keeps the synchronous-new-archetype branch of `AddEntity` safe (see the accessibility note below).

**Sharper reason the current boundary is load-bearing, found while writing this:** adding an entity can *reallocate* component storage. `Archetype.GrowEntityCapacity` calls `ComponentColumn<T>.Grow`, which is `Array.Resize` — a **new array**, leaving the old one orphaned. `ArchetypeChunk.GetSpan<T>()` hands out a `Span<T>` over whatever array `Values` pointed at when it was called. So if an addition could ever be flushed mid-frame while a system held a span, that system would silently keep reading and writing the *old, discarded* array — every write lost, with no error anywhere. Today this is unreachable: growth only happens in `ProcessDeferredUpdates` (after every system has returned) or in `GameWorld.AddEntity` from outside the systems loop, and spans never outlive a system's `Update` call. Worth stating explicitly because it means "adds are deferred" isn't only about archetype-shape correctness — it's also what keeps every outstanding `Span<T>` valid, and any future design that flushes additions earlier has to answer this. Worth recording that this only stays painless because **nothing needs the id of what it just built** — if it did, this would collide head-on with the entity-id entry above.

**Update 2026-08-11 — the add half and the remove half now run as a pair, and the asymmetry is visible from game code.** Founding a station consumes the miner that built it, so `MinerConstructionSystem.CompleteStation` does both halves at once: `spawnQueue.Enqueue(...)` for the station and `archetypeChunk.QueueEntityForRemovalByIndex(i)` for the miner. They land in the same gap between frames — removal in `ProcessDeferredUpdates`, addition in `Sandbox.OnUpdate` immediately after — so the net effect is correct and nothing needed working around. Worth recording as a data point rather than a complaint: the two halves of one conceptual operation ("this entity becomes that entity") are written against two different surfaces, one reachable from inside the system and one only from the game loop. Nothing here argues for exposing addition on the chunk — the archetypes genuinely differ, which is exactly the case the rejection below is about — but it does suggest that if a convenience for delete-and-recreate is ever added (see the archetype-migration entry at the bottom of this file), *this* is its shape: not "mutate this entity's components", but "queue a removal and an addition that resolve together".

**Still open — addition:** deliberately *not* exposed on `ArchetypeChunk`/`IArchetype`. The rejected shape would have forwarded blindly to the chunk's own archetype regardless of the new entity's actual composition — fine for "spawn another one just like me," broken (wrong archetype, missing/garbage columns, or a `KeyNotFoundException`) the moment a system wants to spawn something differently shaped, e.g. a gather system consuming a node and spawning a cargo pickup. Addition stays `GameWorld`-only (mask-based lookup-or-create) and unreachable from inside a system for now — punted rather than shipped unsafe.

**Sanity-check findings on `Archetype` accessibility, still open** (requested separately, logged here since it's the same surface):

- `RemoveEntityWithId`/`RemoveEntityAtIndex` are `internal`, not `private` — the same immediate, unqueued structural mutation that `AddEntity` just got locked down to prevent (it's now `private`) is still reachable by any other code in the `MonoGameLibrary` assembly. `RemoveEntityWithId` isn't called from anywhere today (dead). Recommend tightening both to `private` for consistency with `AddEntity`.
- `GrowEntityCapacity()` is `protected` on a class with no subclasses — vestigial, not a safety issue, just worth `private` in a cleanup pass.
- `WriteComponentById<T>`/`WriteComponentByIndex<T>` (both `internal`) are unqueued by design and that's fine — they only overwrite an existing slot's value, never touch `count`/`DenseIndexToEntityId`/`EntityIdToDenseIndex`, so there's no structural state to corrupt regardless of call timing. This is the path `UserInterfaceManager` already uses for WASD input via `ComponentContainerAttached<T>.WriteComponentById` — legitimate, not a hole.
- `GameWorld.AddEntity`'s two branches have different immediacy: a brand-new archetype composition is constructed and added synchronously, an existing one is deferred via the queue. **Discussed and accepted as safe today** — a freshly created archetype can't have any in-flight `ArchetypeChunk` referencing it, and both current call sites (`LoadContent`, `UserInterfaceManager`'s right-click spawn) run outside `SystemScheduler.Update`'s systems loop, so nothing is enumerating `Archetypes` at the moment it mutates. **Caveat:** this holds only as long as systems can't reach `GameWorld`. If that boundary ever changes, the two branches would start differing in same-frame visibility too (new-composition spawns become visible to later systems in the same frame; existing-composition spawns don't become visible until next frame) — worth a second look at that point, not now.

</details>

## EntityView — entity lifecycle handle
**Status:** Open — design discussed, not yet built
**Priority:** Medium

<details>
<summary>Details</summary>

**What:** a proposed lightweight per-entity handle utility, in response to "what's the path to interact with a specific entity" now that `GameWorld` access, queueing, and removal are split across a few different surfaces (`GameWorld`, `IArchetype`, `ArchetypeChunk`).

**Intended shape and constraints:**

- Carries only: the entity id, a `GameWorld` reference, and possibly an `IArchetype` handle. **Explicitly does not carry component data or values.**
- Purpose is lifecycle interaction (remove, requeue, existence checks) — not a data-access convenience.
- Deliberately designed to be awkward to build an OOP-style architecture on top of — actively resisting becoming a `GameObject`-style handle that invites storing long-lived references and treating entities as objects, which would erode the archetype/SoA model this engine is built around.
- Stale-id handling is an acknowledged open question, raised in review and agreed as valid: an `EntityView` can outlive the entity it names (removed elsewhere, handle held on). Not yet decided whether `Get`/lifecycle calls on a dead handle throw, return a bool/nullable, or something else — needs a deliberate answer before this ships, not an accidental one.
- Because ids don't map to a stable dense index across frames (swap-remove), any future data-returning method on a handle-style object would necessarily return copies, not `ref`s — different shape than `ArchetypeChunk.Get<T>(index)`/`GetSpan<T>()`, which is part of why data access is being kept off `EntityView` entirely rather than added later.
- Should stay aware that `GameWorld` access is currently a global static (`Core.Instance.World`, already the existing pattern via `UserInterfaceManager`'s right-click spawn) as an intentional MVP placeholder, not a permanent design — the expected evolution is toward "the currently selected/user-active `GameWorld`," with other worlds tracked separately through a process not yet designed. `EntityView` holding a `GameWorld` reference directly (rather than resolving one implicitly) is likely the right call precisely because it doesn't bake in a single-world assumption any harder than necessary.

**Second, distinct motivation surfaced later (2026-07-21):** the original design above is about lifecycle *interaction* (remove/requeue/existence). A separate but compatible use case showed up discussing `GameWorld.TryGetComponent<T>`/`SetComponent<T>` (the public single-entity component API that replaced the internal-type leak from `GetComponentsForEntity`/`ComponentContainerAttached<T>`): those calls re-resolve an entity's archetype/dense-index independently on every call, so a caller holding an id across two calls (e.g. read-then-later-write) has no protection if the entity was structurally removed in between — today this can't actually happen mid-frame (`SystemScheduler` is synchronous/single-threaded and structural changes are deferred to `ProcessDeferredUpdates`), but it's an unenforced invariant, not a guaranteed one, and would become a real hazard the moment anything defers between an entity's read and its write (an `await`, a future parallel scheduler, etc). A generation-stamped id (id + version bumped on removal, compared at access time to fail loud instead of silently writing to a resurrected/reused id) would cover this too, and fits naturally on the same handle rather than being a second bolt-on mechanism. Doesn't change the shape or constraints above — still id + `GameWorld` ref, still no component data, still lifecycle-only — just widens why a stale handle needs a defined answer, and makes the stale-id question above less theoretical.

**Related open question, not decided:** whether to remove single-entity/random-access reads from the engine entirely — specifically `ArchetypeChunk.Get<T>(index)` — to push the architecture harder toward "systems + iteration" as the only access pattern, with `EntityView` handling lifecycle-only concerns instead. Acknowledged tension: UI selection/interaction (the WASD-selected-entity flow in `UserInterfaceManager`, `UserInterfaceManager.cs:57-110`) currently depends on exactly this kind of single-entity random access to read/write the selected entity's `Position`/`Motion`. Unclear yet how restrictive a pure iteration-only model would be for cases like this. Left open.

</details>

## No shared Motion→Position integration system
**Status:** Open — discussed
**Priority:** Low

<details>
<summary>Details</summary>

**What:** `MonoGameLibrary` has no engine-level system that integrates `Motion` (velocity/acceleration) into `Position` each frame — `Renderer` and `TimerSystem` are provided and auto-registered by `Core.Initialize`, but the accel→velocity→position step is not, even though nothing about that integration is game-specific in principle.

**Why it came up:** `Proto4X.Sandbox` needed a `MovementSystem` to make WASD input (which only ever sets `Motion.Acceleration`, via `UserInterfaceManager`) actually move anything. `Proto4X.Systems.MovementSystem` already does this, but `Proto4X.Sandbox` deliberately doesn't reference the `Proto4X` project (it's Jason's separately hand-written game, not a library), so a second copy was written from scratch (`Proto4X.Sandbox/Systems/MovementSystem.cs`) rather than sharing it.

**Tried instead:** wrote the sandbox's own copy, but stripped down — no max-speed/max-angular-velocity clamps and no rotation-wrapping, both of which `Proto4X.Systems.MovementSystem` has. So the two copies aren't just duplicated, they've already silently diverged in behavior.

**Possible approaches:** promote a configurable version to `MonoGameLibrary` alongside `Renderer`/`TimerSystem`. Discussed with Jason: prefer a constructor-injected tuning struct (friction, max speed, max angular velocity, wrap-rotation-or-not) over virtual override hooks — a hot per-entity loop is exactly where virtual dispatch cost isn't wanted, given the engine's stated performance priority. This would only cover "same formula, different numbers" variance; a game wanting genuinely different integration math (grid snapping, no inertia, verlet) would still write its own system, which is fine. Explicitly raised as a possible enhancement, not discussed as urgent — not an MVP blocker, not needed for the current sandbox loop.

</details>

## No text rendering
**Status:** Open — deliberately deferred
**Priority:** Low

<details>
<summary>Details</summary>

**What:** no `SpriteFont` loading or `SpriteBatch.DrawString` usage anywhere in `MonoGameLibrary` or either game project.

**Why it came up:** the MVP loop ends in a stockpile count that needs to be shown somewhere — there's currently no way to render any text at all, HUD or otherwise.

**Tried instead:** sidestepped for the MVP by writing the stockpile count to `Window.Title` each frame (`Proto4X.Sandbox/Sandbox.cs`) instead of drawing it in-world. Fine for a single always-visible counter, not a real HUD solution — doesn't generalize to positioned/multi-value/styled text, and will need solving properly as soon as more than one value needs showing at once.

**Update 2026-08-02 — the workaround is now at its ceiling.** The RTS build has a real HUD's worth of state, and all of it is crammed into one title-bar string (`Sandbox.BuildStatusLine`): minerals, own miner/fighter counts, enemy counts, the build menu with its hotkeys and prices, and the victory/defeat message. It is legible, but it is one line of unstyled text in the window chrome, which means:

- **No per-entity text at all** — no unit labels, no build-progress countdown over the station, no floating damage numbers. Anything attached to a position is simply unavailable.
- **The build menu is hotkeys-only** (`[1] Miner 50  [2] Fighter 75` in the title bar) because a clickable button needs a drawn label. Fine for an RTS, which has hotkeys anyway; not fine for the next thing that wants a menu.
- **Nothing can be emphasised**, so "you can't afford this" and "you can" look identical.

Non-text overlays turned out to be easy to solve game-side: `Rendering/Primitives.cs` stretches a 1x1 white texture into lines, circles and bars, which is enough for selection rings, health bars, weapon beams and the drag rectangle. Text is the only thing that genuinely can't be built out of that.

**Possible approaches:** likely just a `SpriteFont` content item plus a thin `IDrawSystem` (or a thing `UserInterfaceManager` can do directly) that draws a string at a screen-space position, unaffected by the world camera transform used for the rest of `SystemScheduler.Draw`. Note this needs the screen-space draw pass below to land first, or it inherits the same camera-transform problem.

**Downgraded 2026-08-05 — this is now a design constraint, not a gap.** Jason's call: build without text deliberately for a while, and express state through icons, radial progress and other visual feedback instead. The reasoning is that a game which is legible without text is a better game *after* text is added, because text stops being the crutch that explains mechanics the visuals failed to. Text will matter eventually; it is no longer blocking anything, so this drops to Low.

**What that changed in the sandbox, all shipped 2026-08-05:**

- `BuildProgressRenderer` (world) — a radial ring around a station shows build progress, a shrunken sprite of the ship itself sits above it, and one pip per queued item sits below. The ship silhouette does the job the word "Miner" would: a player who has watched a freighter mine already knows what that shape means.
- `BuildMenuRenderer` (screen) — one slot per buildable ship, each with an affordability ring that fills as minerals accumulate and closes exactly when the ship becomes affordable. "A complete circle means yes" replaces a price tag, and unlike a number it answers "how much longer" without arithmetic. Hotkeys are shown as one pip for `1`, two pips for `2`.
- `MinimapRenderer` (screen) — position and faction, no labels needed.

Notably, **none of these would have been better with text**, which is a real point in the constraint's favour. The two places it genuinely bites are both about *quantity*: the exact mineral count, and unit counts. The affordability ring converts the first into "can I / how close", which turns out to be the question players actually ask.

**Still text-shaped, still unsolved:** the `Window.Title` line remains the only place showing raw numbers, and it now functions as a debug readout rather than the HUD. Victory and defeat are still title-bar strings — the one remaining piece of genuine UI that has no visual form yet, and the obvious next thing to design without words.

**Design note for whenever text does land:** the hard question isn't the screen-space HUD, it's world-space text attached to entities, because `string` is a managed reference and a dense component column of them undercuts the blittable/SoA premise. Options, roughly increasing in restrictiveness: an int→string table (the trick `SpriteLibrary` already uses for textures), fixed-size inline char buffers via `[InlineArray]`, or numeric-only display components. Worth noting the no-text discipline sidesteps this decision entirely for now, which is a second, unplanned benefit — the engine doesn't have to answer it under pressure.

</details>

## Timer leaves elapsed one-shot timers counting down forever
**Status:** Open — minor
**Priority:** Low

<details>
<summary>Details</summary>

**What:** three loose ends left over after `Timer` was reworked into a countdown (`HasElapsed` derived from `RemainingTicks`, plus `Restart`/`Stop`). The rework itself is done and working; these are the residuals.

- **Elapsed one-shots keep being decremented.** `TimerSystem` doesn't skip a non-repeating timer that has already run out, so `RemainingTicks` runs unboundedly negative. No practical overflow risk (~29,000 years at 60fps), but it's pointless work every frame, and `RemainingTicks = -4000000000` doesn't read as "stopped". An early `if (timer.HasElapsed && !timer.ShouldRepeat) continue;` handles it; clamping to `0` on the crossing would also give "stopped" a single canonical representation shared with `Stop()`.
- **"Never started" and "already finished" are the same state.** There's no `IsRunning`, so an untouched `new Timer(sixSeconds, false)` is indistinguishable from one that has run out. Fine as-is — the consumer has to own completion state anyway — but it means `Timer` alone can never answer "did something just finish".
- **`Stop()` and natural completion are indistinguishable**, both being `RemainingTicks <= 0`. No impact while nothing cancels a build; that's the seam cancel-vs-finish will show up at.

**Worth keeping from the rework:** dropping the edge-triggered `HasJustElapsed` flag removed an *ordering* constraint. With an edge, a consumer had to run after `TimerSystem` or miss the single frame the flag was up. With a level, running earlier just means seeing the countdown one frame late. Ordering became a latency choice rather than a correctness requirement — relevant to the `RunAfter` work, as one fewer edge the scheduler has to be trusted to get right.

</details>
## Possibly: mutating an existing live entity's component set
**Status:** Resolved — decided against
**Priority:** Low

<details>
<summary>Details</summary>

**What:** an `Archetype`'s component-column set is fixed at construction time. There's no path to add or remove a component on an entity that already exists (which would mean moving it between archetypes).

**Why it came up:** a gather loop where an idle ship "becomes" a cargo-carrying ship reads naturally as a component being added/removed.

**Decision:** enforced as delete-and-recreate, not in-place migration. No archetype-migration mechanism is planned. A convenience method wrapping delete+recreate may be worth adding later, depending on how many call sites end up needing it and what access routes are available at that point — not committed now.

</details>
