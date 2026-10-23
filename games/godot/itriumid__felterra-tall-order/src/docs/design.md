# Felterra: Tall Order — design

What we've decided, and why. When the game and this document disagree, one of them is wrong:
fix whichever it is, in the same pull request.

## The game in one line

An auto-shooter roguelike where a crew of cats fights giants: a human company that has bought
their forest and moved in with its machines, and doesn't see cats as people at all.

## World and story

**Felterra** is a world of cats, set in the Nusantara seas. It's shared with other Felterra
games, but this story stands on its own: nothing here depends on another game's events.

The present day. Cats are a modern people, with their own technology at cat scale. Humans exist
too, and to humans, cats are animals: pests, if anything. A human company has moved into the
forest a community of cats lives in, and is clearing it.

**The cats don't know that at first.** Finding out is the story, told area by area in
Liberation: rats where there never were any and a smell of oil in the stream; deeper in, stumps,
ruts and cages, and a giant with a whistle; then the sawpits, and the sign over the gate. It was
always humans.

**The company** is **PT Makmur Bakti Gemilang**, which the cats call **Makmur Bakar**:
MBG. It clears the forest as the "official partner" of the **Food Land Acceleration Agency**,
which has stamped the cats' forest on its maps as *lahan tidur*, idle land, to be cleared for the
nation's food. Its site boards say *From Idle Land to Plenty* beside *Building a Greener
Tomorrow!*, and the finale is an official flying in to cut a ribbon on what's left. It's satire of
deforestation, the peat fires and the way land gets cleared there, and every name in it is made
up: no real ministry, agency or person is named, the system is the joke rather than anyone in
it, and the meal program's purpose (feeding children) is never mocked.

The cats can't out-muscle a giant. What they can do is be **underfoot**: in the way, beneath
notice, at ankle height where a giant can't easily reach. The fight is to make the giants take
cats seriously. Stopping them is a tall order.

**Tone:** warm, cheeky and fierce, the way cats are. The game is aware of real-world logging
and land clearing without preaching about it. The humans are a company with a schedule, not
cartoon villains.

**No magic for the cats.** Everything they fight with could be built. Folklore spirits are kept
in reserve as a possible later enemy faction, where being the first supernatural thing in the
game is the point.

## Factions

Many factions over time; **humans are the first**.

Humans are at **real scale**, about five to six times a cat's height. That sets the whole
faction's shape (each enemy, built and planned, is in [`catalog.md`](catalog.md)):

| Role | Who |
|---|---|
| **The horde** | The humans' creatures: rats from the supply crates, guard dogs, gulls at the camp |
| **Mini-bosses** | Human workers: each one a giant, slow, hitting hard. A stomp is a shockwave; a dropped lantern is a fire |
| **Elites** | The chainsaw crew |
| **Bosses** | Machines: a feller buncher (it grabs and cuts trees in one bite), a bulldozer, an excavator, a logging truck you can tip over, and a helicopter at the end: something giant a cat can't even reach |

A felled human is a large body that falls and **crushes what's under it**, his own dogs
included. Tricking a giant into flattening his own horde is a real tactic.

**Guard dogs** are the company's own, in its hi-vis harness: real-sized, taller than a cat and
longer, deep-chested on long legs, and faster than he is, so a dog can't simply be outrun. They come in
packs of three from about a minute in. A dog that gets close crouches (the warning), then
lunges: a real leap through the air that bites if it reaches him, and that a dodge gets him out
from under; it lands, and needs a moment before it runs again. A dog is heavier than a rat, so a
round shoves it less.

The **chainsaw worker** is the first elite: a giant in ear defenders, tougher and slower than a
worker, from two minutes in (every other giant after that). Instead of stomping, he revs the saw
for a little over half a second, its arc marked on the ground in hi-vis (the warning), then
sweeps it at shin height across the ground in front of him. Whatever is in the arc is cut,
his own rats and dogs included, so luring the horde into it is a tactic; a dodge gets him
through it, a long leap clears it, and behind him is safe.

