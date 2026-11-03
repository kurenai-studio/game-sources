# Slowblue — the whole circuit

> **Status: design intent (§1–§17) plus the log of building it (§18–§19). Not a manual
> for the game as it stands.** It is kept as a measured record, so most of its numbers
> are the ones taken when each passage was written, not today's.
>
> * **Superseded: size.** The 182 sections and ~72 minutes counted here, and the rule
>   that every act keeps its ten minutes, are the campaign as first built.
>   [DESIGN-LENGTH.md](DESIGN-LENGTH.md) measured and rebuilt it: **432 sections and 144
>   authored minutes** (about 108 as played), act I frozen at ten minutes and the other six
>   at 20.6 to 26.5.
> * **Superseded: controls.** The settings screen and COMFORT's two switches (reduced
>   motion, high contrast) that §14, §17 and parts of §18 build on were removed; the game
>   ships in English only. Those passages are history, and say so where they occur.
> * **Targets.** The web is the only target. No iOS shell or store listing exists, and this
>   document does not plan one.
> * **Current ground truth:** [README.md](../README.md) for the game as it is,
>   [IMPLEMENTATION_NOTES.md](../IMPLEMENTATION_NOTES.md) for how it is built.

This is the specification for the complete campaign, and the record of how much of
it exists. It supersedes the earlier four-act ascent memo entirely: that document
described a design with thermals, a lift field and a `Lift.ts`, and the shipped
game does not have any of those — see §4.

Read §1–§3 for what the game *is*, §4–§11 for the seven acts, §12–§17 for the
rules that cut across all of them, §18 for what was built, revision by revision, and §19 for the
one rule §12 got wrong — where the campaign saves, and what a failure costs.

## Contents

