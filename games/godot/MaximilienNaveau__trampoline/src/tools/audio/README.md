# Music and sound effects generators

Everything in `assets/audio/` is generated from source by these scripts, and
isn't committed (only Godot's `.import` files are). From the repository
root:

```sh
nix build .#audio   # the game's music and sound effects, in the Nix sandbox
nix run .#audio     # the same, copied into assets/audio/ for the Godot editor
```

The exports and the tests (`nix build .#linux`, `nix flake check`, CI) use
`.#audio` on their own. To change a sound and listen to it straight away:

```sh
nix develop .#audio
python3 tools/audio/make_music.py   # -> assets/audio/music/*.ogg (seamless loops)
python3 tools/audio/make_sfx.py     # -> assets/audio/sfx/*.wav
```

Two runs don't give bit-identical files (sfizz's round robins and random variations), but they sound the same.

- `arrange.py`: turns a lead sheet (melody + chord symbols) into a small
  band in Brassens's way, no drums: a classical guitar on the chords (the
  "pompe", a waltz, fingerpicking) and a pizzicato double bass (two-feel,
  walking or waltz) make the rhythm, and the tune is on piano, accordion,
  flute (or clarinet, or guitar). The notes are performed as people
  would: a tempo that breathes, each player's own feel against the beat,
  dynamics shaped by the phrase, an accompaniment that varies from bar to
  bar, legato and breaths, swells, scoops and vibrato on the winds,
  strums string by string with damped chops, the piano's sustain pedal.
  They are written to MIDI one instrument at a time, played by sfizz
  through sampled instruments, then mixed in a real small concert hall
  (its recorded impulse response), every tune to the same balance (each
  part measured while it plays and set to its level: `_BALANCE_DB`).
  Loops are seamless: the tune is rendered three times and the middle one
  kept.
- `make_music.py`: the tunes, one per place in the game. Edit the melody
  strings (`note:beats`, `r` for a rest, bars separated by `|`) or the
  chord strings to change them.
- `crossword_tunes.py`: the ten crosswords' tunes, in the same notation.
- `make_sfx.py`: synthesised physical sounds (trampoline, wooden tiles) and
  short musical cues played by the same band.
- `slice_guitar.py`: cuts the Iowa guitar recordings (long chromatic runs)
  into single notes and writes the guitar's SFZ instrument.
- `fetch_zip.py`: downloads only the needed files out of a zip archive on
  the web (HTTP range requests): the bass's pizzicato, the hall's one
  impulse response out of its 1 GB database.

`nix develop .#audio` sets `$TRAMPOLINE_SAMPLES` to the instruments
(`nix build` fetches and prepares them: see `samples` in flake.nix).

## Where the music comes from

All the tunes are original, written for Trampoline:
- `menu_valse_des_lettres` (start menu): a musette waltz,
- `multi_le_bouquiniste` (multiplayer): a swinging chanson,
- `libre_flanerie` (free play): a fingerpicked ballad,
- `croise_01_...` to `croise_10_...` (one per crossword): slow and lively
  waltzes, swing, minor swing, fingerpicked ballads, each with its own key
  and lead instruments (see crossword_tunes.py).

Nothing is taken from Brassens's own songs, which stay under copyright
until the end of 2051 (he died in 1981). Only the general style is
borrowed: the guitar/bass instrumentation and the swing feel, which
copyright doesn't cover.

## Licences of the instruments and tools

The sampled instruments are downloaded by the build, not kept here:
- classical guitar: University of Iowa Musical Instrument Samples
  (theremin.music.uiowa.edu), "may be downloaded and used for any
  projects, without restrictions";
- double bass (pizzicato): Meatbass, Karoryfer Samples, CC0;
- piano: Salamander Grand Piano V3, Alexander Holm, CC-BY 3.0 (credit
  required: see NOTICE);
- clarinet and flute: VSCO 2 Community Edition, Versilian Studios, CC0;
- button accordion: "Button Accordion HN", FreePats, CC0;
- the room: the Brahmssaal, Detmold University of Music, from the "Open
  Database of Spatial Room Impulse Responses at Detmold University of
  Music", S. V. Amengual Gari, J. M. Arend, P. T. Calamia, P. W. Robinson,
  doi:10.5281/zenodo.4116247, CC-BY 4.0 (credit required: see NOTICE).

sfizz (BSD), sox (GPL/LGPL), ffmpeg (LGPL/GPL), mido (MIT), numpy/scipy
(BSD) are build tools only: none of their code ships in the game.