The **feller buncher** is the first boss, five minutes in, and another every five minutes after,
one at a time. It's a tracked machine with a long boom, whose head grabs a tree and saws it
through in one bite. It crawls toward him, turning on the spot before it drives, and whatever is
under its tracks while they turn is crushed, its own horde included; standing still, its steel
just doesn't give. Within reach, it swings its boom out over him, the head's shadow growing on
the ground (the warning), then the head drops and its jaws shut on whatever is there. After a
bite the head sits on the ground for a moment, its hydraulic joint exposed, and hits there do
double; anywhere else, the steel shrugs off most of a hit. That's the fight: dodge the bite, then
punish the joint. Too close for its boom, it backs off. Broken, its engine dies, the boom comes
down, and it stays where it stopped, a wreck to fight around.

## The first map

A clearing the company has cut in an Indonesian tropical forest.

- **The ground is open.** The company has cleared it, which is why there's nothing to block
  movement, and why they're there at all. Mud, burnt earth and log skids vary it: they slow you,
  they never stop you.
- **The jungle is the wall** around the arena: living, thick, impassable.
- **The canopy hangs overhead**, drawn above everything, with no collision. It's above your
  head, so that's honest, and it gives the forest its depth.
- **Low growth never blocks**: grass, ferns, leaf litter. It bends and scatters as things move
  through it.
- **Felled logs are physics objects**, not obstacles: a log rolling down a slope crushes the
  horde.

## The cat

**Tompel** is a white cat with black ears, a black crown and saddle, a black tail, and a black
mole by his nose. He's a cat, so he walks on four legs: he carries one weapon in his mouth and the
other in his tail, his tail a limb of its own that curls up behind him, sways as he walks, and
reaches out to grip what it holds. Every cat in the village walks the same way.

- **Moves freely**, in any direction.
- **Fires automatically.** You steer, dodge and choose upgrades; your weapons aim and shoot.
- **Gear shows on the body.** Every piece of armor and every weapon from an upgrade is visible.

### Starting out

A run starts with a choice of one weapon, and nothing else: armor and accessories are upgrades.
The two cards wink at the films: a cat parody each.

- **Nunchaku**, "Go Chuck Purris style", for close work: two sticks on a chain, swung most of the
  way round him, blunt, and it never runs out.
- **Handgun**, "Go John Whisker style", for range: slow, but it reaches.

**English by default.** Every name on screen is in English: a slingshot, not a ketapel; a fighting
kite, not a layang-layang. Where English has no word of its own (golok, mandau, rencong, badik,
kujang, as a katana is a katana), the name stays, and every thing's story tells its Indonesian name
and where it's from. The ids underneath stay as they were, so a translation is a language
setting later, not a rename.

### Aim

Weapons aim and fire on their own. Each cat picks how they choose a target, and can change it
in a run:

| Mode | Goes for |
|---|---|
| **Nearest** | The closest enemy |
| **Toughest** | The most health left (and, once enemies have armor, defense) |
| **Crowd** | The thickest cluster: best for spread and explosives |

Melee weapons swing a blade through an arc and hit what the blade passes through, at the height
it passes. A swing alternates forehand and backhand.

### Arsenal

Modern weapons anyone could find, plus what a country has uniquely. Indonesia comes first;
other countries' weapons join later, each with its own shape and feel. Everything is something
that could be built.

