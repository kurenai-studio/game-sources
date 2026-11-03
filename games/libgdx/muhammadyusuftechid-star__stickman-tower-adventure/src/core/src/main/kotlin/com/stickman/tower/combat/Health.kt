package com.stickman.tower.combat

/**
 * Komponen nyawa, penanganan damage, dan durasi kebal (i-Frames).
 */
class Health(
    var maxHp: Float = 100f,
    private val invulnerableDuration: Float = 0.25f
) {
    var currentHp: Float = maxHp
        private set

    var invulnerableTimer: Float = 0f
        private set

    var flashTimer: Float = 0f
        private set

    val isDead: Boolean get() = currentHp <= 0f
    val isInvulnerable: Boolean get() = invulnerableTimer > 0f
    val isFlashing: Boolean get() = flashTimer > 0f

    fun update(delta: Float) {
        if (invulnerableTimer > 0f) {
            invulnerableTimer = (invulnerableTimer - delta).coerceAtLeast(0f)
        }
        if (flashTimer > 0f) {
            flashTimer = (flashTimer - delta).coerceAtLeast(0f)
        }
    }

    /**
     * Menerapkan damage pada karakter jika tidak dalam kondisi kebal atau mati.
     * Mengembalikan true jika damage berhasil masuk.
     */
    fun takeDamage(amount: Float): Boolean {
        if (isDead || isInvulnerable) return false

        currentHp = (currentHp - amount).coerceAtLeast(0f)
        invulnerableTimer = invulnerableDuration
        flashTimer = 0.15f
        return true
    }

    fun heal(amount: Float) {
        if (!isDead) {
            currentHp = (currentHp + amount).coerceAtMost(maxHp)
        }
    }

    /**
     * Mengurangi HP untuk ritual pengorbanan altar tanpa memicu invulnerability frames,
     * dan mempertahankan minimal 1 HP agar karakter tidak langsung tewas di tempat.
     */
    fun consumeHp(amount: Float): Float {
        if (isDead) return 0f
        val actual = amount.coerceAtMost(currentHp - 1f).coerceAtLeast(0f)
        currentHp -= actual
        return actual
    }

    fun setMaxHp(newMax: Float, healToFull: Boolean = true) {
        maxHp = newMax
        if (healToFull) {
            currentHp = newMax
        } else {
            currentHp = currentHp.coerceAtMost(maxHp)
        }
    }

    fun reset() {
        currentHp = maxHp
        invulnerableTimer = 0f
        flashTimer = 0f
    }
}
