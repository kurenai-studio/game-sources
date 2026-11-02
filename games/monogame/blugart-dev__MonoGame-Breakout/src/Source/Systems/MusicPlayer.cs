using System;
using Microsoft.Xna.Framework.Audio;

namespace Breakout.Systems;

/// <summary>
/// The looping background track — synthesized, like every other sound here.
/// MonoGame's intended music route is Song + MediaPlayer: a compressed asset
/// (.ogg) streamed from disk and decoded as it plays, one at a time. That is
/// the right tool for a three-minute track you ship as a file. This project
/// ships no files, and a 16-second chip-tune loop is only ~1.4 MB of PCM —
/// small enough to live in RAM as a SoundEffect, built by the same synthesis
/// trick AudioBank already uses.
///
/// The genuinely new API is SoundEffectInstance. SoundEffect.Play() is
/// fire-and-forget: it returns no handle, so a playing SFX cannot be stopped,
/// looped, or re-volumed. CreateInstance() returns the handle you keep —
/// IsLooped, a live Volume, Play/Pause/Stop. SFX never need the handle;
/// music is nothing *but* the handle.
/// </summary>
public static class MusicPlayer
{
    // Music sits under the SFX on purpose — it's a bed, not a lead. Ducked
    // is the pause/game-over level: still audible, clearly backgrounded.
    private const float FullVolume = 0.6f;
    private const float DuckedVolume = 0.2f;

    private const int SampleRate = 44100;

    private static SoundEffectInstance _instance;
    private static bool _muted;
    private static bool _ducked;

    public static void Initialize()
    {
        try
        {
            SoundEffect track = ComposeLoop();
            _instance = track.CreateInstance();
            _instance.IsLooped = true; // must be set before the first Play() — it throws afterwards
            ApplyVolume();
        }
        catch (NoAudioHardwareException)
        {
            // Same degradation contract as AudioBank: _instance stays null,
            // every public method no-ops, the game runs silent, not crashed.
        }
    }

    public static void Play() => _instance?.Play();

    /// <summary>
    /// Duck = drop the music low instead of stopping it. The pause and
    /// game-over screens duck: audio that keeps going (quietly) tells the
    /// player the app is alive — full silence reads as a hang — and the
    /// foreground jingles get the foreground. This is the live Volume
    /// property earning its keep; fire-and-forget Play() has no equivalent.
    /// </summary>
    public static void SetDucked(bool ducked)
    {
        _ducked = ducked;
        ApplyVolume();
    }

    /// <summary>
    /// Mute is Volume = 0, not Pause(): the track keeps advancing silently,
    /// so unmuting drops back in mid-groove instead of restarting bar one.
    /// </summary>
    public static void ToggleMuted()
    {
        _muted = !_muted;
        ApplyVolume();
    }

    private static void ApplyVolume()
    {
        if (_instance != null)
            _instance.Volume = _muted ? 0f : _ducked ? DuckedVolume : FullVolume;
    }

    // ---------------------------------------------------------------- synth

    // MIDI note numbers as the pitch coordinate: 69 = A4 = 440 Hz, +12 = one
    // octave, +1 = one semitone. Writing music as small integers and converting
    // at the end beats sprinkling frequencies like 207.65 through the score.
    private static double MidiToFrequency(int midi)
        => 440.0 * Math.Pow(2.0, (midi - 69) / 12.0);

    private static readonly int[] MinorTriad = { 0, 3, 7 };
    private static readonly int[] MajorTriad = { 0, 4, 7 };

    // Sixteenth-note arpeggio order through the triad: low-mid-high-mid.
    private static readonly int[] ArpPattern = { 0, 1, 2, 1 };

