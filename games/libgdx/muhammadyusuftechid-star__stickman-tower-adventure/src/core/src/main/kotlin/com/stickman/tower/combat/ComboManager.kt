package com.stickman.tower.combat

/**
 * Mengelola sistem serangan kombo 3 pukulan (3-Hit Combo Chain)
 * dengan buffer input dan jendela waktu kombo (combo window).
 */
enum class ComboStep {
    HIT_1, // Tebasan cepat awal
    HIT_2, // Tebasan silang kedua
    HIT_3  // Tebasan pemungkas berat (Finisher Knockback)
}

data class ComboHitConfig(
    val step: ComboStep,
    val damage: Float,
    val knockbackX: Float,
    val knockbackY: Float,
    val startup: Float,
    val active: Float,
    val recovery: Float
) {
    val totalTime: Float get() = startup + active + recovery
}

class ComboManager {
    companion object {
        val HIT_1 = ComboHitConfig(
            step = ComboStep.HIT_1,
            damage = 12f,
            knockbackX = 3.5f,
            knockbackY = 2.0f,
            startup = 0.06f,
            active = 0.10f,
            recovery = 0.12f
        )
        val HIT_2 = ComboHitConfig(
            step = ComboStep.HIT_2,
            damage = 16f,
            knockbackX = 5.0f,
            knockbackY = 2.5f,
            startup = 0.06f,
            active = 0.10f,
            recovery = 0.12f
        )
        val HIT_3 = ComboHitConfig(
            step = ComboStep.HIT_3,
            damage = 26f,
            knockbackX = 9.0f,
            knockbackY = 4.5f,
            startup = 0.10f,
            active = 0.14f,
            recovery = 0.22f
        )

        const val COMBO_BUFFER_WINDOW = 0.38f // Waktu toleransi untuk menyambung combo berikutnya
    }

    var currentStep: ComboStep = ComboStep.HIT_1
        private set
    var currentConfig: ComboHitConfig = HIT_1
        private set

    var comboWindowTimer: Float = 0f
        private set

    var comboCount: Int = 0
        private set

    var hasBufferedInput: Boolean = false

    fun registerHit(): Int {
        comboCount++
        return comboCount
    }

    fun update(delta: Float, isAttacking: Boolean) {
        if (!isAttacking) {
            if (comboWindowTimer > 0f) {
                comboWindowTimer = (comboWindowTimer - delta).coerceAtLeast(0f)
                if (comboWindowTimer <= 0f) {
                    resetToHit1()
                }
            }
        }
    }

    /**
     * Memulai serangan baru atau menyambung kombo ke tahap berikutnya.
     */
    fun startNextHit(): ComboHitConfig {
        if (comboWindowTimer > 0f) {
            currentStep = when (currentStep) {
                ComboStep.HIT_1 -> ComboStep.HIT_2
                ComboStep.HIT_2 -> ComboStep.HIT_3
                ComboStep.HIT_3 -> ComboStep.HIT_1
            }
        } else {
            currentStep = ComboStep.HIT_1
        }

        currentConfig = when (currentStep) {
            ComboStep.HIT_1 -> HIT_1
            ComboStep.HIT_2 -> HIT_2
            ComboStep.HIT_3 -> HIT_3
        }

        // Buka jendela kombo untuk pukulan berikutnya
        comboWindowTimer = COMBO_BUFFER_WINDOW
        hasBufferedInput = false
        return currentConfig
    }

    fun resetToHit1() {
        currentStep = ComboStep.HIT_1
        currentConfig = HIT_1
        comboWindowTimer = 0f
        comboCount = 0
        hasBufferedInput = false
    }
}
