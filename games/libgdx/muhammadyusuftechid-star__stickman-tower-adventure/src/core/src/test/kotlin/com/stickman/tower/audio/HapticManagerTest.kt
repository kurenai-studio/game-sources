package com.stickman.tower.audio

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class HapticManagerTest {

    @Test
    fun testHapticToggle() {
        val initial = HapticManager.isEnabled
        HapticManager.toggle()
        assertEquals(!initial, HapticManager.isEnabled)

        // Toggle kembali ke kondisi awal
        HapticManager.toggle()
        assertEquals(initial, HapticManager.isEnabled)
    }

    @Test
    fun testSafeHeadlessVibrationCalls() {
        // Pemanggilan getaran tidak boleh crash meski dipanggil di environment non-Android / testing
        HapticManager.vibrateLight()
        HapticManager.vibrateMedium()
        HapticManager.vibrateHeavy()
        assertTrue(true, "Vibration calls should execute safely without exceptions")
    }

    private fun assertEquals(expected: Boolean, actual: Boolean) {
        kotlin.test.assertEquals(expected, actual)
    }
}