    /// <summary>
    /// Eight bars of Am–F–C–G (twice through the i–VI–III–VII loop half of
    /// chip-tune music runs on) at 120 BPM = a 16-second buffer. Three voices
    /// are mixed by simple addition: an octave-bouncing square bass, a thinner
    /// 25%-duty arpeggio that climbs an octave for the second half, and noise
    /// hats. Every note's envelope decays to exactly zero and the buffer ends
    /// on a bar boundary, so the last sample is ~0, the first attack starts
    /// from 0, and the loop wraps without a click.
    /// </summary>
    private static SoundEffect ComposeLoop()
    {
        const double secondsPerBeat = 0.5; // 120 BPM
        const int beatsPerBar = 4;
        int samplesPerBar = (int)(SampleRate * secondsPerBeat * beatsPerBar);

        int[] roots = { 45, 41, 48, 43, 45, 41, 48, 43 }; // A2 F2 C3 G2, twice
        int[][] triads =
        {
            MinorTriad, MajorTriad, MajorTriad, MajorTriad,
            MinorTriad, MajorTriad, MajorTriad, MajorTriad,
        };

        var mix = new float[samplesPerBar * roots.Length];
        var rng = new Random(12345); // fixed seed — the hats are part of the composition

        for (int bar = 0; bar < roots.Length; bar++)
        {
            int barStart = bar * samplesPerBar;
            int arpOctave = bar < 4 ? 24 : 36; // second pass lifts the lead an octave

            // Bass: eighth notes bouncing root → octave, the classic chip walk.
            for (int n = 0; n < 8; n++)
                AddSquareNote(mix, barStart + n * samplesPerBar / 8, samplesPerBar / 8,
                    MidiToFrequency(roots[bar] + (n % 2) * 12), volume: 0.20f, duty: 0.5);

            // Arpeggio: sixteenth notes cycling through the bar's triad.
            for (int n = 0; n < 16; n++)
            {
                int midi = roots[bar] + arpOctave + triads[bar][ArpPattern[n % ArpPattern.Length]];
                AddSquareNote(mix, barStart + n * samplesPerBar / 16, samplesPerBar / 16,
                    MidiToFrequency(midi), volume: 0.11f, duty: 0.25);
            }

            // Hats: a noise tick on every eighth, accented off the beat.
            for (int n = 0; n < 8; n++)
                AddNoiseTick(mix, barStart + n * samplesPerBar / 8,
                    volume: n % 2 == 1 ? 0.05f : 0.028f, rng);
        }

        // Float mix → 16-bit little-endian PCM, the format SoundEffect accepts.
        // Clamp first: summed voices could exceed ±1, and integer overflow
        // doesn't clip politely — it wraps, which sounds like a buzz saw.
        var data = new byte[mix.Length * 2];
        for (int i = 0; i < mix.Length; i++)
        {
            short sample = (short)(Math.Clamp(mix[i], -1f, 1f) * short.MaxValue);
            data[i * 2] = (byte)sample;
            data[i * 2 + 1] = (byte)(sample >> 8);
        }
        return new SoundEffect(data, SampleRate, AudioChannels.Mono);
    }

    /// <summary>
    /// Add (not overwrite) one square-wave note into the mix — mixing audio
    /// really is just addition of sample values. Duty is the fraction of each
    /// cycle spent high: 50% is the hollow classic square, 25% the thinner,
    /// reedier voice — the same timbre knob 8-bit sound chips exposed as a
    /// two-bit register. Envelope as in AudioBank: a 3 ms attack kills the
    /// start click, linear decay to zero kills the end click.
    /// </summary>
    private static void AddSquareNote(float[] mix, int start, int length,
        double frequency, float volume, double duty)
    {
        double phase = 0;
        for (int i = 0; i < length; i++)
        {
            phase += frequency / SampleRate;
            double square = phase % 1.0 < duty ? 1.0 : -1.0;

            double t = (double)i / length;
            double attack = Math.Min(1.0, i / (SampleRate * 0.003));

            mix[start + i] += (float)(square * attack * (1.0 - t) * volume);
        }
    }

    /// <summary>
    /// A 30 ms burst of white noise with a squared fade — the fast die-off is
    /// what makes noise read as a percussive "tick" instead of static.
    /// </summary>
    private static void AddNoiseTick(float[] mix, int start, float volume, Random rng)
    {
        int length = (int)(SampleRate * 0.03);
        for (int i = 0; i < length; i++)
        {
            double t = (double)i / length;
            double fade = (1.0 - t) * (1.0 - t);
            mix[start + i] += (float)((rng.NextDouble() * 2.0 - 1.0) * fade * volume);
        }
    }
}