- [1. The sentence](#1-the-sentence)
- [2. The same gesture, seven consequences](#2-the-same-gesture-seven-consequences)
- [3. The circuit, and the secret](#3-the-circuit-and-the-secret)
- [4. What was cut, and why it matters](#4-what-was-cut-and-why-it-matters)
- [5. Act I — Depth (6000 m → surface)](#5-act-i--depth-6000-m--surface)
- [6. Act II — Flight (surface → 11 km)](#6-act-ii--flight-surface--11-km)
- [7. Act III — Thinning (11 km → 100 km)](#7-act-iii--thinning-11-km--100-km)
- [8. Act IV — Orbit (100 km → stable orbit)](#8-act-iv--orbit-100-km--stable-orbit)
- [9. Act V — Fallback (orbit → upper atmosphere)](#9-act-v--fallback-orbit--upper-atmosphere)
- [10. Act VI — Rain (high cloud → the sea)](#10-act-vi--rain-high-cloud--the-sea)
- [11. Act VII — Homecoming (sea surface → 6000 m)](#11-act-vii--homecoming-sea-surface--6000-m)
- [12. Rules that cut across every act](#12-rules-that-cut-across-every-act)
  - [Input](#input)
  - [Swarm and continuity](#swarm-and-continuity)
  - [Rhythm and reward, per act](#rhythm-and-reward-per-act)
  - [Act VII stops being act I with the lights down](#act-vii-stops-being-act-i-with-the-lights-down)
  - [Rings](#rings)
  - [The failure arc](#the-failure-arc)
  - [Scoring](#scoring)
- [13. The sound arc](#13-the-sound-arc)
- [14. The colour arc](#14-the-colour-arc)
- [15. Architecture](#15-architecture)
  - [The one abstraction the direction change turned on](#the-one-abstraction-the-direction-change-turned-on)
- [16. Admin and debug](#16-admin-and-debug)
- [17. Tests and acceptance criteria](#17-tests-and-acceptance-criteria)
  - [What the corridor sweep could not see](#what-the-corridor-sweep-could-not-see)
  - [Definition of done](#definition-of-done)
- [18. Implementation status](#18-implementation-status)
  - [Built and tested](#built-and-tested)
  - [What the visual review found](#what-the-visual-review-found)
  - [What the sweeps measured](#what-the-sweeps-measured)
  - [What the second visual review found](#what-the-second-visual-review-found)
  - [Whether an act can be finished, which nothing had ever asked](#whether-an-act-can-be-finished-which-nothing-had-ever-asked)
  - [What the settings review found](#what-the-settings-review-found)
  - [What the act II picture review found](#what-the-act-ii-picture-review-found)
  - [What the act III picture review found](#what-the-act-iii-picture-review-found)
  - [What the act IV picture review found](#what-the-act-iv-picture-review-found)
  - [What the act V picture review found](#what-the-act-v-picture-review-found)
  - [What the act VI picture review found](#what-the-act-vi-picture-review-found)
  - [What the act VII picture review found](#what-the-act-vii-picture-review-found)
  - [What the colour review found](#what-the-colour-review-found)
  - [Not started](#not-started)
- [19. Station checkpoints, and the act as one attempt](#19-station-checkpoints-and-the-act-as-one-attempt)
  - [The act is one attempt](#the-act-is-one-attempt)

---

## 1. The sentence

> **You do not control the creatures. You control the medium that carries them.**

One gesture, from the first frame to the last: a drag changes the medium the swarm
is in. The player never touches an individual. Everything else in this document is
a consequence.

The whole simulation is one line —

```
acc += (mediumVelocity - velocity) * coupling
```

— and `coupling` is the density of the medium. Make density a function of altitude
and the difficulty curve, the sound, the picture and the story become **the same
number**. Nothing else has to be invented: the physics writes the campaign.

## 2. The same gesture, seven consequences

| act | medium | what a stroke does | the player's verb |
| --- | --- | --- | --- |
| I Depth | water | strong, short-lived | **herd them** |
| II Flight | air | weaker, outlives the hand | **use the wind** |
| III Thinning | thin air | barely grips, lasts a minute | **wait, and choose a layer** |
| IV Orbit | none | lays gravity, not momentum | **aim ahead of them** |
| V Fallback | vacuum → plasma → air | gravity gives way to wind | **brake, and accept the medium** |
| VI Rain | cloud → rain → river | direct again, and downward | **gather them** |
| VII Homecoming | water | soft, sinking, unloseable | **let them settle, together** |

Not seven mechanics. One mechanic, seven densities. A player who has learned the
first act can play all seven; what changes is what the medium *answers*.

## 3. The circuit, and the secret

The campaign is not a climb. It is a round trip:

```
depth → sky → upper air → space → fallback → rain → ocean → depth
```

The reveal is that the player was never steering the fish. They were helping the
same **golden life-spark** along, and the thing holding it changed seven times on
the way round. The gold is the one visual constant: it is in the rescue rings, it
stays visible in every rescued group, it separates out of the old carrier at every
handover, and in the last act it comes back down to the trench floor the first
frame was shot on.

**This is told without a single line of dialogue or lore.** Movement, shape,
colour, sound and the handovers carry it. The final frame dissolves into the title
screen, and the player understands only then.

---

## 4. What was cut, and why it matters

The first act II had its own verb: a lift field, gravity, and a flock that fell out
of the sky unless the player found a thermal. It measured well and it played as a
second game bolted to the side of this one — the hand stopped steering and started
hunting for a resource.

It is gone. `Lift.ts` is gone. There is no thermal, no `gravity` scalar and no
climb-bot anywhere in the repo. Air is water with the density taken out of it, and
act I's own scripted players fly act II with nothing added and nothing told to them
about the medium. **That fact is the acceptance test for the whole approach**, not
a nice property (`tools/air.sweep.ts`).

The same rule binds every act below: a medium may change how the world *answers*
a stroke. It may not change what a stroke *is*.

---

## 5. Act I — Depth (6000 m → surface)

**Carrier:** a shoal. **Medium:** water. **Theme:** gathering and protection.

Shipped, and **frozen**. Six stations — Trench Floor, Black Water, Midnight Current, Blue
Rise, Light Line, The Surface — with their existing obstacles, rings, predators,
swarm physics, scoring and difficulty ramp.

> **This act's balance is defended digit-for-digit.** Any refactor that touches it
> must leave the sweep tables bit-identical. The `Medium` abstraction was accepted
> on exactly that condition, and so was the direction abstraction: the reference
> number is the rescue-ratio probe, which reads `1.8856146758529093` before and
> after both.

What it teaches: laying a current, holding a body of life together, optional pods
worth a detour, compulsory rings drawing the line of the course, and the surface as
the first large reward.

**Handover.** The shoal breaks the surface. The gold flashes out of the breaking
shoal and into a flock appearing above it. Continuous — never a menu.

## 6. Act II — Flight (surface → 11 km)

**Carrier:** a flock. **Medium:** air. **Theme:** freedom and separation.

Same drag, same clock. Air grips less, a laid gust outlives the hand that laid it,
birds bank and glide, clouds are real collision geometry, rotors and raptors are
hazards.

**Six stations:**

| # | station | altitude | what arrives |
| --- | --- | --- | --- |
| 1 | The Spray | 60 m | the same stroke, up here |
| 2 | The Cliff | 300 m | orographic cloud; the first rotor |
| 3 | The Cumulus Field | 1 200 m | the pass |
| 4 | The Passage | 2 500 m | cloud streets; the first raptor |
| 5 | The Squall | 4 000 m | weather, and air that turns |
| 6 | The Anvil | 11 000 m | two stooping raptors; the end of the air |

**The act ends at eleven kilometres, and that is load-bearing.** It used to run to
82 km, through the stratosphere to the noctilucent cloud. Those two stations are
still in the game — they are act III's. What was wrong was not the places but who
was in them: nothing with wings has ever flown at 82 km, because there is no air
there to fly in. A bird at the mesopause is the one image in this campaign that
would tell the player the world is made up. The anvil is where weather stops, it is
roughly where the highest bird ever recorded was found, and it is therefore exactly
where the flock has to hand over.

**Handover.** Above the anvil the air is too thin. Wings stop, the flock levels into
a glide, and it opens: the birds release the golden motes they were carrying. **The
birds do not die.** They simply cannot go on. The motes keep rising. `render/Release.ts`
already owns this film; its last movement runs into act III's first frame.

## 7. Act III — Thinning (11 km → 100 km)

**Carrier:** spores, seeds, aerosols, ice nuclei. **Medium:** thin, layered upper
atmosphere. **Theme:** letting the body go.

The verb changes for the first time since the trench floor, and it changes without
the input changing. A stroke is *small* up here — `thinCoupling` is a third of the
water's grip — and the medium is *enormous*: the upper atmosphere separates into
deep horizontal layers moving at very different speeds and in opposite directions.
A thing with no engine that gets into the right one is taken where that layer goes.

**Six stations:**

| # | station | altitude |
| --- | --- | --- |
| 1 | The Jet Stream | 11 km |
| 2 | Ozone Blue | 20 km |
| 3 | The Nacreous | 25 km |
| 4 | The Black Sky | 50 km |
| 5 | The Noctilucent | 82 km |
| 6 | The Line | 100 km (Karman) |

**The gravity wave runs on the breath.** `sim/Breath.ts` is an 11-second cycle
(5.45 breaths/min), asymmetric, resting at both turns, wall-clock, stateless. Act
III's vertical field is tied to it.

This is not a claim that mountain waves have the period of a human exhale. It is
the opposite: the breath is the only clock in the game derived from the *player's*
body rather than from the world, and act III is the act about waiting. Giving the
wait a period the player is already entrained to means the timing is learnable with
no instruction, no meter and no beat marker.

**The wave's inhale is stronger than its exhale** (`SINK = 0.32`). A symmetric wave
integrates to zero everywhere and is texture. Damped on one half of the *breath*,
a cell that rises on the inhale has *net lift in it*, and the cell half a
wavelength away has exactly as much net sink. The asymmetry is also true of the
thing being modelled — it is the entire reason wave soaring exists.

> It damps the exhale rather than the descent, and doing it the other way round
> was a real bug. "Scale down whichever way the air is currently going" damps the
> downward half of *every* cell, so the whole field came out net-lifting — and
> because the exhale is the longer half of the breath, the cells this section
> calls sinking lifted hardest of all. The field was a free elevator that paid
> best where the player was supposed to leave.

**The wave is a force, not a bonus to be surfed.** This is a correction to an
earlier claim in this document, and it was settled by measurement rather than
taste. The claim was that *the same stroke is worth more if it is made in the
right half of the breath*. It is not, and no value of `SINK` makes it so: what
the swarm feels is one velocity, `water = laid + wave`, so ground made over a
fixed time at a fixed cadence is a **linear** functional of that sum, and
correlating the player's half with the medium's half cannot change the
expectation of a linear functional. Measured over eleven seeds on a 36-section
act III — pushing with the lift cleared 20.6 sections, pushing deliberately
*against* it 21.3, ignoring it entirely 20.9; reallocating the same strokes
between the forward and lateral axes measured 21.9 against 24.5. There is no
stroke schedule that beats not having one.

> Those four numbers are kept as they were measured, on the act's length at the
> time. `tools/thin.sweep.ts` is the standing instrument and it says the same
> thing today against the twenty sections act III now has and with the sweeps'
> seeds made independent (§18): timing the strokes to the breath clears **15.6**
> sections in 300 s and ignoring it entirely clears **15.4**, a bonus of
> **1.01×**. The claim this paragraph corrects has now been false at two
> different act lengths on two different harnesses.

What the wave does instead is carry and cost: a net-lift cell really takes the
swarm somewhere and a net-sink cell really takes ground away, and that is worth
reading and worth drawing. `tests/thinning.test.ts` asserts the two facts that are
true of it rather than the one that was not.

**Bad timing must cost position and time, never life.** A player who stops moving
is a player the forced drift removes; measured, a bot that waited for rising air
made 136 px against 3357. Timing pays a bonus; it never gates progress. **No cell
may sink faster than a competent hand can climb** — the measured forward ceiling
in thin air is 57 px/s, so the deepest station's wave peaks at 46, and act III is
also the first act that restarts a station rather than ending a run (§12).

**The act's pace band is half of act I's, and it has to be.** With the forced drift
switched off, a competent hand makes 57 px/s up the course here. The first cut of
act III carried act I's pace shape straight over, so the drift ran 48–105 px/s
against that ceiling: the act was not hard, it was arithmetically impossible, and
every scripted run died `sweptAway` inside two stations however well it was flown.
`worldSpeed` is one number for the whole campaign and had never been re-derived
for a medium with a third of the water's grip carrying something with a quarter of
its drive. A mote is not a fish and cannot be chased at a fish's pace.

Ramp: **not** by narrowing. Act III's narrowest corridor is wider than act II's last
three stations. It escalates on counterflow (how hard the wrong layer takes you the
wrong way), band thinness, and the wave's authority.

Sound and picture empty out: external voices thin, and the breath becomes the main
line rather than an accompaniment.

**Handover.** At the Karman line the last air runs out. The player's first stroke
makes no wind. The motes carry on anyway, on the momentum they already had. That
teaches the new rule with no words at all. `render/Karman.ts` is that film, and
it is the only one in the game built out of an absence: the ice act III was
flying in stops dead mid-drift when the air gives out, the game's own hint arc is
drawn across the frame and nothing answers it, and the swarm crosses it without
bending at exactly the speed it already had.

## 8. Act IV — Orbit (100 km → stable orbit)

**Carrier:** golden motes. **Medium:** none; gravity becomes the medium.
**Theme:** letting go, and perspective.

**Stations:** Free Fall → The Aurora → The
Umbra → The Debris Belt → The Well → **The Overview**.

A touch or drag lays a **gravity gradient** — a short-lived well — instead of
momentum. Motes move ballistically. No drag, no coupling; momentum is preserved. A
bad stroke is correctable, but not immediately, and that lateness is the act's
subject. The input change is taught by visual response, never by tutorial text.

**The verb is aiming, not releasing.** This is a correction to an earlier claim in
this document, and it was settled by measurement rather than taste, exactly as
§7's was. The claim was *start it, then let go*: that a well laid a long way ahead
and then left alone is how act IV is flown. It is not, and no amount of patience
makes it so. `tests/bot.ts` grew `makeOrbitBot` specifically to play that sentence
— read the swarm's velocity, lay a well well outside its own radius, then wait —
and over eleven seeds in 300 s it cleared **2.3** of act IV's sections against a
bot that simply pushes whenever it has fallen behind, which cleared **8.1**.
Worse, the finding is monotone in the wrong direction: at a 460 px lead and 1.3 s
between strokes — the purest form of letting go — the same bot clears **0.0**, and
shortening the lead and stroking more often improves it all the way. There is no
stroke schedule that beats aiming close and often.

What is actually different about act IV is *when* a stroke has to be made rather
than how often. A current moves a body inside a second; a well bends a trajectory
over ten, so the swarm arrives late, sideways, and long after the hand that sent
it. That is a real verb, it is the one §8 has always described in prose, and it is
what the act-select screen now says: **aim ahead of them**. `tools/space.sweep.ts`
keeps `orbitFar` in its style list as the control, because "the let-go ratio" is a
standing fact about this act and not a target to be tuned green.

Hazards: electric and magnetic arcs in the aurora; reduced visibility in the umbra;
slow-moving debris; gravity nodes; **orbital gates that ask for an arc rather than
for aim**.

**No classical game over.** A scattered swarm, a missed node or a bad trajectory
returns the player to the start of the station, and costs time and score.

**The Overview is the emotional peak of the whole story.** The camera turns for the first
time. The whole Earth appears. The entire atmosphere — everything the game has ever
happened in — resolves into one bright line a few pixels thick. Motion stops. Only
the breath and a very fine internal tone remain. **No results screen arrives.**

**Handover.** The motes' trajectory bends back toward Earth. After the camera turn,
the campaign's direction turns with it: from here the game runs downward.

## 9. Act V — Fallback (orbit → upper atmosphere)

**Carrier:** meteor dust forming out of the motes. **Medium:** vacuum → plasma →
thin air. **Theme:** transformation.

**Stations:** The Deorbit → The Night Side → Aurora →
The Plasma → The Meteor Dust → The Nucleus.

The first station is still dominated by the orbital potential input. Going down,
drag appears and grows. **The input blends continuously between gravity-based and
momentum-based behaviour** — never a switch. The player has to slow the swarm
without scattering it. The danger is not primarily death: it is excessive scatter
and a bad entry angle.

By the end of the act the glowing dust cools and becomes a condensation nucleus —
which is what every noctilucent cloud on the planet is actually built on, and is
why act III's fifth station foreshadows this one.

## 10. Act VI — Rain (high cloud → the sea)

**Carrier:** ice crystals, then droplets, then one joined body of water.
**Medium:** cloud, wind, gravity, running water. **Theme:** reunion.

**Stations:** Cirrus → Under the Anvil → The Downpour
→ Lombkorona (The Canopy) → Hegyipatak (The Mountain Brook) → Torkolat (The Estuary).

Scattered ice crystals merge into droplets. **The rescue-ring system takes a new
meaning: the rings gather scattered droplet groups back.** Growth here makes the
group more stable and heavier to steer. Wind dominates in the cloud, gravity in the
downpour, current in the brook. Canopy, branches and stones are readable organic
obstacles. In the river the separate drops visibly become one flowing community.

Under the Anvil is the same cloud act II climbed over, seen from below — the first
moment the campaign lets the player recognise somewhere they have been.

**Handover.** The river reaches the estuary. Where fresh water meets salt, the gold
reappears as small living forms: plankton and larvae.

## 11. Act VII — Homecoming (sea surface → 6000 m)

**Carrier:** plankton, larvae, marine snow. **Medium:** water again.
**Theme:** homecoming, and the circle.

**Stations:** The Salt Line → The Sunlit Zone → The Twilight Zone → The Deep Sea → Marine Snow →
The Trench Floor.

**This is not act I reversed.** The carrier drifts rather than swims. Currents work
downward and sideways. Hazards thin out and stop. Music and external sound return,
simpler and calmer than before. **The second half of the act cannot be lost.** The
last station has no score chase and no hard obstacle.

**Finale.** The last golden motes reach the trench floor. Small fish gather around
them. Out of the light the first shoal forms — act I's opening. The camera and the
background dissolve imperceptibly into the title screen. Only now does the player
fully understand that they did not play a one-way ascent but a circuit.

It is the longest sequence in the game, and the length is the point: this is the
only ending that has a whole journey behind it rather than a leg. Two of its seven
movements exist for that alone. **Remember** comes after the gold has landed and
before the first fish, and it is the campaign told back — six faint echoes, one per
act, each a gesture quoted from that act's own ending film but repainted in the
trench's violet, because a memory down here is lit by the trench and not by the sky
it happened under. They are placed along the circuit's own rise and fall, so the
shape of the journey is drawn in nothing but where things are, and the seventh
memory is deliberately not drawn: act VII is the room the player is sitting in.
**Vigil** comes after the shoal is one body, and it is the ritual of closing — the
carried light put down in three deliberate steps, the last grain of marine snow
answering the first, and one more fish setting out from the dark to arrive during
the held frame, because act VII's own sentence is *nothing hurries you down here*
and the ending has to keep it too.

Nothing in either movement brightens the trench, moves the camera, or asks to be
looked at. The grandeur is duration and meaning; the picture stays the darkest in
the game, because it still has to become the title screen without a cut.

After the full campaign, these unlock: **continuous circuit mode**,
**per-station replay**, and the **best score and preserved mass for the whole
journey**. Entering the circuit at an act is not one of them and never was — an
act is open once the player has *arrived* at it, which is a record of where the
journey has been rather than a reward for finishing it.

---

## 12. Rules that cut across every act

### Input
- Single-finger drag is the primary input on mobile, throughout.
- Mouse and keyboard work on desktop.
- **No per-act buttons.** The same gesture always modifies the local medium.
- The player learns the new rule from the visual response, never from text.

### Swarm and continuity
- The active group's size and the amount of rescued life **carry between acts**.
- The carrier's visual form may change; the gold motif and the continuity of mass
  may not.
- Visual population scaling is permitted where needed, but campaign state must
  preserve the true amount.
- `MAX_AGENTS` stays a hard performance ceiling.

### Rhythm and reward, per act

This is a correction to what §2 implied, and it was settled by reading the seven
level files rather than by taste. "One mechanic, seven densities" is the thesis
and it holds. What did not hold is that it was being carried by the *alphabet*
alone: every act had shapes nobody else could use, and underneath them all seven
were laid on the same 820 px section spacing, closed every station on the same
empty breath, and put **92 of the campaign's ~100 obstacle sections' compulsory
ring on the section's own centre line, 185–265 px behind it**. The two things a
player answers every ten seconds — how often the world arrives, and where the
reward is — were the two things that never varied.

They are per-act now. Neither needed engine work: `spacing` is already a
per-section field and a ring is already an authored position.

| act | rhythm | reward |
| --- | --- | --- |
| I | the metronome. **Frozen**, and it is the reference the others are heard against | one ring, on the line |
| II | legs and rests — a weather system, then a crossing | inside the corridor it asks you to hold |
| III | the drift opens the station; the decisions close it, 420 px apart | wide, rare, and at the door you chose |
| IV | gravity clusters: a long fall, then two wells 320 px apart | never on the line you are already on |
| V | contraction, to 560 px in the plasma — `mediumTo` drawn in pixels | two rings on one line: the act that pays for width |
| VI | squalls — 380 px, then 1400 | a run of three, in sequence: gathering as a phrase |
| VII | dilation, monotone, to a stop | fewer, wider, and it stops where the failure mode does |

**Each act keeps its ten minutes.** An act's duration is its summed spacing over
its mean pace, and redistributing the ten minutes is the whole licence here.
`tests/descent.test.ts` sums the *authored* spacings rather than assuming a flat
845 px, which is both the honest arithmetic and the only version of that check
that can still fail now that an act is free to choose its own gaps.

> **Superseded:** this holds for act I only. The other six acts were rebuilt to 20.6
> to 26.5 authored minutes ([DESIGN-LENGTH.md](DESIGN-LENGTH.md) §11), and
> `tests/descent.test.ts` now holds act I to 7-12 minutes and the others to 19-27.
> What survives is the licence: an act's rhythm is its own, and act I is the metronome.

**Act I is deliberately not in this.** It is frozen (§5), it is the tutorial, and
it is the origin of the shape rather than a copy of it — a rhythm needs something
regular to be heard against. `tests/geometry.test.ts` asserts exactly that: act I's
spacing spread stays under 400 px and every other act's exceeds it.

### Act VII stops being act I with the lights down

The act's own file opened by insisting **this is not act I reversed** and was then
authored end to end out of the trench's rock: four gates, a rock, a narrows and a
vortex. The rule every other act was held to — a medium never borrows another
medium's silhouettes — was waived here on the technicality that water is water.
The technicality is true and the result was still that the last act of the journey
was the first act of it with the lights down.

Below the sunlit zone almost nothing in the ocean is hard. So act VII has two
shapes of its own, and both are bodies: a **siphonophore**, hanging in strands
*along* the course with real water between them, and a **bloom** of medusae —
seven bells with more open water in it than body, deliberately not in `SPLITTABLE`,
because the swarm is meant to drift through it rather than split on it.

**Nothing in act VII closes the course.** That is the act's rule and the point of
the act. One stone is left, at the salt line, where act VI's brook arrives — so
the act reads in its material alone: stone, then jelly, then nothing.

### Rings
- Optional and compulsory rings both remain in the early acts.
- A compulsory ring is always on the flyable line of the course.
- The penalty softens with altitude.
- In space and on the way back, a miss causes a checkpoint restore or score loss —
  never a campaign-ending failure.
- Rings adapt visually to each carrier; the gold stays common.

### The failure arc

| act | what can end a run |
| --- | --- |
| I | `depleted`, `sweptAway`, `ringMissed` |
| II | `depleted`/fall, `sweptAway`, `ringMissed` |
| III | checkpoint setback and falling behind; hard failure is rarer |
| IV | no permanent game over |
| V | scatter or a bad entry causes a station reset |
| VI | a light checkpoint system |
| VII (second half) | nothing at all |

> **Superseded by §19:** the table is the failure arc as first designed, in which acts
> I and II ended the run. Every act restarts the station now (`sim/Failure.ts`), a
> budget of restarts per act attempt ends the attempt rather than the campaign, and
> only act VII's last three stations remain unloseable.

**The game gets quieter on the way up and fills with sound again on the way back.
The difficulty peak is not the finale. After the Overview the game is about resolution.**

The campaign's peak is act II's **Anvil**, measured rather than assumed: ten demands
a minute, eleven seconds per compulsory ring, a 0.28 aperture, a rotor and two
raptors, and the last failure policy in the game that can end a run. The peak of the
*descent* is act V's Plasma station, which is what §9 means and is second in the campaign
by the same measures. Both files used to claim the superlative outright and act VI's
The Downpour claimed it too, at the identical pace; the pace band separates them now
and each claim is scoped to what it is true of.

### Scoring
- Distance, rescues, gates, headcount and cohesion all stay.
- Per-act score **and** a whole-campaign score.
- The streak rewards holding the group together, not merely surviving.
- In the later, unloseable acts, skilful play is paid in time, score and preserved
  mass.
- **Runs started from the admin surface never touch personal records.**

## 13. The sound arc

```
bubble → wing → thinning wind → breath and silence → inner rumble → rain → river → bubble
```

- The 11-second breath is present throughout.
- Act III's gravity wave is locked to it.
- **In space there is no conventional external sound** — only breath, heartbeat and
  a very fine internal resonance.
- Plasma and re-entry may be louder, but must not break the meditative character.
- The finale returns to act I's bubble voices.

## 14. The colour arc

```
violet-black depth → blue and turquoise surface → bright sky → darkening upper air
→ black space → gold and plasma → grey-blue rain → river green → ocean blue
→ violet-black trench
```

- The screen stays clean and HUD-poor.
- Narrative handovers matter more than menus.
- No long text interstitials.
- Carrier silhouettes must differ unmistakably.
- The golden life-spark is every act's visual link.
- **Reduced motion, high contrast and the quality setting must work in every new
  renderer.**

  *Since then:* the first two settings were removed with the settings screen they sat
  on, and quality is no longer asked for: `adaptQuality` in `src/main.ts` measures the
  frame rate and picks the rung (README, "Where the controls are"). The requirement as
  written no longer applies; §18 records the work it caused.

## 15. Architecture

Reused unchanged: `FlowField`, `SpatialHash`, `SwarmSimulation`, `RunState`,
`RescueSystem`, the `levels.ts` format, `Stone`/`RockPaint`, `Breath`, the
`AudioEngine` track architecture, `Whirl`, and the corridor flood-fill in
`tests/course.ts` — which stays true in any medium.

Required extensions:

| # | thing | state |
| --- | --- | --- |
| 1 | campaign state: act order, checkpoints, automatic handovers, save/resume, whole-campaign result | **built** |
| 2 | direction-agnostic course handling: `Act.direction`; camera, progress, spawning, pruning, straggler culling and section crossing in both directions, behind one shared course-direction abstraction | **built** |
| 3 | new medium configurations: water, air, thinAir, space, plasma/reentry, cloud, stream | **built** |
| 4 | layered atmospheric flow: bands at different speeds, breath-synced vertical wave, tracers visible in the renderer | **sim built, renderer pending** |
| 5 | potential/gravity field for the space input: deterministic, replay-compatible, debug-overlayable | **sim built, overlay pending** |
| 6 | input-mode blending between potential and momentum on re-entry, continuous | **built** (`Medium.vacuum` + `Level.mediumTo`) |
| 7 | new carrier renderers — motes/spores, ice crystals/droplets, plankton/marine snow — sharing one `SwarmSimulation`, with shape a render-side decision | **built** (`render/Carriers.ts`) |
| 8 | seven transitions: water→birds, birds→motes, atmosphere→space, orbit→descent, dust→cloud, rain→sea, trench→title | **all seven built** (`Surfacing`, `Release`, `Karman`, `Overview`, `Nucleus`, `Estuary`, `Circle`) |
| 9 | versioned profile migration: no data loss, act unlocks, checkpoints, admin jumps never recorded | **built** (v2) |

The state column is as written in the first revision. Rows 4 and 5 still say "pending";
they have not been re-audited against the renderer and the debug panel since.

### The one abstraction the direction change turned on

`World.u(worldY)` is the **course coordinate**: larger is always further ahead. Four
acts climb and three fall, and the difference is exactly one sign. Written as
`if (descending)` it would be one sign in about twenty places — camera follow,
section crossing, three prunes, straggler cull, strand line, spawn line, re-form
window — and the failure mode of getting one wrong is not a visible bug. It is a
course that deletes itself in front of the player, on one act, in one direction,
silently.

## 16. Admin and debug

- All seven acts selectable.
- Every station and every section individually startable.
- The correct medium, carrier, palette and direction load with it.
- Debug overlays for the potential field and the layered flow.
- Handovers triggerable directly.
- Every new sound auditionable.

## 17. Tests and acceptance criteria

### What the corridor sweep could not see

The sweep carries a set of reachable x cells down the course and intersects it
with what is open. For six acts that was the whole question, because every
archetype in the game was a row laid *across* the course: the reachable set was
essentially one run of cells, so "is this ring reachable" and "is this ring
reachable by the body that took the last one" were the same question.

They are not the same question, and measured, they had already stopped being one:
**act I's reachable set is in more than one piece on about a tenth of its slices.**
Nothing had exploited it, so nothing had failed. A second check now seeds the sweep
at each compulsory ring in turn and carries it forward to the next, which is the
question the player actually asks. It found one real break the first time it ran —
act VI's Anvil station, where a 480 px gap left 75 px of course in which to cross
172 px of field between two compulsory rings — and that gap is now 1250.

Three more invariants came with it, all cross-act, all previously true by accident:

* **No section's geometry may reach more than 220 px past its own scoring line.**
  `prune` drops a section on its line, and the prune line sits about 236 px behind
  a swarm that is keeping up — so anything further forward stops colliding while it
  is still in front of the player. The deepest reach in the campaign is 180 px.
* **No ring, compulsory or optional, may sit inside an obstacle**, in any act. Act
  I has asserted this since the authored campaign existed and no other act did,
  which was survivable only while every act put one ring per section on that
  section's own centre line.
* **Every act authors only its own alphabet**, from one allow-list table. This was
  three hand-maintained deny-lists covering acts II, III and IV; acts V, VI and VII
  had none at all, which is exactly why they were the three biggest borrowers.

The sweep also reports the narrowest that the widest reachable run ever gets. It is
printed rather than bounded, because the sweep samples points and a shoal is about
150 px across: act I reads 64 px, act III 60, act VII 76. That number is how much
of the approval is real.


Existing tests stay green. New unit, simulation and e2e coverage is required for at
least:

- act I's balance does not move materially
- no bird appears above 11 km
- The Nacreous and The Noctilucent are part of act III
- every authored section of all seven acts builds
- every compulsory objective is reachable from a flyable route
- progress/prune logic is correct on both ascending and descending courses
- an act transition preserves campaign score and cargo count
- after save/reload the correct checkpoint resumes
- the space medium has no drag or coupling
- the potential field is deterministic and gives a correctable trajectory
- the potential→momentum blend is continuous through re-entry
- in act III, timed play beats passive play
- in every act a competent bot beats a passive one
- acts IV–VII cannot cause a permanent campaign game over
- the whole campaign is playable end to end
- the finale returns to the trench floor
- at least 30 FPS on a mobile viewport under load
- reduced motion and high contrast work in every new scene (*since then: withdrawn
  together with the settings; see §14*)
- an admin-started run modifies no record

**Balance is set by measurement, not by feel.** Sweep tools are required for the
thin-air, space, re-entry and descent systems, alongside the existing water and air
sweeps.

### Definition of done

The title screen starts the full seven-act campaign; the two existing acts continue
naturally into the new content; every handover works; the campaign saves at act
boundaries and can be resumed; every act is replayable on its own; the narrative
circle closes at the trench floor; the visual and audio arcs are consistent; there
is no placeholder or half-finished screen; `README.md` and this document match the
actual game; and `npm run verify` passes.

---

## 18. Implementation status

This section is a chronological log. Each paragraph describes the build at the revision
that wrote it, so section counts, test counts and bot results in it are historical; where
a later change made a passage false, it carries a *Since then* or *Superseded* note.

### Built and tested

**The direction spine.** `Act.direction`, `World.u()`, `anchorFraction`,
`behindFraction`, `buildLine`, `behindLine`, `Section.entryY`/`exitY`, and
direction-aware `prune` on the rescue, current, predator and potential systems.
`ObstacleSystem` authors every offset through `back()`/`fwd()`, so a descending act
is written in exactly the same grammar as an ascending one. Proof:
`tests/direction.test.ts` plays act I's own levels downward.

**Act I is unmoved.** The rescue-ratio probe reads `1.8856146758529093` before and
after the refactor.

**The medium table.** `sim/Medium.ts` resolves all seven kinds. `vacuum` is the one
number carrying act IV: a stroke lays that fraction of itself as potential, the
swarm's steering stops acting as an engine in that proportion, and `blendMedium` +
`Level.mediumTo` interpolate it across a station.

**The potential field.** `sim/PotentialField.ts`, `SwarmContext.accel` (applied after
the mass divisor — gravity does not care how much you carry), and the ballistic
swarm mode. `World.injectStroke` splits every stroke by `vacuum` with no branch on a
mode.

**Layered flow.** `sim/LayeredFlow.ts`: repeating wind bands with blended
boundaries, and a breath-synced gravity wave whose rise is stronger than its fall.

**Campaign spine.** `config/campaign.ts` (act registry), `meta/Campaign.ts`
(checkpoints, cargo carry-over, population scaling under `MAX_AGENTS`), and profile
**v3** with a non-destructive migration at every step — v1's act I stations and v2's
reached act both survive into the station record the map is drawn from.

**Palettes.** `config/zones.ts` rebuilt: 40 bands across seven acts, indices stamped
rather than hand-maintained. `tests/zones.test.ts` asserts the light goes out
continuously from the wave tops to the Karman line, and that the last band of act
VII is the first band of act I.

**Act II re-cut.** Six stations ending at the anvil; the Cliff and the Passage added;
The Nacreous and the Noctilucent moved to act III.

**Act III.** `config/thinning.ts`, six stations, its own ice alphabet
(`veil`/`column`/`throat`/`flurry`/`eddy`/`shear`) with geometry in
`ObstacleSystem`, `THIN_MOTIFS`, and `tests/thinning.test.ts`. The corridor sweep
passes; a competent bot clears **15.6** of the act's twenty sections in 300 s
against a passive bot's 1.0, and finishes all twenty on **11/11** seeds when
given the act's own clock. (This read 20.8 while act III was 36 sections long;
the number survived the length re-cut below without being re-taken, which is
exactly the kind of rot the re-measure was for.)

**The failure arc, as code.** `sim/Failure.ts`: `FailurePolicy` on the act and an
optional `Level.failure` override, with `World.endOrRestart` and
`World.restartStation` behind them. As shipped in §12 this was three answers: acts
I and II resolved to `END_ON_FAILURE` and were byte-for-byte unchanged, acts III–VI
restarted a station for time and a sixth of the banked score, and act VII's last
three stations could not be lost at all. **§19 collapses the first two into the
third** — every act restarts the station now, and `END_ON_FAILURE` is left for the
generated water the probes measure on. Act VII's `'none'` stations are untouched.
`RunState.furthestSection` is the progress metric that survives a restart honestly
— `distance` freezes across one and `gates` double-counts a re-flown section.

**Act III's balance, re-derived.** The act was arithmetically unplayable: the
forced drift ran 48–105 px/s against a measured 57 px/s forward ceiling, so every
scripted run died `sweptAway` inside two stations however well it was flown. Pace
is now 0.36–0.46, `SINK` is 0.32 and damps the *exhale* rather than the descent,
and the wave amplitudes are capped so no cell sinks faster than a hand can climb.
See §7; `tools/thin.sweep.ts` is the instrument.

**Acts IV–VII, complete.** `config/orbit.ts`, `config/reentry.ts`, `config/rain.ts`
and `config/homecoming.ts`: twenty-four authored stations, every one of them with
its corridor sweep and reachable-ring check green (`tests/orbit.test.ts`,
`tests/reentry.test.ts`, `tests/descent.test.ts`). Two new alphabets — orbit's
`arc`/`hulk`/`strait`/`shrapnel`/`node`/`flare` and rain's
`downpour`/`canopy`/`boulder` — plus re-entry's three (`shock`/`plume`/`sheet`; a fourth, `ember`, came with the length
rebuild),
all with geometry in `ObstacleSystem`. Act V and act VI deliberately share
vocabularies with their neighbours, because they *are* the handovers.

**Standing gravity.** `Section.wellHints` and `Well.standing`: act IV's `node` is a
gravity well the level author placed, summed by the same field and drawn from the
same profile as one the player's hand lays. It never decays and can never be
evicted by scribbling.

**All seven backdrop sets.** `Sky.ts` gained the Cliff and the Passage; `Upper.ts`,
`Orbit.ts`, `Reentry.ts`, `Rain.ts` and `Homecoming.ts` are new, and `SkyParts.ts`
holds the four primitives acts II–V share so the seam at 11 km cannot show.
**Forty-two stations, forty-two distinct backdrops**, asserted.

**The carriers.** `render/Carriers.ts`: the five that are not animals — motes,
lights, dust, droplets, plankton — as five ways of being a particle rather than
five species. `Renderer.drawAgents` branches on `Act.carrier` rather than on the
medium, which is where the campaign's secret actually lives.

**Act I is unmoved, and it is now locked.** `tests/playability.test.ts` asserts the
rescue-ratio probe equals `1.8856146758529093` to nine places — it is act I's
physics canary rather than a design claim, and the design claim it used to carry
has moved to the authored campaign where it holds (1.12× the fish for 0.8 fewer
gates, score flat at 1.01).

**The circuit runs.** `main.ts` holds a `CampaignController` resumed from the
profile, `startRun` plays whichever act it names and opens on what the last one
handed over, and a completed act inside a live campaign **never reaches the
results screen** — the film plays to its own end and the next act begins. The
seventh closes the circuit, banks it and returns to the title. Saves were written
at every act boundary when this was built and are written at every *station*
boundary now (§19); the `?act=` door and the admin surface are excluded from all
of it, so a jump still touches no record. `tests/circuit.test.ts` covers the state
machine end to end.

**The admin surface reaches all seven acts**, because it reads `CAMPAIGN_ACTS`
rather than a hand-maintained list.

**The camera turn.** `render/Overview.ts`: act IV's ending, and the only sequence
in Slowblue that moves the frame. Five movements — the drift stops, the camera comes
off the direction of travel and the limb *tilts*, the horizon closes into a whole
Earth, the atmosphere brightens to a line about four device pixels thick while
everything else dims, and the gold reaches the top of its arc, stalls, and leans
over toward the disc. That stall is the handover: act V opens into the fall the
player watched begin. Reduced motion drops the roll and keeps the picture, because
the rotation is the only vestibular element and the composition is what the
rotation was for. *(Since then: the reduced-motion setting is gone, so the roll
is always played.)* `tests/overview.test.ts`.

**All seven endings exist, and the seam is never a cut.** `render/Films.ts` maps
an act to its ending and defines the one shape they share — `veil`, `settled`,
`daylight`, `anchor`, `handedOver` — which is a *shape* rather than a base class:
the films share no drawing code at all, deliberately, so a change to act II's
ending can never silently redraw act IV's. `Renderer` holds the seven in one
table, because the seam between "the film exists" and "the renderer knows about
it" is exactly where an ending goes missing, and it went missing once already.

The four that were added last are each built on one fact:

> **`Karman` (act III → IV): the stroke that does nothing.** The only film in the
> game made out of an absence. The ice act III was flying in stops dead mid-drift
> when the air gives out; the game's own hint arc — the same shape, in the same
> colour `Renderer.drawHint` has drawn since the first thirty seconds of act I —
> is drawn across the frame and nothing answers it; one puff of the last air dies
> inside half a second; and the swarm crosses the whole thing without bending, at
> exactly the speed it already had. There is no acceleration term anywhere in the
> function that draws it. Act IV opens into that coast.
>
> **`Nucleus` (act V → VI): the gold comes back out of the fire.** The trails
> retract because the grains braked, not because anything switched them off — the
> streak is the distance covered in the last tenth of a second and the brake
> curve is one exponential. Then the white goes to orange, the orange to ash, and
> what is left glowing inside each grain is the gold, which was in there the whole
> time. §3 says the golden life-spark is the campaign's one visual constant; act V
> is the only act that could have made a liar of that.
>
> **`Estuary` (act VI → VII): the first thing in six acts that moves itself.**
> Fresh water is lighter than salt and rides over it, so the sea arrives as a
> wedge from underneath rather than as a colour change, and the boundary is a real
> surface drawn with three traces. Then the gold cores leave their droplets and
> start to swim — plankton with cilia and larvae with beating tails, on their own
> clock, added on top of the drift so the two motions are legibly different
> things.
>
> **`Circle` (act VII → title): the last sentence.** Painted out of `v.paint`
> rather than out of constants, because act VII's last band and act I's first are
> the same four colours; traced with `FishShapes`, which is act I's own outline;
> and landing exactly on `#f0e7ff`, act I's cold shoal, as the campaign's warm
> light goes out of it. The marine snow stops, the trench floor arrives from
> below, the fish come out of the dark one at a time and turn around the gold, and
> then they are one body going one way. It is the only film that hands over to
> nothing.

Each exposes `handedOver` on its own timeline. Three bugs closed together:

> The dispatch was `if (air) release else surfacing`, so **every act with no film
> of its own played act I's** — finishing act III broke an ocean surface, with
> caustics and spray and daylight, eighty kilometres above the sea. An act without
> a film now gets silence.
>
> The handover was a `setTimeout` in wall-clock seconds against films advanced by
> `frameDt`, which is a fixed step plus the frame's cost. The two clocks differ by
> about 1.5×, so the next act opened while the film was still running on a fast
> frame and left a held frame on screen for seconds on a slow one. `main.ts` now
> waits for the film rather than counting at it, and the end-to-end circuit e2e
> dropped from 42 s to 28 s of real time — all of it dead waiting.
>
> The closing banner read **MISSION COMPLETE** at the end of every act, which
> inside a seven-act campaign is a lie told six times. `Renderer.finale` is true
> only for the last act of a circuit, or for an act played on its own.

**Endings speak their own act's language.** `i18n/strings.ts` gained `ActEndings`,
seven acts × two endings (the game ships in English only). There were two, chosen by a boolean, and
five acts arrived behind them: the shipped build told a player who had just turned
the camera at 460 000 m that they had broken through the waterline. Act II's copy
is corrected in the same pass — it still claimed 82 km and the last noctilucent
cloud, which was true of the act that used to run to the mesopause.

**Act select, and the circuit's own results screen.** `Shell` draws the seven acts
with their numeral, name and verb, open as far as the player has reached; the
title screen's first button says *continue* when there is a circuit to continue,
and names where it is. The seventh act's results report the journey — banked
score, carried life, circuits closed — rather than the leg.

**The map.** The act list is gone; one screen replaced it, **The
Circuit**, and the screen is §3 drawn. `meta/Circuit.ts` places all forty-two
authored stations evenly around one closed ring and cuts it into seven bands, and
`Shell` draws it as SVG — each band in outline, the part of it that has been
flown lit over the top, a filled mark per cleared station, and one bright point
where a put-down circuit is sitting. Where the ring starts is where it ends,
which is the whole of §3 and needs no copy. Altitude is not drawn and does not
have to be: the campaign climbs for four acts and falls for three, so play order
alone puts the trench at the bottom of the circle and orbit at the top.

The half of it that could not be built from what the profile stored is *what is
left*: `unlockedAct` answers where a player has been and nothing answered what
they had finished. Profile **v3** adds a per-act high-water mark of stations
cleared, written from `run.level` — the furthest station reached, not a count of
clears, so an act III retry cannot claim ground twice. The migration is an
inference rather than a reset, and a defensible one: `unlockedAct` can only ever
be raised by `advance`, so a v2 profile naming act V finished four acts and the
map says so. `tests/ring.test.ts` (since deleted, in `5957a92`) asserted the shape — that every station is worth
the same forty-second of the journey, that the step after the last one lands back
on the first, that the seven bands tile the circle with seven equal gaps, and
that the act the campaign turns over on hangs at the top of the dial.

The one thing it deliberately is **not** is a level select. Playing enters the
circuit at the selected act from its first station, exactly as the list it
replaced did; the six stations the selected act names are placed and none of them
is a button. The campaign checkpoints at station boundaries (§19), but a
checkpoint is where a circuit *resumes* rather than a station that can be entered
out of order (`meta/Campaign.ts`). Acts nobody has reached draw their band on the ring — the
title screen has always promised the circuit in words — but stay unlit and their
stations unnamed, because the promise is not the visit. What is new is that
pressing a marker only moves the middle of the dial: seven markers on a circle
are seven small targets, and a small target that starts a run on first touch is a
small target that ends someone's circuit by accident.

**`npm run verify` passes end to end**: lint (0 errors), `tsc --noEmit`,
`vitest run` (556 tests in 45 files at the time; CLAUDE.md counts 790 now, in 72 files), `vite build`, and 28 Playwright specs
including one that flies all seven acts through the real shell and closes the
circuit (`e2e/campaign.spec.ts`), one that shoots all forty-two stations, one
that shoots every movement of all seven endings, and one that measures the
station banner's contrast on all forty-two with high contrast on
(`e2e/acts.spec.ts`; that last one went with the setting).

**...and it leaves the tree clean, which it did not.** `e2e/capture.spec.ts` is
two things at once — a smoke test for mid-run rendering, and the only thing that
regenerates the twelve numbered screens the README shows — and only the first
belongs in a verify. It rewrote all twelve every run, so a verify that changed
nothing still left twelve modified binaries behind and put them in the next
diff. The smoke test still runs every time; the *writing* waits to be asked, and
`npm run screens` asks. Every other screenshot in the repo was already
gitignored review artefact; these twelve are tracked, which is exactly why they
must not move on their own.

### What the visual review found

Every station of every act was looked at, station by station, in a browser. Four
defects that no test had any reason to catch:

1. **The carrier's halo was a disc, not a glow.** One flat-filled circle per
   individual: invisible over water and sky, and a hard-edged brown plate around
   every mote over the black of act IV. Now three concentric batched fills at a
   third of the alpha — a stepped falloff, three fills per faction rather than
   three per *agent*.
2. **Seagrass in vacuum.** Every decor theme in the game was a sea theme, so the
   new acts were authored with `meadow`, the default, and shipped growing sea
   fans at 82 km, bubbles in orbit and an 8 %-per-band chance of a leviathan
   crossing a re-entry plasma sheath. Three new themes: `void` (nothing grows —
   acts III, IV, V and act VI's sky), `canopy`, `stream`. `tests/decor.test.ts`.
3. **The Canopy was one flat green field.** Every element drew correctly at about
   two levels of contrast, because `leaf` was mixed out of the background's own
   mid-tone. A canopy from underneath is dark, and the shafts of light between the
   leaves need something dark on both sides of them to be shafts.
4. **Two acts said they were somewhere they were not.** The station banner's
   range form (`X → 0 M`) was keyed on "is this the act's last station", true of
   act I and nothing else — so act VI's estuary printed a raw `-400 → 0 M` and
   act VII's trench floor, six thousand metres *down*, announced that it was going
   to zero. `stationDepthLabel` now lives in `config/levels.ts` where it can have
   a test.

`src/render/LevelArt.ts` was deleted in the same pass: entirely unreferenced,
superseded by `Motif.ts`, and the only thing standing between the decor themes and
a clean type check.

### What the sweeps measured

`tools/space.sweep.ts` and `tools/descent.sweep.ts` are written, and the answer
they give is not the one §18 expected.

**Act IV's reading is real, and it is not the instrument.** The suspicion was
that `makeAimBot` is the wrong player for vacuum — it pushes when it has fallen
behind, which is a late correction with an instrument that acts late. So
`makeOrbitBot` was written to play the act's own stated verb: lay a well a long
way ahead, then let go. Re-measured at the shipped `potentialStrength` of 300,
eleven seeds, 300 s:

| style | lead | seconds between strokes | sections |
| --- | ---: | ---: | ---: |
| `aim` — push whenever behind | — | 0.4 | **8.1** |
| `orbitNear` | 150 | 0.5 | 4.0 |
| `orbit` | 300 | 0.9 | 2.3 |
| `orbitFar` | 460 | 1.3 | **0.0** |

Monotone, and monotone the wrong way for the design: the more the bot lets go,
the less ground it makes, and the purest form of letting go makes none at all in
five minutes. **The act's verb has been corrected to what it measures** — *aim
ahead of them* — rather than the number tuned toward the sentence. Same finding,
same shape and same resolution as act III's gravity wave in §7. See §8.

> These four numbers were 10.2, 3.0, 2.0 and 0.0 two revisions ago against the 36
> sections the act had then, and 9.2, 4.0, 2.3 and 0.0 one revision ago against
> the 18 it has now. This is the first reading taken with **independent seeds**
> (below): only `aim` moves, 9.2 to 8.1, which is what a bot carrying its stroke
> phase from one seed into the next was worth. The finding is the ordering, and
> the ordering has never moved through any of it.

**What act IV is short of is pull, not patience.** The well grid, eleven seeds,
240 s, sections reached by the best style:

| `potentialStrength` | half-life 1.6 | 2.6 (shipped) | 4.0 |
| --- | ---: | ---: | ---: |
| 150 | 4.5 | 5.1 | 5.2 |
| 210 (was) | 5.5 | 5.1 | 6.1 |
| **300 (now)** | 7.1 | **8.0** | 7.3 |
| 420 | 9.4 | 9.4 | 9.8 |

Half-life barely moves it: the whole spread across a two-and-a-half-fold change
in it is smaller than one step of pull, and at 150 and 210 the act cannot tell
the two pulls apart at all. 300 is the shipped value; 420 is not, because past
about there the swarm arrives fast enough to swing round a laid well and come
back, and the input stops reading as *throw them that way*.

**And it is not the drift either**, which is the same elimination from the other
side. Act IV is flown at `worldSpeed` 68; walking that from 54 to 80 moved the
furthest section between 8.0 and 8.6 with no ordering in it, measured while
`debrisArc` still built the act's gates backwards. No speed opened this act up; a
sign did.

**The circuit is 68 minutes long, and that is arithmetic rather than a bot
reading.** *(Superseded: this is the second-pass shortening of the original 107-minute
campaign. The circuit was later rebuilt to 432 sections and 144 authored minutes; see
[DESIGN-LENGTH.md](DESIGN-LENGTH.md) §11. The table below is the 182-section campaign.)* Every act is authored to within 4 % of the same section spacing
(~845 px between lines), so an act's duration is its length over its forced drift
and nothing else:

| act | sections | pace | drift px/s | minutes |
| --- | ---: | ---: | ---: | ---: |
| water | 42 | 0.86 | 58.8 | 10.1 |
| air | 36 | 0.98 | 66.8 | 7.6 |
| thin | 20 | 0.41 | 27.9 | 10.1 |
| orbit | 18 | 0.35 | 24.0 | 10.6 |
| reentry | 24 | 0.48 | 32.9 | 10.3 |
| rain | 24 | 0.53 | 35.8 | 9.4 |
| home | 18 | 0.36 | 24.3 | 10.5 |

It was 107 minutes, with acts running from 7.6 to 21.1, and the cause was subtle
enough to survive four commits: **the five new acts were authored to act I's
section count at half act I's drift**, so they came out twice as long without
anybody choosing that. Act III's pace is *correct* and defended by §7 — it was
re-derived against a measured 57 px/s forward ceiling — and act IV's is defended
by `tools/space.sweep.ts`, so the lever was the courses' **length**. 179 sections
became 104.

Every station kept three things: the section that states what the station is, the
section where its ramp lands, and a rest. What went was the same argument made a
second and a third time, and at these drifts a section is on screen two to three
times as long as one of act I's — so a three-section station up here takes about
as long to fly as a seven-section station at the trench floor. The stations did
not get shorter in the only unit a player experiences; they stopped being padded.

`tests/descent.test.ts` asserts the consequence — every act between 7 and 12
minutes, the circuit between 60 and 80, and no act more than 1.6× another —
because a length is the kind of fact that rots one added section at a time and
nothing else would notice. *(Since then: those bands are act I's alone; the other
six acts are held to 19-27 minutes, and the circuit-wide bounds changed with them.)*

Acts VI and VII measure healthy: skill multipliers **2.7×** and **2.2×** over
passive, life kept **1.6×** and **1.2×**, and act VII's competent bot restarts a
station **0.2** times in 300 s against act VI's 0.6 and act IV's 5.3, which is
§12's "the difficulty peak is not the finale" arriving as a number.

> That last figure read **zero** on the shared-policy harness and 0.2 on the
> independent one, which is one restart across eleven five-minute runs. It is
> worth correcting rather than rounding, because the sentence it used to carry
> was §12's *cannot be lost* — and a sweep number was never the right evidence
> for that in the first place. What actually holds act VII's promise up is
> `tests/descent.test.ts`, which plays the last three stations as badly as it can
> and asserts the run does not end. A bot happening not to trip is a coincidence;
> a failure policy that cannot fire is the design.

### What the second visual review found

The four new films were shot movement by movement and looked at
(`e2e/acts.spec.ts` writes `docs/screens/films/`, one frame per movement, off the
film's own phase rather than off a wall-clock mark). Nine defects, and not one of
them was reachable by a test that had already passed:

1. **The gold burned white in two films.** Every ending in the game draws the
   carried life with `lighter`, which is right in all five that are dark and
   wrong in the two that are not: gold added to act VI's grey cloud deck or to a
   sunlit estuary comes out white. The two frames whose entire job is to show that
   the campaign's one visual constant survives were thirty white dots. The heat
   and the halo are additive now; the gold is `source-over`, drawn last, and
   opaque, because a cooled grain and a plankter are objects rather than light
   sources.
2. **A film with a movement nobody could reach.** `Karman` had four movements and
   handed over inside the third — and the handover is the frame the next act opens
   and every film is reset, so its fourth was three and a half seconds of picture
   no player could ever see. `tests/films.test.ts` now asserts for all seven that
   the handover falls inside the last movement.
3. **The swarm dissolved into dust.** `Karman`'s motes were spread uniformly over
   nearly two screens, on the reasoning that a long enough stream always has some
   of itself in frame. A uniform distribution over a whole screen is evenly
   scattered dust, and the body of life the player spent seventeen minutes holding
   together came apart on the frame the film started.
4. **The last wind pointed the wrong way.** The tracers answering the dead stroke
   were anchored to fixed points and drawn forward, so on the frames the hand had
   barely moved they lay across it pointing the way it was going — which reads as
   the stroke working, in the film about it not.
5. **The cloud deck was fog.** Soft low-alpha mounds over a grey background make a
   grey background. A cloud top seen from just above it is a silhouette with a lit
   crest, so it is drawn as one: opaque bands, back to front, the far ones higher
   and paler.
6. **The first shoal arrived as a queue.** `Circle` drove the fish's x and y from
   the same lane index, so sixteen fish sat on one straight line — the rung
   failure the flock and the leapers each had once, in a diagonal. An angle and an
   independent radius have no such correlation.
7. **...and never became one body.** A shoal is not fish in the same place, it is
   fish going the same way. The body now has a slow travel of its own that grows
   as the mill is damped, so the headings converge with nothing written about
   heading.
8. **The trench floor was invisible.** Act I's rock is `#05010e` and its deep
   water is `#010108`. The shipped game gets away with that because `RockPaint`
   rim-lights every blob; a film drawing one flat silhouette has to earn its own
   separation, and this one did not — only the hairline showed, with no mass under
   it.
9. **Four columns of light stopped at once.** The estuary's shafts were a
   `fillRect` to 0.8 of the height, which put a hard horizontal edge across the
   whole frame. Tapering the fill into a triangle was worse: a linear gradient is
   anchored in space rather than to the path it fills, so the narrowing shafts
   sampled only the bright middle and became hard-edged threads. They are
   stretched radial gradients now, which have no edge in any direction.

**Continuous circuit mode.** A setting the shell only offers once a circuit has
been closed, and what it does is take the one dialog out of an otherwise unbroken
journey: act VII hands back to act I exactly as the other six hand on. It cost
four lines in `main.ts` and nothing anywhere else, because `render/Circle.ts` was
already built for it — the film dissolves the trench floor into act I's opening
picture, and with this on that dissolve stops being a metaphor and becomes the
cut. The circuit is still banked first; a player running the loop is playing for
records like anyone else.

### Whether an act can be finished, which nothing had ever asked

Every sweep in this repo measured an act by how far a bot gets in a fixed 300
seconds. That is the right question for comparing acts with each other, and it
stopped being answerable as *the* question the moment the acts were re-cut to
about ten minutes each: 300 seconds is half an act. **Not one run in any sweep or
test in this repo had ever reported `completed`.** The suite could not have told
the difference between an act that is finishable and an act that is not.

`tools/finish.sweep.ts` asks it. Each act gets its own clock — its length over its
forced drift, times 1.8 for the time a real run loses to restarts — and the
reading is how many of eleven seeds finish:

| act | budget | finished | furthest | restarts | time to finish |
| --- | ---: | ---: | ---: | ---: | ---: |
| water | 18.1 min | 0/11 | 18.0/42 | 0 | — (`sweptAway`) |
| air | 13.7 min | 0/11 | 9.0/36 | 0 | — (`sweptAway`) |
| thin | 18.2 min | **11/11** | 20/20 | 2.8 | 8.0 min |
| orbit | 19.0 min | **6/11** | 14.5/18 | 18.4 | 8.2 min |
| reentry | 18.0 min | **11/11** | 24/24 | 0.7 | 7.1 min |
| rain | 17.2 min | **11/11** | 24/24 | 4.5 | 9.1 min |
| home | 18.8 min | **11/11** | 18/18 | 0.1 | 4.4 min |

> **The orbit row was `0/11`, `8.1/18` and 43.3 restarts, and the paragraph under
> it said so at length.** It was one character in `ObstacleSystem.debrisArc`: the
> bow term was negated, so every orbital gate's wing tips sat *further along* the
> course than its opening, the mouth was the first part of the wall the swarm met,
> and the deeper the bow the less the wall blocked. Act IV's one declared
> escalation axis ran backwards for the whole life of the act, five written
> descriptions of the shape described its mirror, and the assertion that guards it
> (`tests/orbit.test.ts`) compared `maxY - minY`, which is the same number for a
> shape and for its reflection. Flipping the sign and changing nothing else took
> the act to 3/11 and 11.5/18. Act V's `shock` passes `-bow` into the same
> function and was inverted with it; it is a shock again.
>
> 3/11 was the bow alone. 6/11 is with the rest of act IV's level-file defects
> fixed: the Umbra's `strait` put its right shoulder 55 px off the field and was a
> single wall for the first half of its own funnel, the Well stepped the act's ramp by
> 0.02 where the station before it stepped 0.08, and both of the Well's compulsory
> rings sat 16 px behind a well's eye, where an undamped attractor spends the hold
> pulling the swarm off the thing it is holding.
>
> `thin` costs 2.8 restarts against 1.3 because it has a chicane now — `flurry` was
> built, documented and authored by nobody, so the act made two demands across ten
> minutes. It is two rows rather than the archetype's three: measured, three took
> the act from 11/11 to 8/11, because a lateral move is the expensive thing in a
> medium with a third of the water's grip. `rain` holds 11/11 through `rainCurtain`
> becoming an actual wall — it stepped its columns further apart than its beads are
> wide and left a quarter of them with no bead at the section line, so the act's own
> "commit to one gap" archetype had holes in it and the bot was walking through
> them. Its three curtain gaps were widened by 0.04 to give back the opening the
> leak was providing, which is the part of the difficulty nobody had chosen.

Two different readings sit in that table and they must not be confused.

**Acts I and II are the bot's limit, not the act's.** They were the two acts that
`END_ON_FAILURE` when this table was taken (§12; §19 has since changed it), so a
scripted hand that fell behind did not restart — the run ended, and `sweptAway` is
what every one of those rows says. This measures `makeAimBot`, which was never
good enough to fly forty-two sections of act I without being stranded, and act I's
balance is defended by the rescue-ratio probe rather than by a bot finishing it.
Nothing here is evidence about acts I and II.

**Act IV was the act, and it was a bug.** It used to be the only restart-policy
act that did not finish, and it was not close: forty-three restarts, furthest
section 8.1 of 18, and nineteen minutes instead of five bought nothing. That
reading was correct about the instrument and wrong about the cause — it was read
as evidence about the act's *design*, and the decision taken on it was to change
nothing, which is the right instinct and here protected an inverted sign for the
act's whole life. It is 6/11 and 14.5/18 with the bow the way its own comments
describe and the level file's own defects out of the way. The act is hard and the
bot is still not good at it; it is no longer a wall.

> **Those two readings used to be 8.6 and 9.2, and now they are both 8.1.** The
> reason they ever differed was a wart in how every sweep here was written:
> `styles()` built one policy object and ran all eleven seeds through it, so a bot
> with any internal state — `makeAimBot`'s stroke clock, `makeWaveBot`'s phase,
> `makeOrbitBot`'s cruise memory — started each seed wherever the last one left
> it. The runs were not independent samples, and a mean over eleven correlated
> ones does not have the error bar it looks like it has.
>
> The comment defending it said re-phasing between runs made results wobble for
> no design reason, and that has it backwards: built fresh, the cadence is a
> *constant* rather than a nuisance carried in from whichever seed happened to run
> first. `tests/bot.ts` grew `perSeed` and all six tools use it, so no sweep can
> be written the old way by accident.
>
> What it cost, measured rather than guessed: nothing changes qualitatively
> anywhere. Every table above and below is re-measured under the fixed harness;
> the largest single move is act II's furthest section, 18.8 to 15.0, and the
> ordering that any of these tables is quoted *for* is identical in all of them.
> What it bought is that the same question now gets the same answer from two
> different tools, which is the property a regression instrument needs and did
> not have.

> Not everything in this section could be re-measured, and it is worth saying
> which. The pace-flattening walk and the seven stroke schedules below were
> one-off experiments rather than committed tools, so their numbers are the
> shared-policy instrument's. They are eliminations — *no value of this helps* —
> and an instrument that inflates every row of a grid equally cannot manufacture
> one of those. The committed grids that *do* live in `tools/space.sweep.ts` were
> re-run and agree with them.

Three explanations were tested while the reading was still `0/11`, and all three
are ruled out by measurement. None of them was the cause, and the readings under
them are the pre-fix act's:

* **Not the length.** Progress plateaued inside the first five minutes of a
  nineteen-minute budget. A shorter course would not have been reached any
  faster.
* **Not the pace.** Act IV's pace ramps 0.30 → 0.44 across its stations, and every
  restart fell in stations 2–4 while station 1 (the slowest) never failed once —
  which looked exactly like act III's original defect in §7. It was not.
  Flattening every station's pace and walking it down to 0.22, a drift of 15 px/s
  against act I's 58, gave **0/11 at every value**, with the furthest section
  *falling* slightly as the drift slowed. `tools/space.sweep.ts`'s drift grid said
  the same thing from the other side, on the fixed harness: 54 to 80 px/s of
  `worldSpeed` against a shipped 68 moved the furthest section between 8.0 and
  8.6, with no ordering in it. No speed opened this act up; a sign did.
* **Not the stroke schedule.** §8 has already been round this once with
  `makeOrbitBot`. Seven schedules were walked across the gap the existing two
  leave — leads of 60 to 220 px at 0.15 to 0.3 s between strokes, which is the
  act's own verb played properly — and the best of them reached 10.0/18. Still
  0/11 then, and still 37 restarts.

What was left was the act's authored content or something structural about
steering a ballistic swarm through geometry — and the decision taken was **to
change neither, and to stop treating a bot finishing act IV as the act's
acceptance criterion.** It was the authored content, and one character in the
code that draws it. Both were changed in the end, and the act reads 6/11.

That was not a shrug, it was what the eliminations pointed at. Every lever that
could have been pulled there was a permanent change to the act — a wider strait,
a relaxed compulsory ring, a stronger well — and every one of them would have
been pulled on the evidence of a scripted hand whose whole known weakness is this
act. Two of the three were touched in the end, and not as levers: the strait had
its right shoulder 55 px off the field it is drawn against, and the Well's
compulsory rings sat 16 px behind a well's eye. A defect is not a lever.
§8 has already been round that loop once: `makeAimBot`'s reading was suspected of
being the instrument, `makeOrbitBot` was written to check, and the check is the
only reason the act's verb is now a measured fact rather than a tuned one. The
same discipline says a number is not tuned toward a sentence *or* away from one on
an instrument that has not been shown to be right.

So: act IV's completion is still a **human playthrough**, and the suite does not
claim otherwise — six seeds in eleven is a scripted hand scraping through rather
than an act that has become easy. `tools/finish.sweep.ts` prints `6/11` for
orbit, and what its row is most useful for is still the *furthest section*, which
is a regression signal: if a change to the potential field or to act IV's content
moves 14.5 down, something got worse. The other six acts keep the completion
reading, because for them it works.

> The honest cost of this decision, written down because it is the kind of thing
> that gets forgotten: §17's *the whole campaign is playable end to end* was met
> for six acts by measurement and for act IV only by a person playing it, and
> nobody had. That much has moved — the finish sweep completes orbit on six seeds
> in eleven. `e2e/campaign.spec.ts` flies all seven, but it jumps between them —
> it proves the seams, the handovers and the circuit's state machine, and it does
> not prove that Free Fall reaches the Overview. Nothing in the e2e suite does, and no
> person has.

### What the settings review found

> **Since then:** high contrast was withdrawn together with the settings screen, and
> no renderer, film or banner reads it any more. What follows is the record of how the
> requirement was met and what was learned finding out that it had not been; the
> `FilmView.highContrast` plumbing is gone and no spec writes the `docs/screens/*-hc/` frames any more. The
> lessons (a surface built for two or three of a thing, never re-derived for seven)
> outlive the setting. The audition-panel half of this section (the ending cues)
> is unaffected.

Two requirements from §12–§17 had never been met, and neither had a test with any
reason to notice. Both are the same shape: a thing the campaign added seven of,
and a surface that was still carrying the two or three that existed before it.

**High contrast reached none of the seven endings.** §14 asks for reduced motion,
high contrast and the quality setting to work in every new renderer.
`render/Films.ts`'s `FilmView` carried `still` and `quality` and not
`highContrast` — so the setting could not reach a film even in principle, and the
three that shipped before the campaign were as blind to it as the four that were
written last. `Renderer.style.highContrast` existed the whole time; it simply was
never passed on.

It is on the view now, and **what it means is a per-film decision**, which is the
part worth writing down. It is closer to `daylight` than to `still`: raising the
contrast of a frame whose subject is a bright line four pixels thick is not the
same operation as raising the contrast of a gold dot on a sunlit cloud, and doing
the same thing to both breaks one of them.

| film | what the setting does |
| --- | --- |
| `Surfacing` | mostly subtracts — the sun's bloom and the horizon haze are cut to a third; the waterline and every leaper's shaded underside go hard |
| `Release` | the band gains a third and its hairline goes hard; the flock keeps its fade but gets a floor under it; the sunrise halo is cut |
| `Karman` | the gesture, the stopped ice and the coasting motes all go up hard — they are the film's three terms; the air leaving keeps its geometry and gains only alpha |
| `Overview` | **subtracts.** The stars drop below half and the day side dims; the band brightens and its edge firms |
| `Nucleus` | the deck's range opens *downward*; every cooled core gets a dark rim, arriving on the same ramp the fire leaves on |
| `Estuary` | the halocline roughly doubles; the ceiling and shafts are cut; every body is outlined |
| `Circle` | `RockPaint`'s own accessibility idiom, reached from here: flat lifted fill, hard rims, and the shoal brightened by exactly the 0.5 `Renderer.contrast` gives the live one |

Two rules bind all seven. **The gold is outlined, never recoloured** — §3 makes it
the campaign's one visual constant, so the two films with a bright background get
a rim rather than a different colour. And **nothing is removed except softeners**:
full-screen blooms, hazes and washes exist to make two things meet gently, which
is the opposite of what this setting is for.

> Two defects came out of looking at the frames rather than the numbers, and both
> were mine, made while fixing this. `Overview`'s hairline went to two pixels at
> 0.85, which on a phone is six device pixels of near-white over an atmosphere
> that is four — the whole picture came back as a white ring round a dark disc,
> with the graded band it exists to show buried underneath. And `Estuary`'s and
> `Nucleus`'s rims were discs drawn *behind* the body: on a larva, whose half-
> length is nearly twice its half-height, that is a black plate with a small gold
> animal in the middle of it and a tail out of the side, and on a grain still
> burning it punched a hole through the middle of the heat. Rims are strokes on
> the silhouette now, half inside the fill, and the `Nucleus` one arrives on
> `cool` — the same ramp the fire leaves on, so the transformation is still one
> thing happening.

`e2e/acts.spec.ts` shoots all thirty movements again with the setting on, into
`docs/screens/films-hc/`. The assertions there are deliberately thin — the same
"this is a picture" bar the plain pass uses — because the seven do not agree on
what raising contrast means and no assertion about brightness could be right for
all of them. That the seven each *answer* it is asserted a level down, in
`tests/films.test.ts`, where both frames can be held side by side.

**...and it had never reached the station banner either.** Same requirement, one
layer up, found the same way. `Renderer.drawLevelBanner` never read
`style.highContrast` — while `drawHud` two hundred lines above it and
`drawProgress` ninety lines above it both did. It is the **only text in the game
painted on the canvas**: every station title, every depth, every subtitle, and
the sentence that closes the circuit. Its five elements ran at alphas of 0.24 to
0.78 out of an already quiet tone, and it sits over whatever the act underneath
drew. Measured off the shipped frames with the setting **on**:

| film | eyebrow | title | depth | subtitle | rule |
| --- | ---: | ---: | ---: | ---: | ---: |
| `Estuary` | 1.59 | 2.12 | 1.52 | 1.44 | **1.24** |
| `Circle` | 1.39 | 1.89 | 1.39 | 1.30 | **1.15** |
| `Overview` | 1.88 | 3.74 | 1.97 | 1.69 | 1.25 |

One element of one film clears 3:1. The campaign's last sentence — *Where it
began*, over the trench floor — reads **1.30:1** in a frame whose fish are
near-white on near-black.

Three things had to be true, and only the first is the obvious one:

> **The alphas lift, and the faint ones lift most.** A flat `+0.2` — what the HUD
> and the rail add — leaves the two lines that could not be read still the two
> that cannot be read, because it moves 0.24 and 0.78 by the same amount. Each
> alpha closes 55 % of its own gap to opaque instead. The hierarchy survives:
> size and weight carry it as much as alpha does.
>
> **The ink is chosen against the ground.** This is the half no alpha could have
> done, and it is the same answer `Renderer.contrast` has given since act II —
> *which side of the background is this thing already on* — asked by the one
> element that had never asked it. Four of the forty-two stations are lit: the Spray
> at sixty metres, the surface, the Salt Line, the Sunlit Zone. Pale ink measured
> 1.6:1 on those with the setting on, and white on white has no alpha that helps.
> The pick is by **contrast ratio, not by brightness**, and the two disagree over
> exactly the teal this campaign spends most of its time in: read as brightness a
> 136-of-255 water sits just under halfway and keeps the pale ink at 2.1:1; read
> as contrast the dark ink wins it at 4.0:1. Three stations turned on that
> distinction. The ground is read off the frame itself rather than out of the
> palette, because the base gradient and the backdrop drawn over it say different
> things — `paint.top` reports the Sunlit Zone as dark water. It is one
> `getImageData` per raised banner, only when the setting is on.
>
> **Both inks go to their extremes, and each line is rimmed in the other one.**
> The worst ground for a two-ink scheme is the one exactly between them, where
> neither wins, and that worst case is the geometric mean of the pair's two
> contrasts — so widening the pair raises the floor for every mid-tone at once,
> from 3.5:1 to 4.2:1. The rim is what makes a mid-tone survivable at all: a
> counter-toned stroke laid down *before* the fill, so half of it ends up under
> the glyph. That direction is not a detail — §18 has already paid for rims drawn
> behind a body once, on `Estuary`'s larvae.

`render/Banner.ts` is that code, lifted out of `Renderer` so it can have a test —
the same move `stationDepthLabel` made for the same reason. `tests/banner.test.ts`
asserts what it *does*; `e2e/acts.spec.ts` measures whether that was **enough**,
which only a rendered frame can say, because "enough" is a fact about the picture
underneath and the picture underneath is a different act every time. It walks all
forty-two stations with the setting on and writes `docs/screens/acts-hc/`.

The weakest line of every station now reads **2.67:1** or better, against 1.15
shipped. The two weakest are the Cliff and the Salt Line, both mid-tone water.

> The instrument was wrong first, and in a way worth writing down because it
> produced a plausible false finding. It took the extreme *further* from the
> ground — but in high contrast every glyph now has both a very light pixel and a
> very dark one, and over lit water the further of the two is the **rim**, which
> is by construction the weaker of the pair there. The numbers came back looking
> like small type failing to reach its own alpha, and there is a tidy story about
> antialiased coverage that fits them perfectly. It was the wrong element. A
> measurement that disagrees with the design is worth more than the design; a
> measurement that disagrees with *arithmetic* is worth checking first.
>
> One consequence to know before reading `docs/screens/films-hc/`: those frames
> are shot the moment a movement changes, and the closing banner is raised on
> `settled` — so it is a fifth of a second old in them and still fading up. Their
> banner numbers are its *fade envelope*, not its contrast. The forty-two
> `acts-hc/` frames catch it at rest, which is where it spends its life.

**Six of the seven ending cues could not be heard.** §16 asks for every new sound
to be auditionable. `debug/AdminPanel.ts` listed `surface()`, because it is act
I's and predates the campaign, and none of `release()`, `airless()`, `overview()`,
`nucleus()`, `estuary()` or `circle()`. These are the extreme case of the problem
the panel was built for: they fire **once per act**, at the end of it, after ten
minutes of flying, and only if the act was finished. Four of them were written and
shipped without anybody having heard them.

They are their own group in the panel now — they are also the longest sounds the
engine makes, and fired back to back they overlap into something that is not any
of them. `tests/admin.test.ts` fires every row against a recorder and asserts
which engine method it actually calls, because a row wired to the wrong cue is
exactly the mistake a label check cannot see.

### What the act II picture review found

Act II's six stations shot at their **opening and their late image** — the second
one matters, because a station's own progress moves its floor, its light and its
sheet across most of a screen between the two, and everything shot to date was
shot at the opening. Two defects, both the same class, and the class is worth a
name because the estuary's shafts (#9 above) were the first case of it and nobody
went looking for a second:

**A live gradient clipped by the rectangle that draws it.** A `CanvasGradient` is
only edgeless at the ends where it reaches zero alpha. Fill it with a rectangle
that stops anywhere else and the result is a hard line the full width of the
screen — and it is invisible to every test in the suite, because the frame is not
flat, not black, not blown out, and draws exactly the geometry its unit test
asserts.

- **The anvil's light band ended at its own brightest stop.** The gradient ran 0 →
  0.24 over `sheetY − 0.2h` to `sheetY + 0.15h` and the `fillRect` ended on the
  0.24. Measured on the frame at **14.0 luminance units**, edge to edge, a third
  of a screen above the storm top, in the act's best picture. It peaks on the
  sheet and dies below it now: **4.3**.
- **The squall's break started a fifth of a screen inside its own radius.** The
  radial reaches `0.78h − 0.6h = 0.18h`; the `fillRect` started at `0.3h`. **3.9
  units** at exactly 0.3h, on the opening frame and the late one alike. The
  rectangle starts where the glow has run out now, and the seam is gone from both.

Two things the same pass measured and did *not* change, which are worth writing
down because both were suspected by eye and refuted by the number:

- **The headland has mass.** It reads as two hairlines and it is not: the left
  twentieth of the frame runs **39 to 48 luminance units** below the sky at the
  same height, with a largest column-to-column step of 2.5. That is exactly what
  `cliff` was designed to be — a ramp with no boundary anywhere in it — and the
  eye reading it as thin is the design working, not failing.
- **The spray's sea has mass too.** The bottom of the frame sits **57 to 67 units**
  below the sky extrapolated down from the middle, at the opening *and* after the
  water has drained most of the way out. It is quiet, not absent.

`e2e/acts.spec.ts` measures the seam on all forty-two stations now and holds them
under ten. The instrument's specificity comes from **coherence, not magnitude**: a
cloud's top edge is just as large a row step and is the picture doing its job,
but it is a shape and shapes have sides, so it cannot move every column at the
same y. The distinguishing signature between the two, when a reading is
ambiguous, is that a `fillRect` artefact sits at the same fraction of the height
in the opening frame and the late one, and a silhouette does not.

**Two stations are over the floor at their late image and neither is act II's.**
`thin/ozone` reads **17.0 at 0.337h** and `rain/estuary` **10.1 at 0.749h** — the
estuary being the one whose shafts were already fixed once. Neither is visible at
the opening frame the guard runs on, so neither fails it today. They are the first
thing acts III and VI should be asked about.

> **Neither of those two numbers reproduces**, and the paragraph is left standing
> rather than corrected in place because the useful part of it is the mistake. The
> act III review went to `thin/ozone` first, found nothing there, and then measured
> all forty-two stations at their late image: `ozone` reads **4.14 at 0.793h** and
> `estuary` **2.74 at 0.312h**, with the whole field between 2.09 and 6.66. See the
> section below for the two timings that were tried and what the pass found instead.

### What the act III picture review found

Six stations, shot at **every one of their own sections** rather than at two
points — twenty frames — and each one also swept through twenty-six samples of
forced advance to move the camera under the world-anchored layers. Two frames per
station is not enough here: everything in `Upper.ts` is anchored to `cameraY`, and
`reset` puts the camera in the same place every time, so an opening and a late
image taken that way differ only in `progress` and are blind to anything the
parallax moves.

**Act III cannot be flown to its own late image.** It restarts the station on
failure, so a scripted hand simply loops the opening: twenty-six samples of forced
advance never took `jet` past `progress` 0.55 and never took `nacre` past 0.18,
because the hunters end the attempt first. The late image is reachable only
through `reset` at the station's last section. That is now what the guard does.

**One defect, and it is the same class as act II's one step further out.** There
the rectangle cut the gradient; here the *geometry* did.

- **The nacreous lens had no edge along itself and two hard ones across.** Each
  lens ran its iridescence as a linear gradient from tip to tip, reaching zero
  alpha at both — correct, and the reason the station never read as a rainbow —
  and then let `ctx.ellipse` close the shape top and bottom, where nothing was
  fading toward anything. A lens here is up to one and a half screens wide, so
  both of those edges leave the frame: **a shape with no sides in view is a
  `fillRect` through a live gradient by another name.** Measured at **4.36 to 4.53
  luminance units at 0.590h**, at every one of the station's four sections, and
  4.0 to 4.9 across the sweep — a hard horizontal line, edge to edge, in the act's
  best picture, in the one station whose entire subject is a cloud with no hard
  edge anywhere in it. On the frame it read as a flat grey lozenge with a razor
  top, and the iridescence it is named for was not visible at all.

  It is a radial gradient in a squashed frame now: soft in every direction, one
  gradient per lens exactly as before, and the colour runs **green in the body,
  rose toward the lit edge**, which is what `Motif.ts` has said about `nacre` since
  it was written and what a two-stop gradient across a flat fill could not deliver.
  The seam at 0.590h is gone from all four sections; the station's worst reading is
  **3.28 to 3.50** and no longer sits at a fixed height. Mean 52.5 → 52.2 and spread
  32.9 → 32.8, so the light was not spent buying the fix.

**Two things this pass measured and did not change.**

- **The jet stream's streaks are the act's largest seam and they are the picture.**
  5.7 to 6.4 units at 0.43–0.45h, at every section — but the height does not move
  with `progress` and does move with `cameraY`, which is the signature of something
  anchored to the world rather than clipped by a rectangle. It is the dragged ice
  the station is named for, and at 11 km it is supposed to run the width of the sky.
- **The noctilucent station's dark wedges are its `throat`, not a backdrop fault.**
  Two pale obstacle decks with a narrow gap between them, drawn in the campaign's
  own stone grammar with an ice palette. It is the loudest frame in the act and it
  is the mechanic.

**Act II has a reading over the floor that the opening frame cannot see either.**
`air/squall` at its fifth section reads **12.97 at 0.279h** — the bottom edge of
the two cloud decks that make that section's gap, i.e. two shapes whose sides are
off opposite ends of the frame. It is content, and it names the guard's real blind
spot: the floor of ten is survivable at the opening because *the course has not
arrived yet*. A seam guard that ran everywhere a player actually plays would have
to be a great deal cleverer than this one, and would still be measuring the level
design rather than the art.

`e2e/acts.spec.ts` shoots all forty-two stations at their late image now, to the
same bar as the opening pass, and leaves `docs/screens/acts-late/` behind for the
half of this that a number cannot do.

### What the act IV picture review found

Six stations, all eighteen of their sections, plus twenty-six samples of forced
advance per station to move the camera under the world-anchored layers — the same
method act III settled on, for the same reason.

**The seam instrument found nothing here.** The largest coherent row step anywhere
in act IV was **6.59**, against a floor of ten, and the whole field sat between 2.3
and 6.6 at every section and every sweep sample. That is the useful part of the
finding rather than a clean bill of health: act IV's defect is the *opposite* class,
and it is the one the suite is structurally blind to.

**One defect, and it is the third variant of the family.** Act II's rectangle cut a
live gradient; act III's geometry did; here the geometry was **correct and below the
picture**.

- **Act IV's planet was off the bottom of the frame for four stations out of six.**
  The limb sits at `h · (1.28 − 0.52 · rise)`, so it crosses the bottom edge at
  `rise` 0.538 — and the six stations passed 0→0.12, 0.14→0.26, 0.30→0.40,
  0.44→0.54, 0.58→0.68 and 0.80→1.00. Free fall put the limb at **1.28h**, 236 px
  below an 844 px frame, and the top of the band of air along it at 1.197h, still
  167 px below. The planet, that band, the weather on the day side and the umbra's
  cities were all drawn, every frame, into nothing.

  Measured on the pixels rather than inferred: the largest coherent row step in the
  bottom quarter — the limb's signature — read **1.04 to 2.50** at free fall, the
  aurora, the umbra and the debris belt, which is noise, and **4.32 at 0.937h** at
  the well and **6.35 at 0.794h** at the Overview. Those two land exactly where the
  formula puts the limb at those stations' own progress (0.926h and 0.794h). The
  instrument agrees with the arithmetic to three decimals wherever the planet is in
  shot, and finds nothing at all where it is not.

- **The umbra drew none of its cities, ever.** Zero warm pixels below 0.88h, at
  every one of the station's sections. They were hung `0.02 to 0.22` of a *screen*
  below the limb — a spacing that only fits a planet filling the bottom fifth, i.e.
  the Overview — so with the limb at 1.07–1.12h all twenty-six failed the clip on
  every frame. The module's comment says of them: *the one detail that keeps it a
  place rather than a blank*, *the first time since the trench floor that the game
  shows anything made by people*, and *it is never mentioned*. It was never
  mentioned because it was never drawn, and the station was the blank.

**What changed.** Six new `rise` values — 0.45, 0.53, 0.61, 0.69, 0.76 — chosen so
the band of air is in shot on the act's first frame and the limb climbs
monotonically with no step at any station boundary. **The Overview's
`0.8 + progress · 0.2` is untouched**, and its readings say so: 6.17 at 0.846h and
6.33 at 0.794h against 6.17 and 6.35 before, i.e. the same heights to three decimals
and the same magnitudes to inside the ±0.02 that repeat runs of an unchanged build
give anyway. The body now runs 0 at free fall, a twentieth of the frame at the
umbra, a tenth by the debris belt and a quarter at the turn.

Everything that sits *on* the planet is laid out across `v.h − surfaceY` — what
is actually left of the frame under the limb — instead of a fixed fraction of the
screen, so it crowds toward the horizon when the limb is low, which is also what a
shallower view of the same ground does. And the arithmetic that decides where the
limb is lives in one `limbY` rather than the three copies it had, since a number
that says where the planet is cannot be in three places.

After: light along the bottom of the frame at free fall **1.26 → 5.35** on the
opening frame and 19.7 by the last section; the limb's step at the debris belt
**1.50–2.50 → 2.93–4.72**, at 0.900–0.918h and matching the formula again; the
umbra's cities **0 → 164–177**.

**Act V shares this planet and did not move.** `Orbit.drawPlanet` is act V's first
two stations as well. The de-orbit's mean went 12.6–12.9 → 12.8–13.1 and its four
seams are within 0.01 of what they were; the night side is identical to three
decimals, because `lit` is zero there and the day-side branch never runs. Its five
weather patches are now laid out against the ground that is in frame like everyone
else's, which is the same defect reached in passing rather than looked for. Act V's
own review is 6.5 and this is not it.

**Two things this pass measured and did not change.** Both are the frozen visual
language rather than faults, and both were suspected by eye first:

- **The aurora's curtains read as hanging lozenges rather than sheets.** They are
  ellipses with a bright lower edge and a crown that fades to nothing, which is
  what `Motif.ts` describes and what hard flat vector asks for. The objection is
  taste and the language is decided.
- **The day side's weather is hard-edged ellipses.** Same answer, and it is also
  why the seam pass never sees them: they are shapes, and shapes have sides.

`e2e/acts.spec.ts` counts the umbra's cities now. They are the canary rather than
the subject — they hang off `limbY` like everything else on that planet, they sit in
the narrowest strip of it, and they are warm on the darkest frame in the game, so
they are the first thing to leave the picture if the mapping moves and the easiest
thing to count when it has not. The floor is sixty, under a reading of 164–177 and
over a reading of nought.

### What the act V picture review found

Six stations, all twenty-four of their sections, plus twenty-six samples of forced
advance per station — the same method acts III and IV settled on.

**The instrument the suite did not have.** Everything caught in acts II, III and IV
is one defect on one axis: a live gradient with a hard edge somewhere in shot, found
by scanning *rows* for a step that every column agrees on. Act V's is the same defect
on the **other** axis, and the seam pass is blind to it by construction — a step every
*row* agrees on is a step in a column, and nothing was looking at columns. So this
pass added the transpose, and it is reported as a **prominence** rather than as a
magnitude, which is what makes it specific: a radial gradient laid across the frame
steps in the same direction in every column it covers and steps by a lot, but it
cannot step much more at one column than at the columns ten pixels either side,
because it is a ramp. An edge does exactly that. The number is the step at a column
minus the mean of the steps at ±10.

**Defect one: act V's aurora was seven rectangles.** Each curtain was a `fillRect`
1.2 screens tall, filled with a vertical gradient that runs to zero at both ends —
correctly edgeless along its length, and then hard down both sides, both of which are
in shot for the whole height of the picture. It is exactly the anvil's light band
turned through ninety degrees.

- Measured at **11.07** units of coherent column step on the opening frame and 10.05
  on the late one, with a second curtain in the same frame at 9.36 — against a
  campaign that reads **0.00 to 4.69** everywhere else. The row agreement at the two
  worst columns was 1.00 and 0.99: every sampled row of the frame stepping the same
  way.
- Its `seam` at that same moment was **3.05**, in the middle of the field. That is
  the finding about the suite rather than about the picture.
- On the glass it was flat green stripes with hard vertical sides, in the station
  the act's own file calls *the most beautiful thing in act V on purpose*.

It is a radial gradient in a squashed frame now, the same shape the nacreous lens
was given one act earlier, with the two circles **offset along the major axis** —
the one thing a linear gradient could do here and a centred radial could not, so
the bright point still sits below the middle and the fade upward is still the long
one. After: **2.38, 1.68, 0.98 and 1.11** at the four sections, and 2.78 as the worst
of twenty-six sweep samples.

The peak alpha went from `0.06 + h·0.05` to `0.115 + h·0.095`, and the factor is
arithmetic rather than taste: a cone over an ellipse is a third of the cylinder over
it, where the old fill was a slab of constant alpha across its whole width, so the
same numbers laid down about half the light. Checked rather than assumed — the four
sections read 32.8, 32.7, 33.8 and 31.9 before and 32.1, 32.0, 33.2 and 31.1 after,
and the missing two thirds of a unit is the planet's unlit body standing where sky
used to be. Horizontal spread went **up**, 17.2/10.8/6.9 to 18.0/13.6/7.5, because a
slab of constant alpha across its own width has none.

**Defect two: the planet's schedule was a step, a freeze and an absence.** Act V
reuses `Orbit.drawPlanet`, and the module header says the limb keeps rising through
the early stations and is gone from the plasma on. None of that was true, and the
pixels agree with the arithmetic to three decimals wherever the limb is drawn, which
is how all three were found.

- **A step backwards at the campaign's turn.** `Overview` closes on `rise` 1.0, which
  puts the limb at 0.760h; act V opened on 0.86, which puts it at 0.833h. The Earth
  fell **61 px away** from the swarm on the first frame of the act that falls into it.
- **A freeze.** The night side passed a bare constant, 0.96. Measured at **0.781h at
  all four of its sections** — the one station on this planet whose horizon does not
  move, for 3590 px of course, in the act whose whole subject is that the ground is
  coming up.
- **An absence.** The aurora drew no planet at all, three stations before the prose
  says the limb goes.

Three new schedules, monotone across the act boundary and inside every station: the
de-orbit 1.0 → 1.1, the night side 1.1 → 1.26, the aurora 1.26 → 1.38. Measured
after: 0.758, 0.745, 0.732 and 0.719h at the de-orbit against a formula that says
0.7588, 0.7457, 0.7327 and 0.7197; 0.662h at the night side's third section against
0.6623; 0.620h, 0.604h and 0.572h at the aurora against 0.6198, 0.6042 and 0.5729.
The plasma is now the first station in the act with no limb, which is what the file
always claimed.

**Defect three: the night side's storms were in the vacuum.** Seven cells laid out
at `0.72h..0.96h` — a fixed fraction of the *screen* — against a horizon at 0.781h.
Two of the seven were centred **above the limb**, at 0.758h and 0.772h, and a third
sat 2 px under it with a 32 px glow radius, so it bloomed across the horizon. Every
frame of the station. This is act IV's cities one act later and one module along: the
same class the umbra's fix was written for, in the one file that was not touched by
it.

They hang off the limb now, like everything else on that planet, with a clearance of
their own glow radius plus the sag of the horizon across the frame — and that sag is
a property of the planet rather than of the screen, `w/21` at a radius of 2.6 w. The
topmost bloom is 39 px below the limb's centre, which is at least 20 px below the
horizon anywhere across the width, and all seven are inside the bottom edge.
`Orbit.drawPlanet` returns where it put the limb now, rather than act V re-deriving
it — which is the three-copies mistake act IV already made once, and which act V made
a fourth time by not deriving it at all.

**Three things measured and not changed.**

- **The plasma reads 5.97 on the column step, the highest in the campaign after the
  aurora, and it is not a defect.** Three of the thirty-four wake streaks land within
  two CSS pixels of each other and stack into what reads as one ruled line down the
  frame — a hash coincidence in the loudest picture in the game. It is what fixes the
  guard's floor rather than something to fix.
- **The meteor dust's 6.29 to 9.52 at 0.433h** is the underside of two cloud banks
  making the same gap, i.e. content, and the same reading as the squall's fifth
  section for the same reason.
- **The violet crown is dead in both auroras.** `mix(motif.crest, [190, 150, 255],
  0.4)` is computed in act IV's aurora and in act V's, and drawn at alpha zero in
  both: a colour that is named, mixed and never seen. Fixing it is a colour decision
  across two acts, one of which is closed, and the frozen visual language is teal plus
  **one warm** second colour per station — violet is neither. It belongs to 6.8.

`e2e/acts.spec.ts` measures the column step on both passes now and holds it under
**nine**. Where the measurement put it: all eighty-four frames read 0.00 to 5.97
after the fix, the twenty-six sample sweep never got past 6.29, and the defect this
was written for read 11.07. Half again in hand below, a quarter above, and nothing
tuned to clear it.

**Act IV did not move.** Its six stations read within 0.2 of their previous column
step, which is the spread repeat runs of an unchanged build give anyway, and the
umbra still counts its cities.

### What the act VI picture review found

Six stations, all twenty-four of their sections, and every reading taken as the mean
of five frames a second apart rather than of one — which is a change to the method
and the first finding of the review. Act VI's pictures are made of a few slow
wrapping masses, and a single instant of that is a coin toss: the same estuary
measured **1.42 and 1.13** on two builds that differed only in where its plumes
happened to be. Every before-and-after below is the five-frame mean.

**Defect one: the canopy's light shafts had a hard top, and it is the largest edge
this campaign has measured.** Each shaft is a `fillRect` filled with a gradient that
runs *across* it — zero at both sides, brightest down the middle — so the two edges
act V taught everyone to check are genuinely edgeless. The rect's **end** was the
edge. Nothing about the fill varies down the column, so the shaft came on at full
strength in the space of one pixel, four times over, all four at the same height.

- Measured at the exact `roofY` the arithmetic puts it at: **19.8** units of coherent
  row step at the station's opening and **40.9** at its late image, against the
  anvil's 14.0 that act II called its worst.
- It is drawn before the canopy now and starts off the top of the frame, so it has
  no end in shot at all, and the roof gradient — nine tenths opaque at the top of the
  frame, nothing a third of a screen below the leaves — attenuates it instead of
  cutting it. Both readings go to nothing: the probe's largest non-UI step in those
  frames is now 5.4 and 0.9, and what is left of the list is the obstacles.
- The frame is brighter rather than dimmer for it. Peak alpha went 0.13 + h·0.09 to
  0.16 + h·0.11 to pay for the third of each column that is now under the canopy, and
  the four sections read 77.1, 76.0, 75.3, 75.0 mean before and 78.2, 77.0, 76.5,
  76.4 after, with the middle third's horizontal spread up from 19.5, 20.6, 19.7,
  19.4 to 23.6, 24.3, 23.5, 22.8.

**The third orientation, and why no guard could have caught it.** `seam` demands that
every column in the play field step together; `rib` is the same demand turned onto
columns. A shaft is a fifth of the width, so neither applies. A partial-width row step
*was* built during this review and then thrown away: the swarm, the banner rule and
every obstacle silhouette in the game read 20 to 80 units on it, so no floor separates
a defect from the picture — the specificity these passes have comes from coherence
across the whole frame, and a local edge cannot have it. On top of that the entire
defect lived above 0.23h, and the play field starts at 0.25h because the station
banner owns the top fifth of the frame for its first five seconds. **The top fifth of
every frame in the campaign is unmeasured by construction.** That is the standing
blind spot this review leaves behind, and the way to close it is a pass taken after
`BANNER_LIFE`, not a lower `y0`.

**Defect two: the cirrus is the jet stream with the picture deleted.** `Upper.jet` is
a floor gradient, a sky gradient, the last anvil as a `bank` and a field of shear
lines; `Rain.cirrusFall` is the same function with the anvil gone, and what is left is
two vertical gradients — which have no horizontal spread along a row by construction —
plus nine hairlines two pixels thick.

- The middle third read **0.92** on a single frame, in the vacuum's range: the deorbit
  reads 0.80 and act VII's salt line 0.74, and those are stations whose subject is
  that there is nothing there. This one is named after a cloud.
- It was also the wrong way up for the act it opens. §10's rule is that the busy plane
  is at the bottom and rises through every station; this read 5.73 at the top against
  3.43 at the bottom, the only station in act VI heaviest where the sky is.
- The anvil comes back — and it is the anvil the *next* station is underneath, sitting
  on the haze line rather than at a fixed height, so it rises into the middle of the
  frame as the station goes on. The ice stops being a ruled line: cirrus at this
  height is *uncinus*, hooked, and the fallstreaks are three per streak on the same
  path, so nine streaks still cost nine strokes.
- Five-frame middle third: 1.33, 2.83, 2.56, 1.14 → 1.38, 2.89, 2.97, 1.86. **The gain
  is small and nearly all of it is in the station's second half**, which is where the
  anvil has risen far enough to be in the middle third at all. A hooked filament is
  two pixels of line however long its tail is; it moves the picture far more than it
  moves this number, and that is reported rather than tuned around.

**Defect three: the estuary is the spray, one act on and with the water arriving.**
Everything in the frame hangs off `seaY` and `seaY` runs from 0.68h to 0.18h, so by
the station's late image the salt wedge — which the file calls the one detail that
carries the picture — has left through the top of it and what is under it is bare
gradient. The lower two thirds read **0.84 and 3.11** against 6.58 and 7.64 at the
same station's opening.

- It contradicts §10 in the frame that is supposed to be the arrival — *by the estuary
  the whole lower half of the picture is a place rather than a distance* — and it sits
  immediately in front of act VII's salt line, which is empty below on purpose. Two
  adjacent stations cannot both be that.
- Silt is the missing plane: a river mouth carries its bed in suspension, the plume is
  the one thing about an estuary that is visible from orbit, and it is the only element
  here that never reads `seaY`. Radial gradients in a squashed frame rather than `bank`
  lumps, because a mass in water has no side to it.
- Both of its numbers were measured rather than chosen. Three plumes 0.52h apart left
  the late middle third *between* two of them, reading 0.97 against a baseline of 0.84
  — the defect with a smaller radius. And a plume nearly two screens wide has almost no
  variation along a row: it darkens the water without giving it a shape. Six, a third
  of a screen apart and half a screen across, read **1.33**.
- That is short of the 1.45 the spray's own fix landed on, and it is left there. The
  alternative is a murky frame in the campaign's quietest handover, and the picture is
  the criterion the number is evidence for.

**Two suspicions the numbers refused.** The brook's 15.9 and the estuary's 11.9 row
step at 0.93h are the obstacle silhouettes — a shape with a contour, which the frozen
visual language asks for on large silhouettes — and they appear only in the two
*intermediate* sections that no guard shoots. Worth knowing before someone extends the
opening pass to every section and finds act VI failing on its own content.

### What the act VII picture review found

Six stations, all eighteen of their sections, five frames a second apart, and act I
measured beside them section for section — because act VII's whole claim is that its
last frame *is* act I's first, and that is a claim about numbers as much as about
paint. It holds: the trench floor reads 15.7, 18.0, 20.7 mean against act I's own
14.4 to 16.1, rising only by the gold the ending adds.

**Both sweep instruments found nothing, and that is the finding.** All eighteen
sections read **3.37 to 4.90** on the seam and **1.41 to 2.40** on the column step,
against floors of ten and nine — the quietest act in the campaign on both. Act VI
predicted this. The defect it could not catch was a *partial-width* row step, and
this act had one too.

**Defect one: the sunlit zone's shafts had a bottom, and it is the third time the
campaign has shipped this.** Five shafts, each a `fillRect` filled with a gradient
running *across* it, so both sides are edgeless and nothing at all varies down the
column: the shaft switched off in one pixel at the row `end` puts it. The anvil's
light band, the canopy's shafts, these — the same sentence three acts apart.

- No sweep could see it. `seam` and `rib` want the whole frame to agree and a shaft
  is a seventh of the width; the local step act VI built and threw away is swamped
  here by the swarm, which reads 8 to 23 units in the same columns. So it was
  measured the way act IV's limb was: aimed at the row the arithmetic names, inside
  one shaft's own columns, following the same shear the fill was drawn under. The
  largest step in a shaft's columns landed on **that shaft's own `end`, to three
  decimals**, at **5.0 to 7.2** units — 5.13@0.563h against an `end` of 0.564h,
  6.46@0.714h against 0.714h, 7.18@0.704h against 0.705h.
- It is a radial gradient in a squashed frame now, the nacreous lens and the aurora
  curtain stood on end, with the circle pushed up its own axis so the bright part is
  off the top of the frame and the long tail is the one running down the water. The
  fill dies exactly where the rect used to stop, so **the light still runs out on the
  station's own schedule** — that half of the design is the one a shape fix could
  quietly delete, and the unit test asserts it separately.
- Every peak at every `end` is gone: what is left in those columns is the swarm and
  the rings, at the rows they were always at.
- Peak alpha doubled to pay for it, and the multiplier is arithmetic rather than
  taste. The old fill was a constant alpha all the way down the shaft's middle; this
  one falls from 0.65 of peak at the top of the frame to nothing at `end`, averaging
  0.325. The station's three sections read 87.3, 85.4, 82.5 mean before and **86.7,
  84.9, 82.1** after — parity, which is what was aimed at. Its middle third goes 9.88,
  5.08, 1.01 to 8.72, 4.05, 0.96: the light sits higher in the frame now, which is
  where light in water actually is.

**Defect two: the salt line never drew the thing it is for.** The module says the
station has "the first living things the campaign has had since the estuary —
plankton, drifting up past the swarm because the swarm is going down", and §11's
handover sentence is *where fresh water meets salt, the gold reappears as small
living forms*. What the frame contained was the receding surface, the caustics under
it and marine snow. This is the umbra's cities one act on: not a line that should not
be there, but a thing that should be and never was.

- Its middle third read **2.78, 1.72, 1.80** across the three sections — the range the
  campaign's *empty* stations read, in the frame that opens the last act.
- Two planes of them now, and their `wrapY` rate is the whole design: `falling` is
  what is *left* of life nearer the surface and it descends with the swarm at a rate
  near zero, so it barely moves on the glass. Plankton is life, and life holds the
  depth it lives at — rate 1 and just above — so the swarm goes past it. One goes with
  you and the other does not, and that difference is the station.
- They pulse out of phase on one shared path, so a plane of larvae is one fill however
  many there are. **Every bell needs its own `moveTo`**: without it `ellipse` joins
  each body to the last and twenty of them become one enormous polygon, which is what
  the first build of this did and what took the station's mean from 84 to 112 before
  anyone looked at the frame. The number said *more picture*. The frame said what had
  actually happened.
- Middle third after: **3.15, 2.10, 2.34**, with the station's mean unmoved at 84.2,
  78.7, 75.6. The gain is small and is reported rather than tuned at, for the reason
  the marine snow station demonstrates below: this instrument barely sees particulate.

**What the numbers refused, and why the act's emptiness is not the defect act VI's
was.** Three of these six stations empty out through the top of the frame as they go —
the salt line's ceiling, the twilight's edge line, the sunlit zone's shafts — and the
twilight's middle third runs 8.67 to 1.32 across its own sections. That is the act:
*the light is behind you now, and it drains upward and out across six stations*. The
estuary's emptying was a defect because §10 asks for the arrival's lower half to be a
place; §11 asks for the opposite, and a station cannot be corrected for obeying its
own design. What was corrected is a station that did not draw what its own file says
is in it.

**And one instrument's blind spot, named.** Marine Snow's middle third reads 1.55 —
lower than the deep sea's 1.90, in the one station whose entire subject is that the
frame is full of falling particulate. The picture is there; 166 specks of one to two
pixels at a tenth alpha simply do not move a horizontal-spread number. Band spread
answers *is there a shape in this row*, and a field of motes is not a shape. Worth
knowing before somebody reads a low band number as an empty station.

### What the colour review found

**The suite had never had a colour instrument, and §14 is the only criterion that is
about hue.** Every number this project has ever pointed at a frame is a *luminance*
number: `frame()` in `e2e/acts.spec.ts` collapses each pixel to one Rec.601 value
before it does anything else, and the seam pass, the column-step pass and the band
pass are all built on that one value. That is the right reduction for the six defects
those passes were written for — every one of them is an edge — and it cannot tell
teal from gold. So the palette was read where it is actually authored: forty zone
palettes and forty-two motifs, in OkLCh, by `tools/palette.sweep.ts`.

**What the wash is, measured rather than assumed.** `Renderer.drawBackground` folds
the motif's `wash` into the three stops of the zone gradient, and its own comment
says what for: act I paints six levels from four zone palettes, so two stations
sharing one have nothing else to tell them apart. The measurement says that is
*literally* all it is for. The only washes in the campaign carrying a real **hue**
shift are act I's shared-zone pairs — the midnight current at 61° and the light line
at 58° off the mid they are laid over. Every act after act I gives each station its
own zone, the mechanism has nothing left to separate, and the thirty authored washes
degenerate into a *tone*: 24 of them sit within 6° of their own mid and move it
almost entirely in lightness.

**The defect: twelve stations washed with their own zone's `mid`, byte for byte.**
Two in act V (the plasma, the nucleus), five in act VI and five in act VII — a column
filled in rather than authored. Mixing the middle stop with itself is arithmetically
nothing (**0.0000** in OkLab, against 0.0009 to 0.0371 for the other thirty), but the
top and bottom stops are still pulled toward it, so the tint that added no colour went
on charging the gradient **10 to 16 per cent of its vertical range**. Those twelve
rendered a flatter water than the zone table authored.

- No guard could have caught it and none was badly written. The defect has no edge in
  it: it is a gradient that is *correct in shape and short in range*, which is exactly
  what every instrument in the suite is built to ignore. `spread` is taken over the
  whole frame, and the whole frame always has the banner, the HUD and the swarm in it.
- They declare `washAmount: 0` now. A station may have no colour of its own — most of
  them genuinely do not, because their zone already **is** their colour — but it may
  not pay for one it is not getting.
- Measured on the glass, all eighty-four frames, before and after. The twenty-four
  frames of the twelve gain spread in every case, median **+0.95** and up to **+3.50**
  at the plasma, while the mean barely moves (largest 1.40, median 0.65) — depth back,
  brightness unchanged. The sixty untouched frames read |Δmean| ≤ **0.10** and Δspread
  −0.50 to +0.20, which is the scatter of a rebuilt but unchanged build and sets the
  floor the gains are read against. Seam and column step stayed at 6.97 and 6.05
  against floors of ten and nine.
- Two of the twelve gained nothing: Marine Snow at +0.0 and the deep sea at +0.2, both
  inside the noise. Their gradients run 0.19 to 0.14 in lightness — there was almost no
  range there to give back. Reported rather than tuned.
- **The nearest thing left alone is the squall**, whose wash moves its mid by 0.0063 —
  close enough to nothing to be worth knowing about, and left because it was *written*
  rather than copied. The floor in `tests/palette.test.ts` sits at 0.004, between it
  and the twelve's zero.

**Defect two: the violet crown in both auroras was computed every frame and handed to
a stop that cannot show it.** `mix(motif.crest, [200,160,255], 0.35)` in act IV and
`[190,150,255]` in act V, each used only at `rgba(crown, 0)`. Proved rather than
argued, because a zero-alpha stop is not obviously inert — canvas interpolates
gradients in *premultiplied* space, so what a transparent stop leaks is whatever 8-bit
rounding leaves. Composited over an opaque sky with `lighter`, swapping the violet for
pure red moved the frame by **4 of 255 at most on one channel** and swapping it for the
green by **2**, against **15** for a control carrying 0.06 alpha. It was never on the
glass. Deleted, and the frames confirm it: the aurora reads 26.8 → 26.7 mean and the
aurora-from-below 31.1 → 31.0, inside the noise floor above. Had it worked it would
have been a *third* hue in those frames, which is the one thing the visual language
does not have — teal and one warm, and there green and nothing else.

**Three things measured and deliberately not touched.**

- The **nucleus** is the campaign's one achromatic station: every colour it declares is
  under 0.03 chroma. It sits at the act V → VI handover, where §14 asks for grey-blue
  rain, so the greyness is the arc rather than a gap.
- The **gold runs at half chroma through act VI** — 0.057 to 0.076 against 0.105 to
  0.118 in act I — in the one act whose carrier is water. §14 calls the golden
  life-spark every act's visual link, and this is the act where it is quietest. It is
  a question for whoever takes the arc next, not a defect to fix on this evidence.
- The **shoal inverts inside act II**, L 0.24 at the squall to 0.97 at the anvil. That
  is correct and worth knowing: the top of a storm is dark, and a dark flock against it
  would disappear. Contrast against the medium, not a palette break.

### Not started

> Several of the surfaces named below (the setting, high contrast) no longer exist; see
> the note under "What the settings review found".

**Act IV has still never been flown from Free Fall to the Overview by a person.** A
bot now finishes it on six seeds in eleven, which it could not do at all while the
orbital gate was bowed the wrong way, so the act is no longer suspected of being
unflyable — but six in eleven is a scripted hand scraping through, and the thing
outstanding from §1–§17 is unchanged: somebody has to play it. Act IV's *furthest
section* is watched by `tools/finish.sweep.ts` in the meantime, and 14.5/18 is now
the number a regression would move.

> The five revisions of this section are worth leaving written down, because the
> fifth is the one with a lesson the other four do not have. The first four were
> each a surface that had never been asked a question — the films and high
> contrast, the ending cues and the audition panel, the banner and the setting.
> This one was a surface that *was* asked, answered `0/11`, and had its answer
> believed: the sweep was right, the reading of the sweep was careful, and the
> conclusion drawn from it ("act IV is a wall; change nothing on this evidence")
> was the correct instinct applied to a measurement whose cause nobody went and
> looked at. **A number that has been explained is not the same as a number that
> has been diagnosed**, and an explanation that recommends doing nothing is the
> one that never gets tested.

> This section said *nothing from §1–§17 is outstanding* two revisions earlier and
> was wrong three times over; the revision that corrected it was wrong a fourth
> time. All four are worth leaving written down rather than quietly correcting.
> Act IV is above. §14's *high contrast must work in every new renderer* had never
> been met by any of the seven films — the setting could not reach them, because
> `FilmView` did not carry it — and §16's *every new sound auditionable* had never
> been met by six of the seven ending cues. The fourth is §14 again, on the one
> surface the previous pass did not think to look at because it is not a film:
> **the station banner**, the only text in the game drawn on the canvas, which
> never read the setting at all. All four are closed above.
>
> None of the four was visible from inside the suite, and every test that could
> have failed was passing — because a renderer that ignores a setting draws
> exactly the picture the tests assert, a sound nobody can trigger is a sound
> nobody has heard, and a sweep that stops at 300 seconds cannot report that an
> act does not end. All four have the same shape as each other and as the
> missing-film bug in §18: **a surface that was built when there were two or three
> of a thing, and was never re-derived when the campaign made seven.** That is the
> class of defect to go looking for, and "nothing is outstanding" is exactly the
> sentence that hides it. It should be read as "nothing is *known* to be
> outstanding".
>
> The fourth one carries its own lesson on top of that, because it was found
> *one requirement at a time*: the pass that closed the films read §14, checked
> the seven renderers §14 was about, and stopped. The banner is not a renderer in
> that sense — it is chrome — and it fell in the gap between "every new scene" and
> "the HUD". The question that finds this class is not *does the setting reach the
> seven*, it is **what else on the screen has text on it**.

---

## 19. Station checkpoints, and the act as one attempt

Two things were true of the shipped campaign that nobody had ever argued for, and
both of them were artefacts of the order the acts were built in.

**The save was drawn at the wrong line.** The campaign wrote itself down once an
act. The reason given for that is in `meta/Campaign.ts` and it is a good reason for
a different limit: a checkpoint in the *middle* of a station would mean restoring a
swarm's positions and velocities, which is a savegame of a simulation, and the
first thing that would do is make every future physics change break every existing
save. But a station *boundary* is not a snapshot. It is an act index, a station
index, a headcount and a number of points, and the station it names is rebuilt from
its own first section by the same `World.reset(seed, section)` that builds any run.
Nothing about the simulation is stored, so nothing about the simulation can go
stale — the argument never applied to it.

What drawing the line at the act cost was the whole point of having a save. An act
is fifteen to twenty-five minutes. A phone call, a tab reclaimed in the background,
or a home button is enough to take all of it, and the player was handed back a save
that said *you were in act V* and made them fly it from the top.

So the campaign checkpoints at every station it clears. The value stored in
`CampaignPosition.level` is **the next station to start**, never the last one
finished — the save is a place to resume, not a receipt — and the sim's own station
event already carries that number, so there is no arithmetic at the call site to
get wrong. Cargo and banked score go with it, which makes a crash cost the current
station and nothing else.

Points are booked exactly once, and that is the only part of this with any teeth.
`RunState.score` is cumulative over a whole run, so a controller that banked it at
every boundary would bank station one's points six times over by the end of the
act. `CampaignController.credited` is the high-water mark each checkpoint is
measured against: a boundary contributes the difference and nothing else, a
repeated save contributes nothing, and a restart — which cuts the live score by
`restartCost` — cannot un-bank a station already cleared or make the climb back up
to the mark payable twice.

**The failure rule was three rules.** §12 gave the campaign a failure arc that only
ever softened: acts I and II ended the run, III–VI restarted the station, act VII's
last three stations could not be lost. The softening is right and the *start* of it
was accidental. Acts I and II are what a player meets first, on a phone, before
they have learned anything — and they were the only two that could take twenty
minutes for one mistake.

Every act restarts the station now, at the same price (`RESTART_ON_FAILURE`, a
sixth of the live score) through the same code path (`World.restartStation`), stated
in exactly one place: `makeAct`'s default. The five act files that each named the
policy by hand no longer do, so an act cannot acquire its own price by being
written slightly differently from its neighbours. `END_ON_FAILURE` survives for the
generated water the headless probes measure on, which has no authored station to go
back to.

Act VII's `'none'` stations are untouched, and that is the end of the rule rather
than an exception to it: the last water in the campaign has no failure state to
unify, and inventing one so the table reads evenly would end the campaign on a
threat.

### The act is one attempt

Those two changes together have an obvious hole in them, and it is worth stating
before the fix rather than after: an unlimited station restart is a station you
cannot fail, only take longer over. Six stations retried independently, in any
order, across any number of sittings, is not a journey flown — it is six unrelated
exercises, and the campaign's whole claim is the opposite.

The naive correction is to end the act on the first mistake, and it is worse than
the hole. A slip on the sixth station would delete fifteen to twenty-five minutes
of correct play, which is not difficulty: the act does not get harder, it gets
longer, and what the player re-flies is content they have already proved. That is
also the most mobile-hostile shape available.

So the act carries a **budget of two restarts** (`RESTARTS_PER_ACT`; *since then* it is
a rate, `restartsForMinutes` in `sim/Failure.ts`: two for act I and three for each of the
other six at today's lengths). A station may
be got wrong and learned; an act may not be ground through; the third failure ends
the run and the attempt goes back to `CampaignState.actStart` — the act's first
station, the cargo it was entered with, the score it was entered with, a fresh
budget. The player is shown the results screen, because a twenty-minute loss that
silently teleports somebody back to station one is a bug as far as they can tell.

Three details carry the weight:

* **The budget lives in the campaign, not in `RunState`.** An attempt can span any
  number of runs once an interruption can happen inside one, so a run-local count
  would be refilled by closing the app and reopening it. An interruption must be
  worth exactly nothing — neither a penalty nor a refund. `World.restartBudget` is
  seeded from `CampaignController.attemptsLeft` at `startRun` and the sim's own
  copy is only ever a frame out of date.
* **The rollback is arithmetic, not punishment.** Points banked at stations the
  player is about to re-fly would otherwise be paid for twice, which makes dying
  *profitable*: clear five stations, die on the sixth, repeat. `actStart` is the
  snapshot that makes the second attempt worth what the first was and no more, and
  it has to be stored because `banked` and `cargo` are both overwritten as the act
  goes on — by the third station nothing is left in the state that remembers what
  entering the act looked like.
* **Death and interruption are told apart without a flag.** Nothing runs when an
  app is killed, so an interruption leaves the last station checkpoint standing. A
  death runs `loseAct`, and `loseAct` writes the act's own beginning over that
  checkpoint. There is no "was this exit clean" test to get wrong about a crash,
  because a crash never reaches the line.

The known cost of that last one: killing the app immediately before dying keeps the
station. It is a deliberate trade — the alternative charges every real interruption
for the few that were not one, and the whole point of the checkpoint was that a
phone call is not a mistake.

**The probes do not get the budget, and that is methodology rather than
convenience.** `World.restartBudget` is unbounded until something sets it, and the
only thing that sets it is `main.ts` at `startRun`. Every headless probe in
`tests/` and `tools/` is a fixed-time instrument — give two policies the same T
seconds and compare what they did with it — and a rule that *ends* a run turns T
into a variable, which does not measure the game better: it removes the control
variable from every comparison in the suite. Measured, giving the probes the budget
moved act I's rescue-choice probe by enough to fail it (detour rescues 233.9
against safe's 242.2, where the design asserts detour buys at least 5% more fish),
with nothing about the water having changed. The budget is a campaign rule; the
probes measure the simulation; `tests/checkpoint.test.ts` asserts the rule directly,
per act, by setting the budget it is testing.

Two marks in the top-left corner say what is left, and they follow the streak
badge's rule: **nothing is drawn while there is nothing to say.** A player who has
not failed sees empty water, which is most players for most of an act. Spent marks
stay as outlines rather than vanishing, because "one of two" is the fact and a mark
that disappeared would only say "one"; the last one runs warm, because at that
point the next mistake is the act.

`tests/checkpoint.test.ts` holds all of it — the off-by-one, the restore from a
seed and a section, exactly-once banking, the restart price in every act, the third
failure ending the run in every act, a lost attempt that cannot be made profitable,
and the old saves (`level: 0`, no `level`, no `actStart`) that still open where they
always did. `e2e/campaign.spec.ts` drives the same thing through the real shell, a
real `page.reload()` and three real deaths, because every join between those pieces
is an off-by-one waiting to happen and none of them is visible from a unit test.

---

*Code, identifiers, commits and comments are English. Station names appear here in
English because they are player-facing text and live in the level files as
`name`.*