Every weapon, built and planned, is in [`catalog.md`](catalog.md). Weapons differ by more than
their numbers: rounds can come several to a shot (the shotgun's cone), go through what they hit
(the crossbow, the sniper rifle, the bow), or glance off to the next (the slingshot's stones); they
can poison and slow (the sumpit), set alight (the flare gun), leave burning oil (lamp oil) or
nails (the nail gun) where they land, or pop as firecrackers (petasan). Blades can trip (the
celurit), hook what they catch in toward him (the kujang), thrust in a line instead of swinging
(the tombak, the rencong), or break after so many hits and be sharpened again (bambu runcing).
Families can branch: a rifle grows into the automatic rifle or the sniper rifle, a card for each.

### The dodge

A short roll, with a moment where hits don't land. It takes a charge, which comes back in a
little under a second. Over a run it takes up to **three mutations**, each changing what the
dodge *does*, not just its numbers. Upgrading a mutation you already have strengthens it without
taking another slot, and, as everywhere, a card's rarity changes only how much it gives.

Every mutation, built and planned, is in [`catalog.md`](catalog.md). Some wait on what they act
on: fire and oil, or crewmates who can be downed.

## Runs

- **The flow lives in the village.** The title is short, over the forest path to the village:
  Play, Settings and Leave. Play makes the menu fall away, and he walks into the village, a
  cutscene; the first time, the Elder walks out to meet him where the village starts, and the
  story's opening is told over the walk, the Elder's part in his own words (what's wrong, what
  needs doing). From the village, walking out through the gate is seen off: the villagers come to
  the gate as he heads for it, the Elder at the front, and line the path while he walks on into
  the forest. The first time he leaves for an area, someone has a word for him on the way; any
  other time he just goes, at his own pace. He walks into every run the same way, from the way
  he came, the world held still until he's in: slowly enough for the area's story to be told
  on the way the first time, at his own pace after. Then he chooses what he starts with,
  nunchaku or handgun. Coming home, whatever has happened since is told on the walk in: what an
  area freed teaches him, from the cat who teaches it, and what the story has brought back. Then
  a panel sets out what's new, a line each on what it does and where to find it: a building, a
  dodge mutation now on the cards, an area found on the map. When he's down, a summary of the run (time
  survived, level reached, kills, giants felled, machines broken, cats rescued, salvage) marks
  any new best in words as well as color, and offers Home to the village, Straight back out (a
  new run at once: "one more run" shouldn't mean a walk across the village every time), or
  Leave. Giving a run up from the pause menu takes him home with what he's carrying. The best
  run is kept beside the settings.
- **Cutscenes are always the player's to skip,** to follow WCAG AA: Escape skips the whole scene,
  Enter hurries a line along, and both keys are shown on screen while one plays. A setting makes
  story lines wait for Enter instead of moving on by themselves, so nobody reads against a
  clock. A line can carry a voice recording, held until it's been heard; there are none yet.
- **The cast speak for themselves.** In a cutscene, a line someone says is set along the bottom
  of the screen beside their portrait: a bigger, more detailed bust, in the mood of the line
  (neutral, happy, sad, surprised, determined or worried), the same pixels as everything else,
  only more of them. Each cat is the one bust in their own coat with their own touches: the
  Elder's headcloth and white brows, Nenek Pus's glasses and shawl, Tompel's crown and mole.
- **The cast**, one freed in each area, each bringing back what their trade needs:

  | Who | Freed in | Brings back | Teaches |
  |---|---|---|---|
  | The Elder | (always home) | | Rolling slash, land on your feet |
  | Pak Besi, the smith | The village's edge | The smithy, and he fixes Tompel's roof | |
  | Nenek Pus, the weaver | The deep forest | The weaver's hut | Pounce, riposte |
  | Si Belang, the carpenter | The sawpits | The longhouse | Ankle cutter, caltrops |
  | Jingga, the scout | The logged clearing | The watchtower | Long leap, dust cloud |
  | Kopi and Susu, the stall keepers | The log slide | The market | More charges, slipstream |
  | Bu Jamu, the herbalist | The company's offices | The healer's hut | Lick your wounds, scent trail |
  | Datuk, the ferryman | The airstrip | | Chain roll |

  The huts the rescued cats build themselves, as their number grows.
- **Jogiboy** is a villager in his own right: in Felterra everyone is equal, and he's nobody's
  pet. He lives next door to the Elder, has decided Tompel is his friend, and goes everywhere he
  goes, the way a friend once took him out to play: ginger, with a white blaze, white socks, tall
  ears, sad eyes, and a blue collar with keys on it. He speaks for himself, with his own portrait.
  Finding things is his trade: each time Tompel walks home he has dug up a little salvage for him,
  and on the map board he sniffs out how many caged cats each area holds. He never comes on a run,
  and nothing ever hurts him. He's here in memory of a dog a friend loved.
- **Who's talking is shown, not said.** Someone without a portrait says a line in a speech bubble
  over them, their name at its top and its tail pointing down at them; a line of the story itself
  is written across the top of the screen. In a fight, the same bubbles carry what freed cats say,
  without holding anything up.
- **The village has its own music**, from the run's instruments at an easy walking pace (92 beats
  a minute against the run's 154), no drums or rock, the bronze up front, and the run's melody
  played slow and soft over it. Walking out to a run crossfades from one to the other. The title
  and the story's opening have their own, mellower still (72 beats a minute): a lone suling, the
  bamboo flute, over a soft pad and a gong, crossfading into the village's as he arrives.
- A run lasts **15 to 30 minutes**. Progress carries over between runs.
- **Two modes.** **Liberation** is the story: the forest freed area by area (below). **Endless**
  is the score chase: a fresh, generated clearing every run, everything coming at once and
  growing until he's down; the best run is Endless's. Co-op is for Endless only: Liberation
  moves one village's story, so it's solo, but nothing in it assumes one cat, so a "help a friend"
  co-op Liberation stays possible later.
- **Liberation** is chosen at the map board by the village's gate, drawn as a map of the forest
  from above: the river, the village, and the path through every area in the order it's found,
  each wrecked while it's held, green again once it's free, and under mist until it's found.
  Endless lies off the map's corner. Each area is a fixed, hand-made place and one run: push in through what holds it, do
  what only that place asks, then its boss comes; beat it and the area is free, and the next one
  opens. Held by the company, an area is wrecked (stumps, felled trunks, ruts, oil, litter,
  smoldering peat, fewer trees standing at its edge); freed, it's healed (grassed over, saplings,
  flowers, clear water), and stays healed on every run after. The first time he goes into an
  area its story is told going in, to the opening's mellow music; the first time it's freed, the
  healed ground spreads out from where its boss fell while the story goes on, to music of its
  own. Losing still brings home what he carried; the area stays the company's. But what he did
  there stays done: a goal finished before its boss beat him is kept, so the next run in starts
  with it done (a word on the way in says so) and the boss comes after 45 seconds, time for him to
  grow into the fight from the first level. The first time
  each is freed brings the village salvage, brings a building back, some free cats who come
  home, and most have a cat who teaches him their dodge mutations.

  | Area | Goal | Boss |
  |---|---|---|
  | The village's edge | Break the three rat nests | The Rat Baron, a rat as big as a dog that calls rats in |
  | The deep forest | Free the four caged | The Handler, who keeps his distance and whistles his dogs in |
  | The sawpits | Wreck the three saws | The feller buncher |
  | The logged clearing | Hold it for three minutes | The log loader, throwing logs where he stands |
  | The log slide | Pull the three levers, and the logs roll down over everything | The logging truck: it charges, stalls with its tank open, and tips over when wrecked |
  | The company's offices | Cut the power: three generators | The bulldozer, whose engine at the back is the only weak point |
  | The airstrip | Cut the three fuel lines | The helicopter, out of reach until it lands to unload |
- **Endless mode**: the giants never stop coming; factions arrive and start to mix.
- **The hub is the cats' village** at the forest's edge. It grows between runs: rescued cats
  join, the smith forges better gear. That growth is the progress that carries over, and it's
  the story moving forward.
  - **A run brings home rescued cats and salvage.** To the company, cats are pests, and its
    traps turn up in the clearing from 40 seconds in, one every 75 seconds, never close to him.
    Standing by a cage picks its lock over three seconds; leaving lets the pick slip back. The
    cat inside, with its own name and coat, has its say in a bubble, each its own way, then runs
    for the jungle, home: a grateful one a quick thanks; a chatty one going on until he cuts in
    and tells it to go; a fighter throwing a firecracker at the horde (a real one, lobbed, that
    pops like any) on its way out. A mark at the screen's edge
    shows the way to a cage out of sight. What he breaks throws out salvage (a worker 2 pieces,
    a chainsaw worker 4, a machine 12), which flies, lands and slides, and walking over it takes
    it. Both are counted on the summary and kept in the village between runs.
  - **The village is walked**: a forest path in, the village itself a screen wide, and the path
    out to the clearing on its far side. The cats he's rescued live there, each in its own
    coat, and show their names as he passes.
  - **It starts in ruins.** The company's machines have already been through: his own home, the
    Elder's longhouse, the smithy and five huts all stand wrecked, holed, scorched and
    half-roofed. Restored, the village is bright and lived-in: walls painted in reds, teal,
    yellow and pink, trimmed in cream; bunting under every eave; flowers in the grass; the
    longhouse's painted band and its umbul-umbul, the tall flags on bamboo poles, at the way in.
  - **The story brings it back, never salvage.** His home is fixed up by the first cat he
    rescues, as a thank-you. Freeing the village's edge brings back the smithy (the company's
    crates were full of tools); the deep forest, the weaver's hut (Nenek Pus moves in with her
    loom); the sawpits, the longhouse (after the sawpits, everyone wants to talk at once); and
    each area after, another hut. What came back is told as he walks home to it. A ruin's door
    says what will bring it back.
  - **Each building opens what it holds.** His home is his pack. The smithy forges weapons, gear
    and support into the cards (8 to 24 salvage each): salvage is spent there and nowhere else.
    The longhouse's elder lets a run start with any weapon forged, and keeps the book of
    stories, the story so far to read again. Never a stat on its own: stats only come from gear.
  - **A run starts with what any village has lying about**: six weapons (the nunchaku, the
    handgun, the knife, the slingshot, the golok and the rattan staff) and five pieces of gear
    (the conical hat, the red scarf, the boots, the sarong and the gloves). Nothing else turns up
    on the cards until it's forged or taught. Dodge mutations are taught, one or two by a cat
    for each area freed.
  - **His pack** holds what he has, and each thing can be packed or left home, so the cards
    offer only what he wants; a piece of gear can also be worn from a run's start. Leaving
    things home narrows the cards but never past a draw: three of each kind stay packed for every
    place a run has for one (his mouth and his tail, so six weapons; seven slots, so twenty-one pieces of gear;
    a drone and a set-down, so six support; three mutations, so nine).
  - **Everything has its story**, read on a card with Tab and at the smithy and the pack: where
    it came from, as the cats tell it.
  - **Housed cats weave cloth**: each restored hut houses two rescued cats, and every run brings
    in a cloth for each. The first hut is the weaver's, who sells looks for cloth (his coat, the
    umbul-umbul's colors), its own currency so a look never competes with forging. The full
    list is in the catalog.
  - **Progress can be reset** from the settings: it asks once more, then the village and the
    best run go back to nothing, and the settings stay.
