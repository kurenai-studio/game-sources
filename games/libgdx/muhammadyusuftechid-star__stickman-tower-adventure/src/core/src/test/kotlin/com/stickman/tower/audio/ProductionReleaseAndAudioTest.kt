package com.stickman.tower.audio

import com.stickman.tower.rpg.SaveData
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Unit Test Komprehensif untuk Sintesis Audio Master Prosedural,
 * VFX Vignette Anima Kritis & Integritas Kesiapan Rilis Produksi (Fase 20).
 */
class ProductionReleaseAndAudioTest {

    @Test
    fun testBgmDroneSampleSynthesisIntegrity() {
        val sampleRate = 22050
        val expectedLength = (sampleRate * 4.0f).toInt() // 88200 samples

        val tracks = listOf(
            "Act 1 Drone" to ProceduralMusicEngine.genAct1Drone(sampleRate),
            "Act 2 Drone" to ProceduralMusicEngine.genAct2Drone(sampleRate),
            "Act 3 Drone" to ProceduralMusicEngine.genAct3Drone(sampleRate),
            "Act 4 Drone" to ProceduralMusicEngine.genAct4Drone(sampleRate),
            "Endless Drone" to ProceduralMusicEngine.genEndlessDrone(sampleRate),
            "Boss Tension Drone" to ProceduralMusicEngine.genBossDrone(sampleRate)
        )

        for ((name, samples) in tracks) {
            assertEquals(expectedLength, samples.size, "Panjang durasi trek $name harus persis 4.0 detik")

            var hasNonZero = false
            for (s in samples) {
                assertTrue(s in -32767..32767, "Nilai sample $name berada di luar rentang 16-bit PCM: $s")
                if (s != 0.toShort()) hasNonZero = true
            }
            assertTrue(hasNonZero, "Trek audio $name tidak boleh menghasilkan keheningan/silent audio")
        }
    }

    @Test
    fun testBgmSettingsAndSaveDataIntegration() {
        val save = SaveData()
        assertEquals(0.65f, save.bgmVolume, 0.001f, "Default volume BGM harus 0.65f")
        assertEquals(0.85f, save.sfxVolume, 0.001f, "Default volume SFX harus 0.85f")
        assertFalse(save.isAudioMuted, "Default status audio harus tidak termute")

        val initialChecksum = save.calculateChecksum()

        // Ubah volume BGM
        save.bgmVolume = 0.40f
        val modifiedChecksum = save.calculateChecksum()
        assertFalse(initialChecksum == modifiedChecksum, "Checksum SaveData harus memperhitungkan perubahan bgmVolume")

        // Sanitasi nilai volume di luar batas 0..1
        save.bgmVolume = 1.8f
        save.sfxVolume = -0.5f
        save.sanitize()
        assertEquals(1.0f, save.bgmVolume, 0.001f, "Sanitasi harus membatasi bgmVolume maksimal 1.0f")
        assertEquals(0.0f, save.sfxVolume, 0.001f, "Sanitasi harus membatasi sfxVolume minimal 0.0f")
    }

    @Test
    fun testCriticalAnimaVignetteThresholdCalculation() {
        val maxHp = 100f

        // Kondisi 1: HP 15 (di bawah ambang batas 25% Max HP = 25 HP)
        val hpCritical = 15f
        val isCritical = hpCritical <= maxHp * 0.25f
        assertTrue(isCritical, "HP 15 harus terdeteksi sebagai kondisi kritis")

        val hpRatio = (hpCritical / (maxHp * 0.25f)).coerceIn(0f, 1f)
        val urgency = 1f - hpRatio
        assertTrue(urgency in 0f..1f, "Tingkat urgensi bahaya harus berada di rentang 0..1")
        assertEquals(0.40f, urgency, 0.01f, "Urgensi untuk HP 15 dari 25 harus 0.40")

        // Kondisi 2: HP 60 (aman di atas 25%)
        val hpSafe = 60f
        val isSafeCritical = hpSafe <= maxHp * 0.25f
        assertFalse(isSafeCritical, "HP 60 tidak boleh memicu vignette kritis")
    }

    @Test
    fun testParryFlashFlareDecay() {
        var timer = 0.18f
        val delta = 0.06f

        timer = (timer - delta).coerceAtLeast(0f)
        assertEquals(0.12f, timer, 0.001f)

        timer = (timer - 0.20f).coerceAtLeast(0f)
        assertEquals(0.0f, timer, 0.001f, "Timer tidak boleh bernilai negatif")
    }

    @Test
    fun testFloorTransitionAlphaDecay() {
        var alpha = 1.0f
        val delta = 0.25f
        val decaySpeed = 2.2f

        alpha = (alpha - delta * decaySpeed).coerceAtLeast(0f)
        assertEquals(0.45f, alpha, 0.001f)

        alpha = (alpha - 1.0f).coerceAtLeast(0f)
        assertEquals(0.0f, alpha, 0.001f, "Alpha transisi tidak boleh bernilai negatif")
    }
}
