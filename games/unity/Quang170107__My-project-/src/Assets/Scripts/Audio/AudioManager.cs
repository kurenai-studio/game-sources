using System.Collections.Generic;
using UnityEngine;

namespace SimpleRPG
{
    public class AudioManager : MonoBehaviour
    {
        public static AudioManager Instance { get; private set; }

        private AudioSource _sfxSource;
        private readonly Dictionary<string, AudioClip> _clips = new Dictionary<string, AudioClip>();

        private void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
            }
            else
            {
                Destroy(gameObject);
                return;
            }

            _sfxSource = gameObject.AddComponent<AudioSource>();
            _sfxSource.playOnAwake = false;

            GenerateClips();
        }

        private void GenerateClips()
        {
            _clips["slash"] = CreateToneClip(0.12f, 440, 150, ToneType.Noise);
            _clips["hit"] = CreateToneClip(0.08f, 220, 80, ToneType.Square);
            _clips["enemy_death"] = CreateToneClip(0.25f, 300, 50, ToneType.NoiseBurst);
            _clips["shoot"] = CreateToneClip(0.14f, 880, 440, ToneType.Sine);
            _clips["dash"] = CreateToneClip(0.15f, 600, 200, ToneType.Noise);
            _clips["coin"] = CreateChimeClip(new float[] { 987.77f, 1318.51f }, 0.08f); // B5 -> E6
            _clips["potion"] = CreateChimeClip(new float[] { 523.25f, 659.25f, 783.99f }, 0.07f);
            _clips["levelup"] = CreateChimeClip(new float[] { 523.25f, 659.25f, 783.99f, 1046.50f }, 0.12f);
            _clips["portal"] = CreateChimeClip(new float[] { 440f, 554.37f, 659.25f, 880f }, 0.15f);
            _clips["hurt"] = CreateToneClip(0.12f, 180, 90, ToneType.Sawtooth);
            _clips["special"] = CreateToneClip(0.35f, 180, 40, ToneType.Sine);
            _clips["explode"] = CreateToneClip(0.4f, 140, 30, ToneType.NoiseBurst);
            _clips["fuse"] = CreateToneClip(0.1f, 1200, 900, ToneType.Square);
            _clips["combo"] = CreateChimeClip(new float[] { 784f, 987.77f, 1174.66f }, 0.06f);

            // New synthesized SFX for Relics and Combat Synergies
            _clips["shield_block"] = CreateChimeClip(new float[] { 880f, 1320f }, 0.09f);
            _clips["freeze"] = CreateToneClip(0.18f, 1200f, 600f, ToneType.Sine);
            _clips["lightning"] = CreateToneClip(0.15f, 950f, 200f, ToneType.NoiseBurst);
            _clips["relic"] = CreateChimeClip(new float[] { 587.33f, 739.99f, 880f, 1174.66f }, 0.14f);
        }

        public void PlaySound(string soundName, float volume = 1f)
        {
            if (_clips.TryGetValue(soundName, out var clip) && clip != null)
            {
                _sfxSource.PlayOneShot(clip, volume);
            }
        }

        private enum ToneType { Sine, Square, Sawtooth, Noise, NoiseBurst }

        private AudioClip CreateToneClip(float duration, float startFreq, float endFreq, ToneType type)
        {
            int sampleRate = 44100;
            int samples = Mathf.CeilToInt(sampleRate * duration);
            float[] data = new float[samples];
            float phase = 0f;

            for (int i = 0; i < samples; i++)
            {
                float t = (float)i / samples;
                float freq = Mathf.Lerp(startFreq, endFreq, t);
                float envelope = 1f - t; // Linear decay

                float sample = 0f;
                switch (type)
                {
                    case ToneType.Sine:
                        sample = Mathf.Sin(phase);
                        break;
                    case ToneType.Square:
                        sample = Mathf.Sin(phase) >= 0 ? 0.6f : -0.6f;
                        break;
                    case ToneType.Sawtooth:
                        sample = (2f * (phase / (2f * Mathf.PI) - Mathf.Floor(phase / (2f * Mathf.PI) + 0.5f))) * 0.7f;
                        break;
                    case ToneType.Noise:
                        sample = (Random.value * 2f - 1f) * 0.5f;
                        break;
                    case ToneType.NoiseBurst:
                        sample = (Random.value * 2f - 1f) * (1f - t * 0.8f);
                        break;
                }

                phase += (2f * Mathf.PI * freq) / sampleRate;
                data[i] = sample * envelope;
            }

            var clip = AudioClip.Create("sfx_" + type, samples, 1, sampleRate, false);
            clip.SetData(data, 0);
            return clip;
        }

        private AudioClip CreateChimeClip(float[] frequencies, float noteDuration)
        {
            int sampleRate = 44100;
            int totalSamples = Mathf.CeilToInt(sampleRate * noteDuration * frequencies.Length);
            float[] data = new float[totalSamples];
            int noteSamples = Mathf.CeilToInt(sampleRate * noteDuration);

            for (int n = 0; n < frequencies.Length; n++)
            {
                float freq = frequencies[n];
                float phase = 0f;

                for (int i = 0; i < noteSamples; i++)
                {
                    int index = n * noteSamples + i;
                    if (index >= totalSamples) break;

                    float t = (float)i / noteSamples;
                    float env = Mathf.Pow(1f - t, 1.5f);
                    float sample = Mathf.Sin(phase) * 0.7f;

                    phase += (2f * Mathf.PI * freq) / sampleRate;
                    data[index] = sample * env;
                }
            }

            var clip = AudioClip.Create("chime", totalSamples, 1, sampleRate, false);
            clip.SetData(data, 0);
            return clip;
        }
    }
}