- Maps push deeper into the camp: the clearings, the sawpits, the log slide to the river, the
  company's offices, the airstrip.

## Upgrades

Level-ups arrive as **cards**. A card offers a choice of three; you hold it until you play it.

- **Cards never expire.** The only pressure is the danger around you, never a timer.
- **Solo and online behave the same.** Nothing pauses for a level-up, so the game is tuned once
  and endless scores compare fairly.
- **A pause menu exists in both.** Solo, it stops the world. Online, it opens over a world that
  keeps running, and its panel is see-through so you can see what's coming.
- Held cards can be read in the pause menu, and are only played in action.
- **The pause menu**: carry on, settings, start again, leave the game. **Settings**: graphics
  (full screen, window size, vertical sync), audio (overall, music, effects and interface
  volumes, each its own bus) and gameplay (aim mode, blood), kept for next time. It opens
  on its own when a run ends, ready to start again. Its see-through panel is a checkerboard of
  palette pixels, not a blend.
- **Card text is short.** If a card needs a paragraph, the upgrade is too complicated.

### What a card can offer

| Kind | Offers |
|---|---|
| **A weapon** | A new one, into his mouth, his tail, or a support slot |
| **A weapon's level** | Levels 1 to 10 for a weapon held; at 10 it can evolve along its family (knife to kris to karambit, machete to greatsword, handgun to submachine gun, rifle to automatic rifle to assault rifle, or rifle to sniper rifle), keeping everything its levels gave it |
| **Mastery** | Past the top: a weapon at the last of its family, or gear at level 5, takes mastery levels without limit, each worth half a level. A long run keeps growing, which is what makes a god run possible, and a card is never empty |
| **Gear** | Armor and accessories, worn and visible |
| **A dodge mutation** | See the dodge |

