"""The recipe for every sound effect: what it is meant to sound like, and how it is built.

Written without being heard - Claude cannot listen - so each recipe says in its
docstring what it is *meant* to be, and the listening rounds judge whether it
is. The numbers are starting points to be tuned by ear.

The file names mirror the Java contract, `com.tomer.scoundrel.audio.Sound`:
`<sound>_<version>`, or `<sound>_<weight>_<version>` for a weighted sound.
AudioAssetsTest holds the folder to that enum, and check.py holds this list to
the folder, so the three cannot drift apart silently.

Weights index 0 = light, 1 = medium, 2 = heavy. The thud has no medium.
"""

import zlib
from dataclasses import dataclass, field

import numpy as np

import synth as s

WEIGHTS = ("light", "medium", "heavy")
FRAME = 1 / 12
"""One effect frame. The bare-handed blows land a frame apart, and so do the deal's cards."""


# --- the recipes -------------------------------------------------------------

def click(rng, w, v):
    """A menu button going down: a small, dry, wooden 'tock' - a damped knock with a
    tick of grit on the front. Quiet; it is the only sound on most menu screens."""
    n = s.samples(0.07)
    body = s.modal(n, [(1150, 1.0, 0.035), (2320, 0.35, 0.02), (3480, 0.15, 0.012)])
    tick = s.bandpass(s.noise(n, rng), 3200, q=1.0) * s.decay(n, 0.006)
    return body + 0.5 * tick


def flip(rng, w, v):
    """A card from the dungeon landing in the room: a soft papery 'fwip' as it settles on
    the table - more air than snap - with a gentle pat under it. Four land a frame (83 ms)
    apart, so each is soft and each version has its own shape.

    Round 1: the first render's flips were a hard 2-3 kHz snap with a sub-millisecond
    attack, alike enough that four in a row read as a machine gun. Now lower and wider,
    a slower attack, and versions that differ in shape: a plain settle, one with a second
    brush as the card's face follows its edge, and a duller one with more pat."""
    # Round 1, second pass: still "a bit like a machine gun" - four even, separate
    # attacks at a steady 83 ms, with the level falling ~34 dB between them. Now each
    # flip swells in over 25 ms and settles over ~0.35 s, so the cards of a deal overlap:
    # the level only bumps ~12 dB between cards (~10 with the riffle's fading contour)
    # and the deal reads as one gesture. The low pat that thumped on every card is
    # softened for the same reason.
    centre, t60, pat = ((1150, 0.33, 0.12), (1400, 0.30, 0.10), (950, 0.37, 0.18))[v - 1]
    n = s.samples(t60 + 0.05)
    t = s.times(n)
    centre *= 1 + 0.05 * rng.uniform(-1, 1)
    # The band slides down a little as the card settles.
    centres = centre * (1.25 - 0.25 * np.clip(t / 0.05, 0, 1))
    air = s.lowpass(s.swept_bandpass(s.noise(n, rng), centres, q=0.7) * s.attack_decay(n, 0.025, t60), 3000)
    x = air + pat * s.sweep_sine(n, 170, 110, 0.02) * s.attack_decay(n, 0.015, 0.05)
    if v == 2:
        brush = s.lowpass(s.bandpass(s.noise(n, rng), centre * 0.8, q=0.6), 2500) \
            * s.attack_decay(n, 0.01, 0.12)
        x += 0.35 * s.place(n, brush, s.samples(0.02))
    return x


def sweep(rng, w, v):
    """A whole room swept back into the dungeon: four cards whooshing away together, a
    band of noise sliding down as it goes, with a papery flutter. The cards are gone
    in 250 ms, so is the sound."""
    n = s.samples(0.34)
    t = s.times(n)
    centres = 3200 * (700 / 3200) ** (t / t[-1])
    whoosh = s.swept_bandpass(s.noise(n, rng), centres, q=1.3)
    swell = np.clip(t / 0.03, 0, 1) * np.exp(-np.maximum(t - 0.03, 0) * s.LN_1000 / 0.3)
    flutter = 1 + 0.35 * s.one_pole_lowpass(s.noise(n, rng), 40) * 6
    return whoosh * swell * np.clip(flutter, 0.3, 1.7)


