"""The ten crosswords' tunes ("Mots croisés"), one per puzzle: original
chansons in the same small band's hands (see arrange.py), each with its
own key, tempo, meter and lead instruments, so every puzzle has its own
colour. Used by make_music.py; same notation (see there).

Every tune is AABA, 32 bars, played twice by different lead instruments.
The A sections share their first 4 bars (`head`): A ends on `end1` and
leads on, A' ends on `end2` and closes; the bridge B is 8 bars.
"""

from arrange import ACCORDION, CLARINET, FLUTE, GUITAR, PIANO, Pass, Tune


def _aaba(head, end1, end2, bridge):
    """The melody (or the chords) of an AABA tune from its parts."""
    a, a2 = f"{head} | {end1}", f"{head} | {end2}"
    return " | ".join([a, a2, bridge, a2])


def _tune(number, title, tempo, meter, swing, chords, melody, first, second, seed):
    """Crossword `number`'s tune; `first` and `second`: the two passes'
    Pass settings (without the melody)."""
    return Tune(
        name=f"croise_{number:02d}_{title}",
        tempo=tempo,
        meter=meter,
        swing=swing,
        chords=_aaba(*chords),
        passes=[Pass(melody, **first), Pass(melody, **second)],
        seed=seed,
    )


_WALTZ = dict(comp="waltz", bass="waltz")

