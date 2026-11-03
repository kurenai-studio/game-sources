package com.stickman.tower.quest

import com.stickman.tower.rpg.CharacterStats
import com.stickman.tower.rpg.SaveData
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class QuestManagerTest {

    @BeforeTest
    fun setUp() {
        QuestManager.reset()
    }

    @Test
    fun testQuestRegistryIntegrity() {
        val mainQuests = QuestRegistry.getMainQuests()
        assertEquals(7, mainQuests.size, "Must have exactly 7 canonical Main Odyssey quests")
        assertEquals("MQ_1", mainQuests[0].id)
        assertEquals("MQ_7", mainQuests[6].id)

        val sideQuests = QuestRegistry.getSideQuests()
        assertEquals(3, sideQuests.size, "Must have 3 Heritage Side Quests")
        assertTrue(sideQuests.any { it.id == "SQ_ARIA_COLORS" })
        assertTrue(sideQuests.any { it.id == "SQ_VALERIUS_VOW" })
        assertTrue(sideQuests.any { it.id == "SQ_VULCANUS_METEOR" })
    }

    @Test
    fun testInitialQuestState() {
        val activeMain = QuestManager.getActiveMainQuest()
        assertNotNull(activeMain)
        assertEquals("MQ_1", activeMain.id)
        assertEquals(QuestStatus.ACTIVE, QuestManager.getQuestStatus("MQ_1"))

        assertEquals(QuestStatus.LOCKED, QuestManager.getQuestStatus("MQ_2"))
        assertEquals(QuestStatus.ACTIVE, QuestManager.getQuestStatus("SQ_ARIA_COLORS"))
    }

    @Test
    fun testMainQuestProgressAndFSMTransitions() {
        val stats = CharacterStats()
        val initialGold = stats.gold
        val initialExp = stats.currentExp

        // 1. Kirim event parsial
        QuestManager.notifyEvent(ObjectiveType.CLEAR_FLOOR, "FLOOR_2", count = 1)
        assertEquals(1, QuestManager.getObjectiveCount("MQ1_OBJ1"))
        assertEquals(QuestStatus.ACTIVE, QuestManager.getQuestStatus("MQ_1"))
        assertFalse(QuestManager.canClaimReward("MQ_1"))

        // 2. Selesaikan objektif 1
        QuestManager.notifyEvent(ObjectiveType.CLEAR_FLOOR, "FLOOR_2", count = 1)
        assertEquals(2, QuestManager.getObjectiveCount("MQ1_OBJ1"))

        // 3. Selesaikan objektif 2 & 3
        QuestManager.notifyEvent(ObjectiveType.READ_TABLET, "TABLET_2", count = 2)
        QuestManager.notifyEvent(ObjectiveType.PERFECT_PARRY, "PARRY", count = 1)

        // Verifikasi FSM beralih ke OBJECTIVES_MET
        assertEquals(QuestStatus.OBJECTIVES_MET, QuestManager.getQuestStatus("MQ_1"))
        assertTrue(QuestManager.canClaimReward("MQ_1"))

        // 4. Klaim hadiah misi
        val claimed = QuestManager.claimReward("MQ_1", stats)
        assertTrue(claimed)
        assertEquals(QuestStatus.COMPLETED, QuestManager.getQuestStatus("MQ_1"))
        assertEquals(initialGold + 120, stats.gold)
        assertEquals(2, stats.level, "Player should level up to 2 with 150 EXP")
        assertEquals(50, stats.currentExp, "Remaining EXP after 100 consumed for level up")

        // 5. Rantai otomatis memajukan ke MQ_2
        val nextMain = QuestManager.getActiveMainQuest()
        assertNotNull(nextMain)
        assertEquals("MQ_2", nextMain.id)
        assertEquals(QuestStatus.ACTIVE, QuestManager.getQuestStatus("MQ_2"))
    }

    @Test
    fun testSideQuestCompletion() {
        val stats = CharacterStats()
        assertEquals(QuestStatus.ACTIVE, QuestManager.getQuestStatus("SQ_VALERIUS_VOW"))

        // Kumpulkan 3 lencana
        QuestManager.notifyEvent(ObjectiveType.COLLECT_ITEM, "LEGION_SIGNET", count = 3)
        assertTrue(QuestManager.canClaimReward("SQ_VALERIUS_VOW"))

        val success = QuestManager.claimReward("SQ_VALERIUS_VOW", stats)
        assertTrue(success)
        assertEquals(QuestStatus.COMPLETED, QuestManager.getQuestStatus("SQ_VALERIUS_VOW"))
        assertEquals(250, stats.gold)
    }

    @Test
    fun testSaveAndRestoreQuestProgress() {
        // Buat progres pada MQ_1
        QuestManager.notifyEvent(ObjectiveType.CLEAR_FLOOR, "FLOOR_2", count = 2)
        QuestManager.notifyEvent(ObjectiveType.READ_TABLET, "TABLET_2", count = 2)
        QuestManager.notifyEvent(ObjectiveType.PERFECT_PARRY, "PARRY", count = 1)
        QuestManager.claimReward("MQ_1")

        // Buat progres parsial pada MQ_2
        QuestManager.notifyEvent(ObjectiveType.READ_TABLET, "TABLET_3", count = 1)

        // Simpan ke SaveData
        val save = SaveData()
        QuestManager.saveTo(save)
        assertEquals("MQ_2", save.activeQuestId)
        assertTrue(save.completedQuests.contains("MQ_1"))
        assertEquals(1, save.questProgressMap["MQ2_OBJ2"])

        // Reset dan pulihkan dari SaveData
        QuestManager.reset()
        assertEquals("MQ_1", QuestManager.getActiveMainQuest()?.id)
        assertFalse(QuestManager.completedQuestIds.contains("MQ_1"))

        QuestManager.initFromSave(save)
        assertEquals("MQ_2", QuestManager.getActiveMainQuest()?.id)
        assertTrue(QuestManager.completedQuestIds.contains("MQ_1"))
        assertEquals(1, QuestManager.getObjectiveCount("MQ2_OBJ2"))
    }
}
