package com.stickman.tower.quest

import com.badlogic.gdx.Gdx
import com.stickman.tower.achievement.AchievementManager
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.audio.HapticManager
import com.stickman.tower.rpg.CharacterStats
import com.stickman.tower.rpg.SaveData

/**
 * Enterprise Finite State Machine (FSM) Quest Manager untuk Stickman Tower Adventure:
 * - Mengelola siklus hidup misi: LOCKED -> AVAILABLE -> ACTIVE -> OBJECTIVES_MET -> COMPLETED.
 * - Pelacakan objektif event-driven terisolasi (decoupled) melalui dispatching sinyal `notifyEvent()`.
 * - Rantai otomatis Main Quest Odyssey (MQ_1 s/d MQ_7) dan Heritage Side Quests (SQ_*).
 * - Sinkronisasi penuh dengan SaveData V2 dan pemberian reward (Gold, EXP, Relic, Talent Point).
 */
object QuestManager {

    private const val TAG = "QuestManager"

    var activeMainQuestId: String = "MQ_1"
        private set

    val activeSideQuestIds = mutableSetOf<String>()
    val completedQuestIds = mutableSetOf<String>()

    // Map: objectiveId -> currentCount
    private val objectiveProgress = mutableMapOf<String, Int>()

    // Listener untuk notifikasi UI jika ada kemajuan quest
    var onQuestProgressChanged: ((questId: String, objective: QuestObjective) -> Unit)? = null
    var onQuestCompleted: ((quest: QuestDefinition) -> Unit)? = null

    init {
        // Secara default aktifkan MQ_1 dan 3 side quest warisan
        activeSideQuestIds.add("SQ_ARIA_COLORS")
        activeSideQuestIds.add("SQ_VALERIUS_VOW")
        activeSideQuestIds.add("SQ_VULCANUS_METEOR")
    }

    /**
     * Memulihkan status progres quest dari SaveData.
     */
    fun initFromSave(saveData: SaveData) {
        completedQuestIds.clear()
        completedQuestIds.addAll(saveData.completedQuests)

        activeMainQuestId = if (saveData.activeQuestId.isNotBlank()) {
            saveData.activeQuestId
        } else {
            findNextAvailableMainQuest() ?: "MQ_7"
        }

        objectiveProgress.clear()
        for ((key, value) in saveData.questProgressMap) {
            objectiveProgress[key] = value
        }

        // Pastikan side quests tetap aktif jika belum selesai
        activeSideQuestIds.clear()
        val allSide = QuestRegistry.getSideQuests()
        for (sq in allSide) {
            if (!completedQuestIds.contains(sq.id)) {
                activeSideQuestIds.add(sq.id)
            }
        }

        syncRegistryObjectiveCounts()
    }

    /**
     * Menyimpan status progres quest ke objek SaveData.
     */
    fun saveTo(saveData: SaveData) {
        saveData.activeQuestId = activeMainQuestId
        saveData.completedQuests = ArrayList(completedQuestIds)
        saveData.questProgressMap = HashMap(objectiveProgress)
    }

    /**
     * Mengambil definisi Main Quest yang sedang aktif saat ini.
     */
    fun getActiveMainQuest(): QuestDefinition? {
        if (completedQuestIds.contains(activeMainQuestId)) {
            val next = findNextAvailableMainQuest()
            if (next != null) {
                activeMainQuestId = next
            }
        }
        return QuestRegistry.getQuestById(activeMainQuestId)
    }

    /**
     * Mengambil daftar seluruh misi yang sedang aktif (Main Quest + Side Quests).
     */
    fun getAllActiveQuests(): List<QuestDefinition> {
        val list = mutableListOf<QuestDefinition>()
        val mainQ = getActiveMainQuest()
        if (mainQ != null && !completedQuestIds.contains(mainQ.id)) {
            list.add(mainQ)
        }
        for (sid in activeSideQuestIds) {
            if (!completedQuestIds.contains(sid)) {
                QuestRegistry.getQuestById(sid)?.let { list.add(it) }
            }
        }
        return list
    }

    /**
     * Mengambil status FSM dari sebuah quest berdasarkan progres objektifnya.
     */
    fun getQuestStatus(questId: String): QuestStatus {
        if (completedQuestIds.contains(questId)) {
            return QuestStatus.COMPLETED
        }

        val quest = QuestRegistry.getQuestById(questId) ?: return QuestStatus.LOCKED

        if (quest.category == QuestCategory.MAIN_ODYSSEY) {
            if (quest.id != activeMainQuestId && !isMainQuestUnlocked(quest.id)) {
                return QuestStatus.LOCKED
            }
        } else {
            if (!activeSideQuestIds.contains(quest.id)) {
                return QuestStatus.AVAILABLE
            }
        }

        return if (isAllObjectivesComplete(quest)) {
            QuestStatus.OBJECTIVES_MET
        } else {
            QuestStatus.ACTIVE
        }
    }