def equip(rng, w, v):
    """A weapon set down on the rail: an iron clank - the inharmonic ring of a struck bar -
    with a short scrape in its attack. A shiv rings high and brief; a greatsword rings
    low and long, with a dull thump of weight under it."""
    base = (1250, 820, 520)[w]
    t60 = (0.18, 0.30, 0.48)[w]
    n = s.samples(t60 + 0.08)
    ratios, amps, decays = (1.0, 2.76, 5.40, 8.93), (1.0, 0.6, 0.35, 0.2), (1.0, 0.6, 0.4, 0.25)
    partials = [(base * r * (1 + 0.004 * rng.uniform(-1, 1)), a, t60 * d)
                for r, a, d in zip(ratios, amps, decays)]
    ring = s.modal(n, partials)
    scrape = s.highpass(s.noise(n, rng), 2500) * s.attack_decay(n, 0.001, 0.05)
    thump = s.sweep_sine(n, 160, 60, 0.03) * s.attack_decay(n, 0.001, 0.15)
    return ring + 0.4 * scrape + (0.0, 0.3, 0.6)[w] * thump


def blade(rng, w, v):
    """A weapon kill, the blade landing: a fast swoosh of air that turns into the thin
    'shing' of steel, with a dull cut under it. The ring swells in, as if by friction
    along the edge, rather than being struck. Light blades are short and high; heavy
    ones move more air, lower and longer, and cut deeper.

    Round 1: the first render was a struck, inharmonic ring at 1.3-2.6 kHz with a thump
    under it - a pick on stone - and it read as mining. What separates a slice is that
    nothing is hit: the steel is drawn. So no strike and no thump; a swoosh that rises
    and falls, and a high ring of two close pitches that shimmer against each other."""
    n = s.samples((0.30, 0.38, 0.48)[w])
    t = s.times(n)
    # The swoosh: a band sweeping up to its peak, then falling away.
    lo, hi = ((1200, 5500), (900, 4500), (600, 3500))[w]
    peak_at = (0.025, 0.02)[v - 1]
    shape = np.where(t < peak_at, t / peak_at, np.exp(-(t - peak_at) / 0.04))
    swoosh = s.swept_bandpass(s.noise(n, rng), lo + (hi - lo) * shape, q=1.1) \
        * s.attack_decay(n, 0.02, (0.10, 0.13, 0.16)[w])
    # The shing: steel ringing, swelling in over ~12 ms, shimmering where two partials beat.
    base = (3400, 2800, 2200)[w] * (1.0, 1.06)[v - 1] * (1 + 0.02 * rng.uniform(-1, 1))
    t60 = (0.22, 0.30, 0.40)[w]
    ring = s.modal(n, [(base, 1.0, t60), (base * 1.004, 0.8, t60), (base * 1.87, 0.4, t60 * 0.6),
                       (base * 2.93, 0.2, t60 * 0.4)], attack=0)
    friction = 1 + 0.3 * np.clip(s.one_pole_lowpass(s.noise(n, rng), 60) * 12, -1, 1)
    ring *= (1 - np.exp(-t / 0.012)) * friction
    # The cut: a short, dull tick of the edge going in.
    cut = s.lowpass(s.noise(n, rng), 900) * s.attack_decay(n, 0.001, 0.03)
    return swoosh + 0.35 * ring + (0.25, 0.4, 0.55)[w] * cut


def thud(rng, w, v):
    """Damage getting through the weapon: a heavy body blow under the blade - a deep punch
    with a hollow knock in the chest and a crack of grit on top. Heavier when more got
    through. Absent on a clean kill.

    Round 1: the first render was nearly all sub-bass (45-150 Hz), which most speakers
    barely play; it was all but inaudible even at its heaviest. The knock at ~300 and
    ~520 Hz carries on small speakers, and the harder saturation adds harmonics the ear
    reads as the missing low end."""
    heavy = w == 2
    n = s.samples(0.40 if heavy else 0.26)
    f_start, f_end = (150, 55) if heavy else (190, 75)
    # The second version differs by design, not by chance: a low sine is much of
    # this sound, and a random few-percent detune left the first render's two near-identical.
    detune, drop = ((1.0, 0.05), (0.88, 0.07))[v - 1]
    detune *= 1 + 0.02 * rng.uniform(-1, 1)
    body = s.sweep_sine(n, f_start * detune, f_end * detune, drop) \
        * s.attack_decay(n, 0.002, 0.32 if heavy else 0.18)
    knock = s.modal(n, [(300 * detune, 1.0, 0.10 if heavy else 0.07), (520 * detune, 0.5, 0.06)],
                    attack=0.001)
    grit = s.bandpass(s.noise(n, rng), 900, q=0.7) * s.attack_decay(n, 0.0005, 0.02)
    return s.saturate(body + 0.6 * knock + 0.4 * grit, 3.0 if heavy else 2.0)


