package com.stickman.tower.achievement

import com.stickman.tower.rpg.SaveData

/**
 * Manajer Pengelolaan Sistem Achievement, Pelacak Statistik Tempur,
 * dan Antrean Notifikasi Banner Trofi Real-Time.
 */
object AchievementManager {

    private val unlockedAchievementIds = mutableSetOf<String>()
    val pendingNotifications = mutableListOf<Achievement>()

    var perfectParryCount: Int = 0
        private set
    var highestComboCount: Int = 0
        private set

    fun isUnlocked(id: String): Boolean = unlockedAchievementIds.contains(id)

    fun getUnlockedCount(): Int = unlockedAchievementIds.size

    fun getTotalCount(): Int = AchievementCatalog.ACHIEVEMENTS.size

    fun getUnlockedIds(): Set<String> = unlockedAchievementIds.toSet()

    /**
     * Membuka pencapaian tertentu, menambahkan reward emas, dan mengantrekan notifikasi banner.
     * Mengembalikan true jika baru pertama kali terbuka, false jika sudah terbuka sebelumnya.
     */
    fun unlock(id: String, saveData: SaveData? = null): Boolean {
        if (isUnlocked(id)) return false
        val achievement = AchievementCatalog.findById(id) ?: return false

        unlockedAchievementIds.add(id)
        pendingNotifications.add(achievement)

        if (saveData != null) {
            saveData.gold += achievement.goldReward
            syncToSave(saveData)
        }
        return true
    }

    /**
     * Memverifikasi dan memicu achievement berdasarkan peristiwa tempur (Event Hooks).
     */
    fun onEnemyKilled(isBoss: Boolean, floorNumber: Int, bossName: String? = null, saveData: SaveData? = null): List<Achievement> {
        val unlockedNow = mutableListOf<Achievement>()

        if (unlock("FIRST_BLOOD", saveData)) {
            AchievementCatalog.findById("FIRST_BLOOD")?.let { unlockedNow.add(it) }
        }

        if (isBoss) {
            val name = bossName?.lowercase() ?: ""
            if (floorNumber == 3 || name.contains("oakhaven") || name.contains("guardian")) {
                if (unlock("TOWER_GUARDIAN_DOWN", saveData)) AchievementCatalog.findById("TOWER_GUARDIAN_DOWN")?.let { unlockedNow.add(it) }
            }
            if (floorNumber == 5 || name.contains("matron") || name.contains("amethyst")) {
                if (unlock("MATRON_SLAYER", saveData)) AchievementCatalog.findById("MATRON_SLAYER")?.let { unlockedNow.add(it) }
            }
            if (floorNumber == 8 || name.contains("doppelganger") || name.contains("doppelgänger") || name.contains("shadow")) {
                if (unlock("SHADOW_REFLECTOR", saveData)) AchievementCatalog.findById("SHADOW_REFLECTOR")?.let { unlockedNow.add(it) }
            }
            if (floorNumber == 9 || name.contains("sovereign") || name.contains("crimson")) {
                if (unlock("CRIMSON_CLEANSER", saveData)) AchievementCatalog.findById("CRIMSON_CLEANSER")?.let { unlockedNow.add(it) }
            }
            if (floorNumber == 10 || name.contains("calligrapher")) {
                if (unlock("DESTINY_REWRITTEN", saveData)) AchievementCatalog.findById("DESTINY_REWRITTEN")?.let { unlockedNow.add(it) }
            }
        }
        return unlockedNow
    }

    fun onPerfectParry(saveData: SaveData? = null): Boolean {
        perfectParryCount++
        if (perfectParryCount >= 10) {
            return unlock("PERFECT_PARRY_PRO", saveData)
        }
        return false
    }

    fun onComboHit(currentCombo: Int, saveData: SaveData? = null): Boolean {
        if (currentCombo > highestComboCount) {
            highestComboCount = currentCombo
        }
        if (highestComboCount >= 15) {
            return unlock("COMBO_VIRTUOSO", saveData)
        }
        return false
    }

    fun onWeaponUpgraded(atkLevel: Int, saveData: SaveData? = null): Boolean {
        if (atkLevel >= 5) {
            return unlock("FORGE_MASTER", saveData)
        }
        return false
    }

