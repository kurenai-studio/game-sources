# Progression and economy (TODO)

Deferred (discussion of 2026-10-28). Nothing is implemented — these are notes inspired by World of Tanks and a plan for how to do it in our game.

## How it works in World of Tanks

### Currencies

| Currency                          | How it is earned                                  | What it is spent on                                                              |
| --------------------------------- | ------------------------------------------------- | -------------------------------------------------------------------------------- |
| Battle XP (on a specific vehicle) | per battle: damage, spotting, assistance, victory | researching modules and the next tanks in the tree                               |
| Free XP (~5% of battle XP)        | automatically                                     | researching anything in any tree                                                 |
| Credits (silver)                  | per battle                                        | buying tanks and modules, repairs, shells, consumables                           |
| Gold                              | real money                                        | premium account, premium tanks, converting XP to free XP, slots, crew retraining |

### Progression

- Research trees by tiers I–X. XP on a tank unlocks its modules (gun, turret, engine, suspension, radio), then the next tank in the tree.
- Stock vs top: a freshly bought tank drives with weak modules — worse gun, speed, view range. The main "time tax".
- The crew levels up together with the tank: 100% in the primary specialty, then skills (repair, camouflage, sixth sense).
- Tier economy: the higher the tier, the more expensive repairs and shells are; at VIII–X without premium, battles are often credit-negative, so players farm on mid tiers or premiums.
- Repairs and ammunition are automatic by default: after the battle, repairs (proportional to lost hit points) and the restocking of spent shells and consumables are deducted from the income.

### Premium

- Premium account: +50% XP and credits — pure acceleration.
- Premium tanks: bought for gold, top configuration right away, more credits, crew training for the tree; many have preferential matchmaking (±1 instead of ±2).
- "Gold ammo" (high-penetration shells) was at first gold-only; after "pay-to-win" criticism it became available for credits too.

### Why this (mostly) does not break the balance

1. Money buys time, not power: everything that affects the battle is available for credits.
2. A premium tank is not stronger than a fully researched counterpart, usually slightly weaker; you pay for income and convenience.
3. Tier-based matchmaker (3/5/7 templates, ±2 tiers).
4. Stock weakness lasts a couple dozen battles.

It does not always work out: "overpowered" premiums (Progetto, Defender, Chieftain and the like), gold-ammo spam devalues armor, preferential matchmaking gives premiums an advantage.

## How to do it in our game

Key difference: battles are against bots, and the matchmaker already picks bots by `rating` (`src/config/match.ts`: `ratingSpread`, `ratingTolerance`). Progression does not break the balance the way it does in PvP.

1. **Tiers from `rating`** (currently 2…7 → 5–6 tiers). USSR and German trees: T-60 → T-70 → T-34-76 → T-34-85 → IS-2, TD and artillery trees, Germans likewise.
2. **Currencies: XP and credits.** Battle XP per vehicle, free XP ~5%. Awarded from `src/game/battleReport.ts`: damage, spotting, assist, blocked damage, victory, medals.
3. **Stock/top modules** (gun, engine, suspension). The matchmaker uses the actual rating with modules, not the nominal one — a stock tank gets slightly weaker bots.
4. **Economy through what already exists:** ammunition is already finite → shells spent and post-battle repairs cost credits.
   **Decided:** a single currency, no gold and no "gold ammo" (premium shells) at all. XP stays, but it is not a currency, it is research points.
5. **Crew:** XP → skills (repair, camouflage, reloading). Careful: do not take away from a beginner what they have now (e.g. the sixth-sense lamp).
6. **"Premium" without paying:** premium tanks for achievements (a streak of medals, an Ace Tanker badge on a tank). The German KV-1 (r) is a ready candidate: more credits, not stronger than its counterpart, no progression. A premium account is not needed.

## Vehicle progression (ideas, 2026-10-28)

Not moving on to the next tank, but developing the existing one. Technically — adjustments to the `TankDef` fields (`gun`, `speed`, `accel`, `hullTurn`, `turretTurn`, `viewRange`, `camo`).

### 1. Modules: stock → top (for vehicle XP)

Historical variants:

- **Gun:** T-34-76 L-11 → F-34, KV-1 L-11 → ZiS-5, Pz.IV H KwK 40 L/43 → L/48, StuG III L/24 → L/48.
- **Engine:** speed and acceleration.
- **Suspension:** hull traverse, less dispersion on the move.
- **Turret:** only where historical.

### 2. Crew (XP accumulates by itself)

- Training 75% → 100%: reloading, aiming, view range.
- Skills, at most 2–3: module repair, camouflage, firefighting, smooth ride, "brothers in arms" (+small bonus to everything).

### 3. Equipment (3 slots, bought for supplies, removable)

