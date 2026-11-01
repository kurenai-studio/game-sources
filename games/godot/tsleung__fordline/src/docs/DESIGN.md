# Fordline — design

A real-time tactics game about holding river crossings with regiments of
little soldiers, seen from above on a flat field map. One campaign is five
battles and takes about twenty minutes. Built in Godot 4.5, so it runs in a
browser (desktop or phone) and exports to Android and iOS from the same code.

Every decision here is provisional: it is the studio's call, made to be
played and argued with.

## The thirty-second version

You command a small army: swords, pikes, archers, cavalry, cannons and your
general (in the Pike and Shot scenarios, muskets take the place of swords
and bows). Each battle is on a new map with a river, woods and hills, and
three flags at the crossings. Holding more flags than the enemy drains their
**resolve**; routing their regiments drains it faster. When one side's
resolve hits zero, its whole army breaks and runs. After a win you keep your
survivors, pick one of three rewards, and march to the next battle. Lose
once and the run is over; your score goes on the board.

## Pillars

1. **The look is the toy.** Hundreds of soldiers in blocks, banners over
   each block, lines grinding together at a ford. Soldiers die one by one,
   the front rank refills from the back, and a broken regiment scatters.
2. **Read the board in a glance.** Each banner shows the regiment's type,
   strength (the ring) and morale (the bar beneath it; the banner blinks
   when wavering). A line marks each block's front, so its flanks show.
   The flags and the two resolve bars say who is winning.
3. **See it coming.** A red arrow shows each enemy regiment closing on one
   of yours, and a red ring pulses on the banner it is coming for; enemy
   horse on the move trails a faint arrow. Flank and rear hits are called
   out. The fun is reading the move and answering it in time.
4. **Every battle is short.** Resolve drains a little faster after four
   minutes. A battle is two to four minutes, a run is about twenty.
5. **One more run.** Losses carry over, regiments earn stars, rewards stack
   into a build, and a run ends on the first defeat with a score.
6. **History serves the fun.** A rule taken from history or physics earns
   its place when it shows on the map and changes a decision. Hills do:
   you see them and choose where to stand. Squares do: you see horse
   coming and the infantry answers. Currents, tides and wind at sea do
   not: they are invisible and would drift a ship off the place you sent
   it, fighting the one-tap order instead of adding a choice.

## Rules

- **Counters.** Pikes stop cavalry. Swords beat pikes. Cavalry rides down
  archers, muskets and cannons. Archers and cannons wear everyone down from
  range; muskets break blocks of pikes.
- **Muskets.** Range 170 (archers 230), one volley every 7.5 s that lands
  at once. Shot goes through 70% of armour, but woods still halve it, and a
  volley costs its target 6 morale on top of the men it kills (arrows: 1.5).
  Weak in melee and soft to horse (1.8×), so they stand behind pikes. A
  musket on the move doesn't fire, so the AI's muskets only step back from
  foot within 60 (archers: 110).
- **Flanks.** A regiment fights the enemy in front of it. Hit it from the
  side and it takes 1.5× damage and 1.7× the morale loss; from behind,
  2.2× and 2.5×. So pin with infantry, then hit with cavalry.
- **Morale.** Casualties, flanks, cannon fire and nearby routs drain
  morale. At zero the regiment routs: it runs for its own edge and can't be
  ordered. If it gets clear of the enemy it rallies, and its side wins back
  a little resolve. Your general's aura slows the bleed; the Rally horn
  brings broken regiments back.
- **Terrain.** The river can only be crossed at fords (slow) and bridges.
  Woods slow movement and halve arrow damage. Hills extend range and
  harden defence.
- **Fatigue.** Melee wears a regiment out in about a minute; marching
  tires it a little; standing clear of the fight restores it in about
  thirty seconds. A spent regiment strikes at half strength, loses nerve
  half as fast again, moves at three-quarters pace and its horse cannot
  charge. So the side that wins the first clash is tired when the second
  comes: a fresh reserve sent in where the line bends turns fights.
