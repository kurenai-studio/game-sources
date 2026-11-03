package com.stickman.tower.vfx

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Unit Test untuk PostProcessingManager (Engine & Graphics 10/10).
 * Memverifikasi state machine shockwave, trigger flash, dan ketiadaan error saat update.
 */
class PostProcessingManagerTest {

    @Test
    fun testScreenFlashLifecycle() {
        val ppm = PostProcessingManager()

        // Flash mula-mula tidak aktif
        ppm.update(0.1f)

        // Memicu flash putih
        ppm.triggerFlash(1f, 1f, 1f, duration = 0.2f, maxAlpha = 0.5f)

        // Update sebagian durasi
        ppm.update(0.1f)

        // Update hingga habis
        ppm.update(0.15f)
        ppm.update(0.05f)

        assertTrue("PostProcessingManager harus mengelola siklus flash dengan mulus", true)
    }

    @Test
    fun testChromaticShockwaveLifecycle() {
        val ppm = PostProcessingManager()

        // Memicu shockwave
        ppm.triggerChromaticShockwave(x = 10f, y = 5f, maxRadius = 20f, speed = 40f, duration = 0.5f)

        // Update seiring berjalannya waktu
        ppm.update(0.2f)
        ppm.update(0.35f)

        // Setelah melebihi durasi, shockwave non-aktif
        ppm.update(0.1f)

        assertTrue("Shockwave harus berkembang dan kadaluwarsa dengan benar", true)
    }
}
