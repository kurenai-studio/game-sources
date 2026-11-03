package com.stickman.tower.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class FontManagerTest {

    @Test
    fun testFontManagerConstants() {
        assertTrue(FontManager.EXTRA_CHARS.contains("•"))
        assertTrue(FontManager.EXTRA_CHARS.contains("★"))
        assertTrue(FontManager.EXTRA_CHARS.contains("⚔"))
        assertTrue(FontManager.EXTRA_CHARS.contains("◀"))
        assertTrue(FontManager.EXTRA_CHARS.contains("▶"))
        assertTrue(FontManager.EXTRA_CHARS.contains("☼"))
        assertTrue(FontManager.EXTRA_CHARS.contains("☽"))
        assertTrue(FontManager.EXTRA_CHARS.contains("⚡"))
        assertTrue(FontManager.EXTRA_CHARS.contains("☯"))
        assertTrue(FontManager.EXTRA_CHARS.contains("◇"))
        assertTrue(FontManager.EXTRA_CHARS.contains("◈"))
        assertTrue(FontManager.EXTRA_CHARS.contains("◆"))
        assertTrue(FontManager.EXTRA_CHARS.contains("▲"))
        assertTrue(FontManager.EXTRA_CHARS.contains("▼"))
        assertTrue(FontManager.EXTRA_CHARS.contains("—"))
    }

    @Test
    fun testFontManagerLifecycleFallback() {
        // Pada headless test runner tanpa OpenGL backend, init() harus fallback dengan aman
        FontManager.init()
        assertTrue(FontManager.isInitialized)

        // Idempotency check: inisialisasi ganda harus aman
        FontManager.init()
        assertTrue(FontManager.isInitialized)

        FontManager.dispose()
        assertFalse(FontManager.isInitialized)
    }
}