- **Castles.** A fortress map is a castle backing onto one edge of the
  field: a moat with one bridge, a curtain wall with a gatehouse, and an
  inner keep with its own gate in its side wall and a great tower. Nobody
  walks through stone, and no blades cross a wall; arrows, shot and balls
  fly over. A gate is open to its own garrison and shut to the besieger
  until battered down: the outer gate takes 300, the keep's 220; each
  cannonball landing on it 5, each barrage shell 14, and the regiment of
  foot pressed closest against it from outside 0.04 per man per second
  (one ram at a time; 48 men take about two minutes alone). Select guns
  and tap an enemy gate to batter it. The wall-walk, 40 deep inside each
  wall, counts as a hilltop (range +25%, defence +0.12) and its
  battlements stop 70% of arrows and shot. The side holding a castle
  fights as its garrison: its foot form across the gateway and fight only
  what gets inside, its shooters and guns man the wall-walk and answer
  the enemy's shooters first, its horse may sally.
- **Charge.** Cavalry that hits at speed deals heavy damage and a morale
  shock for two seconds, except against pikes from the front.

## Controls (touch and mouse alike)

- Tap a regiment to select it; tap again to deselect it. Double-tap to
  select every regiment of that type. **All** selects the whole army.
- With nothing selected, drag on the field to box-select.
- With a selection: tap the field to move there; tap an enemy to attack it.
- A drag is an arrow: the selection stands where it starts and faces the
  way it points, side by side across it. Drag from a selected banner to
  turn the selection where it stands. Any direction works, so a line can
  face a flank or its own rear.
- Waypoints: a selected route ends in a gold marker. Tap it to pin it (a
  ring with a plus) and the next tap on the field adds a leg from there
  instead of replacing the route; tap it again to unpin. On a computer,
  shift-click the field does the same in one click. Routing a flank force
  around woods or through a chosen ford is what this is for.
- Pause any time; orders can be given while paused. 2× speed for the
  quiet parts.
- **Menu** (top left, or Esc with nothing selected) pauses and offers
  Resume, Restart (quick battles) and leaving: back to the scenarios, back
  to the briefing before the fighting starts, or, once it has started, a
  retreat that ends the campaign (it asks twice).
- Abilities: **Rally** (from the start), **Barrage** and **Forced March**
  (rewards).

## The campaign

| # | Battle | Ground | Enemy |
|---|--------|--------|-------|
| 1 | Millbrook Ford | river, three fords | small, balanced |
| 2 | Ashwood | woods and hills, no river | aggressive, cavalry |
| 3 | Two Bridges | river, two bridges | dug in, archers and a cannon |
| 4 | Saltmarsh Road | river and roads | large, flanking |
| 5 | Marshal's Ridge | ridge at the centre | the Marshal and his guard |

Map details and the exact enemy roster vary per run from a seed.

After a win, every regiment gets back 40% of its missing men, and you pick
one of three rewards: a new regiment, a full muster, an ability, or a
doctrine (longbows, iron shot, steel, warhorses, old banners, drill).

## Quick battle

Scenarios for when there isn't time for a campaign: one battle each, on a
map fixed by design so it can be learned, three to five minutes. A win is
one star; each scenario names two more conditions (a fast win, light
losses, crossings held at the end), and the best is kept on the device.

| Scenario | Ground | Goal | Teaches |
|---|---|---|---|
| Skirmish | a new field each time | break them | two armies made the same; only play differs |
| Hold the Fords | fords, deploy at the river | hold one ford at 3:00 | standing on ground you already own |
| Hammer and Anvil | open woods | break them | pin with foot, ride round with horse |
| Two Narrow Bridges | bridges | hold both bridges at 5:00 | forcing a crossing with guns and a barrage |
| Riders at Dawn | the ridge | break them | pikes against a cavalry army |
| The Storming of Duskwatch | a castle | hold two of its three flags at 6:00 | a siege: guns and a ram on the gate, then the keep |
| The Last Keep | your castle | hold one flag at 5:00 | holding the walls, then the gateway |