**Stats come only from what he wears**, never as cards of their own: every stat he has is
something you can see on him. Each slot holds one item, and the same item's card again levels
it up, to level 5, then into mastery.

The gear for each slot is in [`catalog.md`](catalog.md), fitted to a cat on four legs: a hat on
his head, glasses over his eyes, a collar round his neck, a coat over his back, wraps on his front
paws, boots on his hind feet, and round his middle a belt, a sash or a saddle cloth (the sarong).
Toggled with I, a panel sets out what he carries, each piece's level, and every stat as it stands,
without stopping anything.

The stats, and what each means, are in [`catalog.md`](catalog.md) too. A card shows a stat's
short form; holding Tab explains each one, and a card with a stat most players won't know is
marked as worth reading. Adrenaline is what other games call lifesteal: grounded, not magic, and
the game explains it.

### Rarity

Four tiers: **common, uncommon, rare, legendary**, rarer ones turning up less often, and luck
raising the odds.

- **Rarity changes only how much an upgrade gives**, never what it does. A rare "attack
  speed" is a bigger common one.
- **Rarity shows by more than color**: the card's frame shape and its pips change too, so it
  reads as fast for colorblind players.

### What a cat can carry

- **A mouth and a tail.** Two one-handed weapons, one in his mouth and one in his tail (nunchaku
  and handgun, kris and golok), or one two-handed weapon (rifle, assault rifle, sniper rifle,
  greatsword) that hits harder, held in his mouth and braced with his tail.