CROSSWORD_TUNES = [
    # 1. "Les Définitions": a slow waltz in D minor, the clarinet, then the piano.
    _tune(1, "les_definitions", 120, 3, 0.5,
          ("Dm | Dm/C | Bb | A7", "Gm | C7 | F | A7", "Gm | A7 | Dm | Dm",
           "F | C7 | C7 | F | Bb | Gm | E7 | A7"),
          _aaba("A4:2 D5:1 | F5:2 E5:1 | D5:1.5 C5:.5 Bb4:1 | A4:2 E4:1",
                "G4:1 Bb4:1 D5:1 | E5:2 C5:1 | F5:1.5 E5:.5 C5:1 | E5:2 C#5:1",
                "G4:1 Bb4:1 D5:1 | C#5:1.5 E5:.5 G5:1 | F5:2 E5:1 | D5:2 r:1",
                "C5:1 F5:1 A5:1 | G5:2 E5:1 | Bb4:1 C5:1 E5:1 | F5:2 C5:1 |"
                " D5:1 F5:1 Bb5:1 | G5:1.5 F5:.5 D5:1 | G#4:1 B4:1 D5:1 | C#5:2 E4:1"),
          dict(lead=CLARINET, lead_velocity=70, **_WALTZ),
          dict(lead=PIANO, lead_velocity=64, **_WALTZ), seed=11),

    # 2. "Case blanche": a bouncing swing in F, the clarinet over the pompe,
    # then the guitar takes the tune over a walking bass.
    _tune(2, "case_blanche", 126, 4, 0.63,
          ("F | D7 | Gm7 | C7", "F | D7 | G7 | C7", "F F7 | Bb Bbm6 | F/C C7 | F",
           "A7 | A7 | Dm | Dm | G7 | G7 | Gm7 | C7"),
          _aaba("C5:1 A4:.5 C5:.5 F5:1 E5:1 | F#5:1.5 E5:.5 D5:1 C5:1 |"
                " Bb4:1 D5:.5 F5:.5 A5:1 G5:1 | E5:2 r:1 C5:1",
                "A4:1 C5:.5 F5:.5 A5:1 G5:1 | F#5:1 A5:1 F#5:1 D5:1 | F5:1.5 D5:.5 B4:1 G4:1 | Bb4:2 r:1 C5:1",
                "A5:1 F5:1 Eb5:1 C5:1 | D5:2 Db5:2 | C5:1 A4:1 G4:1 Bb4:1 | A4:2 r:2",
                "r:.5 E5:.5 E5:1 C#5:1 A4:1 | G5:2 E5:1 C#5:1 | D5:1 F5:.5 A5:.5 F5:1 D5:1 | A4:2 r:1 A4:1 |"
                " B4:1 D5:.5 F5:.5 G5:1 F5:1 | D5:2 B4:1 G4:1 | Bb4:1 D5:1 F5:1 A5:1 | G5:2 E5:1 C5:1"),
          dict(lead=CLARINET, lead_velocity=74),
          dict(lead=GUITAR, lead_velocity=80, bass="walk", comp_velocity=-4), seed=12),

    # 3. "Horizontalement": a fingerpicked ballad in G, the guitar sings
    # it, then the clarinet.
    _tune(3, "horizontalement", 88, 4, 0.55,
          ("G | Em | C | D7", "G | Em | Am7 | D7", "G/B | C | D7 | G",
           "C | G/B | Am7 | G | C | G/B | A7 | D7"),
          _aaba("D5:1.5 B4:.5 G4:1 B4:1 | E5:3 D5:1 | C5:1.5 B4:.5 A4:1 G4:1 | F#4:2 A4:1 r:1",
                "B4:1.5 D5:.5 G5:1 F#5:1 | E5:2 B4:2 | C5:1.5 B4:.5 A4:1 E5:1 | D5:3 r:1",
                "B4:1.5 D5:.5 G5:2 | E5:1.5 D5:.5 C5:1 E5:1 | D5:1 C5:1 A4:1 F#4:1 | G4:3 r:1",
                "E5:1 G5:1 E5:1 C5:1 | D5:2 B4:2 | C5:1 E5:1 A5:1 G5:1 | G5:2 D5:2 |"
                " E5:1.5 D5:.5 C5:1 E5:1 | D5:2 B4:1 G4:1 | A4:1 C#5:1 E5:1 G5:1 | F#5:2 A4:1 C5:1"),
          dict(lead=GUITAR, comp="picking", lead_velocity=78, comp_velocity=-8),
          dict(lead=CLARINET, comp="picking", lead_velocity=64, comp_velocity=-6), seed=13),

    # 4. "Verticalement": a slow, dreamy ballad in A minor, the piano, then
    # the flute.
    _tune(4, "verticalement", 80, 4, 0.55,
          ("Am | Am/G | F | E7", "Dm | G7 | C | E7", "Dm | E7 | Am | Am",
           "F | G | Em | Am | Dm7 | G7 | Cmaj7 | E7"),
          _aaba("E5:2 C5:1 A4:1 | G4:1.5 A4:.5 E5:2 | C5:2 A4:1 F4:1 | G#4:3 r:1",
                "A4:1.5 D5:.5 F5:2 | F5:1 E5:1 D5:1 B4:1 | E5:2 G5:1 E5:1 | D5:2 B4:1 G#4:1",
                "A4:1 D5:1 F5:1 A5:1 | G#5:2 B4:1 D5:1 | C5:1.5 B4:.5 A4:1 E4:1 | A4:3 r:1",
                "A4:1 C5:1 F5:2 | G5:1.5 F5:.5 D5:1 B4:1 | E5:2 B4:2 | C5:1 E5:1 A5:1 G5:1 |"
                " F5:2 D5:1 C5:1 | B4:1 D5:1 G5:1 F5:1 | E5:2 B4:1 G4:1 | G#4:2 B4:1 r:1"),
          dict(lead=PIANO, comp="picking", lead_velocity=62, comp_velocity=-8),
          dict(lead=FLUTE, comp="picking", lead_velocity=60, comp_velocity=-8), seed=14),

    # 5. "L'Encrier": a walking chanson in Bb, the piano, then the clarinet.
    _tune(5, "l_encrier", 112, 4, 0.62,
          ("Bb | G7 | Cm7 | F7", "Bb | G7 | Cm7 F7 | Bb F7", "Bb Bb7 | Eb Ebm6 | Bb/F F7 | Bb",
           "D7 | D7 | G7 | G7 | C7 | C7 | F7 | F7"),
          _aaba("D5:1 F5:1 D5:.5 C5:.5 Bb4:1 | B4:1.5 D5:.5 F5:1 D5:1 | Eb5:1 G5:1 Bb5:1 G5:1 | A5:2 F5:1 r:1",
                "D5:1.5 C5:.5 Bb4:1 F4:1 | G4:1 B4:1 D5:1 F5:1 | Eb5:1 C5:1 A4:1 C5:1 | Bb4:2 r:1 F4:1",
                "F5:1 D5:1 Ab5:1 F5:1 | G5:2 Gb5:2 | F5:1 D5:1 C5:1 Eb5:1 | D5:2 r:2",
                "F#5:1.5 E5:.5 D5:1 A4:1 | C5:2 A4:1 F#4:1 | G4:1 B4:1 D5:1 F5:1 | E5:2 D5:1 B4:1 |"
                " C5:1 E5:1 G5:1 Bb5:1 | A5:2 G5:1 E5:1 | F5:1.5 Eb5:.5 C5:1 A4:1 | C5:2 r:1 F4:1"),
          dict(lead=PIANO, bass="walk", lead_velocity=66),
          dict(lead=CLARINET, bass="walk", lead_velocity=70, comp_velocity=4), seed=15),

    # 6. "Le Crayon": a lively musette waltz in G, the accordion, then the
    # clarinet.
    _tune(6, "le_crayon", 152, 3, 0.5,
          ("G | G | D7 | D7", "D7 | D7 | G | G", "G/D | D7 | G | G",
           "Em | Em | B7 | B7 | Am | D7 | G | D7"),
          _aaba("D5:1 G5:1 B5:1 | A5:.5 B5:.5 A5:1 G5:1 | F#5:2 C5:1 | A4:1 C5:1 F#5:1",
                "A5:.5 G5:.5 F#5:1 E5:1 | D5:2 A4:1 | B4:1 D5:1 G5:1 | B4:2 D5:1",
                "B4:1 D5:1 G5:1 | F#5:1.5 E5:.5 C5:1 | B4:2 A4:1 | G4:2 r:1",
                "B4:1 E5:1 G5:1 | F#5:.5 G5:.5 F#5:1 E5:1 | D#5:2 B4:1 | F#4:1 A4:1 D#5:1 |"
                " E5:.5 F#5:.5 E5:1 C5:1 | A4:1 C5:1 F#5:1 | G5:2 D5:1 | C5:1 B4:1 A4:1"),
          dict(lead=ACCORDION, lead_velocity=78, **_WALTZ),
          dict(lead=CLARINET, lead_velocity=72, **_WALTZ), seed=16),

    # 7. "La Gomme": a minor swing in E, the accordion, then the guitar.
    _tune(7, "la_gomme", 100, 4, 0.6,
          ("Em | Em | Am6 | Am6", "B7 | B7 | Em | Em", "F#m7b5 | B7 | Em | Em",
           "Am | D7 | G | Cmaj7 | F#m7b5 | B7 | Em | B7"),
          _aaba("B4:1 E5:.5 G5:.5 B5:1 G5:1 | F#5:1.5 E5:.5 B4:2 | C5:1 E5:.5 F#5:.5 A5:1 F#5:1 | E5:2 r:1 C5:1",
                "D#5:1 F#5:.5 A5:.5 B5:1 A5:1 | F#5:2 D#5:1 B4:1 | E5:1 G5:1 F#5:1 D#5:1 | E5:2 r:2",
                "C5:1 A4:.5 C5:.5 E5:1 C5:1 | D#5:1.5 C5:.5 B4:1 A4:1 | G4:1 B4:1 E5:1 D#5:1 | E5:2 r:2",
                "A4:1 C5:1 E5:1 A5:1 | F#5:1.5 E5:.5 D5:1 C5:1 | B4:1 D5:1 G5:2 | E5:1.5 D5:.5 B4:1 G4:1 |"
                " A4:1 C5:1 E5:1 F#5:1 | D#5:2 B4:1 A4:1 | G4:1 B4:1 E5:1 G5:1 | F#5:2 D#5:1 B4:1"),
          dict(lead=ACCORDION, lead_velocity=76),
          dict(lead=GUITAR, lead_velocity=80, bass="walk", comp_velocity=-4), seed=17),

    # 8. "Mot de passe": a syncopated, fingerpicked tune in D, the flute,
    # then the piano.
    _tune(8, "mot_de_passe", 96, 4, 0.56,
          ("D | Bm | G | A7", "D | Bm | Em7 | A7", "D/F# | G | A7 | D",
           "G | A | F#m | Bm | Em | A7 | D | A7"),
          _aaba("r:.5 F#5:.5 A5:1 F#5:.5 E5:.5 D5:1 | B4:1 D5:.5 F#5:1.5 E5:1 | D5:1.5 B4:.5 G4:2 |"
                " A4:1 C#5:1 E5:1 G5:1",
                "F#5:1.5 E5:.5 D5:1 A4:1 | B4:.5 C#5:.5 D5:1 F#5:2 | G5:1 F#5:1 E5:1 D5:1 | C#5:3 r:1",
                "A5:2 F#5:1 D5:1 | B5:1.5 A5:.5 G5:1 D5:1 | E5:1 G5:1 C#5:1 E5:1 | D5:3 r:1",
                "B4:1 D5:1 G5:1.5 F#5:.5 | E5:2 C#5:2 | C#5:1 F#5:1 A5:1.5 G#5:.5 | F#5:2 D5:2 |"
                " E5:1 G5:1 B5:1 G5:1 | A5:1.5 G5:.5 E5:1 C#5:1 | D5:1 F#5:1 A5:1 F#5:1 | E5:2 C#5:1 A4:1"),
          dict(lead=FLUTE, comp="picking", lead_velocity=64, comp_velocity=-6),
          dict(lead=PIANO, comp="picking", lead_velocity=60, comp_velocity=-6), seed=18),

    # 9. "Le Dictionnaire": a gentle waltz in C, the piano, then the flute.
    _tune(9, "le_dictionnaire", 126, 3, 0.5,
          ("C | Am | Dm | G7", "C | A7 | Dm | G7", "F | G7 | C | C",
           "F | F | C | C | D7 | D7 | G | G7"),
          _aaba("E5:2 G5:1 | A5:1.5 G5:.5 E5:1 | F5:2 D5:1 | B4:2 G4:1",
                "C5:1 E5:1 G5:1 | C#5:2 E5:1 | D5:1.5 E5:.5 F5:1 | G5:2 r:1",
                "A4:1 C5:1 F5:1 | D5:1.5 C5:.5 B4:1 | E5:1 D5:1 G4:1 | C5:2 r:1",
                "A5:2 F5:1 | C5:1 F5:1 A5:1 | G5:2 E5:1 | C5:2 E5:1 |"
                " F#5:2 D5:1 | A4:1 C5:1 F#5:1 | G5:1.5 F#5:.5 G5:1 | B4:1 D5:1 F5:1"),
          dict(lead=PIANO, lead_velocity=64, **_WALTZ),
          dict(lead=FLUTE, lead_velocity=62, **_WALTZ), seed=19),

    # 10. "Le Point final": a bright swing in C, the guitar, then the
    # accordion over a walking bass.
    _tune(10, "le_point_final", 120, 4, 0.62,
          ("C | A7 | Dm7 | G7", "C | A7 | D7 | G7", "C C7 | F Fm6 | C/G G7 | C",
           "F | Fm6 | C | A7 | D7 | G7 | C | G7"),
          _aaba("G4:1 C5:1 E5:1 G5:1 | A5:1.5 G5:.5 E5:1 C#5:1 | D5:1 F5:1 A5:1 F5:1 | G5:2 r:1 G4:1",
                "C5:1.5 D5:.5 E5:1 G5:1 | C#5:1 E5:1 A5:1 G5:1 | F#5:1.5 E5:.5 D5:1 A4:1 | B4:2 r:1 G4:1",
                "E5:1 G5:1 Bb4:1 C5:1 | A4:1 C5:1 Ab4:1 D5:1 | E5:1.5 D5:.5 B4:1 D5:1 | C5:2 r:2",
                "A4:1 C5:.5 F5:.5 A5:2 | Ab5:1.5 F5:.5 D5:2 | E5:1 G5:1 C5:1 E5:1 | G5:2 E5:1 C#5:1 |"
                " D5:1 F#5:1 A5:1 F#5:1 | G5:1.5 F5:.5 D5:1 B4:1 | C5:1 E5:1 G5:1 E5:1 | D5:2 B4:1 G4:1"),
          dict(lead=GUITAR, lead_velocity=80),
          dict(lead=ACCORDION, lead_velocity=76, bass="walk", comp_velocity=4), seed=20),
]