Scenarios are grouped by era, oldest first, with a tab for each above the
list (the list remembers the last one). An era is data: a name, the kinds a
Skirmish of that era draws from, and its scenarios. Medieval is the five
above; Pike and Shot fights with pikes, muskets, horse and guns:

| Scenario | Ground | Goal | Teaches |
|---|---|---|---|
| Skirmish | a new field each time | break them | the same, drawn from pike, shot, horse and guns |
| Push of Pike | roads | break them | let the shot thin their blocks before the pikes meet |
| Shot at the Fords | fords, deploy at the river | hold one ford at 3:00 | muskets on ground that makes the enemy wade |
| The Cuirassiers | roads | break them | ride round the pikes into the shot behind them |
| The Great Battery | the ridge | break them | cross open ground under three batteries |
| The Breach at Greyhold | a castle | hold two of its three flags at 6:00 | great guns against walls built for bows |

In a siege the flags don't drain resolve (a castle's three would bleed
the attacker dry before the gate fell); they decide at the deadline.

A range slider is the next step once there are four or more eras.

Measured 2026-10-31, AI players of the luck study, wins (stars):

| Scenario | idle | slow | standard | sharp |
|---|---|---|---|---|
| Skirmish (36 battles each) | 0% | 42% | 28% | 61% (1.2) |
| Push of Pike | 0% | 0% | 17% | 100% (2.0) |
| Shot at the Fords | 0% | 100% | 0% | 100% (2.0) |
| The Cuirassiers | 0% | 100% (2.0) | 100% (2.0) | 100% (3.0) |
| The Great Battery | 0% | 0% | 67% | 100% (2.3) |

Sieges, measured the same day:

| Scenario | idle | slow | standard | sharp |
|---|---|---|---|---|
| The Storming of Duskwatch | 0% | 50% | 100% | 83% (1.3) |
| The Last Keep | 67% | 33% | 83% | 100% (3.0) |
| The Breach at Greyhold | 0% | 83% | 50% | 83% (1.7) |

A garrison that does nothing holds the Last Keep two times in three:
standing in the bailey is a defence. Building them, three things were
found and fixed: every regiment at a gate rammed it at once, so it fell in
twenty seconds; battlements that stopped only half lost the archery duel
to two regiments in the open; and garrison archers shooting the nearest
foot rather than the archers shooting them lost it anyway.

