# Felterra: Tall Order — catalog

Everything in the game, built or not: enemies, weapons, support, gear, dodge mutations and
stats. It's the one list to brainstorm on, so add to it freely. The rules for how these work
together are in [`design.md`](design.md).

Each row's status is one of:

- **Built:** in the game now. A test checks that these rows match the code exactly, so building
  something means changing its row to Built here, and a Built row always exists in the code.
- **Planned:** decided, in the design, not built yet.
- **Idea:** being considered. Brainstorm here, then promote it to Planned or take it out.

## Enemies

The humans are the first faction, at real scale. Their creatures make up the horde; their
workers are giants.

### The horde

| Name | Status | What it does |
|---|---|---|
| **Rat** | Built | From the supply crates. Small and quick, comes in numbers, bites |
| **Guard dog** | Built | The company's, in a hi-vis harness. Faster than a cat; crouches, then lunges through the air. In packs of three |
| **Gull** | Planned | At the camp |
| **Cockroach** | Idea | From the supply crates too: tiny, in swarms, crunched underfoot by him and the giants alike |
| **Survey drone** | Idea | The company's: flies over the clearing and marks him for the giants, who come faster while it sees him |

### Giants

| Name | Status | What it does |
|---|---|---|
| **Worker** | Built | A mini-boss: slow, heavy, stomps (the boot's shadow is the warning). Felled, he topples and crushes what he lands on |
| **Chainsaw worker** | Built | The first elite: revs (the arc on the ground is the warning), then sweeps the saw at shin height, cutting his own horde too |
| **Lantern worker** | Planned | A dropped lantern is a fire |
| **Handler** | Built | The deep forest's boss: keeps his distance, and whistles a pack of dogs in every few seconds |
| **Foreman** | Idea | Stays back with a megaphone; while he shouts, the workers near him hurry |
| **Fumigator** | Idea | Sprays smoke for the pests: it hides what's in it, and makes him cough |
| **Tree climber** | Idea | In spikes and a harness, up a trunk: drops what he cuts on whatever is below |

### Bosses

Machines.

| Name | Status | What it does |
|---|---|---|
| **Rat Baron** | Built | The village's edge: a rat as big as a dog, a bottle cap for a crown, calling rats in around it |
| **Log loader** | Built | The logged clearing: lifts a log overhead and throws it where he stands, its shadow the warning; reaching back to its pile, its grapple's joint is open |
| **Feller buncher** | Built | Grabs and cuts trees in one bite. Crawls on its tracks, crushing the horde while they turn; swings its boom out over him (the head's shadow is the warning), and bites. After a bite the head sits on the ground, its hydraulic joint exposed for double damage; its steel shrugs off most of a hit elsewhere. Five minutes in |
| **Bulldozer** | Built | The company's offices: raises its blade, then rams forward, shoving everything in front of it. Its engine at the back is the weak point: get behind it |
| **Excavator** | Planned | |
| **Logging truck** | Built | The log slide: revs, sounds its horn, then charges down a line; stalled, its fuel tank is open. Wrecked, it tips over |
| **Helicopter** | Built | The airstrip: out of reach in the air, strafing lines marked on the ground; it lands to unload workers, and only then can blades reach it, its tail rotor open |
| **Wood chipper** | Idea | Pulls in what's near its chute, his own horde too; feeding it a giant's lost boot jams it |
| **Skidder** | Idea | Drags logs across the clearing on a chain: a sweeping wall to get out of the way of |

## Areas

Liberation, the story: the forest freed area by area, each one run with a goal and a boss.
Endless is the other mode: a fresh clearing every run, the horde growing until he's down.

| Name | Status | What it holds |
|---|---|---|
| **The village's edge** | Built | Break the nests; the Rat Baron |
| **The deep forest** | Built | Free the caged; the Handler |
| **The sawpits** | Built | Wreck the saws; the feller buncher. The company's sign over the gate |
| **The logged clearing** | Built | Hold the clearing for three minutes; the log loader |
| **The log slide** | Built | Pull the levers and let the logs roll; the logging truck |
| **The company's offices** | Built | Cut the power; the bulldozer |
| **The airstrip** | Built | Cut the fuel lines; the helicopter |
| **Endless** | Built | A fresh clearing every run; co-op lives here |
| **The river** | Idea | Beyond the log slide: the barges that take the wood away |

## Weapons

Held in his mouth and his tail: two one-handed, or one two-handed, in his mouth and braced with
his tail. Modern weapons anyone could find, plus what
a country has uniquely, Indonesia first. A run from the village starts with six weapons in the cards
(the nunchaku, the handgun, the knife, the ketapel, the golok and the rattan staff); every other
weapon is forged at the smithy first, and what a weapon grows
into needs no forging. Every weapon, piece of gear, support and mutation has a story, in
`simulation/lore.gd`.

### Modern

| Name | Status | What it does |
|---|---|---|
| **Nunchaku** | Built | A starting choice, "Go Chuck Purris style": two sticks on a chain, swung most of the way round him. Blunt, so it shoves more than it cuts |
| **Handgun** | Built | A starting choice, "Go John Whisker style". Slow, but it reaches. Evolves into the submachine gun |
| **Knife** | Built | Close and quick, never runs out. In the cards from the start. Evolves into the keris |
| **Submachine gun** | Built | The handgun grown up: fast and loose |
| **Machete** | Built | A broad blade, quick and wide. Evolves into the greatsword |
| **Greatsword** | Built | Two-handed: slow, very wide, very hard, and it throws what it hits |
| **Rifle** | Built | Long, hard-hitting rounds. Evolves into the automatic rifle, or the sniper rifle |
| **Automatic rifle** | Built | The rifle firing fast and loose. Evolves into the assault rifle |
| **Assault rifle** | Built | Two-handed: faster still, and further |
| **Sniper rifle** | Built | Two-handed: slow, very long, and a round goes through four in a line |
| **Shotgun** | Built | Two-handed: seven pellets in a cone, close |
| **Grenade launcher** | Built | Two-handed: lobs a grenade that bursts a meter wide |
| **Lamp oil** | Built | Thrown: the flask breaks where it lands and the oil burns, setting alight whatever stands in it |
| **Nail gun** | Built | Looted from the camp's toolboxes: fast, short, and nails that miss stay where they land, in the next foot on them |
| **Flare gun** | Built | One bright, slow shot that sets what it hits alight |
| **Crossbow** | Built | Two-handed: slow, and a bolt goes through one and into the next |

### Indonesia

| Name | Status | What it does |
|---|---|---|
| **Kris** | Built | The keris: the knife grown up, the cats' heritage blade, its wavy edge longer and harder. Evolves into the karambit |
| **Karambit** | Built | The kerambit, the curved claw blade: very fast, very close |
| **Golok** | Built | Indonesia's machete: heavier, harder |
| **Sickle** | Built | The celurit: hooks a leg and trips, leaving what it hits down a moment |
| **Rattan staff** | Built | Two-handed: a full sweep around him with heavy knockback |
| **Slingshot** | Built | The ketapel: stones that glance off one into the next, twice. In the cards from the start |
| **Blowpipe** | Built | The sumpit, the Dayak blowpipe: darts that poison and slow |
| **Firecrackers** | Built | Petasan, thrown: they land and pop, four times |
| **Spear** | Built | Two-handed: the tombak, a long thrust in a straight line |
| **Bamboo spear** | Built | Two-handed: the bambu runcing, the sharpened bamboo spear of the independence fight. It breaks after fourteen hits, and he sharpens a new one |
| **Mandau** | Built | The Dayak sword: heavy, wide swings |
| **Rencong** | Built | The Acehnese dagger: a quick thrust, not a swing |
| **Badik** | Built | The Bugis and Makassar knife: short, deadly up close |
| **Kujang** | Built | The Sundanese blade, its hooked edge pulling what it catches in toward him |
| **Bow** | Built | The panah: arrows lobbed over the horde, each going through one |

## Support

Carried on his back, not in his mouth or tail: one drone, and one thing he sets down. He starts with
neither, and each comes with its mount. Each is forged at the smithy before the cards can offer
it.

| Name | Status | What it does |
|---|---|---|
| **Gun drone** | Built | Drone. Lifts off his pack when something is in reach, hovers off his shoulder and fires down at it; docks again when it's quiet |
| **Net drone** | Built | Drone: lobs nets that pin down what they land on |
| **Bamboo cannon** | Built | Set down: the meriam bambu, as a turret. Strapped across the pack until something is in reach; lobs stones that burst where they land, and after eight shots the tube cracks and he cuts a new one |
| **Mines** | Built | Set down. Ride in pouches on the pack's straps; he drops one every few seconds while enemies are near, up to four, and a foot sets one off, a giant's boot included |
| **Fighting kite** | Built | Drone: a layang-layang circling him, whose glass-coated string cuts what it crosses |
| **Bamboo spikes** | Built | Set down: the ranjau bambu, a bed of bamboo spikes that pricks and slows the horde on it, until it's trampled flat |
| **Radio** | Built | Set down when the horde crowds him: it plays loud, and the horde goes for it instead of him until its battery's flat |
| **Bee swarm** | Built | Drone: a hive on his pack. The bees go out after whatever's nearest, stinging it and slowing it, and come home when it's quiet |
| **Alarm drum** | Built | Set down when the horde crowds him: the kentongan, beaten six times, each beat throwing what's close back off him, until it splits |
| **Snare** | Built | Set down: a jerat, a rattan loop that catches the first foot in it. A rat is held down; a giant is held by the boot, and can't walk off |

## Gear

Worn and visible, one item to a slot. Stats come only from gear. What's listed is what a common
level gives. Every piece is forged at the smithy before the cards can offer it.

| Name | Status | Slot | Gives |
|---|---|---|---|
| **Conical hat** | Built | Head | Regeneration, luck. The caping, the farmer's hat; from the start |
| **Hard hat** | Built | Head | Armor, health. Looted from the giants |
| **Vest** | Built | Body | Armor, health |
| **Bell collar** | Built | Neck | Luck |
| **Red scarf** | Built | Neck | Speed |
| **Goggles** | Built | Eyes | Reach |
| **Gloves** | Built | Paws | Damage, attack speed. Wraps on his front paws |
| **Boots** | Built | Feet | Speed, armor |
| **Herbal flask** | Built | Waist | Adrenaline. Jamu, the herbal tonic |
| **Bandana** | Built | Neck | Attack speed |
| **Sunglasses** | Built | Eyes | Critical hits |
| **Wristbands** | Built | Paws | Knockback, damage |
| **Sandals** | Built | Feet | Speed |
| **Velvet cap** | Built | Head | Luck, health. The peci |
| **Batik shirt** | Built | Body | Health, luck |
| **Raincoat** | Built | Body | Armor |
| **Headlamp** | Built | Eyes | Reach |
| **Rubber boots** | Built | Feet | Armor |
| **Sarong** | Built | Waist | Speed, armor |
| **Tool belt** | Built | Waist | Attack speed |
| **Batik headcloth** | Built | Head | Luck, attack speed. The blangkon |
| **Ear defenders** | Built | Head | Armor. Off a chainsaw worker |
| **Life jacket** | Built | Body | Health |
| **Lace blouse** | Built | Body | Regeneration, luck. The kebaya |
| **Company lanyard** | Built | Neck | Critical hits, luck |
| **Prayer beads** | Built | Neck | Regeneration, adrenaline. The tasbih |
| **Safety glasses** | Built | Eyes | Armor, reach |
| **Gem rings** | Built | Paws | Luck, critical hits. Batu akik |
| **Rattan bracers** | Built | Paws | Armor, knockback |
| **Wooden clogs** | Built | Feet | Knockback, damage. Bakiak |
| **Fighting sash** | Built | Waist | Damage, critical hits. A silat school's |

## Dodge mutations

Up to three a run, each changing what the dodge does. Another card for one he has strengthens
it. What the dodge deals grows with damage from his gear, the same as his weapons. None is in the
cards at first: each is taught by a cat, when an area is freed. The village's edge teaches rolling
slash and land on your feet (the Elder); the deep forest, pounce and riposte (Nenek Pus); the
sawpits, the ankle cutter and caltrops (Si Belang); the logged clearing, the long leap and the dust
cloud (Jingga); the log slide, more charges and slipstream (Kopi and Susu); the offices, lick your
wounds and the scent trail (Nenek Pus again); and the airstrip, the chain roll (Datuk).

| Name | Status | Kind | What it does |
|---|---|---|---|
| **Rolling slash** | Built | Attack | The roll cuts every creature it touches, once, harder the faster he rolls |
| **Pounce** | Built | Attack | As the roll ends, he leaps onto the nearest enemy within 3 meters, led to where it will be; landing hits what's under him |
| **Ankle cutter** | Built | Attack | Rolling between a giant's legs cuts 12 percent of his full health, once a roll |
| **Land on your feet** | Built | Survival | Knocked off his feet, he rolls out of it, for free |
| **Lick your wounds** | Built | Survival | Each roll heals a little, up to 3 health a minute |
| **Shake it off** | Planned | Survival | Rolling puts out fire and sheds oil. Waits on fire and oil |
| **More charges** | Built | Movement | Another charge for each card; a rarer card brings them back faster |
| **Long leap** | Built | Movement | The roll leaves the ground, high enough to clear a rat and the chainsaw's sweep |
| **Riposte** | Built | Timing | A hit that lands while he's safe in a roll is answered at once, against everything within 0.9 meters |
| **Powder trail** | Planned | Traps | A trail that the first spark ignites, anyone's spark. Waits on fire |
| **Caltrops** | Built | Traps | The roll scatters three caltrops behind him; the first foot on each is pricked and lamed |
| **Oil slick** | Planned | Traps | Waits on oil |
| **Rescue roll** | Planned | Crew | Rolling through a downed crewmate revives them faster. Waits on downed crewmates |
| **Slipstream** | Built | Crew | Rolling past a crewmate speeds them up for two seconds |
| **Dust cloud** | Built | Control | The roll kicks up dust where it starts, and the horde in it stops to cough a moment |
| **Scent trail** | Built | Control | Where he rolls from, his scent lingers a moment, and the horde goes to it instead of him |
| **Chain roll** | Built | Movement | A kill during a roll gives back part of a charge, once a roll |

## Stats

What gear gives. A card shows the short form; holding Tab explains each one.

| Name | Status | Does |
|---|---|---|
| **Health** | Built | How much he can take before he's down |
| **Armor** | Built | Each hit takes this much less |
| **Regeneration** | Built | Health that comes back on its own, every second |
| **Adrenaline** | Built | A share of the damage he deals comes back to him as health. Grounded, not magic: it's what other games call lifesteal, and the game explains it |
| **Damage** | Built | Every weapon he holds hits harder |
| **Attack speed** | Built | Every weapon fires and swings sooner |
| **Reach** | Built | Guns reach further, blades reach longer |
| **Speed** | Built | He runs faster |
| **Luck** | Built | Rarer cards turn up more often |
| **Critical hits** | Built | A chance for a hit to land twice as hard |
| **Knockback** | Built | Every hit shoves harder |

## Buildings

The village's, every one a ruin at the start. The story brings each back, never salvage: his
home with the first cat he rescues, the rest with an area freed. Each opens what it holds.

| Name | Status | What it opens |
|---|---|---|
| **Home** | Built | His, the first house in from the forest. Fixed up by the first cat he rescues, as a thank-you. His pack: what the cards can offer, what's left home, and the piece worn from the start |
| **Smithy** | Built | Pak Besi's, back with the village's edge freed. The smith forges weapons, gear and support into the cards |
| **Huts** | Built | Five, each home to two rescued cats, who weave cloth while he's away. The first is the weaver's, Nenek Pus's, back with the deep forest freed, who sells looks; the rest the rescued cats build themselves, at 3, 5, 7 and 9 of them |
| **Longhouse** | Built | Rebuilt by Si Belang, the carpenter, back with the sawpits freed. The Elder's: a run can start with any weapon the smith has forged, and the book of stories keeps the story so far |
| **Map board** | Built | At the gate, never a ruin: the forest carved on a board and drawn as a map, each area wrecked, freed or under mist, where he chooses the next run, or Endless |
| **Well** | Idea | Water for the village; a place the cats gather and talk |
| **Watchtower** | Built | Jingga's, by the gate, back with the logged clearing freed: the map board shows each area's boss, and how to beat it |
| **Healer's hut** | Built | Bu Jamu's, back with the offices freed: a tonic for 6 salvage, and the next run starts with two more rerolls |
| **Market** | Built | Kopi and Susu's stall, back with the log slide freed: trade salvage for cloth, three for one, or cloth for salvage, one for two |

## Looks

Bought from the weaver with cloth: looks only, never stats.

| Name | Status | What it is |
|---|---|---|
| **Tompel's own coat** | Built | White, with his black ears, crown, saddle and tail, and the mole by his nose. From the start |
| **Orange coat** | Built | Free, from the start |
| **Gray coat** | Built | 6 cloth |
| **Black coat** | Built | 8 cloth |
| **Cream coat** | Built | 8 cloth |
| **Festival banners** | Built | The umbul-umbul in red, yellow, cream and teal, from the start |
| **Rhodonite banners** | Built | Pink and graphite. 10 cloth |
| **Lagoon banners** | Built | Teal, cream and blue. 10 cloth |
| **Tabby and spotted coats** | Idea | Patterns over the coats: stripes, spots, a white chest |
| **Scarf colors** | Idea | The red scarf in other colors |
| **Weapon wraps** | Idea | Cloth wound round a weapon's grip, in his colors |
| **House paint** | Idea | Each hut's walls in a color he picks |
| **Lanterns** | Idea | Paper lanterns strung over the path at dusk |

## Ideas

Anything not yet in a section above. Give each a name, the status Idea, and a line on what it
does; when it's decided, move it to its section as Planned.

| Name | Status | What it does |
|---|---|---|
| **John Whisker** | Idea | A cat in a black suit who comes out of retirement over a stolen collar. Could teach the handgun's tricks, or be met in the story |
| **Chuck Purris** | Idea | A cat of few words and many roundhouse kicks. The nunchaku's master, met somewhere in the forest |
