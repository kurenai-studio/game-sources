package com.stickman.tower.narrative

import kotlin.math.sin

/**
 * Pengelola Bisikan Menara Kuno (Tower Whispers Engine).
 * Memantau kondisi idle pemain (> 4.0 detik tanpa input pergerakan/serangan)
 * dan menampilkan monolog puitis atmosferik yang memudar sesuai babak/lantai.
 */
class TowerWhisperManager {

    companion object {
        const val IDLE_THRESHOLD = 4.0f
        const val FADE_IN_TIME = 0.6f
        const val DISPLAY_DURATION = 4.5f
        const val FADE_OUT_TIME = 0.8f
        const val COOLDOWN_TIME = 3.0f

        val WHISPERS_ACT_1 = listOf(
            "Garis-garis ini... seperti pernah kulihat sebelum kanvas membeku.",
            "Dengarlah bisikan dinding kayu tua yang meratapi hilangnya warna hijau daun...",
            "Tinta di ujung jemarimu bergetar, merindukan goresan kuas kehidupan.",
            "Setiap pijakan di benteng bawah menyimpan gema langkah mereka yang gagal."
        )

        val WHISPERS_ACT_2 = listOf(
            "Uap belerang ini... mengingatkanku pada kobaran api penempaan purba.",
            "Kristal ungu di sekeliling kita berdenyut bagai detak jantung yang terbuang...",
            "Paron sang penempa terus berdentang menantang keheningan mutlak menara.",
            "Miasma beracun merayap perlahan, berusaha melarutkan garis tekadmu."
        )

        val WHISPERS_ACT_3 = listOf(
            "Kekosongan kosmis menatap balik ke dalam jiwamu.",
            "Tinta hitam di bawah kakimu berbisik tentang ribuan ksatria yang terhapus...",
            "Bintang-bintang di luar jendela ini hanyalah titik cat yang belum sempat mengering.",
            "Goresan pena terakhir menantimu di ujung kanvas keberadaan."
        )
    }

    var idleTimer: Float = 0f
        private set

    var currentWhisper: String? = null
        private set

    var whisperAlpha: Float = 0f
        private set

    var isWhisperActive: Boolean = false
        private set

    private var whisperTimer: Float = 0f
    private var cooldownTimer: Float = 0f
    private var lastIndex: Int = -1

    /**
     * Memperbarui logika waktu idle dan transparansi puitis bisikan menara.
     * @param delta Waktu antar frame dalam detik.
     * @param isPlayerIdle Benar jika pemain diam tanpa input tombol gerak/serang.
     * @param actNumber Nomor babak menara (1 = Lantai 1-3, 2 = Lantai 4-6, 3 = Lantai 7-10).
     */
    fun update(delta: Float, isPlayerIdle: Boolean, actNumber: Int) {
        if (!isPlayerIdle) {
            idleTimer = 0f
            if (isWhisperActive) {
                // Perlahan padam jika pemain mulai bergerak
                whisperAlpha = (whisperAlpha - delta * 2.5f).coerceAtLeast(0f)
                if (whisperAlpha <= 0f) {
                    endWhisper()
                }
            }
            return
        }

        // Pemain sedang diam (idle)
        if (cooldownTimer > 0f) {
            cooldownTimer -= delta
            return
        }

        if (!isWhisperActive) {
            idleTimer += delta
            if (idleTimer >= IDLE_THRESHOLD) {
                triggerWhisper(actNumber)
            }
        } else {
            whisperTimer += delta
            val totalTime = FADE_IN_TIME + DISPLAY_DURATION + FADE_OUT_TIME

            whisperAlpha = when {
                whisperTimer < FADE_IN_TIME -> (whisperTimer / FADE_IN_TIME).coerceIn(0f, 1f)
                whisperTimer < FADE_IN_TIME + DISPLAY_DURATION -> 1f
                whisperTimer < totalTime -> {
                    val fadeProgress = (whisperTimer - (FADE_IN_TIME + DISPLAY_DURATION)) / FADE_OUT_TIME
                    (1f - fadeProgress).coerceIn(0f, 1f)
                }
                else -> {
                    endWhisper()
                    0f
                }
            }
        }
    }

    private fun triggerWhisper(actNumber: Int) {
        val pool = when (actNumber) {
            1 -> WHISPERS_ACT_1
            2 -> WHISPERS_ACT_2
            else -> WHISPERS_ACT_3
        }
        if (pool.isEmpty()) return

        var nextIdx = (pool.indices).random()
        if (pool.size > 1 && nextIdx == lastIndex) {
            nextIdx = (nextIdx + 1) % pool.size
        }
        lastIndex = nextIdx

        currentWhisper = pool[nextIdx]
        isWhisperActive = true
        whisperTimer = 0f
        whisperAlpha = 0f
    }

    private fun endWhisper() {
        isWhisperActive = false
        currentWhisper = null
        whisperAlpha = 0f
        idleTimer = 0f
        whisperTimer = 0f
        cooldownTimer = COOLDOWN_TIME
    }

    fun reset() {
        idleTimer = 0f
        currentWhisper = null
        whisperAlpha = 0f
        isWhisperActive = false
        whisperTimer = 0f
        cooldownTimer = 0f
        lastIndex = -1
    }
}
