package com.stickman.tower.screen

import com.stickman.tower.world.TowerLevelBuilder
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Unit Test untuk FASE 30: Integrasi 50 Lore Tablets & Modernisasi Story Codex 50 Bab (Tab Paginasi 5 Saga).
 * Memvalidasi keberadaan 50 tablet pada level generator dan integritas struktur 5 Saga di StoryCodexScreen.
 */
class StoryCodexSagaTabsTest {

    @Test
    fun testFiftyLoreTabletsInTowerLevelBuilder() {
        // Validasi Modul 30.1: Setiap lantai 1 s/d 50 memiliki LoreTablet terpasang
        for (f in 1..50) {
            val floor = TowerLevelBuilder.buildFloor(f)
            assertTrue(floor.loreTablets.isNotEmpty(), "Lantai $f harus memiliki setidaknya 1 Lore Tablet!")
            val tablet = floor.loreTablets.first()
            assertEquals("TABLET_$f", tablet.tabletId, "Tablet ID di lantai $f harus TABLET_$f")
            assertTrue(tablet.title.isNotEmpty(), "Judul tablet di lantai $f tidak boleh kosong!")
            assertTrue(tablet.text.isNotEmpty(), "Teks tablet di lantai $f tidak boleh kosong!")
        }
    }

    @Test
    fun testFiveSagasStructureInStoryCodex() {
        // Validasi Modul 30.2: StoryCodexScreen memiliki 5 Saga
        val codex = StoryCodexScreen(game = com.stickman.tower.StickmanGame())
        assertEquals(5, codex.sagas.size, "StoryCodexScreen harus memiliki tepat 5 Saga!")

        val expectedTabs = listOf("SAGA I", "SAGA II", "SAGA III", "SAGA IV", "SAGA V")
        for (i in codex.sagas.indices) {
            val saga = codex.sagas[i]
            assertEquals(expectedTabs[i], saga.tabLabel, "Label tab saga index $i harus ${expectedTabs[i]}")
            assertEquals(10, saga.chapters.size, "Masing-masing saga harus memiliki tepat 10 bab!")
        }

        // Total seluruh bab harus tepat 50
        val totalChapters = codex.sagas.sumOf { it.chapters.size }
        assertEquals(50, totalChapters, "Total bab di seluruh 5 saga harus tepat 50 bab!")
    }

    @Test
    fun testAllChaptersHaveCanonicalTabletsAndPages() {
        val codex = StoryCodexScreen(game = com.stickman.tower.StickmanGame())

        var expectedFloor = 1
        for (saga in codex.sagas) {
            for (chapter in saga.chapters) {
                assertEquals(expectedFloor, chapter.floorNumber, "Nomor lantai chapter harus $expectedFloor")
                assertTrue(chapter.title.contains("Lt $expectedFloor:"), "Judul chapter harus memuat 'Lt $expectedFloor:'")
                assertTrue(chapter.tag.isNotEmpty(), "Tag bioma chapter $expectedFloor tidak boleh kosong!")

                // Verifikasi 2 halaman per bab
                assertEquals(2, chapter.pages.size, "Chapter $expectedFloor harus memiliki 2 halaman baca!")
                val page1 = chapter.pages[0]
                val page2 = chapter.pages[1]

                assertTrue(page1.subtitle.contains("Lantai $expectedFloor"), "Subtitle hal 1 harus memuat 'Lantai $expectedFloor'")
                assertTrue(page1.paragraphs.isNotEmpty(), "Paragraf hal 1 tidak boleh kosong")

                assertTrue(page2.subtitle.contains("Tablet $expectedFloor"), "Subtitle hal 2 harus memuat 'Tablet $expectedFloor'")
                assertTrue(page2.paragraphs.any { it.startsWith("📜") || it.contains("Tablet") },
                    "Halaman 2 harus memuat kutipan resmi prasasti kuno Tablet $expectedFloor")

                expectedFloor++
            }
        }
        assertEquals(51, expectedFloor, "Harus mencakup tepat dari Lantai 1 s/d Lantai 50!")
    }
}
