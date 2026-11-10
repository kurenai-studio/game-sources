"""Build the music loops into assets/audio/music/.

Original tunes written for Trampoline, one per place in the game, played
by a small band in Brassens's way (see arrange.py): the guitar and the
double bass on the chords and the rhythm, piano, accordion or flute on
the tune. Run from the project root inside `nix develop .#audio`:

    python3 tools/audio/make_music.py                     # every tune
    python3 tools/audio/make_music.py --out DIR NAME...   # some, elsewhere

Melodies are `note:beats` (`r` for a rest), bars separated by `|`; chords
are one bar per `|`, several chords in a bar split it evenly, `G/B` puts B
in the bass.
"""

import argparse
import os

from arrange import ACCORDION, FLUTE, PIANO, Pass, Tune, build_loop
from crossword_tunes import CROSSWORD_TUNES

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "music")


def _rest(bars, meter=4):
    """`bars` silent bars, for a counter-melody that waits."""
    return " | ".join([f"r:{meter}"] * bars)


# --- Start menu: "La Valse des lettres" -- a musette waltz in A minor. -------
# The accordion sings it, then the flute takes over, over the guitar's
# "pom-tchi-tchi" and the bass on 1.
_VALSE_A = (
    "A4:1 C5:1 E5:1 | E5:2 D5:1 | C5:1.5 B4:.5 A4:1 | G#4:2 E4:1 |"
    " F4:1 A4:1 D5:1 | D5:1.5 C5:.5 B4:1 | C5:1 E5:1 G5:1 | B4:2 G#4:1 |"
)
_VALSE_A_VARIED = (
    "A4:1 C5:.5 B4:.5 C5:.5 E5:.5 | E5:2 D5:.5 C5:.5 | C5:1.5 B4:.5 A4:1 | G#4:.5 A4:.5 B4:.5 D5:.5 E5:1 |"
    " F5:2 D5:1 | B4:1 D5:1 F5:1 | E5:2 B4:1 | B4:1 G#4:1 E4:1 |"
)
_VALSE_REST = (
    " A4:1 C5:1 E5:1 | G5:2 E5:1 | F5:1.5 E5:.5 D5:1 | A4:2 C5:1 |"
    " D5:1.5 C5:.5 B4:1 | G#4:1 B4:1 D5:1 | C5:1 B4:1 A4:1 | A4:2 r:1 |"
    " G4:1 C5:1 E5:1 | G5:2 E5:1 | F5:1.5 E5:.5 D5:1 | B4:2 G4:1 |"
    " F4:1 G4:1 B4:1 | D5:2 F5:1 | E5:2 D5:1 | C5:2 r:1 |"
    " G4:1 Bb4:1 E5:1 | F5:2 A4:1 | Ab4:1 C5:1 D5:1 | E5:2 C5:1 |"
    " A4:1 C5:1 E5:1 | F#5:2 C5:1 | B4:1 D5:1 F5:1 | E5:1 D5:1 B4:1"
)
VALSE_DES_LETTRES = Tune(
    name="menu_valse_des_lettres",
    tempo=138,
    meter=3,
    swing=0.5,  # a waltz is played straight
    chords=(
        "Am | Am/G | Fmaj7 | E7 | Dm | G7 | Cmaj7 | E7 |"
        " Am | A7/C# | Dm | F | Bm7b5 | E7 | Am | Am |"
        " C | C | G7 | G7 | G7 | G7 | C | C |"
        " C7 | F | Fm6 | C | Am | D7 | G7 | E7"
    ),
    passes=[
        Pass(_VALSE_A + _VALSE_REST, lead=ACCORDION, comp="waltz", bass="waltz", lead_velocity=80),
        Pass(_VALSE_A_VARIED + _VALSE_REST, lead=FLUTE, comp="waltz", bass="waltz", lead_velocity=78),
    ],
    seed=4,
)

