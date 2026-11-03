# digitalTULPA — studio ident

Two files, no dependencies, one folder. Copy `src/brand/digital-tulpa/` into any
project that bundles CSS imports (Vite, webpack, Parcel, esbuild with a CSS
plugin) and it plays there unchanged.

```ts
import { playDigitalTulpaIdent } from './brand/digital-tulpa';

playDigitalTulpaIdent({ onComplete: () => showTitleScreen() });
```

That is the whole integration. The ident brings its own background, colour, type
stack and stacking context; it reads nothing the host project owns.

## How the name is written

**digitalTULPA.** One word, lowercase `digital`, capital `TULPA`. That is the form
for anything a person reads — page titles, store pages, credits, invoices, this
file.

Identifiers do not shout. Code keeps `DigitalTulpa` (`playDigitalTulpaIdent`,
`DIGITAL_TULPA_IDENT_DURATION_MS`), the DOM id stays `digitaltulpa-intro` and the
event stays `digitaltulpa:introcomplete`, because `playDigitalTULPAIdent` is
unreadable and a run of capitals inside camelCase has no word boundary left. The
wordmark in the ident renders the real form; the code spells the same name the way
code spells names.

## What it is

A tulpa is a thought-form imagined so completely that it starts acting on its own.
Both variants are that sentence, told from opposite ends.

| | |
|---|---|
| **`summon`** | The form is *built*. Brackets close in on empty space, the quotes drop, the eye rings are drawn stroke by stroke — and only then does something arrive inside them and look around. You watch it being made. |
| **`reveal`** | The form is already there, vast and out of focus, looking past you. The camera walks backwards until it resolves, and the last thing it does is find you. You discover it was always looking. |

Same lockup, same 6.6 seconds, opposite claim. Switch with `variant`, or set
`DEFAULT_IDENT_VARIANT` in `index.ts` to change what a plain call gets.

```ts
playDigitalTulpaIdent({ variant: 'reveal' });
```

Both end the same way, and this is the part that carries the idea: the eyes stop
looking around and centre on the viewer, then close once, slowly.

## The lockup is a face

Two eyes, two nostrils, one mouth. The pair of low dots in the middle was drawn as
punctuation and the code still calls it `.separator` — but a colon is stacked and
these two sit side by side, below the eye line, in the middle of the drawing. They
are nostrils, and the mouth is the piece that was missing rather than a decoration
added underneath a mark that was finished.

It is flat, level and closed, and that is the tone rather than a shortcut: a curve
up is a smiley and a curve down is a frown, and both give a thought-form that
watches you a mood it should not have.

The ends are round, after both alternatives were built and looked at. Tapered to a
point — drawn the way the brackets are drawn, on the argument that the mark has no
curves in it — reads as a quill stroke, and the tips are the first thing to go at
phone size. Square ends read as a censor bar. The semicircular cap is the terminal
the mark already owns: the quotes end that way, and the lashes that appear during a
blink are drawn with `stroke-linecap: round`.

It is drawn at the eye ring's own stroke width, 6, because that is the mark's line
weight and a mouth is a line. Matching the nostrils' mass instead gives a slab —
they are small enough to be solid shapes; 112 units of the same thickness is not.

It is **1.4× the width of the nose**, which is the ratio a mouth has to a nose. The
tempting measurement is the 139 units of air between the two marks — and every
version measured against *that* came out as a rule spanning the gap rather than a
feature belonging to the nose above it.

**The viewBox grew for this**, 158 → 251. A mouth needs air under the nose to read
as a mouth rather than as a rule under one, and 158 had eight units left below the
nostrils. The gap went 13 → 36 → 57 → 85 before it stopped looking hung off the
nose. The nostrils are what makes that counter-intuitive: they sit high, right
under the eye line, so the mouth is not placed relative to them — it goes where a
mouth goes in the frame and the gap is what is left over. 251 is the ink centred
again, which moves the eye line from exactly half the frame to 31% of it. That is
what a portrait does. `dt-reveal-pull`'s origin is a percentage of the viewBox and
moved with it; anything else that measures the box vertically has to move too.

In `summon` the mouth is the last thing built, at 2.72s, and the only part of the
lockup that opens from the centre out instead of landing.

## The palette

```
void    #07090C   near-black, a hair blue
ink     #EDEAE3   bone white — the built form
signal  #DDA53C   yellow ochre
```

**The logo is one colour.** The whole drawing — brackets, quotes, rings, pupils,
the nose and the mouth — is ink. The signal lands in exactly one place, `TULPA` in
the wordmark, which is type rather than drawing. A coloured pupil was built and rejected: a
second colour inside a single drawing turns it into a diagram of two parts instead
of one mark. Contrast against the void is 16.6:1 for ink
and 9.0:1 for signal, so the ident can be completely flat and still read on a
phone in daylight.

The ochre is the hue the brand already had: the wordmark's original gold was
`#C89536`, and `#DDA53C` is that hue lifted until it holds its own beside the ink.

There is no glow, no bloom and no grain. Where the ident needs to say *light*, it
says it with form: `.eye-ping` is a real ring that expands out of the pupil once,
at the one moment that earns it. The only blur in the file belongs to `reveal`,
where the focus pull *is* the subject.

