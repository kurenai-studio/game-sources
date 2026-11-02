using System;
using Microsoft.Xna.Framework.Audio;

namespace Breakout.Systems;

/// <summary>
/// All SFX are synthesized square waves built at startup: SoundEffect accepts
/// raw 16-bit PCM, which keeps this project entirely asset-free. The normal
/// route is .wav files through the Content Pipeline; this is the "no assets
/// handy, retro is fine" route — and it teaches what a sound actually is.
/// MonoGame's audio split: SoundEffect = short, fire-and-forget, polyphonic
/// SFX; Song + MediaPlayer = one streamed music track. Don't mix them up.
/// (This project's music takes a third, asset-free route — the same PCM
/// synthesis on a looping SoundEffectInstance; see MusicPlayer.)
/// </summary>
public static class AudioBank
{
    public static SoundEffect PaddleHit { get; private set; }
    public static SoundEffect WallHit { get; private set; }
    public static SoundEffect BrickHit { get; private set; }
    public static SoundEffect BrickBreak { get; private set; }
    public static SoundEffect PowerUpCatch { get; private set; }
    public static SoundEffect DebrisHit { get; private set; }
    public static SoundEffect LifeLost { get; private set; }
    public static SoundEffect LevelClear { get; private set; }
    public static SoundEffect Win { get; private set; }
    public static SoundEffect SpeedUp { get; private set; }

    /// <summary>
    /// Play with a small random pitch offset. MonoGame's pitch parameter is in
    /// octaves: -1 = one octave down, +1 = one octave up, so ±0.08 is under a
    /// semitone — too small to hear as a "different note", just enough that
    /// rapid identical hits stop sounding like a stuck sample. The cheapest
    /// audio juice there is: one parameter on a call you already make.
    /// </summary>
    public static void PlayVaried(this SoundEffect effect, Random rng,
        float maxPitchOffset = 0.08f)
    {
        // Roll BEFORE the null check. The pitch comes from the session's
        // seeded stream, and the simulation's RNG consumption must never
        // depend on output devices: with `effect?.PlayVaried(...)` at the
        // call sites, a machine with no sound card would skip these draws,
        // shifting every roll after them — drop chances, serve angles — and
        // a replay recorded with audio would desync on a machine without.
        // (Extension methods accept a null receiver, so call sites invoke
        // this unconditionally and the null check lives here, after the roll.)
        float pitch = ((float)rng.NextDouble() * 2f - 1f) * maxPitchOffset;
        effect?.Play(volume: 1f, pitch: pitch, pan: 0f);
    }

    public static void Initialize()
    {
        try
        {
            PaddleHit = CreateTone(220, 220, 0.06, 0.50f);
            WallHit = CreateTone(440, 440, 0.035, 0.35f);
            BrickHit = CreateTone(520, 480, 0.045, 0.40f);
            BrickBreak = CreateTone(620, 920, 0.07, 0.45f);
            PowerUpCatch = CreateTone(300, 900, 0.25, 0.40f);
            DebrisHit = CreateTone(280, 70, 0.22, 0.50f); // PowerUpCatch's mirror: falling, not rising
            LifeLost = CreateTone(400, 110, 0.45, 0.50f);
            LevelClear = CreateTone(392, 784, 0.30, 0.45f); // shorter sibling of Win
            Win = CreateTone(523, 1046, 0.40, 0.45f);
            SpeedUp = CreateTone(700, 1400, 0.09, 0.40f); // a short upward zip: the speed ladder stepping
        }
        catch (NoAudioHardwareException)
        {
            // Machines with no audio device: the properties stay null, plain
            // call sites use `?.Play()`, and PlayVaried tolerates null itself
            // (see why above), so the game runs silent instead of crashing.
        }
    }

    private static SoundEffect CreateTone(
        double startFrequency, double endFrequency, double duration, float volume)
    {
        const int sampleRate = 44100;
        int sampleCount = (int)(sampleRate * duration);
        var data = new byte[sampleCount * 2]; // 16-bit mono PCM, little-endian

        double phase = 0;
        for (int i = 0; i < sampleCount; i++)
        {
            double t = (double)i / sampleCount;
            double frequency = startFrequency + (endFrequency - startFrequency) * t;
            phase += frequency / sampleRate;

            double square = phase % 1.0 < 0.5 ? 1.0 : -1.0;
            double attack = Math.Min(1.0, i / (sampleRate * 0.002)); // 2 ms fade-in kills the start click
            double envelope = attack * (1.0 - t);                    // linear decay to silence

            short sample = (short)(square * envelope * volume * short.MaxValue);
            data[i * 2] = (byte)sample;
            data[i * 2 + 1] = (byte)(sample >> 8);
        }

        return new SoundEffect(data, sampleRate, AudioChannels.Mono);
    }
}