def fist(rng, w, v):
    """A bare-handed fight: two blows a frame (83 ms) apart, each a low punch with the
    smack of it landing and a slap of skin on top. The heavier the monster, the deeper
    and longer they land. Both blows are in the one file, matching the two stars.

    Round 3: "very silent" under the music. The punch is a sine falling through
    50-190 Hz - the band where the run's drone and heartbeat are loudest, and which small
    speakers barely play - and above 250 Hz the fist stood only 1-9 dB over the music,
    where the blade stands 20-35. Now each blow has a smack of mid-range noise
    (750 / 560 / 420 Hz by weight) and a longer, stronger slap, so it carries where the
    music is quiet; the punch stays for weight, as the thud's knock did in round 1."""
    t60 = (0.09, 0.12, 0.16)[w]
    f_start, f_end = ((190, 80), (150, 65), (115, 50))[w]
    smack_band = (750, 560, 420)[w]
    slap_band = (2200, 1600, 1100)[w]
    # Versions differ by design: pitch, how fast the punch drops, the spacing and
    # balance of the two blows. A random few-percent detune left them near-identical.
    detune, drop, late, second_strength = ((1.0, 0.025, 0.0, 0.85), (0.9, 0.04, 0.006, 1.0))[v - 1]
    gap = s.samples(FRAME + late)
    n = gap + s.samples(t60 + 0.06)

    def blow(strength, shift):
        m = s.samples(t60 + 0.06)
        k = detune * shift
        punch = s.sweep_sine(m, f_start * k, f_end * k, drop) * s.attack_decay(m, 0.001, t60)
        smack = s.bandpass(s.noise(m, rng), smack_band * k, q=1.2) * s.attack_decay(m, 0.001, 0.04)
        slap = s.bandpass(s.noise(m, rng), slap_band * k, q=0.8) * s.attack_decay(m, 0.0005, 0.025)
        return strength * (punch + 3.0 * smack + 1.5 * slap)

    first = blow(1.0, 1 + 0.02 * rng.uniform(-1, 1))
    second = blow(second_strength, 0.93 + 0.02 * rng.uniform(-1, 1))
    x = s.place(n, first, 0) + s.place(n, second, gap)
    return s.saturate(x, (1.2, 1.6, 2.2)[w])


def drink(rng, w, v):
    """A potion pouring: a quick run of glugs - bubbles, each a tone that rises as it dies -
    over a soft wash of liquid. A dram is three small high bubbles; a flagon is six
    deeper ones and a longer pour."""
    count = (3, 4, 6)[w]
    lo, hi = ((600, 900), (450, 750), (320, 600))[w]
    spacing = (0.06, 0.07, 0.08)[w]
    n = s.samples(count * spacing + 0.16)
    x = np.zeros(n)
    at = 0
    for i in range(count):
        f0 = rng.uniform(lo, hi)
        b = s.bubble(s.samples(0.08), f0, rise=8.0, t60=rng.uniform(0.03, 0.05))
        x += s.place(n, b * (1.0 if i == 0 else rng.uniform(0.6, 0.95)), at)
        at += s.samples(spacing * rng.uniform(0.8, 1.2))
    t = s.times(n)
    wash = s.lowpass(s.noise(n, rng), 1200) * np.clip(t / 0.02, 0, 1) * np.exp(-t * s.LN_1000 / (n / s.SR))
    return x + 0.08 * wash


def spill(rng, w, v):
    """A wasted potion tipping over where it stood: a small glass tink as the bottle goes
    over, then a thin dribble - drained and quiet, because nothing reaches you."""
    n = s.samples(0.5)
    tink = s.modal(n, [(3100, 1.0, 0.12), (7300, 0.4, 0.06), (10100, 0.2, 0.04)])
    x = 0.6 * tink
    for at, f0 in ((0.12, 1300), (0.2, 1000), (0.27, 1150)):
        x += 0.35 * s.place(n, s.bubble(s.samples(0.06), f0, rise=6.0, t60=0.035), s.samples(at))
    splash = s.lowpass(s.noise(n, rng), 1800) * s.place(n, s.decay(s.samples(0.15), 0.12), s.samples(0.1))
    return s.lowpass(x + 0.15 * splash, 3500)


