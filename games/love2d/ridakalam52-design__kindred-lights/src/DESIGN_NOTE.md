# Kindred Lights — design note (thatgamejam #02)

## What the theme track is (librosa analysis, `analyze.py`, `analyze2.py`)
- **Length:** 60.0 s, 48 kHz / 24-bit stereo WAV.
- **Tempo:** ~117 BPM (beat tracker found 104 beats).
- **Key:** F minor (Krumhansl correlation 0.92), with D♭ major heavily present. The harmony mostly
  rocks between **D♭ and F minor** (roughly three bars of D♭, one bar of Fm, repeated): warm major
  light that keeps falling back into the minor. Bittersweet rather than sad.
- **Dynamics / arc (RMS, spectral centroid, harmonic-vs-percussive energy):**
  | Section | Time | What happens | Loudness |
  |---|---|---|---|
  | Hush | 0–9 s | almost purely tonal, sparse, dark timbre | ~-26 dB |
  | Swell | 9–21 s | melody and pads rise, still no rhythm (harmonic/percussive ratio ~37:1) | ~-21 dB |
  | Pulse | 21–41 s | rhythm enters (ratio drops to ~2:1), brighter (centroid 1000 → 1500 Hz), loudest, busiest onsets | ~-18 dB |
  | Glow | 41–55 s | stays full but the onsets calm down; it sustains instead of pushing | ~-17.5 dB |
  | Release | 55–60 s | quick fade into silence | -34 → -64 dB |
- **Contrast / transformation:** the big change is **alone → together**. The opening is one quiet
  voice in the dark. Then other layers join it one by one, until a shared heartbeat (the rhythm)
  carries everything. It ends on a soft release, not a big ending.

## Feelings it carries
Loneliness that is not despair. A small, warm hope (the D♭ major) that keeps coming back. The
pleasure of being answered. The lift of many voices finding one pulse. Then a quiet goodbye that
feels grateful.

## How the game turns that into play
You are a small light alone in a dark land. **You sing (Space / right-click), and sleeping lights
answer.** Each light that wakes follows you, adds its own voice to an echoing chord, and makes your
shared glow bigger. The land is shaped like the track:

1. **I · Hush.** Darkness and one pad. You learn to move and sing, and you wake your first friend.
   Deep dark mist will not part for one light alone.
2. **II · Swell.** Violet dusk and wind ribbons. Each friend you wake unlocks one more note of the
   melody. Thicker mist needs a bigger group to part.
3. **III · Pulse.** Dawn colours, and a soft rhythm enters, as it does in the track. Sing over
   sleeping flower-buds to bloom them. If you sing on the beat, your friends sing with you.
4. **IV · Glow.** On the hilltop stands an Old Light. Sing to it and the **original theme plays,
   unmodified, from start to end**. Lights all over the world rise and join into constellations,
   timed to the track's own sections, beats and loudness (from the analysis data). It closes on
   "Thank you for answering."

All music before the finale is made inside the game by a synthesizer. It uses the track's key
(D♭ / F minor), its harmonic rhythm (D♭ D♭ D♭ Fm) and its tempo (117 BPM), so the finale feels like
coming home. There is no failing, no enemies and no timer. Play takes about 6–9 minutes.