Open: in the Pike and Shot Skirmish the slow AI player beats the standard
one (in Medieval it doesn't: 50% and 53%). The first musket design made a
volley more accurate close in; the slow player's muskets walked in further
before firing, so slow won 64% to standard's 31%. Auto-fire always shoots
at the edge of range, so the falloff punished holding ground; it was
removed, which narrowed the gap but did not close it. Separately, pikes in
the line take the enemy general as a target whenever he is within reach
(pikes hit horse 2.5×), in both eras.

Every briefing (and each card in the scenario list) shows the field as it
will be fought, both armies deployed: the battle's own map, drawn small.

A scenario may give the player abilities, start them holding every flag,
let them deploy further forward, and end on the flags at a deadline. They
are data in `scripts/scenarios.gd`.

Measured 2026-10-30 against the AI players of the luck study: every
scenario is won by some ways of playing and lost by others (Hold the Fords
is won by the patient players and lost by the ones that throw the line
forward; Riders at Dawn the other way round), and no AI player averages
three stars. On a fixed map the AI players' results barely vary with the
dice, so an army composition tends to be all or nothing for them; the
stars, not the win rate, carry the difficulty.

## Grand battles

The second way to play. Quick battles and the campaign are arcade: one
screen, a few regiments, three minutes. A grand battle is a historical
day: a field several screens across, twenty blocks a side, armies that
arrive along the roads through the afternoon, and about fifteen minutes
of play. The fun is different: not reflexes at one ford but where to
send the next division when it comes up the road, and when to give
ground.

**The scale.** A block is a brigade, not a regiment; the rules are the
same. The field is 3200 × 2200, about 2.5 × 2.7 quick-battle fields,
drawn by hand from the real ground. The clock shows the hour of the
historical day (an hour is 78 seconds at Gettysburg, 90 at Waterloo), and dusk ends it.

**The pace.** Fights are stretched to fit the day: volleys do 0.4 of
their damage and nerve comes back at 0.4 of its rate, so a brigade
firefight lasts the better part of an hour of the day. A volley's shock is
not stretched, so brigades break and rally long before they are shot to
pieces, as they did.

**Keeping it calm.** More units must not mean more stress:

- The battle opens paused, and orders work while paused, as always.
- Time runs at 1×, 2× or 4×; the marches are long, the fights are not.
- A drag on empty ground with nothing selected pans the map; with two
  fingers it always pans, and pinching zooms. On a computer: the wheel or
  a trackpad pinch zooms where the pointer is, a middle-drag or a
  trackpad scroll pans, the arrow keys move the view, and shift-drag
  still box-selects.
- A minimap in the corner shows the whole field, both armies and the
  view; tap or drag on it to look there.
- Blocks belong to divisions. Double-tap a block to select its division,
  then drag one arrow and the division forms its line across it.
- **Its own command.** With blocks selected, tap a named flag and they
  take it and hold it on their own: the same AI the enemy uses forms them
  square to their approach, fights what comes, and holds the ground once
  there. A gold diamond over the banner marks them; any order of yours
  takes a block back. This is how a corps commander fights: send a
  division to the wood and turn to the next problem.
- A routing brigade is named ("The Iron Brigade is running!") and ringed
  on the minimap, since it may be off screen.
- Arrivals are announced ("Wadsworth's Division comes up the
  Emmitsburg Road"), and a gold ring pulses on the minimap where they
  come on.
- The briefing lists the day's order of march, both sides, by the hour.
- A block given no orders stands, faces what comes and fights it. Fresh
  divisions march up their road to a mustering point and wait for you.

**Resolve.** A rout costs half what it does in a quick battle, since there
are three times the blocks, and the four-minute late drain is off. Flags
don't drain resolve; they decide at dusk, like a siege's.

**History as a test.** The enemy follows its historical orders: each
division has its objectives in order, and takes the next once it holds the
last. A division forms its line square to the way it is going, and once
there, square to the nearest enemy; its batteries unlimber short of the
objective as soon as anything is in reach. Fought computer against computer, a battle should come out roughly
as it did in history; `tests/luck_skill.gd` measures how often it does,
alongside the usual skill ladder. If a historical day plays out as history
with nobody steering, and a good commander can do better, the scenario
works.

### Gettysburg, the first day (1 July 1863)

You are the Union. Buford's two cavalry brigades hold McPherson Ridge west
of town at 8:00 against Heth's division coming down the Chambersburg Pike.
The I Corps comes up the Emmitsburg Road from 10:00, the XI Corps up the
Taneytown Road from 12:30. The Confederates keep coming: Rodes from Oak
Hill to the north at 13:00, Early down the Harrisburg Road at 15:00,
Pender behind Heth. Historically the Union line broke at about 16:30 and
fell back through the town to Cemetery Hill, and held it.

- **Win:** hold Cemetery Hill at dusk (19:30), or break their army.
- **Stars:** also hold Seminary Ridge at dusk; lose no more than 45% of
  your men.
- **Era:** rifles. Rifled muskets reach farther than smoothbores (230
  against 170) and hit more often (accuracy 0.4 against 0.3); cavalry
  hits them 1.3× rather than musketeers' 1.8×, since a rifled brigade can
  form and fire with the bayonet fixed.
- **Veterans:** the Confederate brigades carry one star each, for the
  Army of Northern Virginia's size and confidence that summer.

Measured (`tests/luck_skill.gd --scenario=gettysburg`, four dice per
commander, the enemy at its historical orders):

| | idle | slow | standard | sharp |
|---|---|---|---|---|
| Union wins | 0% | 25% | 25% | 50% |
| Union holds Cemetery Hill at the end | 25% | 25% | 25% | 50% |
| Union holds McPherson Ridge at the end | 0% | 25% | 25% | 25% |

The Confederates took Oak Hill and Barlow's Knoll in every run, and the
town in all but one, as on the day. A defeat usually comes between 15:00 and 17:00, when the
Union army breaks; historically it broke at about 16:30 and fell back to
Cemetery Hill. Holding the hill means doing what Howard did: keeping
von Steinwehr's division there and giving up the western ridges in time.

### Waterloo (18 June 1815)

You are Wellington, on the ridge of Mont-Saint-Jean with Hougoumont, La
Haye Sainte and Papelotte held out in front. Napoleon's corps go in at
their historical hours: Reille at Hougoumont from 11:30, the grand battery
from 12:30, d'Erlon's four divisions at 13:30, Ney's cuirassiers at 16:00
and 17:00, Lobau and the Young Guard against the Prussians at Plancenoit,
and the Middle and Old Guard at 19:30. Bülow's Prussians come out of the
Paris Wood at 16:30, Pirch's at 18:00, Zieten's by Smohain at 19:00; they
are yours to command.

- **Win:** hold Mont-Saint-Jean at dusk (21:00), or break their army.
- **Stars:** also hold La Haye Sainte at dusk; take Plancenoit.
- **Era:** Napoleonic line infantry: smoothbore muskets (range 170) and
  the bayonet, and **squares**. Standing line infantry forms square when
  enemy horse comes within 240 and keeps it until none is within 330. In
  square it has no flank or rear, a charge doesn't land, horse hits it at
  0.35, and only one face fires (half a volley); marching breaks it, and
  horse that reaches a line before it forms catches it in line.
- **Quality:** the French carry two stars (the Guard two more); four of
  Wellington's brigades are raw, a star below the line (the
  Dutch-Belgians, the Nassauers and the Hanoverian militia).
- **Held back:** a corps whose hour has not come keeps to its ground
  unless the enemy comes near; horse held back rides at an enemy within
  500, as a cavalry reserve does.

Measured (four dice per commander):

| | idle | slow | standard | sharp |
|---|---|---|---|---|
| Allied wins | 0% | 100% | 75% | 75% |

The French take Hougoumont in every run, as they never did on the day.
Open: the slow commander does better than the quick ones, because the
AI's defenders counterattack off the ridge into the French columns; a
person holding the crest does not have that habit, so the scenario is
tuned to the quicker AI's result. Each AI-against-AI run first found a
real problem: Allied horse riding down the grand battery unopposed (the
French cavalry reserve now answers), and a French army a third short of
its order of battle.

## Play over time

What the game should feel like at each time horizon, as measures the
studies compute and targets they are judged against. The frame: decisions
should matter and not be monotonous, and their consequences should last
yet be reversible with effort; and killing is not everything.

Every measure is read from a battle's trace (one sample a second) and its
order log, fought through the same loop the game uses. A target is a band
the studies report against, not a check the suite enforces: balance is
judged, then changed deliberately.

| Horizon | Question | Measure | Target |
|---|---|---|---|
| The moment (seconds) | Can you see it coming? | warning: seconds a regiment had been aimed at one of yours before the blow landed | median 4 s or more; under a fifth of blows unannounced |
| The moment | Is there always something to do? | longest quiet stretch after the first clash: no block engaged and nothing fired | under 10 s in a quick battle |
| The engagement (a minute) | Do decisions matter? | decision impact: take one of the player's orders out of the log, fight again, compare | at least a third of orders move the final margin by 5 or more |
| The engagement | Do they last? | persistence: an order's effect on the margin at the end over its effect 20 s after | 1 or more on average: effects grow or hold rather than wash out |
| The battle (minutes) | Does skill win? | the ladder (idle, slow, standard, sharp) in win rate, and skill's share of the outcome | rising up the ladder; skill's share over half |
| The battle | Is it decided early? | lead changes; comebacks: battles won by a side that was behind by 0.15 after the first clash | lead changes 0.5 or more; comebacks 15–35% |
| The battle | Is it short? | battle length | quick battles 2–4 minutes |
| The run (twenty minutes) | Do consequences carry? | how much a costly win (40% of men lost) lowers the next battle's win rate | a real drop, but the next battle is still winnable more often than not |
| The day (a grand battle) | Does history hold, and can you beat it? | how often the AI-against-AI day ends as history did; the ladder | history most of the time with nobody steering; skill still rising |

How far the AI can be trusted as a stand-in for a player is its own
question, measured alongside: see the AI audit below.

**Every older table in this document was measured at the wrong step.**
Until 1 November 2026 the tests and studies stepped the battle at 1/15 s
while the game steps at 1/30 s, and the two are different games: 6 of the
15 campaign battles in the suite change winner between them. The suite,
the studies and the screen now share one loop at the game's step
(`scripts/battle_run.gd`). The older tables stay below as a record of how
the design got here, and are not current.

### Measured, 1 November 2026

Every quick scenario and campaign battle, AI against AI through the game's
own loop, four dice each (`tests/luck_skill.gd`, reported by
`tests/play.py`). Win rates for the player's commander:

| Battle | idle | slow | standard | sharp | minutes | lead changes | orders a minute |
|---|---|---|---|---|---|---|---|
| Millbrook Ford | 0% | 100% | 100% | 100% | 1.0 | 0.0 | 85 |
| Ashwood | 0% | 100% | 100% | 100% | 0.6 | 0.0 | 79 |
| Two Bridges | 0% | 100% | 100% | 100% | 3.2 | 0.0 | 134 |
| Saltmarsh Road | 0% | 0% | 0% | 0% | 1.7 | 1.0 | 100 |
| Marshal's Ridge | 0% | 100% | 100% | 100% | 2.1 | 1.0 | 110 |
| Skirmish | 0% | 50% | 75% | 100% | 2.6 | 0.0 | 28 |
| Hold the Fords | 100% | 100% | 0% | 0% | 1.7 | 1.0 | 37 |
| Hammer and Anvil | 0% | 0% | 0% | 100% | 2.0 | 1.0 | 81 |
| Two Narrow Bridges | 0% | 0% | 0% | 0% | 1.6 | 0.0 | 40 |
| Riders at Dawn | 0% | 100% | 100% | 100% | 1.9 | 0.0 | 44 |
| The Storming of Duskwatch | 0% | 0% | 0% | 100% | 3.5 | 0.0 | 47 |
| The Last Keep | 75% | 100% | 50% | 100% | 3.3 | 0.5 | 29 |
| Skirmish (Pike and Shot) | 0% | 0% | 100% | 100% | 2.4 | 1.0 | 66 |
| Push of Pike | 0% | 0% | 100% | 100% | 1.6 | 0.0 | 93 |
| Shot at the Fords | 0% | 100% | 0% | 100% | 1.2 | 1.0 | 65 |
| The Cuirassiers | 0% | 100% | 100% | 100% | 1.1 | 0.0 | 179 |
| The Great Battery | 0% | 0% | 75% | 100% | 2.3 | 0.2 | 103 |
| The Breach at Greyhold | 0% | 25% | 100% | 50% | 2.0 | 2.0 | 67 |

Minutes, lead changes and orders a minute are for the standard commander.
Against the targets:

- **The outcome is set by the commander and the map, not the dice.** A
  battle and a commander almost always give the same winner on every dice,
  yet one order taken out of Hold the Fords flips the winner a third of the
  time (Push of Pike: never; Millbrook Ford: never, but the margin moves in
  a quarter of cases). The battle is a knife edge more than a dice roll:
  small differences grow (the effect of a dropped order is larger at the
  end than 20 s after), so a player's small slips can matter far more than
  they look.
- **Battles are short and settled early.** Most last 1–2 minutes against a
  target of 2–4, with 0–1 lead changes and few comebacks.
- **The ladder breaks on defence.** Where you start holding the ground
  (Hold the Fords, The Last Keep), doing nothing beats the standard
  commander, which gives the ground up to attack. Elsewhere it rises.
- **The AI commands like no person can.** The standard commander gives
  40–180 orders a minute; a person gives perhaps 10–30. "Standard wins"
  says what an untiring micro-manager can do, not what a player will.
- **You see it coming.** A blow counts as announced when its attacker was
  closing on your side beforehand, by the rule the screen draws its red
  arrows by (`Telemetry.closing_on`: the regiment it is ordered to attack,
  or the one where its march ends). Measured that way, nearly every blow
  is announced, with a median warning of 6–20 s against a target of 4. (A
  first version of the measure counted only blows on the very regiment an
  arrow pointed at, and called a third to a half of blows unannounced; in a
  line the blow often lands on that regiment's neighbour.)

### The AI audit

What the AI is: a reactive commander. Every 0.75 s each regiment's role
(foot, shooters, horse, guns, general) picks an order from the battle as it
stands, tuned by a persona (how long to hold, whether to flank, a reserve).
In a grand battle, divisions take objectives in order. It has no lookahead,
no memory and no read of the player's plan.

`tests/plans.gd` searches fixed plans against it: each of the player's
regiments is sent to one flag, or left to the AI's line, and the standard
commander fights the plan out on three dice. Thirty to forty plans each:

| Battle | the AI's own line | plans that win all three dice | plans that win none |
|---|---|---|---|
| Hold the Fords | wins none | 24 of 33 | 9 |
| Hammer and Anvil | wins none | 24 of 30 | 6 |
| Push of Pike | wins all three | 21 of 35 | 4 |

So:

- **As an opponent it is easy to beat on purpose.** Sending the army at
  chosen flags, almost any choice, beats it on every dice where its own
  line, spread across every flag, loses on every dice. A player who
  concentrates will find the quick battles easier than the tables above
  say.
- **As a stand-in for a player it is fit for some things only.** It is
  fit for regressions (the recorded battles), for comparing scenarios with
  each other, and for the history checks of the grand battles. It is not
  fit for saying how hard a battle is for a person: it gives superhuman
  orders a minute, spreads itself thin, and gives up good ground.
- **The plan is worth almost everything; the dice almost nothing.** A plan
  wins on every dice or on none far more often than it splits them.

What to expect of it, and the next fixes, each measured by these studies:
the line should concentrate as divisions do (the plans that win are
divisions); a side that starts on good ground should hold it; and the
standard commander should give orders at a person's rate, so that "the
standard commander wins" means something about players. Past that, a
planner that searches plans during the battle would be the stronger AI and
the honest ceiling; see "Solving the game" in ARCHITECTURE.md.

## Score

1000 per victory, plus 2 per enemy soldier killed, plus 1 per surviving
soldier at the end of each battle, plus a speed bonus for battles won
under three minutes. Best score is kept on the device.

## Architecture (for whoever edits next)

- `scripts/battle.gd` is the simulation and the one writer of battle
  state. Everything else hands it orders (`apply_orders`) and reads it.
- `scripts/ai.gd` is a pure decision: battle state in, orders out. The
  player's side in the headless balance tests uses the same function.
- `scripts/combat.gd` holds the rules as pure functions over values.
- `scripts/campaign.gd` is pure: run state in, new run state out.
- `scripts/terrain.gd` builds a seeded map, or a grand battle's map from
  a hand-drawn plan (`Terrain.from_plan`), and answers queries about it.
  Each map has its own size.
- `scripts/gettysburg.gd` and `scripts/waterloo.gd` are grand battles as
  pure data: the ground, who starts where, when each corps goes in, and
  who comes up which road when. `Scenarios` builds the
  battle from it; the battle raises each arrival at its hour.
  River maps route by banks and crossings; a fortress map routes on a
  16-unit grid (Godot's AStarGrid2D) pulled tight to straight legs, with
  gates open in the plan so a besieger's route ends pressed against the
  gate, which is where it rams. Only the battle writes `gate_broken`.
- The views (`terrain_view.gd`, `units_view.gd`, `minimap.gd`) and HUD read state and turn the battle's
  events into effects and sound; they never write battle state. A grand
  battle's camera (centre and zoom) and minimap are screen state.
- `tests/run_tests.gd` runs headless: rules, pathing, campaign, and
  AI-vs-AI battles that must finish in time.

## Luck and skill (measured)

Measured at the old test step (1/15 s); see "Play over time" for what is
current.

`tests/luck_skill.gd` fights each campaign battle under a ladder of player
commanders of rising skill (idle; slow; standard; sharp, which thinks
faster and blows the Rally horn) and two variants of sharp (reserve: holds
one foot regiment back and sends it onto the flank of whoever a friend is
fighting; hills: puts archers on high ground), × 8 draws (map and enemy
roster) × 3 dice (the battle's own random numbers). `tests/luck_skill.py`
splits the spread of the final resolve margin between them. Among slow,
standard and sharp, measured 2026-10-30:

| | first build (0cab6d9) | slower fights, softer panic, no reload luck (3eb5e33) | + line fix, fatigue |
|---|---|---|---|
| commander (same edge everywhere) | 5% | 7% | 21% |
| fit to the map | 31% | 39% | 34% |
| the draw | 48% | 42% | 39% |
| the dice | 15% | 12% | 6% |
| **skill in all** | **36%** | **46%** | **56%** |
| wins: slow / standard / sharp | – | 38% / 46% / 57% | 29% / 34% / 49% |
| lead changes per battle, sharp | – | 0.26 | 0.58 |

What each change bought, from runs that changed one thing at a time:

- **The line fix** (each regiment takes the crossing on its own part of the
  front, instead of crossing paths) took skill from 46% to 55%.
- **Fatigue** left skill's share about where it was (55% → 56%) but doubled
  how often the lead changes hands for the sharp commander (0.34 → 0.58)
  and widened the gap between slow and sharp play (38% → 29% for slow).
- **A reserve pays on some maps and costs on others.** Held back and sent
  in as soon as a friend is pinned, it lifts Two Bridges from 50% to 83%
  and Saltmarsh Road from 8% to 17%, and drops Ashwood, where their horse
  comes early through open woods, from 75% to 38%. Overall it draws level
  with no reserve (49% each). Whether to hold one is a call to make from
  the briefing. Committed late, when a friend is about to break, it
  measured worse everywhere and was removed.
- Tried and dropped: throwing the whole line at one crossing (loses the
  flag race), and a morale shock when fresh troops hit worn ones (no
  measurable gain).

Giving orders at all is decisive: an idle army never wins. Past that, the
draw weighs most, but it is luck you can see: the briefing shows their army
and deployment shows the map before you commit, and the study's commanders
are map-blind AI, so they cannot use it. The dice are luck after you
commit; they are now only cannon scatter. Volleys fall out of step by a
fixed stagger per regiment rather than a random reload.

The last two battles are hard: no AI commander wins Saltmarsh Road or
Marshal's Ridge more than 17% of the time. A player has rewards and the
abilities the study does not use; whether that is enough is for play to
show.

**2026-10-31: the AI holds its objectives.** Until it advances, an army
used to stand in its deployment zone, so a dug-in enemy let the player
walk onto both bridges unopposed. Now it stands just short of each flag on
its own side and its guns cover the most wanted flag. Measured on the
campaign: the sharp AI wins 61% (was 49%), the last two battles became
winnable for it (Saltmarsh Road 38%, Marshal's Ridge 38%, from 8–12%), and
skill's share among slow, standard and sharp fell to 47% (the draw rose to
46%): attacking a held crossing is costly, and which crossings the map
gives you matters more. Two Narrow Bridges is now lost by every AI player;
a person has guns and a barrage they use badly.

Rerun after any balance change:

```bash
for i in 0 1 2 3 4; do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s tests/luck_skill.gd -- --battle=$i > build/luck/b$i.txt & done; wait
python3 tests/luck_skill.py build/luck/b*.txt
```