    /**
     * Notifikasi kejadian aksi tempur atau platforming dari game loop.
     * Mendorong pembaruan progres pada seluruh misi yang membutuhkan event ini.
     */
    fun notifyEvent(type: ObjectiveType, targetIdentifier: String = "", count: Int = 1) {
        if (count <= 0) return

        val activeList = getAllActiveQuests()
        for (quest in activeList) {
            if (completedQuestIds.contains(quest.id)) continue

            for (obj in quest.objectives) {
                if (obj.type == type) {
                    val matchesTarget = obj.targetIdentifier.isEmpty() ||
                            targetIdentifier.isEmpty() ||
                            obj.targetIdentifier.equals(targetIdentifier, ignoreCase = true)

                    if (matchesTarget) {
                        val current = getObjectiveCount(obj.id)
                        val updated = (current + count).coerceAtMost(obj.targetCount)
                        objectiveProgress[obj.id] = updated
                        obj.currentCount = updated

                        onQuestProgressChanged?.invoke(quest.id, obj)

                        Gdx.app?.log(TAG, "Quest [${quest.id}] Objective [${obj.id}] updated: $updated / ${obj.targetCount}")
                    }
                }
            }
        }
    }

    /**
     * Memeriksa apakah suatu objektif sudah mencapai target yang ditentukan.
     */
    fun isObjectiveComplete(objectiveId: String, targetCount: Int): Boolean {
        return getObjectiveCount(objectiveId) >= targetCount
    }

    /**
     * Mengambil nilai progres saat ini untuk suatu objektif.
     */
    fun getObjectiveCount(objectiveId: String): Int {
        return objectiveProgress[objectiveId] ?: 0
    }

    /**
     * Menentukan apakah semua objektif dalam sebuah quest telah terpenuhi.
     */
    fun isAllObjectivesComplete(quest: QuestDefinition): Boolean {
        for (obj in quest.objectives) {
            val progress = getObjectiveCount(obj.id)
            if (progress < obj.targetCount) {
                return false
            }
        }
        return true
    }

    /**
     * Memeriksa apakah hadiah misi siap diklaim.
     */
    fun canClaimReward(questId: String): Boolean {
        if (completedQuestIds.contains(questId)) return false
        val quest = QuestRegistry.getQuestById(questId) ?: return false
        return isAllObjectivesComplete(quest)
    }

    /**
     * Mengklaim hadiah misi dan memajukan rantai cerita Odyssey atau menyelesaikan Side Quest.
     */
    fun claimReward(questId: String, stats: CharacterStats? = null, saveData: SaveData? = null): Boolean {
        val quest = QuestRegistry.getQuestById(questId) ?: return false
        if (!canClaimReward(questId)) return false

        completedQuestIds.add(questId)
        activeSideQuestIds.remove(questId)

        // Berikan reward ke stats jika diberikan
        stats?.let { s ->
            s.gold += quest.goldReward
            s.addExp(quest.expReward)
        }

        saveData?.let { save ->
            if (quest.talentPointsReward > 0) {
                if (save.unspentTalentPoints < 0) save.unspentTalentPoints = 0
                save.unspentTalentPoints += quest.talentPointsReward
            }
        }

        // Efek audio dan haptic reward
        AudioManager.playLevelUp()
        HapticManager.vibrateMedium()

        // Pindahkan aktifitas cerita utama ke bab berikutnya jika ini Main Quest
        if (quest.category == QuestCategory.MAIN_ODYSSEY) {
            advanceMainQuestChain(quest.id)
        }

        onQuestCompleted?.invoke(quest)
        Gdx.app?.log(TAG, "Quest '${quest.title}' ($questId) successfully COMPLETED! Rewards claimed.")
        return true
    }

    /**
     * Memajukan rantai Main Quest Odyssey ke bab berikutnya.
     */
    private fun advanceMainQuestChain(currentQuestId: String) {
        val mainQuests = QuestRegistry.getMainQuests()
        val currentIndex = mainQuests.indexOfFirst { it.id == currentQuestId }
        if (currentIndex in 0 until mainQuests.size - 1) {
            val nextQuest = mainQuests[currentIndex + 1]
            activeMainQuestId = nextQuest.id
            Gdx.app?.log(TAG, "Advanced to Next Main Quest: ${nextQuest.title} (${nextQuest.id})")
        }
    }

    private fun isMainQuestUnlocked(questId: String): Boolean {
        val mainQuests = QuestRegistry.getMainQuests()
        val index = mainQuests.indexOfFirst { it.id == questId }
        if (index <= 0) return true
        val prevQuest = mainQuests[index - 1]
        return completedQuestIds.contains(prevQuest.id)
    }

    private fun findNextAvailableMainQuest(): String? {
        val mainQuests = QuestRegistry.getMainQuests()
        for (q in mainQuests) {
            if (!completedQuestIds.contains(q.id)) {
                return q.id
            }
        }
        return null
    }

    /**
     * Sinkronisasi nilai field `currentCount` pada objek di QuestRegistry dengan progress map internal.
     */
    fun syncRegistryObjectiveCounts() {
        for (quest in QuestRegistry.allQuests) {
            for (obj in quest.objectives) {
                obj.currentCount = getObjectiveCount(obj.id)
            }
        }
    }

    /**
     * Reset semua status progres (untuk reset profil atau unit test).
     */
    fun reset() {
        activeMainQuestId = "MQ_1"
        activeSideQuestIds.clear()
        activeSideQuestIds.add("SQ_ARIA_COLORS")
        activeSideQuestIds.add("SQ_VALERIUS_VOW")
        activeSideQuestIds.add("SQ_VULCANUS_METEOR")
        completedQuestIds.clear()
        objectiveProgress.clear()
        syncRegistryObjectiveCounts()
    }
}