## Options

| option | default | |
|---|---|---|
| `variant` | `DEFAULT_IDENT_VARIANT` | `'summon'` or `'reveal'`. |
| `reducedMotion` | `false` | Plays a 1.2s still instead of the performance. |
| `respectReducedMotionMedia` | `false` | Honour the OS `prefers-reduced-motion`. Off deliberately — see below. |
| `force` | `false` | Play under `navigator.webdriver`, which otherwise skips the ident. |
| `skip` | `false` | Do not play at all. A development door. |
| `zIndex` | `1000` | If the host has something higher. |
| `onComplete` | — | Fires once, after the ident leaves — natural end, skip, or a path where it declines to play. |

Also dispatched on `window`, for hosts that would rather listen than pass a
callback:

```ts
window.addEventListener('digitaltulpa:introcomplete', (event) => {
  // event.detail === { duration: 6600, variant: 'summon' }
}, { once: true });
```

`identOptionsFromSearch(location.search)` parses the development doors:
`?intro=summon`, `?intro=reveal`, `?intro=reduced`, `?intro=1` (force under an
automated browser), `?skipIntro`.

### Why `prefers-reduced-motion` is off by default

The ident used to honour it, and the result was that most phones never saw it. iOS
puts Reduce Motion one tap into Accessibility and plenty of people leave it on for
reasons that have nothing to do with a logo. What they got instead was a lockup
that appeared and vanished in 1.2 seconds — which reads as a bug, and got reported
as one.

The setting is not being ignored, it is being scoped. It exists for things that
move a screenful at a time, and this is a fixed lockup with a two-pixel eye
performance inside it. A project that disagrees passes
`respectReducedMotionMedia: true` and gets the still.

## Skipping

Any key or any pointer press ends it, as a 300ms fade rather than a cut — a cut
900ms in reads as a crash rather than as a choice.

The keystroke is **eaten**: the ident captures `keydown` and calls
`stopPropagation`. This matters more than it looks. Whatever the ident is covering
is usually still listening, and in the game this was written for, one press of
Space both dismissed the ident and started a run behind it — so the title screen
the ident exists to introduce was never seen at all. Everything else on `body` is
made `inert` for the ident's lifetime for the same reason, and restored after.

## Tuning it

Run the dev server and open **`/brand.html`** — the bench. Variant buttons, replay,
and a **scrub** mode that freezes every CSS timeline and replays the scripted beats
from the same `CHOREOGRAPHY` table the ident reads, so the slider shows the
performance rather than an approximation of it. It is dev-only: Vite's build input
is `index.html` alone, so it never reaches a bundle.

It exists because an ident cannot be tuned by watching it. Six and a half seconds
go past once and leave an impression rather than a note, and the beat that is 0.2s
late is invisible at speed and obvious on a scrubber. Every timing decision in this
folder was made on that slider — including the two that were plainly wrong on it
and looked fine at speed: `reveal` used the same arrival easing as everything else
and so finished its camera move in 700ms and then sat still for two and a half
seconds, and it framed its opening push on the middle of the lockup, which is the
colon.

The entrance beats live in `ident.css`, grouped under `Entrance: summon` and
`Entrance: reveal`. The performance beats live in `CHOREOGRAPHY` in `index.ts`, as
absolute offsets from the first frame rather than delays from the previous beat —
because the thing that actually goes wrong in an ident is two events landing on
the same 100ms, and that is obvious in a column of absolute times and invisible in
a chain of relative ones.

Nothing may be scheduled after 5.8s. `dt-lifecycle` starts the fade at 6.1s, and a
gesture that begins under a fade reads as a dropped frame.

## The square mark

`mark.svg` — 128×128, one bracket and one eye. Favicon, itch.io icon, Steam
capsule, social avatar. Nothing imports it; it is an export, so it never reaches a
bundle and you copy it out wherever it is needed.

```html
<link rel="icon" href="/mark.svg" />
```

It is **not a cropped lockup**, and it could not have been. The lockup is 5.4:1;
halving it to one bracket and one eye still leaves a group around 1.85:1, so
something has to give. What gives is the *ratio between the two parts*, never
either part's own geometry — every number in `mark.svg` is the lockup's, scaled,
and the chevron path is copied verbatim. The eye takes 63% of the frame where the
lockup's proportion would give it 49%.

Two alternatives were built and looked at before this one, at 160/64/32/20 px:

- **keeping the lockup's proportion** leaves the drawing in a thin horizontal band
  with half the square empty — a wordmark shoved in a box.
- **overlapping the bracket into the ring** fills the square best and destroys the
  idea: the two merge into one silhouette that reads as a comet with a tail, and
  the chevron's notch — the thing that makes it a bracket rather than a triangle —
  disappears behind the stroke.

The bracket degrades before the eye does, and that is the right way round. At 16
pixels the eye and its coloured pupil still say who this is; punctuation at 16 pixels
never says anything.

**The void is part of the mark.** Do not ship it on transparent — the ink and the
signal are chosen against `#07090C` and lose their contrast on anything lighter.
