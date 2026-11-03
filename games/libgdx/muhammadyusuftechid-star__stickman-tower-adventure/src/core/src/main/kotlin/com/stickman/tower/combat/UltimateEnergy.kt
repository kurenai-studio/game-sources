package com.stickman.tower.combat

/**
 * Komponen akumulasi energi untuk jurus pamungkas (Ultimate).
 * Energi diperoleh setiap kali serangan pemain mengenai musuh.
 */
class UltimateEnergy(
    var maxEnergy: Float = 100f
) {
    var currentEnergy: Float = 0f
        private set

    val isReady: Boolean get() = currentEnergy >= maxEnergy
    val energyPercent: Float get() = (currentEnergy / maxEnergy).coerceIn(0f, 1f)

    fun addEnergy(amount: Float) {
        currentEnergy = (currentEnergy + amount).coerceAtMost(maxEnergy)
    }

    /**
     * Menggunakan energi untuk memicu Ultimate jika sudah mencapai 100%.
     */
    fun consume(): Boolean {
        if (isReady) {
            currentEnergy = 0f
            return true
        }
        return false
    }

    fun reset() {
        currentEnergy = 0f
    }
}
