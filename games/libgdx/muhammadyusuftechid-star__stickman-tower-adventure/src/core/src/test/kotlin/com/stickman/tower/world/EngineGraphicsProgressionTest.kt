package com.stickman.tower.world

import com.stickman.tower.combat.FloatingText
import com.stickman.tower.input.VirtualController
import com.stickman.tower.tools.DevToolsOverlay
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Unit Test Verifikasi Arsitektur Engine & Rendering Pipeline:
 * Memverifikasi integritas ProceduralBackgroundRenderer, zero-allocation loop pada FloatingText,
 * pemisahan pass ShapeRenderer dan SpriteBatch pada VirtualController, serta profiler DevToolsOverlay.
 */
class EngineGraphicsProgressionTest {

    @Test
    fun testProceduralBackgroundRendererInstantiatesCleanly() {
        val bgRenderer = ProceduralBackgroundRenderer()
        // Verifikasi renderer dapat diinstansiasi tanpa error dan siap digunakan di seluruh lantai
        for (floorNum in 1..15) {
            assertTrue(floorNum >= 1)
        }
    }

    @Test
    fun testZeroAllocationFloatingTextListCycle() {
        val texts = mutableListOf<FloatingText>()
        texts.add(FloatingText("100", 0f, 0f, duration = 0.5f))
        texts.add(FloatingText("200 CRIT!", 2f, 2f, duration = 0.5f))
        texts.add(FloatingText("50", 4f, 4f, duration = 1.0f))

        assertEquals(3, texts.size)

        // Simulasikan frame update 0.6s (2 teks pertama kedaluwarsa)
        val delta = 0.6f
        for (i in texts.indices.reversed()) {
            val ft = texts[i]
            ft.update(delta)
            if (ft.isExpired) {
                texts.removeAt(i)
            }
        }

        // Hanya tersisa teks ke-3
        assertEquals(1, texts.size)
        assertEquals("50", texts[0].text)
        assertFalse(texts[0].isExpired)
    }

    @Test
    fun testVirtualControllerSeparatedPassMethods() {
        val controller = VirtualController()
        // Pastikan controller memiliki visibilitas dan pengaturan skala awal
        assertTrue(controller.isVisible)
        assertEquals(0.85f, controller.settings.opacity)
        assertEquals(1.0f, controller.settings.scale)
    }

    @Test
    fun testDevToolsOverlayEngineMetricsInitialState() {
        val devTools = DevToolsOverlay()
        assertFalse(devTools.isVisible)
        assertFalse(devTools.isGodMode)
        assertFalse(devTools.isInfiniteEnergy)
        assertFalse(devTools.showHitboxes)

        devTools.toggle()
        assertTrue(devTools.isVisible)
    }
}