- **Two support slots** for what isn't held, one of each kind, both on his back: **one drone**
  and **one thing he sets down** (a turret, or mines). One of each, because two drones or two
  turrets on one pack would never sit right. **He starts with neither.** The drone docks in a
  cradle on top of the pack when there's nothing to shoot; the bamboo cannon is a bamboo tube
  strapped across it until he sets it down; mines ride in pouches on the straps. Each comes
  with its mount, and the pack shows from every side.
- **Support works on its own,** as his weapons do, and takes levels the same way. The drone lifts
  off when something comes in reach, hovers off his shoulder and fires down, and docks when it's
  quiet. The cannon is set down where he stands when something comes in reach, and stays there:
  stones lobbed over the horde burst where they land. A bamboo tube cracks after eight shots and
  he cuts a new one, so there's nothing to go back for. Mines are dropped while enemies are near,
  four down at most, and the first foot on one sets it off, a giant's boot included; they never
  hurt the crew.

### Controls

Your left hand never leaves movement.

| Key | Action |
|---|---|
| W A S D | Move |
| Space | Dodge |
| 1, 2, 3 | Pick from the oldest offer you're holding |
| Tab (hold) | Read held offers in full, without stopping anything |
| R | Reroll the offer, if you have rerolls |
| X with 1, 2 or 3 | Banish that choice for the rest of the run |
| Enter | Go again, once a run has ended |
| Escape | Pause menu |

Held offers sit as a strip of icons at the bottom of the screen, with a count. Everything can
be rebound; controllers get the same layout on face buttons and bumpers. The mouse is optional:
clicking a card works, but nothing needs it.

## Playing together

One to four players, **online and on one screen**.

- **Shared experience, separate choices.** The crew levels up together from one pool; each cat
  picks their own upgrade. No kill-stealing, no one falling behind.
- **Nine Lives, shared.** The crew carries nine lives between them. A downed cat is revived by a
  crewmate standing by them for a few seconds; if nobody comes in time, a life is spent and they
  respawn. When the ninth is gone, the run ends.
- **Builds combine across players.** Some upgrades set up what another player's finish: one cat
  spills oil, another throws sparks. Synergy comes from talking, not from one player's build.
- **Scaling** is less than linear: four players face about two and a half times the enemies,
  not four times.
- **Camera:** online, each player has their own, kept within a shared arena. On one screen, a
  shared camera zooms out to fit everyone, up to a leash. No split screen: it halves the
  readability the genre lives on.
- **No friendly fire, but the physics is shared.** A crewmate's explosion doesn't hurt you; it
  still throws you.

**In-game names** carry Indonesian words where they can mean something without having to sell
the game: cooperative play could be *Gotong Royong*, communal work; endless mode could be
*Tanah Air*, holding the homeland.

### Networking

**The host runs the world; each player predicts their own cat.** The host simulates every
enemy and sends compressed positions about 20 times a second; each player's own movement runs
locally so it feels immediate.

Not lockstep: lockstep needs every machine to compute identical results, and GDScript can't
promise identical floating-point math across Windows, macOS and Linux. Online play through
Steam would mean adding GodotSteam later, which is a new dependency and gets decided then.

## Art

**Hand-drawn pixel art**, in the spirit of Stardew Valley and Core Keeper, at 16-pixel tiles on
a 640 by 360 screen. A cat is about 16 to 20 pixels tall, a human about 100.

### Style rules

These apply to everything, wherever it comes from:

1. **One palette**, about 32 colors, in `game/palette.gd`: jungle greens, earth, fur, steel, and
   hi-vis orange for the human workers, which is realistic and makes enemies easy to read in a
   crowd.
2. **One pixel size.** A pixel always covers the same size in the world. Nothing is scaled or
   mixed with art drawn at another resolution.