# --- Multiplayer: "Le Bouquiniste" -- a swinging chanson in G, AABA. -------
# The piano sings it over the guitar's pompe, the flute holding the
# bridge's guide tones; then the accordion ornaments it over a walking
# bass.
_BOUQ_A_HEAD = "B4:1.5 A4:.5 G4:1 D4:1 | D#4:1 F#4:1 A4:1.5 B4:.5 |"
_BOUQ_A_HEAD_VARIED = "r:.5 B4:1 A4:.5 G4:1 D4:1 | D#4:.5 E4:.5 F#4:1 A4:1 B4:1 |"
_BOUQ_SEVENTH = " G4:1 B4:1 D5:1 F5:1 |"
_BOUQ_A2 = (
    _BOUQ_A_HEAD + " G4:2 r:1 E4:.5 F#4:.5 |" + _BOUQ_SEVENTH
    + " E5:1.5 G5:.5 E5:1 C5:1 | Eb5:1 D5:1 C5:1 A4:1 | B4:1 G4:1 A4:1 F#4:1 | G4:2 r:.5 G4:.5 A4:.5 B4:.5 |"
)
_BOUQUINISTE = (
    _BOUQ_A_HEAD + " G4:2 r:1 E4:.5 F#4:.5 |" + _BOUQ_SEVENTH
    + " E5:2 D5:1 C5:1 | Eb5:1.5 C5:.5 A4:2 | B4:1 D5:1 G#4:1 B4:1 | A4:2 r:1 D4:1 |"
    + _BOUQ_A2
    + " C5:1.5 B4:.5 A4:1 E5:1 | D5:1.5 C5:.5 A4:1 F#4:1 | G4:1 B4:1 D5:1 F#5:1 | E5:2 r:.5 G#4:.5 B4:.5 D5:.5 |"
    " C5:1.5 B4:.5 A4:1 G4:1 | F#4:1 A4:1 C5:1 E5:1 | D5:1 B4:1 G#4:1 B4:1 | A4:1 C#5:1 C5:1 r:.5 D4:.5 |"
    + _BOUQ_A_HEAD + " G4:1 E5:1.5 D5:.5 B4:1 |" + _BOUQ_SEVENTH
    + " E5:2 G5:1 E5:1 | Eb5:1.5 D5:.5 C5:1 A4:1 | C5:1 E5:.5 C5:.5 A4:1 F#4:1 | G4:2 r:1 D4:1"
)
_BOUQ_A_VARIED = (
    _BOUQ_A_HEAD_VARIED + " G4:1.5 F#4:.5 E4:1 r:.5 F#4:.5 | G4:.5 A4:.5 B4:.5 D5:.5 F5:2 |"
)
_BOUQUINISTE_VARIED = (
    _BOUQ_A_VARIED
    + " E5:1.5 D5:.5 C5:1 E5:1 | Eb5:2 D5:.5 C5:.5 A4:1 | B4:1 D5:.5 B4:.5 G#4:1 E4:1 | A4:2 r:1 D4:1 |"
    + _BOUQ_A2
    + " E5:1 C5:1 A4:1.5 B4:.5 | C5:1 A4:1 F#4:1 D4:1 | B4:1.5 D5:.5 F#5:1.5 E5:.5 | D5:1 B4:1 G#4:1 E4:1 |"
    " A4:1 C5:1 E5:1 G5:1 | F#5:2 E5:1 C5:1 | D5:1.5 B4:.5 E5:1 D5:1 | C#5:2 C5:1 r:.5 D4:.5 |"
    + _BOUQ_A_VARIED
    + " E5:1 G5:1 E5:1 C5:1 | Eb5:1 C5:1 A4:1 G4:1 | A4:1 C5:1 F#4:1 A4:1 | G4:3 r:1"
)
_BOUQ_GUIDE_TONES = (
    _rest(16) + " | E4:4 | F#4:4 | F#4:4 | G#4:4 | A4:2 G4:2 | F#4:4 | F#4:2 G#4:2 | G4:2 F#4:2 | " + _rest(8)
)
LE_BOUQUINISTE = Tune(
    name="multi_le_bouquiniste",
    tempo=108,
    meter=4,
    swing=0.62,
    chords=(
        "G | B7/F# | Em | G7/D | C | Cm6 | G/D E7 | A7 D7 |"
        " G | B7/F# | Em | G7/D | C | Cm6 | G/D D7 | G |"
        " Am | D7 | Gmaj7 | E7 | Am7 | D7 | Bm7 E7 | A7 D7 |"
        " G | B7/F# | Em | G7/D | C | Cm6 | Am7 D7 | G D7"
    ),
    passes=[
        Pass(_BOUQUINISTE, lead=PIANO, comp="pompe", bass="two", lead_velocity=74,
             counter=_BOUQ_GUIDE_TONES, counter_lead=FLUTE, counter_velocity=48),
        Pass(_BOUQUINISTE_VARIED, lead=ACCORDION, comp="pompe", bass="walk", lead_velocity=80,
             comp_velocity=4),
    ],
    seed=3,
)

