# PropHunt RPG — Game Design

Classic prop hunt (hiders disguise as world objects, hunters find them) with a
**persistent RuneScape-style skill layer**. Skills never reset, but they are
designed as *side-grades and variety*, not raw power, so a level-1 player can
still beat a level-50 player.

## 1. The round cycle

```
 LOBBY ──► PREP (30s) ──► HUNT (180s) ──► RESULTS (8s) ──┐
             ▲                                           │
             └───────── teams rotate, next round ◄───────┘
```

| Phase   | Hiders                                                   | Hunters                                         |
|---------|----------------------------------------------------------|-------------------------------------------------|
| Lobby   | Pick a **Trade** (Woodcutting / Mining / Fishing)        | Pick a Trade                                    |
| Prep    | Run around, disguise (E) as any prop they have unlocked  | Frozen & blindfolded                            |
| Hunt    | Stay hidden, **forage** for XP, use trade ability        | Hunt with their trade **tool**, gather, ability |
| Results | XP summary, level-ups                                    | XP summary, level-ups                           |

Hunters win by eliminating every hider before the timer ends. Hiders win if
any of them survive, or if every hunter is eliminated by self-damage.

## 2. Skills

| Skill        | Prop family it unlocks                         | Tool (hunter) | Earn XP by                                         |
|--------------|------------------------------------------------|---------------|----------------------------------------------------|
| Woodcutting  | logs, stumps, bushes, pines, oaks, birches     | Axe           | chopping real trees, foraging as wood props        |
| Mining       | rocks, ore veins, crystal clusters, boulders   | Pickaxe       | mining real ore, foraging as stone props           |
| Fishing      | crates, barrels, lobster pots, buoys, boats    | Harpoon       | fishing real fishing spots, foraging as dock props |
| Agility      | — (movement)                                   | —             | moving while disguised, surviving, escaping        |

Levels run from 1 to 50. XP needed for level L is `40 · (L−1)²`
(L5 = 640, L10 = 3,240, L25 = 23,040, L50 = 96,040). A normal round gives about
150–300 XP, so early levels come quickly and late levels are a long-term goal.

## 3. How the skills plug into prop hunt

### 3.1 Unlocks = your disguise wardrobe (the main hook)
Every disguisable prop has a skill requirement (see `src/world/PropCatalog.js`).
A new player can only become crates, logs and small rocks. A Woodcutting-30
player can become a birch tree in the middle of a forest. **All** props appear
on the map whatever anyone's level, so high-level players blend into more
places, but a low-level player always has enough options to hide.

### 3.2 Resource nodes = risk vs reward for both teams
Some props are real **resource nodes** (oak/pine trees, copper ore, crystal,
fishing spots).

* **Hunters**: hitting a wrong prop normally costs HP (classic prop-hunt
  penalty). Hitting a node *with the matching tool* costs nothing and gives XP.
  So a woodcutter hunter can chop through the forest freely, which makes
  trees a dangerous disguise when a woodcutter is hunting. Nodes deplete after
  a few hits and respawn later.
* **Hiders**: while disguised as a prop of the same family and standing next
  to a matching node, holding **F** forages XP, but every tick puts out a
  visible puff of particles that hunters can spot.

### 3.3 Trades = your active ability
Before each round you pick a trade. It decides your hunter tool and your
ability on either team:

| Trade       | Hunter ability                                                  | Hider ability                                          |
|-------------|-----------------------------------------------------------------|--------------------------------------------------------|
| Woodcutting | **Timber Sense**: outline all wood-disguised hiders within 18 m  | **Take Root**: −50% damage for 6 s, can't move         |
| Mining      | **Seismic Pulse**: outline every hider within 9 m                | **Decoy**: drop a copy of your current prop (max 2)    |
| Fishing     | **Harpoon Line**: 40 m shot; reveals + damages the hider it hits | **Slippery**: +80% move speed for 3 s                   |

### 3.4 Level perks (deliberately small and capped)

Perks scale linearly from nothing at level 1 to the cap at level 50.


| Perk                                     | ≈ Per level | At L50 |
|------------------------------------------|-----------|------------|
| Hunter tool damage (trade skill)         | +0.6 %    | +30 %      |
| Bonus vs hiders disguised in your family | flat (any level) | +25 % |
| Hider HP (skill of the disguise's family)| +0.8 %    | +40 %      |
| Ability cooldown (trade skill)           | −0.8 %    | −40 %      |
| Move speed (Agility)                     | +0.3 %    | +15 %      |

All formulas live in `src/game/rules.js` so balance tuning happens in one file.

## 4. XP sources (host-authoritative)

| Event                                   | XP              | Skill                    |
|-----------------------------------------|-----------------|--------------------------|
| Hunter gathers a node                   | 12–30 per hit   | node's skill             |
| Hider forage tick                       | 8               | node's skill             |
| Hunter eliminates a hider               | 60              | hunter's trade           |
| Hider survives the round                | 120             | hider's trade            |
| Hider survives (Agility)                | 40 + distance   | Agility                  |
| Hider eliminated (participation)        | 25              | hider's trade            |
| Win bonus                               | 30              | trade                    |

## 5. Networking model

* Peer-to-peer star topology over WebRTC (PeerJS). The lobby host is
  authoritative for rounds, damage, abilities and XP awards.
* Clients own their movement and send positions at 20 Hz. The host checks
  speed and reach (for hits).
* The host sends a snapshot at 15 Hz plus reliable events.
* Single player is the same host code with an in-memory link and bots.

### Trust caveat
Progression is saved in each player's browser (`localStorage`). In a P2P game
nothing stops a determined player from editing their own save. That's why
perks are capped and small. If the game ever needs competitive integrity,
move `CharacterStore` behind a small signed-profile server; the host already
treats incoming levels as untrusted input (it clamps them).

## 6. Roadmap ideas
* Cooking/Crafting: spend gathered resources on cosmetics (prop skins).
* Prestige titles at L50 shown in the lobby.
* Seasonal maps that bring in new prop families (e.g. Farming).