3. **One light**, from the top left, with three tones per material: light, base and shadow.
4. **Outlines** in a dark warm brown, not black, on characters and anything you can hit or pick
   up. **The environment has none**, which is what makes characters stand out from the ground.
5. **Effects are pixels too**: smoke, sparks and debris are palette particles, never smooth
   gradients. Only lighting is smooth.
6. **Rotations are drawn.** Weapons that aim have hand-drawn angles (8 or 16); rotating pixel
   art in code mangles it.

### Layers

Gear is drawn in layers over the body, Stardew-style, and the cost decides how much gear of
each kind we make:

| Gear | Cost | How |
|---|---|---|
| Weapons | Cheap | One drawing per angle, held at a hand point marked on each body frame |
| Helmets and hats | Cheap | One drawing per direction, moved by a head point per frame |
| Body armor | Expensive | Full frames for every body frame; few designs, with color swaps for variety |
| Trinkets | Cheap | Small sprites at an anchor point |

Hand-drawn frames give the beauty; the simulation gives the motion on top: tail and cloth
follow procedurally, hits and recoil push the sprite, a felled body falls as physics parts.

**Blood** is honest: droplets are particles that arc, fall and stain the ground where they
land; stains dry darker and in time are gone. A setting turns it off, and the same hits throw up
dust and fur instead, so a hit still reads. The fallen lie where they fall, up to a few hundred;
past that the oldest crumble away pixel by pixel rather than vanishing.

**Walking** steps with the ground covered, never a clock, so feet don't slide and a body
thrown through the air doesn't run.

**Light** carries much of the look: sun shafts through the canopy, muzzle flashes on the
ground, torches at dusk. Godot's 2D lights with normal maps should do it; how much of that the
Compatibility renderer supports is the first thing the prototype checks.

### Where the art comes from

For now, we draw it. Free packs are used only when they pass the style rules and are CC0 or
CC-BY, since the repository is public; most won't, and get redrawn. When the game earns money,
the first spend is a commissioned style kit (the cat's body frames, one human, one horde
creature, one tile set) to set the standard everything else is matched to.

### Type

Our own pixel font from Nine Seas for everything you read: capitals 7 pixels tall, proportional,
on whole pixels. A larger display face drawn the same way for titles, card names and banners,
and outlined digits for damage numbers. Outside the game (store page, logo, trailer), Plus
Jakarta Sans.

## Sound

**Every effect is synthesized in code**, like the art is drawn in it: a few shared building
blocks (a tone that sweeps, filtered noise, a pulse wave, the stepped noise of old sound chips),
so every sound belongs to the same game, and there's nothing to license.

- **The simulation drives it.** A shot plays for each round fired; a blade whooshes with each
  swing, deeper for a kris, quicker for a karambit; a rat's hit is a small high thud and its fall
  a squeak, a giant's hit is deep; a giant's footfalls land with his stride, his stomp booms and
  his fall thunders.
- **Sounds sit where they happen** and fade with distance from the view; the interface's play
  flat, on their own bus.
- **Voices are limited per sound**, so a horde never drowns the rest.
- Each sound comes in a few variants, played a little off pitch, so repeats never ring the same.

**Music**, as a direction (it's still to be composed): chiptune and bitpop in the spirit of
Megabonk's soundtrack, fast (about 150 to 165 beats a minute), in a major key, bright and a
little comical, with **gamelan bronze answering the chiptune lead** between its phrases, the
kentongan tapping the off-beats and kendang fills closing them. It adapts: the main theme
carries the run, and **when a giant walks in, a rock layer joins** (a backbeat and a
power-chord riff), so a giant is heard arriving before he's seen.

Until it's composed, a **placeholder in the same shape** plays: six layers synthesized in code,
all the same eight-bar loop so they stay in step (drums with the kentongan and kendang, the
octave bass, chords that turn to angklung, the chiptune lead, the gamelan answer, and the rock
layer). Drums, bass and the gamelan always play; the chords, then the lead, come in as the horde
thickens around him; the rock layer whenever a giant is on his feet; and everything drops back
in the pause menu. Real music replaces the layers one for one.

## First prototype

Placeholder art; it tests the three biggest risks, all technical:

1. **Light** in the Compatibility renderer: does the canopy-and-muzzle-flash look work?
2. **Layered sprites** with anchor points: a cat whose gear can be swapped.
3. **A horde of a few hundred**, with the height coordinate and physics, to measure what
   GDScript can carry.