    fun onTalentsUnlocked(unlockedTalentCount: Int, saveData: SaveData? = null): Boolean {
        if (unlockedTalentCount >= 3) {
            return unlock("TALENT_ADEPT", saveData)
        }
        return false
    }

    fun onEndlessFloorReached(floor: Int, saveData: SaveData? = null): Boolean {
        if (floor >= 15) {
            return unlock("ENDLESS_SURVIVOR", saveData)
        }
        return false
    }

    fun onStoryCodexOpened(saveData: SaveData? = null): Boolean {
        return unlock("CHRONICLER_OF_AETHELGARD", saveData)
    }

    /**
     * Mengambil dan menghapus satu banner notifikasi dari antrean (FIFO).
     */
    fun pollNotification(): Achievement? {
        if (pendingNotifications.isEmpty()) return null
        return pendingNotifications.removeAt(0)
    }

    /**
     * Memuat daftar ID prestasi yang telah dicapai dari SaveData.
     */
    fun loadFromSave(saveData: SaveData) {
        unlockedAchievementIds.clear()
        // Skema V2: Baca dari koleksi khusus
        for (id in saveData.unlockedAchievements) {
            if (AchievementCatalog.findById(id) != null) {
                unlockedAchievementIds.add(id)
            }
        }
        // Skema V1 legacy fallback
        for (item in saveData.unlockedCharacters) {
            if (item.startsWith("ACHV_")) {
                val achvId = item.removePrefix("ACHV_")
                if (AchievementCatalog.findById(achvId) != null) {
                    unlockedAchievementIds.add(achvId)
                }
            }
        }

        // Retroactive Auto-Validation berdasarkan progres tersimpan di SaveData
        if (saveData.totalEnemiesDefeated > 0) {
            unlockedAchievementIds.add("FIRST_BLOOD")
        }
        if (saveData.highestTowerFloor > 3 || (saveData.bestiaryKills["TOWER_GUARDIAN"] ?: 0) > 0) {
            unlockedAchievementIds.add("TOWER_GUARDIAN_DOWN")
        }
        if (saveData.highestTowerFloor > 5 || (saveData.bestiaryKills["AMETHYST_MATRON"] ?: 0) > 0) {
            unlockedAchievementIds.add("MATRON_SLAYER")
        }
        if (saveData.highestTowerFloor > 8 || (saveData.bestiaryKills["SHADOW_DOPPELGANGER"] ?: 0) > 0) {
            unlockedAchievementIds.add("SHADOW_REFLECTOR")
        }
        if (saveData.highestTowerFloor > 9 || (saveData.bestiaryKills["CRIMSON_SOVEREIGN"] ?: 0) > 0) {
            unlockedAchievementIds.add("CRIMSON_CLEANSER")
        }
        if (saveData.highestTowerFloor > 10 || saveData.highestEndlessFloor > 0 || (saveData.bestiaryKills["GRAND_CALLIGRAPHER"] ?: 0) > 0) {
            unlockedAchievementIds.add("DESTINY_REWRITTEN")
        }
        if (saveData.highestEndlessFloor >= 15) {
            unlockedAchievementIds.add("ENDLESS_SURVIVOR")
        }
        if (saveData.weaponAtkLevel >= 5) {
            unlockedAchievementIds.add("FORGE_MASTER")
        }
        if (saveData.unlockedTalents.size >= 3) {
            unlockedAchievementIds.add("TALENT_ADEPT")
        }
        if (saveData.unlockedLoreTablets.size >= 3) {
            unlockedAchievementIds.add("CHRONICLER_OF_AETHELGARD")
        }
        syncToSave(saveData)
    }

    /**
     * Menyimpan seluruh ID prestasi aktif ke dalam SaveData.
     */
    fun syncToSave(saveData: SaveData) {
        saveData.unlockedAchievements.clear()
        saveData.unlockedAchievements.addAll(unlockedAchievementIds)

        saveData.unlockedCharacters.removeAll { it.startsWith("ACHV_") }
        for (id in unlockedAchievementIds) {
            saveData.unlockedCharacters.add("ACHV_$id")
        }
    }

    /**
     * Menyetel ulang seluruh data prestasi (untuk keperluan testing / reset save).
     */
    fun reset() {
        unlockedAchievementIds.clear()
        pendingNotifications.clear()
        perfectParryCount = 0
        highestComboCount = 0
    }
}
