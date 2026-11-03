package com.stickman.tower.enemy

/**
 * Combat Director / Attack Token Manager:
 * Sistem koordinasi taktis kelompok musuh untuk mencegah situasi "dogpiling" (semua musuh menyerang
 * bersamaan dalam frame yang sama sehingga mustahil dihindari pemain).
 *
 * Mengatur kuota token serangan:
 * - Melee Attack Tokens: Maksimal 2 penyerang aktif simultan.
 * - Ranged Attack Tokens: Maksimal 1 penembak proyektil aktif simultan.
 *
 * Musuh yang tidak memegang token serangan akan beralih ke formasi taktis "ORBIT / FLANKING",
 * menjaga jarak aman, bersiap melingkar, dan menunggu giliran token serangan dibebaskan.
 */
object CombatDirector {

    var maxMeleeTokens: Int = 2
    var maxRangedTokens: Int = 1
    const val TOKEN_TIMEOUT: Float = 2.5f

    // Penyimpan pemegang token dan durasi aktifnya
    private val meleeHolders = mutableMapOf<Any, Float>()
    private val rangedHolders = mutableMapOf<Any, Float>()

    /**
     * Meminta token serangan jarak dekat (Melee).
     * Mengembalikan true jika token berhasil didapatkan atau requester sudah memilikinya.
     */
    fun requestMeleeToken(requester: Any): Boolean {
        if (meleeHolders.containsKey(requester)) {
            return true
        }
        if (meleeHolders.size < maxMeleeTokens) {
            meleeHolders[requester] = 0f
            return true
        }
        return false
    }

    /**
     * Meminta token serangan jarak jauh (Ranged).
     * Mengembalikan true jika token berhasil didapatkan atau requester sudah memilikinya.
     */
    fun requestRangedToken(requester: Any): Boolean {
        if (rangedHolders.containsKey(requester)) {
            return true
        }
        if (rangedHolders.size < maxRangedTokens) {
            rangedHolders[requester] = 0f
            return true
        }
        return false
    }

    /**
     * Melepaskan token serangan yang dipegang oleh requester.
     */
    fun releaseToken(requester: Any) {
        meleeHolders.remove(requester)
        rangedHolders.remove(requester)
    }

    /**
     * Memeriksa apakah requester saat ini memegang token serangan aktif.
     */
    fun hasToken(requester: Any): Boolean {
        return meleeHolders.containsKey(requester) || rangedHolders.containsKey(requester)
    }

    val activeMeleeTokensCount: Int
        get() = meleeHolders.size

    val activeRangedTokensCount: Int
        get() = rangedHolders.size

    val totalActiveTokens: Int
        get() = meleeHolders.size + rangedHolders.size

    /**
     * Update berkala per frame.
     * Mengawasi timeout keselamatan untuk mencegah kebocoran token (token starvation).
     */
    fun update(delta: Float) {
        val meleeIterator = meleeHolders.entries.iterator()
        while (meleeIterator.hasNext()) {
            val entry = meleeIterator.next()
            entry.setValue(entry.value + delta)
            if (entry.value > TOKEN_TIMEOUT) {
                meleeIterator.remove()
            }
        }

        val rangedIterator = rangedHolders.entries.iterator()
        while (rangedIterator.hasNext()) {
            val entry = rangedIterator.next()
            entry.setValue(entry.value + delta)
            if (entry.value > TOKEN_TIMEOUT) {
                rangedIterator.remove()
            }
        }
    }

    /**
     * Mereset seluruh token (misalnya saat ganti lantai menara atau restart game).
     */
    fun reset() {
        meleeHolders.clear()
        rangedHolders.clear()
    }
}