# --- Free play: "Flanerie" -- a fingerpicked ballad in C, ABAC. -------------
# The flute over the fingerpicked guitar and the bass; then
# the piano takes the tune and the flute answers in the gaps.
_FLAN_A = (
    "E5:1.5 D5:.5 C5:1 G4:1 | B4:2.5 r:.5 C5:.5 D5:.5 |"
)
_FLANERIE = (
    _FLAN_A + " E5:1.5 D5:.5 Bb4:1 G4:1 | A4:3 r:1 |"
    " Ab4:1.5 Bb4:.5 C5:1 D5:1 | G5:2 E5:1 C5:1 | F#4:1.5 A4:.5 C5:1 E5:1 | D5:2 r:1 G4:1 |"
    + _FLAN_A + " E5:1 G5:1.5 F5:.5 E5:1 | F5:2 C5:2 |"
    " D5:1.5 E5:.5 F5:1 A5:1 | G5:2 F5:1 D5:1 | E5:1.5 D5:.5 C#5:1 E5:1 | D5:1.5 C5:.5 B4:1 G4:1 |"
    " A4:1.5 C5:.5 E5:1 A5:1 | G5:2 E5:1 B4:1 | C5:1.5 D5:.5 F5:1 A5:1 | G5:2 E5:1 C5:1 |"
    " F5:1.5 E5:.5 D5:1 C5:1 | B4:1 D5:1 G5:1 F5:1 | E5:2 C#5:1.5 E5:.5 | D5:2 B4:1 G4:1 |"
    + _FLAN_A + " E5:1.5 D5:.5 Bb4:1 G4:1 | A4:2 C5:1 F5:1 |"
    " F5:1.5 D5:.5 C5:1 Ab4:1 | E5:1.5 C5:.5 C#5:1 E5:1 | D5:1.5 F5:.5 B4:1 D5:1 | C5:3 r:1"
)
_FLAN_ANSWERS = (
    "r:4 | r:1 E4:.5 F4:.5 G4:1 r:1 | r:4 | r:1 C4:.5 D4:.5 F4:1 r:1 |"
    " r:4 | r:4 | r:4 | r:2 F4:.5 E4:.5 D4:1 |"
    " r:4 | r:1 E4:.5 F4:.5 G4:1 r:1 | r:4 | r:2 A4:.5 G4:.5 F4:1 |"
    " r:4 | r:4 | r:4 | r:4 |"
    " r:4 | r:4 | r:4 | r:4 | r:4 | r:4 | r:4 | r:4 |"
    " r:4 | r:1 E4:.5 F4:.5 G4:1 r:1 | r:4 | r:4 | r:4 | r:4 | r:4 | r:1 E4:.5 D4:.5 C4:1 G3:1"
)
FLANERIE = Tune(
    name="libre_flanerie",
    tempo=92,
    meter=4,
    swing=0.57,
    chords=(
        "C | Cmaj7 | C7 | F | Fm6 | C/E | D7 | G7 |"
        " C | Cmaj7 | C7 | F | Dm7 | G7 | Em7 A7 | Dm7 G7 |"
        " Am | Em | F | C/E | Dm7 | G7 | C A7 | Dm7 G7 |"
        " C | Cmaj7 | C7 | F | Fm6 | C/E A7 | Dm7 G7 | C"
    ),
    passes=[
        Pass(_FLANERIE, lead=FLUTE, comp="picking", bass="two", lead_velocity=64, comp_velocity=-4),
        Pass(_FLANERIE, lead=PIANO, comp="picking", bass="two", lead_velocity=58, comp_velocity=-4,
             counter=_FLAN_ANSWERS, counter_lead=FLUTE, counter_velocity=44),
    ],
    seed=5,
)

# The crosswords' tunes are in crossword_tunes.py.
TUNES = {t.name: t for t in (VALSE_DES_LETTRES, LE_BOUQUINISTE, FLANERIE, *CROSSWORD_TUNES)}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", default=OUT, help="output folder")
    parser.add_argument("names", nargs="*", help=f"tunes (default: all): {', '.join(TUNES)}")
    args = parser.parse_args()
    for name in set(args.names) - set(TUNES):
        parser.error(f"unknown tune {name!r}")
    os.makedirs(args.out, exist_ok=True)
    for tune in (TUNES[n] for n in args.names or TUNES):
        seconds = build_loop(tune, os.path.join(args.out, tune.name + ".ogg"))
        print(f"{tune.name}.ogg  {seconds:.1f} s loop")
