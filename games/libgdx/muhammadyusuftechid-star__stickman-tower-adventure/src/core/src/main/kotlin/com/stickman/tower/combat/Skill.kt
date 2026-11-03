package com.stickman.tower.combat

/**
 * Komponen Skill biasa berbasis waktu cooldown.
 */
class Skill(
    var name: String = "Dash Strike",
    var cooldown: Float = 4.5f
) {
    var remainingCooldown: Float = 0f
        private set

    val isReady: Boolean get() = remainingCooldown <= 0f
    val cooldownPercent: Float get() = (remainingCooldown / cooldown).coerceIn(0f, 1f)

    fun update(delta: Float) {
        if (remainingCooldown > 0f) {
            remainingCooldown = (remainingCooldown - delta).coerceAtLeast(0f)
        }
    }

    /**
     * Mengaktifkan skill jika cooldown telah selesai, dengan dukungan cooldown reduction multiplier.
     */
    fun use(multiplier: Float = 1.0f): Boolean {
        if (isReady) {
            remainingCooldown = cooldown * multiplier.coerceIn(0.2f, 1.0f)
            return true
        }
        return false
    }

    fun reset() {
        remainingCooldown = 0f
    }
}
