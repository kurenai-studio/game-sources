package com.darumahq.rainbowclimb.audio

import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.sin

enum class Waveform {
    SINE, SQUARE, SAW, TRIANGLE, NOISE
}

data class ADSREnvelope(
    val attack: Float = 0.01f,   // seconds
    val decay: Float = 0.1f,
    val sustain: Float = 0.7f,   // level 0-1
    val release: Float = 0.2f
)

class Synthesizer(private val sampleRate: Int = 44100) {

    private val noiseBuffer = FloatArray(sampleRate) { (Math.random() * 2 - 1).toFloat() }
    private var noiseIndex = 0

    fun generateTone(
        frequency: Float,
        duration: Float,
        waveform: Waveform,
        envelope: ADSREnvelope = ADSREnvelope(),
        volume: Float = 0.5f
    ): FloatArray {
        val numSamples = (sampleRate * duration).toInt()
        val samples = FloatArray(numSamples)

        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val phase = (t * frequency) % 1f

            val raw = when (waveform) {
                Waveform.SINE -> sin(2.0 * PI * phase).toFloat()
                Waveform.SQUARE -> if (phase < 0.5f) 1f else -1f
                Waveform.SAW -> 2f * phase - 1f
                Waveform.TRIANGLE -> 4f * abs(phase - 0.5f) - 1f
                Waveform.NOISE -> {
                    noiseIndex = (noiseIndex + 1) % noiseBuffer.size
                    noiseBuffer[noiseIndex]
                }
            }

            val env = calculateEnvelope(t, duration, envelope)
            samples[i] = raw * env * volume
        }
        return samples
    }

    fun generateKick(duration: Float = 0.15f, volume: Float = 0.8f): FloatArray {
        val numSamples = (sampleRate * duration).toInt()
        val samples = FloatArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val freq = 150f * Math.pow(0.01, (t / duration).toDouble()).toFloat()
            val env = (1f - t / duration).coerceAtLeast(0f)
            samples[i] = (sin(2.0 * PI * freq * t).toFloat() * env * volume)
        }
        return samples
    }

    fun generateSnare(duration: Float = 0.1f, volume: Float = 0.6f): FloatArray {
        val numSamples = (sampleRate * duration).toInt()
        val samples = FloatArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val env = (1f - t / duration).coerceAtLeast(0f)
            val noise = (Math.random() * 2 - 1).toFloat()
            val tone = sin(2.0 * PI * 200.0 * t).toFloat() * 0.3f
            samples[i] = (noise * 0.7f + tone) * env * volume
        }
        return samples
    }

    fun generateHiHat(duration: Float = 0.05f, volume: Float = 0.3f): FloatArray {
        val numSamples = (sampleRate * duration).toInt()
        val samples = FloatArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val env = (1f - t / duration).coerceAtLeast(0f)
            val noise = (Math.random() * 2 - 1).toFloat()
            samples[i] = noise * env * env * volume // quick decay
        }
        return samples
    }

    private fun calculateEnvelope(t: Float, duration: Float, env: ADSREnvelope): Float {
        val releaseStart = duration - env.release
        return when {
            t < env.attack -> t / env.attack
            t < env.attack + env.decay -> {
                val decayProgress = (t - env.attack) / env.decay
                1f - (1f - env.sustain) * decayProgress
            }
            t < releaseStart -> env.sustain
            else -> {
                val releaseProgress = (t - releaseStart) / env.release
                env.sustain * (1f - releaseProgress).coerceAtLeast(0f)
            }
        }
    }

    companion object {
        // Pentatonic minor scale intervals (semitones from root)
        val PENTATONIC_MINOR = intArrayOf(0, 3, 5, 7, 10)

        fun noteToFrequency(note: Int): Float {
            // MIDI note to frequency (A4 = 69 = 440Hz)
            return (440.0 * Math.pow(2.0, (note - 69.0) / 12.0)).toFloat()
        }

        fun scaleNote(root: Int, scaleIndex: Int, octaveOffset: Int = 0): Int {
            val idx = scaleIndex % PENTATONIC_MINOR.size
            val octave = scaleIndex / PENTATONIC_MINOR.size + octaveOffset
            return root + PENTATONIC_MINOR[idx] + octave * 12
        }
    }
}
