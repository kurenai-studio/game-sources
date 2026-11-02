package com.darumahq.rainbowclimb.audio

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.audio.AudioDevice
import com.darumahq.rainbowclimb.util.SeededRandom
import com.darumahq.rainbowclimb.world.Biome

class MusicEngine(seed: Long = System.currentTimeMillis()) {
    private val synth = Synthesizer()
    private val sequencer = Sequencer(bpm = 120, random = SeededRandom(seed))

    private var audioDevice: AudioDevice? = null
    private var isPlaying = false
    private var musicThread: Thread? = null

    // Pre-rendered samples for current pattern cycle
    private var kickSample = synth.generateKick()
    private var snareSample = synth.generateSnare()
    private var hihatSample = synth.generateHiHat()

    var enabled = true

    fun start() {
        if (isPlaying) return
        isPlaying = true

        try {
            audioDevice = Gdx.audio.newAudioDevice(44100, true)
        } catch (e: Exception) {
            // Audio not available (e.g., in tests)
            isPlaying = false
            return
        }

        musicThread = Thread({
            val bufferSize = 1024
            val buffer = FloatArray(bufferSize)
            var sampleIndex = 0
            val samplesPerStep = (44100 * sequencer.stepDuration).toInt()

            // Current step samples
            var currentStepSamples: FloatArray? = null
            var stepSampleIndex = 0

            while (isPlaying) {
                if (!enabled) {
                    Thread.sleep(100)
                    continue
                }

                for (i in 0 until bufferSize) {
                    var sample = 0f

                    // Mix current step sound
                    if (currentStepSamples != null && stepSampleIndex < currentStepSamples.size) {
                        sample += currentStepSamples[stepSampleIndex]
                        stepSampleIndex++
                    }

                    buffer[i] = sample.coerceIn(-1f, 1f) * 0.5f
                    sampleIndex++

                    // Check if we need to advance step
                    if (sampleIndex >= samplesPerStep) {
                        sampleIndex = 0
                        sequencer.currentStep = (sequencer.currentStep + 1) % 16

                        // Trigger sounds for new step
                        currentStepSamples = renderStep()
                        stepSampleIndex = 0

                        // Update samples per step (BPM may change)
                        // samplesPerStep recalculated on next cycle
                    }
                }

                try {
                    audioDevice?.writeSamples(buffer, 0, bufferSize)
                } catch (e: Exception) {
                    break
                }
            }
        }, "MusicEngine")
        musicThread?.isDaemon = true
        musicThread?.start()
    }

    private fun renderStep(): FloatArray? {
        val step = sequencer.currentStep
        var result: FloatArray? = null

        // Drums
        val drumNote = sequencer.drumPattern.notes[step]
        if (drumNote >= 0) {
            result = when (drumNote) {
                0 -> kickSample.copyOf()
                1 -> snareSample.copyOf()
                2 -> hihatSample.copyOf()
                else -> null
            }
        }

        // Bass
        val bassNote = sequencer.bassPattern.notes[step]
        if (bassNote >= 0) {
            val freq = Synthesizer.noteToFrequency(bassNote)
            val bassSample = synth.generateTone(
                freq, sequencer.stepDuration,
                Waveform.SQUARE,
                ADSREnvelope(attack = 0.005f, decay = 0.05f, sustain = 0.4f, release = 0.05f),
                volume = 0.3f
            )
            result = mixSamples(result, bassSample)
        }

        // Lead
        val leadNote = sequencer.leadPattern.notes[step]
        if (leadNote >= 0) {
            val freq = Synthesizer.noteToFrequency(leadNote)
            val leadSample = synth.generateTone(
                freq, sequencer.stepDuration * 0.8f,
                Waveform.SAW,
                ADSREnvelope(attack = 0.01f, decay = 0.08f, sustain = 0.5f, release = 0.1f),
                volume = 0.2f
            )
            result = mixSamples(result, leadSample)
        }

        return result
    }

    private fun mixSamples(a: FloatArray?, b: FloatArray): FloatArray {
        if (a == null) return b
        val len = maxOf(a.size, b.size)
        val mixed = FloatArray(len)
        for (i in 0 until len) {
            val sa = if (i < a.size) a[i] else 0f
            val sb = if (i < b.size) b[i] else 0f
            mixed[i] = (sa + sb).coerceIn(-1f, 1f)
        }
        return mixed
    }

    fun updateForBiome(biome: Biome) {
        sequencer.bpm = biome.tempo
        // Root note varies by biome mood
        val root = 36 + (biome.musicMood * 12).toInt() // C2 to C3 range
        sequencer.regeneratePatterns(root)
    }

    fun stop() {
        isPlaying = false
        musicThread?.join(1000)
        musicThread = null
        audioDevice?.dispose()
        audioDevice = null
    }

    fun dispose() {
        stop()
    }
}
