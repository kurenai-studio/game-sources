package com.stickman.tower.combat

/**
 * Mengelola efek Hit Stop (jeda mikro / frame freeze) saat serangan mengenai target.
 * Memberikan rasa bobot benturan (impact weight) yang mantap pada aksi hack-and-slash.
 */
class HitStopManager {
    var timer: Float = 0f
        private set

    val isHitStopped: Boolean get() = timer > 0f

    fun trigger(duration: Float = 0.05f) {
        timer = duration
    }

    /**
     * Memperbarui timer hit stop. Mengembalikan true jika game sedang dalam freeze.
     */
    fun update(delta: Float): Boolean {
        if (timer > 0f) {
            timer = (timer - delta).coerceAtLeast(0f)
            return true
        }
        return false
    }
}
