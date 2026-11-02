package com.darumahq.rainbowclimb.audio

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.audio.AudioDevice

class SfxManager {
    private val synth = Synthesizer()
    var enabled = true

    // Pre-generate common sound effects
    private val jumpSfx = synth.generateTone(
        523f, 0.08f, Waveform.TRIANGLE,
        ADSREnvelope(0.005f, 0.02f, 0.3f, 0.05f), 0.3f
    )

    private val collectSfx = synth.generateTone(
        880f, 0.1f, Waveform.SINE,
        ADSREnvelope(0.005f, 0.03f, 0.5f, 0.06f), 0.3f
    )

    private val rainbowSfx = generateRainbowSfx()

    private val deathSfx = synth.generateTone(
        120f, 0.4f, Waveform.SAW,
        ADSREnvelope(0.01f, 0.1f, 0.3f, 0.3f), 0.4f
    )

    private val enemyDeathSfx = synth.generateTone(
        300f, 0.12f, Waveform.NOISE,
        ADSREnvelope(0.005f, 0.03f, 0.2f, 0.08f), 0.25f
    )

    private fun generateRainbowSfx(): FloatArray {
        // Ascending arpeggio
        val notes = floatArrayOf(523f, 659f, 784f)
        val noteLen = 0.04f
        val total = FloatArray((44100 * noteLen * notes.size).toInt())
        var offset = 0
        for (freq in notes) {
            val tone = synth.generateTone(
                freq, noteLen, Waveform.TRIANGLE,
                ADSREnvelope(0.005f, 0.01f, 0.4f, 0.02f), 0.25f
            )
            for (i in tone.indices) {
                if (offset + i < total.size) total[offset + i] = tone[i]
            }
            offset += tone.size
        }
        return total
    }

    fun playJump() = playSample(jumpSfx)
    fun playCollect() = playSample(collectSfx)
    fun playRainbow() = playSample(rainbowSfx)
    fun playDeath() = playSample(deathSfx)
    fun playEnemyDeath() = playSample(enemyDeathSfx)

    private fun playSample(samples: FloatArray) {
        if (!enabled) return
        Thread({
            try {
                val device = Gdx.audio.newAudioDevice(44100, true)
                device.writeSamples(samples, 0, samples.size)
                device.dispose()
            } catch (_: Exception) {
                // ignore audio errors
            }
        }, "SFX").apply {
            isDaemon = true
            start()
        }
    }
}