- Gun rammer: −10% reload time.
- Stabilizer: smaller aiming penalty on the move (`Tank.bloom`).
- Optics: +10% `viewRange`.
- Camouflage net: +`camo` while stationary.
- Ventilation: +small bonus to everything.
- Wet ammo rack: lower chance of ammo-rack detonation.
- Fire extinguishers: lower chance of fire.

7–8 options for 3 slots — the point is the choice.

### 4. Prestige without power

- Camouflages and inscriptions — no camouflage bonus.
- Marks of excellence on the barrel (average damage), the «Мастер» (Ace Tanker) badge (medals).

### Balance rules

1. **Progression removes a penalty rather than giving power above the norm.** The current tank stats = top; stock is weaker. The current balance stays untouched.
2. **Armor and hit points are not upgraded** (except a historical top turret).
3. **Small percentages and a cap:** a 5–10% bonus each, no more than ~15–20% in total to a single parameter.
4. **Choice instead of a pure plus:** 3 slots for 8 options; a field modification with a trade-off is possible ("+speed, −armor", "+reload, −aiming").
5. **The matchmaker sees progression:** effective rating = base − stock penalty + bonus for equipment and crew. Works through the existing `rating` / `ratingTolerance`.
6. **Bots are progressed the same way:** rookies — stock and a 75% crew, veterans — top and equipment. Can be tied to bot difficulty.
7. **Progression is visible in battle** (a hint above the tank or in the team list), so that battles in a stock tank do not feel unfair.

## Repairs and ammunition (ideas, 2026-10-28)

As in WoT:

- **Auto-resupply by default.** After the battle, spent shells and consumables are deducted from the income. Unfired shells stay in the tank.
- **Repairs are proportional to lost hit points.** Came back intact — free; destroyed — full price. An unrepaired tank does not go into battle; no credits — take another one.
- **No "gold ammo".** Shells are priced by type (HE, AP); there are no premium shells. Right now there is deliberately no ammo-loadout screen before battle; adding one is a separate decision.
- **Battle report:** income − repairs − shells − consumables = net profit (can be negative). Extend `battleReport.ts`.
- **Income by tier:** low tiers are almost always profitable, at the top tiers a bad battle is a loss; premium tanks with increased income — for farming.

### Why this is needed

The economy gives a reason to drive different tanks, not just the strongest one:

- the top tiers are expensive to maintain, their credits are earned on mid-tier vehicles and premiums;
- each vehicle has its own XP and modules: progressing a tree requires playing that very vehicle;
- a tank under repair with no credits is a reason to take another one;
- premium tanks earned for achievements become "credit farmers" rather than mere trophies.

Almost everything already exists: finite ammunition, modules, damage, consumables. All that is needed is to count credits after the battle.

### If everything is broken and there is no money

In WoT there is no dead end: tier I tanks are repaired for free or for pennies, you can always sell a tank or a module, and daily missions and the "first victory of the day" (×2 XP) give a boost.

For us — a guarantee that the player never gets stuck:

- **Starter tanks** (rating 2: T-60, Pz.II F and the like) are repaired and resupplied for free — you can always earn on them.
- **Insurance:** if the money is less than the repair cost of the player's cheapest tank, the repair after the first battle of the day is free (or repair on credit).
- **Daily:** first victory of the day ×2 XP and credits; 2–3 daily missions ("deal 1000 damage in a TD", "spot 5 enemies") — they also nudge the player to play different classes.
- **Selling** tanks and modules for part of the price.
- A softer option (as in mobile games): a broken tank repairs itself for free after N minutes or N battles on other vehicles.

### Currency name

**Decided (for now): «Снабжение» (Supplies).** Other options were: «Кредиты» (Credits), «Серебро» (Silver), «Боны» (Bonds), «Трофеи» (Trophies), «Марки» (Marks). In the text above, "credits" means supplies.

## Storage

Decided 2026-10-28: everything local first, then move it to the server; offline play with progression remains.

- **Rules separate from storage.** Awarding XP and supplies, prices, modules, effective rating — pure functions in shared code (`profile/rules`), with no DOM and no `localStorage`. The server imports the same functions later.
- **Storage behind an interface** `ProfileStore` (`load`, `applyBattle`, `buy`, `repair`…): now `LocalProfileStore` (`localStorage`), later `RemoteProfileStore` (HTTP/WebSocket to the server).
- **Profile schema version** with migrations from day one.
- **The online server is the source of truth:** it computes the rewards itself from the outcome of the battle it simulated; the client only displays them. The offline client computes them on its own (tampering does not matter against bots).
- **Two profiles:** offline and online kept separate, like single-player and multiplayer. Transferring offline progress to online — do not do it, or do it once with a cap, otherwise a tampered `localStorage` gets into ranked play.

## Open questions

- Build offline progression now or wait for the server?
- Keep the "free mode" with all tanks unlocked, or does a beginner start with the T-60 / Pz.II?
- Formulas for XP and credits, prices of tanks, modules, repairs and shells.
