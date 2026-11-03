package com.stickman.tower.leaderboard

/**
 * Entri data papan peringkat ksatria menara (Leaderboard Entry).
 * Dilengkapi dengan 64-bit Salted FNV-1a Anti-Tamper Signature (Backend Standard 10/10)
 * untuk mencegah kecurangan pemalsuan skor lokal saat ditransmisikan ke cloud leaderboard.
 */
data class LeaderboardEntry(
    val id: String = java.util.UUID.randomUUID().toString(),
    val playerName: String = "Kaelen",
    val characterArchetype: String = "BALANCED",
    val floorReached: Int = 1,
    val score: Long = 0L,
    val clearTimeSeconds: Long = 0L,
    val timestamp: Long = System.currentTimeMillis(),
    var signature: String = ""
) : Comparable<LeaderboardEntry> {

    init {
        if (signature.isBlank()) {
            signature = calculateSignature()
        }
    }

    companion object {
        private const val LEADERBOARD_SALT = 0x4B3C2A1E9F8D7C6BL
    }

    /**
     * Menghitung tanda tangan anti-cheat 64-bit Salted FNV-1a dari data skor.
     */
    fun calculateSignature(): String {
        var hash = -3750763034362895579L xor LEADERBOARD_SALT
        val prime = 1099511628211L

        fun mix(value: Long) {
            hash = (hash xor value) * prime
        }

        fun mixString(s: String) {
            for (ch in s) {
                hash = (hash xor ch.code.toLong()) * prime
            }
        }

        mixString(id)
        mixString(playerName)
        mixString(characterArchetype)
        mix(floorReached.toLong())
        mix(score)
        mix(clearTimeSeconds)

        val positiveHash = hash and 0x7FFFFFFFFFFFFFFFL
        return positiveHash.toString(16)
    }

    /**
     * Memvalidasi apakah entri skor memiliki tanda tangan yang sah dan belum termutasi.
     */
    fun isSignatureValid(): Boolean {
        if (signature.isBlank()) return false
        return signature == calculateSignature()
    }

    /**
     * Mengurutkan entri berdasarkan skor tertinggi (descending),
     * atau waktu tersingkat (ascending) bila skor sama.
     */
    override fun compareTo(other: LeaderboardEntry): Int {
        val scoreComp = other.score.compareTo(this.score)
        if (scoreComp != 0) return scoreComp
        return this.clearTimeSeconds.compareTo(other.clearTimeSeconds)
    }

    /**
     * Memformat durasi detik menjadi string MM:SS atau HH:MM:SS.
     */
    fun getFormattedTime(): String {
        val hours = clearTimeSeconds / 3600
        val minutes = (clearTimeSeconds % 3600) / 60
        val seconds = clearTimeSeconds % 60
        return if (hours > 0) {
            String.format("%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format("%02d:%02d", minutes, seconds)
        }
    }
}
