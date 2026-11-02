package com.darumahq.rainbowclimb.util

import java.util.Random

/**
 * Deterministic RNG — same seed produces the same level layout.
 * Enables seed sharing between players.
 */
class SeededRandom(seed: Long = System.currentTimeMillis()) {
    private val random = Random(seed)
    val seed: Long = seed

    fun nextFloat(): Float = random.nextFloat()
    fun nextInt(bound: Int): Int = random.nextInt(bound)
    fun nextBoolean(): Boolean = random.nextBoolean()

    fun nextFloat(min: Float, max: Float): Float =
        min + random.nextFloat() * (max - min)

    fun nextInt(min: Int, max: Int): Int =
        min + random.nextInt(max - min + 1)
}