def chime(rng, w, v):
    """Trophies unlocked: two warm bell strikes a fifth apart, D5 then A5 - the key the
    music is in. A little ceremony, not a fanfare."""
    n = s.samples(1.7)

    def bell(fundamental):
        # hum, prime, tierce (minor third), quint, nominal: a church-bell's partials
        return s.modal(s.samples(1.7), [
            (fundamental * 0.5, 0.35, 1.4), (fundamental, 1.0, 1.1), (fundamental * 1.2, 0.45, 0.8),
            (fundamental * 1.5, 0.3, 0.6), (fundamental * 2.0, 0.35, 0.5), (fundamental * 2.74, 0.12, 0.3)],
            attack=0.001)

    return s.place(n, bell(587.33), 0) + 0.8 * s.place(n, bell(880.0), s.samples(0.14))


# --- the catalogue -----------------------------------------------------------

@dataclass(frozen=True)
class Recipe:
    sound: str
    build: object
    versions: int
    weights: tuple = ()
    target_db: tuple = ()
    """Loudness per weight (or one value), as the loudest 50 ms in dBFS."""
    max_seconds: float = 1.0
    lofi: dict = field(default_factory=dict)


# Loudness targets, K-weighted (as heard: see synth.loudness_db), relative to one another.
#
# Round 1 set them. The first render was levelled by plain RMS, which heard the old thud
# 7 dB under the blade it sits beneath and the flips louder than the click, and the user
# flagged exactly those. Every sound the user did not flag keeps the level it was heard at
# in round 1, re-measured this way. The blade keeps its level under its new sound. The
# thud now sits level with the blade (heavy) and a notch under (light). The flips are
# about 3.5 dB under where they were heard.
#
# Round 3 raised the fist, "very silent", from -17.5 / -17 / -16.5 to the blade's
# neighbourhood: a bare-handed kill always costs health, so it lands at least as hard as
# a weapon kill. Every other effect keeps its level; the music came down (music.py).
RECIPES = (
    Recipe("click", click, 1, target_db=(-23,), max_seconds=0.12),
    Recipe("flip", flip, 3, target_db=(-25,), max_seconds=0.45),
    Recipe("sweep", sweep, 1, target_db=(-18.5,), max_seconds=0.45),
    Recipe("equip", equip, 1, WEIGHTS, (-16.5, -16, -15.5), max_seconds=0.8),
    Recipe("blade", blade, 2, WEIGHTS, (-13.5, -13, -12.5), max_seconds=0.6, lofi={"cutoff": 9500}),
    Recipe("thud", thud, 2, ("light", "heavy"), (-15, -12.5), max_seconds=0.5,
           lofi={"hold_rate": 14000, "cutoff": 6000}),
    Recipe("fist", fist, 2, WEIGHTS, (-14, -13, -12), max_seconds=0.6,
           lofi={"hold_rate": 16000, "cutoff": 7000}),
    Recipe("drink", drink, 1, WEIGHTS, (-20, -19, -18), max_seconds=0.8),
    Recipe("spill", spill, 1, target_db=(-17.5,), max_seconds=0.8),
    Recipe("chime", chime, 1, target_db=(-18,), max_seconds=2.0, lofi={"cutoff": 10000, "bits": 11}),
)


# Options put to the user by ear, rendered only into build/candidates/ by audition.py.
# Not part of the contract, never under assets/. Removed once one is chosen: round 1
# tried one riffle per deal against a flip per card, and the flip per card won.
CANDIDATES = ()


@dataclass(frozen=True)
class Job:
    """One file to render."""
    name: str
    recipe: Recipe
    weight: int
    version: int
    target_db: float


def jobs(recipes=None):
    """Every sound-effect file, in the Java enum's order, with the parameters to build it.
    Pass CANDIDATES instead to get the audition-only options."""
    out = []
    for recipe in RECIPES if recipes is None else recipes:
        if recipe.weights:
            for weight_name, target in zip(recipe.weights, recipe.target_db):
                w = WEIGHTS.index(weight_name)
                for v in range(1, recipe.versions + 1):
                    out.append(Job(f"{recipe.sound}_{weight_name}_{v}", recipe, w, v, target))
        else:
            for v in range(1, recipe.versions + 1):
                out.append(Job(f"{recipe.sound}_{v}", recipe, 0, v, recipe.target_db[0]))
    return out


def render(job):
    """The finished float signal for one file. Seeded by its name, so it never changes
    unless its recipe does."""
    rng = np.random.default_rng(zlib.crc32(job.name.encode("utf-8")))
    raw = job.recipe.build(rng, job.weight, job.version)
    return s.finish(raw, job.target_db, lofi_args=job.recipe.lofi)
