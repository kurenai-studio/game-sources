package com.stickman.tower.rpg

import com.badlogic.gdx.Gdx

/**
 * Enterprise Save Data Migration Pipeline:
 * Mengelola evolusi skema penyimpanan data pemain secara otomatis antar versi permainan.
 *
 * Versi 1 -> Versi 2:
 * - Memisahkan entri 'ACHV_*' dari unlockedCharacters ke dalam koleksi khusus unlockedAchievements.
 * - Memisahkan entri 'TALENT_*' dari unlockedCharacters ke dalam koleksi khusus unlockedTalents.
 * - Menambahkan koleksi unlockedLoreTablets untuk pelacakan prasasti cerita.
 * - Mengisi metadata lastSavedTimestamp, playTimeSeconds, dan saveSlotId.
 * - Meningkatkan saveVersion ke 2 dan memperbarui checksum dengan FNV-1a salted hash.
 */
object SaveMigrator {

    private fun log(msg: String) {
        Gdx.app?.log("SaveMigrator", msg)
    }

    /**
     * Memeriksa dan menjalankan proses migrasi data jika saveVersion lebih rendah dari versi target.
     * Mengembalikan true jika data telah dimigrasi.
     */
    fun migrate(data: SaveData): Boolean {
        var migrated = false

        if (data.saveVersion < 2) {
            log("Migrating save data from Version ${data.saveVersion} to Version 2...")

            // 1. Ekstrak Achievements dari unlockedCharacters
            val achvEntries = data.unlockedCharacters.filter { it.startsWith("ACHV_") }
            for (entry in achvEntries) {
                val achvId = entry.removePrefix("ACHV_")
                if (!data.unlockedAchievements.contains(achvId)) {
                    data.unlockedAchievements.add(achvId)
                }
            }

            // 2. Ekstrak Talents dari unlockedCharacters
            val talentEntries = data.unlockedCharacters.filter { it.startsWith("TALENT_") }
            for (entry in talentEntries) {
                val talentId = entry.removePrefix("TALENT_")
                if (!data.unlockedTalents.contains(talentId)) {
                    data.unlockedTalents.add(talentId)
                }
            }

            // 3. Inisialisasi metadata tambahan jika masih kosong
            if (data.lastSavedTimestamp == 0L) {
                data.lastSavedTimestamp = System.currentTimeMillis()
            }
            if (data.saveSlotId <= 0) {
                data.saveSlotId = 1
            }

            data.saveVersion = 2
            data.sanitize()
            data.updateChecksum()
            migrated = true

            log("Migration to Version 2 completed successfully. Unlocked Achv: ${data.unlockedAchievements.size}, Talents: ${data.unlockedTalents.size}")
        }

        return migrated
    }
}
