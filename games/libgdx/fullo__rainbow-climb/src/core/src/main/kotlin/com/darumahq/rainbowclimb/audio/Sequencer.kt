package com.darumahq.rainbowclimb.audio

import com.darumahq.rainbowclimb.util.SeededRandom

data class Pattern(
    val steps: Int = 16,
    val notes: IntArray = IntArray(16) { -1 }, // -1 = rest
    val velocities: FloatArray = FloatArray(16) { 0.5f }
)

class Sequencer(
    var bpm: Int = 120,
    private val random: SeededRandom = SeededRandom()
) {
    var currentStep = 0
    var stepTimer = 0f
    val stepDuration: Float get() = 60f / bpm / 4f // 16th note duration

    // Markov chain transition probabilities for melody (must be before pattern generation)
    // Index = interval from current note (in scale degrees): -2, -1, 0, +1, +2
    private val markovWeights = floatArrayOf(0.1f, 0.25f, 0.15f, 0.3f, 0.2f)

    // Patterns for each track
    var drumPattern = generateDrumPattern()
    var bassPattern = generateBassPattern(48) // C3
    var leadPattern = generateLeadPattern(60) // C4
    var padChord = intArrayOf(48, 55, 60) // root, fifth, octave

    fun update(delta: Float): Boolean {
        stepTimer += delta
        if (stepTimer >= stepDuration) {
            stepTimer -= stepDuration
            currentStep = (currentStep + 1) % 16
            return true // step advanced
        }
        return false
    }

    fun generateDrumPattern(): Pattern {
        val notes = IntArray(16) { -1 }
        val velocities = FloatArray(16) { 0.5f }

        // Kick on 1, 5, 9, 13 (four-on-the-floor)
        for (i in listOf(0, 4, 8, 12)) {
            notes[i] = 0 // 0 = kick
            velocities[i] = 0.9f
        }
        // Snare on 4, 12
        for (i in listOf(4, 12)) {
            notes[i] = 1 // 1 = snare
            velocities[i] = 0.7f
        }
        // Hi-hat on even steps
        for (i in 0 until 16 step 2) {
            if (notes[i] == -1) {
                notes[i] = 2 // 2 = hihat
                velocities[i] = 0.4f
            }
        }
        // Random extra hits
        for (i in 0 until 16) {
            if (notes[i] == -1 && random.nextFloat() < 0.2f) {
                notes[i] = 2
                velocities[i] = 0.25f
            }
        }

        return Pattern(notes = notes, velocities = velocities)
    }

    fun generateBassPattern(root: Int): Pattern {
        val notes = IntArray(16) { -1 }
        val velocities = FloatArray(16) { 0.6f }

        // Bass hits on kick positions + some fills
        for (i in 0 until 16) {
            if (i % 4 == 0) {
                notes[i] = root
            } else if (random.nextFloat() < 0.3f) {
                val scaleIdx = random.nextInt(Synthesizer.PENTATONIC_MINOR.size)
                notes[i] = root + Synthesizer.PENTATONIC_MINOR[scaleIdx]
            }
        }
        return Pattern(notes = notes, velocities = velocities)
    }

    fun generateLeadPattern(root: Int): Pattern {
        val notes = IntArray(16) { -1 }
        val velocities = FloatArray(16) { 0.5f }

        var currentScaleDegree = 2 // start in middle of scale
        for (i in 0 until 16) {
            if (random.nextFloat() < 0.6f) { // 60% note density
                notes[i] = Synthesizer.scaleNote(root, currentScaleDegree)
                velocities[i] = random.nextFloat(0.3f, 0.7f)

                // Markov transition
                val roll = random.nextFloat()
                var cumulative = 0f
                var delta = -2
                for (w in markovWeights.indices) {
                    cumulative += markovWeights[w]
                    if (roll < cumulative) {
                        delta = w - 2
                        break
                    }
                }
                currentScaleDegree = (currentScaleDegree + delta).coerceIn(0, 9)
            }
        }
        return Pattern(notes = notes, velocities = velocities)
    }

    fun regeneratePatterns(root: Int) {
        drumPattern = generateDrumPattern()
        bassPattern = generateBassPattern(root)
        leadPattern = generateLeadPattern(root + 12) // lead one octave up
        padChord = intArrayOf(root, root + 7, root + 12)
    }
}
