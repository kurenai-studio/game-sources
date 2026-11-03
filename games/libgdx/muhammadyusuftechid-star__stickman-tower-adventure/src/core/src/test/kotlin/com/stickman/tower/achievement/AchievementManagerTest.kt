package com.stickman.tower.achievement

import com.stickman.tower.rpg.SaveData
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class AchievementManagerTest {

    @BeforeTest
    fun setUp() {
        AchievementManager.reset()
    }

    @Test
    fun testCatalogCompleteness() {
        val total = AchievementCatalog.ACHIEVEMENTS.size
        assertEquals(12, total, "Harus terdapat 12 trofi prestasi di katalog Aethelgard")
        assertNotNull(AchievementCatalog.findById("FIRST_BLOOD"))
        assertNotNull(AchievementCatalog.findById("DESTINY_REWRITTEN"))
        assertNotNull(AchievementCatalog.findById("CHRONICLER_OF_AETHELGARD"))
    }

    @Test
    fun testUnlockGrantsGoldAndQueuesNotification() {
        val saveData = SaveData(gold = 100)
        assertFalse(AchievementManager.isUnlocked("FIRST_BLOOD"))

        val unlocked = AchievementManager.unlock("FIRST_BLOOD", saveData)
        assertTrue(unlocked)
        assertTrue(AchievementManager.isUnlocked("FIRST_BLOOD"))
        assertEquals(150, saveData.gold, "Gold harus bertambah +50 dari reward FIRST_BLOOD")

        // Verifikasi antrean notifikasi banner
        val notification = AchievementManager.pollNotification()
        assertNotNull(notification)
        assertEquals("FIRST_BLOOD", notification.id)
        assertEquals("Darah Pertama", notification.title)

        // Verifikasi sifat idempoten (tidak dapat di-unlock dua kali)
        val secondAttempt = AchievementManager.unlock("FIRST_BLOOD", saveData)
        assertFalse(secondAttempt)
        assertEquals(150, saveData.gold)
    }

    @Test
    fun testCombatEventHooks() {
        val saveData = SaveData(gold = 0)

        // 1. Kematian musuh biasa
        AchievementManager.onEnemyKilled(isBoss = false, floorNumber = 1, saveData = saveData)
        assertTrue(AchievementManager.isUnlocked("FIRST_BLOOD"))

        // 2. Kematian Boss Lantai 3
        AchievementManager.onEnemyKilled(isBoss = true, floorNumber = 3, bossName = "TOWER GUARDIAN", saveData = saveData)
        assertTrue(AchievementManager.isUnlocked("TOWER_GUARDIAN_DOWN"))

        // 3. Kematian Boss Lantai 10
        AchievementManager.onEnemyKilled(isBoss = true, floorNumber = 10, bossName = "THE GRAND CALLIGRAPHER", saveData = saveData)
        assertTrue(AchievementManager.isUnlocked("DESTINY_REWRITTEN"))
    }

    @Test
    fun testParryAndComboMilestones() {
        val saveData = SaveData()

        // Uji coba 9x parry belum memicu prestasi
        for (i in 1..9) {
            val unlocked = AchievementManager.onPerfectParry(saveData)
            assertFalse(unlocked)
        }
        assertFalse(AchievementManager.isUnlocked("PERFECT_PARRY_PRO"))

        // Parry ke-10 memicu prestasi
        val unlockedTenth = AchievementManager.onPerfectParry(saveData)
        assertTrue(unlockedTenth)
        assertTrue(AchievementManager.isUnlocked("PERFECT_PARRY_PRO"))

        // Uji coba Combo 15-hit
        AchievementManager.onComboHit(14, saveData)
        assertFalse(AchievementManager.isUnlocked("COMBO_VIRTUOSO"))

        AchievementManager.onComboHit(15, saveData)
        assertTrue(AchievementManager.isUnlocked("COMBO_VIRTUOSO"))
    }

    @Test
    fun testSaveDataPersistenceAndRestore() {
        val saveData = SaveData()
        AchievementManager.unlock("MATRON_SLAYER", saveData)
        AchievementManager.unlock("FORGE_MASTER", saveData)

        // Sinkronisasi ke SaveData
        AchievementManager.syncToSave(saveData)
        assertTrue(saveData.unlockedCharacters.contains("ACHV_MATRON_SLAYER"))
        assertTrue(saveData.unlockedCharacters.contains("ACHV_FORGE_MASTER"))

        // Reset memory state lalu restore dari SaveData
        AchievementManager.reset()
        assertEquals(0, AchievementManager.getUnlockedCount())

        AchievementManager.loadFromSave(saveData)
        assertEquals(2, AchievementManager.getUnlockedCount())
        assertTrue(AchievementManager.isUnlocked("MATRON_SLAYER"))
        assertTrue(AchievementManager.isUnlocked("FORGE_MASTER"))
    }
}
