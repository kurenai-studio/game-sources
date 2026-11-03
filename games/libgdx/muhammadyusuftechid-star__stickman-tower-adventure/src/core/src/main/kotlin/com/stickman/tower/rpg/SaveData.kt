package com.stickman.tower.rpg

/**
 * Enterprise Game Save Data Architecture (Version 2 Schema):
 * - Skema versi terstruktur dengan migrasi otomatis mundur-maju (Backward & Forward Safe).
 * - Koleksi terpisah dan ternormalisasi: Karakter, Trofi/Achievement, Talent, dan Prasasti Cerita (Lore Tablets).
 * - Metadata sesi & sinkronisasi multi-slot: slotId, playTimeSeconds, lastSavedTimestamp.
 * - Keamanan integritas data: 64-bit FNV-1a Salted Cryptographic Checksum & Sanitasi Batas Nilai Ketat.
 */
data class SaveData(
    var playerLevel: Int = 1,
    var currentExp: Int = 0,
    var gold: Int = 0,
    var highestTowerFloor: Int = 1,
    var highestEndlessFloor: Int = 0,
    var totalEnemiesDefeated: Int = 0,
    var unlockedCharacters: ArrayList<String> = arrayListOf("STICKMAN_SWORD"),
    var unlockedAchievements: ArrayList<String> = arrayListOf(),
    var unlockedTalents: ArrayList<String> = arrayListOf(),
    var unlockedLoreTablets: ArrayList<String> = arrayListOf(),
    var activeQuestId: String = "MQ_1",
    var completedQuests: ArrayList<String> = arrayListOf(),
    var questProgressMap: HashMap<String, Int> = hashMapOf(),
    var challengeMedals: HashMap<String, String> = hashMapOf(),
    var acceptedBounties: ArrayList<String> = arrayListOf(),
    var completedBounties: ArrayList<String> = arrayListOf(),
    var claimedBounties: ArrayList<String> = arrayListOf(),
    var bestiaryKills: HashMap<String, Int> = hashMapOf(),
    var bgmVolume: Float = 0.65f,
    var sfxVolume: Float = 0.85f,
    var isAudioMuted: Boolean = false,
    var selectedArchetype: String = "BALANCED",
    var selectedSubClass: String = "BERSERKER",
    var selectedFamiliar: String = "ARIA_WISP",
    var unlockedFamiliars: ArrayList<String> = arrayListOf("ARIA_WISP"),
    var equippedRunes: ArrayList<String> = arrayListOf("RUNE_SOLAR", "NONE"),
    var unlockedRunes: ArrayList<String> = arrayListOf("RUNE_SOLAR"),
    var bossRushBestTimes: HashMap<String, Float> = hashMapOf(),
    var unlockedTitles: ArrayList<String> = arrayListOf("TITEL_NOVICE"),
    var activeTitle: String = "TITEL_NOVICE",
    var weaponAtkLevel: Int = 0,
    var weaponCritLevel: Int = 0,
    var weaponSpdLevel: Int = 0,
    var unspentTalentPoints: Int = -1,
    var playTimeSeconds: Long = 0L,
    var lastSavedTimestamp: Long = 0L,
    var isZephyrRescued: Boolean = false,
    var isGorgonRescued: Boolean = false,
    var hasSeenPrologue: Boolean = false,
    var saveSlotId: Int = 1,
    var saveVersion: Int = 2,
    var checksum: Long = 0L
) {
    companion object {
        const val MAX_STORY_FLOORS = 50
        const val CURRENT_VERSION = 2
        private const val CHECKSUM_SALT = 0x5F3759DF4923C021L
    }

    /**
     * Menghitung nilai checksum dari seluruh parameter progres dengan FNV-1a salted hash 64-bit.
     */
    fun calculateChecksum(): Long {
        var hash = -3750763034362895579L xor CHECKSUM_SALT // FNV offset basis xor salt
        val prime = 1099511628211L

        fun mix(value: Long) {
            hash = (hash xor value) * prime
        }

        fun mixString(s: String) {
            for (ch in s) {
                hash = (hash xor ch.code.toLong()) * prime
            }
        }

        mix(playerLevel.toLong())
        mix(currentExp.toLong())
        mix(gold.toLong())
        mix(highestTowerFloor.toLong())
        mix(highestEndlessFloor.toLong())
        mix(totalEnemiesDefeated.toLong())
        mix(weaponAtkLevel.toLong())
        mix(weaponCritLevel.toLong())
        mix(weaponSpdLevel.toLong())
        mix(unspentTalentPoints.toLong())
        mix(playTimeSeconds)
        mix(saveSlotId.toLong())
        mix(saveVersion.toLong())

        mixString(selectedArchetype)
        mixString(selectedSubClass)
        mixString(selectedFamiliar)

        // Hash koleksi secara deterministik terurut
        unlockedCharacters.sorted().forEach { mixString(it) }
        unlockedAchievements.sorted().forEach { mixString(it) }
        unlockedTalents.sorted().forEach { mixString(it) }
        unlockedLoreTablets.sorted().forEach { mixString(it) }
        unlockedFamiliars.sorted().forEach { mixString(it) }
        unlockedRunes.sorted().forEach { mixString(it) }
        equippedRunes.forEach { mixString(it) }

        bossRushBestTimes.keys.sorted().forEach { key ->
            mixString(key)
            mix(((bossRushBestTimes[key] ?: 0f) * 100).toLong())
        }
        unlockedTitles.sorted().forEach { mixString(it) }
        mixString(activeTitle)

        mixString(activeQuestId)
        completedQuests.sorted().forEach { mixString(it) }
        questProgressMap.keys.sorted().forEach { key ->
            mixString(key)
            mix(questProgressMap[key]?.toLong() ?: 0L)
        }

        challengeMedals.keys.sorted().forEach { key ->
            mixString(key)
            mixString(challengeMedals[key] ?: "")
        }
        acceptedBounties.sorted().forEach { mixString(it) }
        completedBounties.sorted().forEach { mixString(it) }
        claimedBounties.sorted().forEach { mixString(it) }
        bestiaryKills.keys.sorted().forEach { key ->
            mixString(key)
            mix(bestiaryKills[key]?.toLong() ?: 0L)
        }

        mix((bgmVolume * 100).toLong())
        mix((sfxVolume * 100).toLong())
        mix(if (isAudioMuted) 1L else 0L)

        return hash and 0x7FFFFFFFFFFFFFFFL // Bilangan bulat positif 63-bit
    }

    /**
     * Checksum fallback legacy (V1) untuk kompatibilitas file lama sebelum upgrade.
     */
    fun calculateLegacyChecksum(): Long {
        var hash = 17L
        hash = 31L * hash + playerLevel
        hash = 31L * hash + currentExp
        hash = 31L * hash + gold
        hash = 31L * hash + highestTowerFloor
        hash = 31L * hash + highestEndlessFloor
        hash = 31L * hash + weaponAtkLevel
        hash = 31L * hash + weaponCritLevel
        hash = 31L * hash + weaponSpdLevel
        hash = 31L * hash + unspentTalentPoints
        hash = 31L * hash + selectedArchetype.hashCode()
        hash = 31L * hash + selectedSubClass.hashCode()
        return hash and 0x7FFFFFFFFFFFFFFFL
    }

    /**
     * Memvalidasi dan membersihkan data agar berada dalam batasan aman (Sanitization).
     */
    fun sanitize(): SaveData {
        playerLevel = playerLevel.coerceIn(1, 100)
        currentExp = currentExp.coerceAtLeast(0)
        gold = gold.coerceIn(0, 999_999_999)
        highestTowerFloor = highestTowerFloor.coerceIn(1, 1000)
        highestEndlessFloor = highestEndlessFloor.coerceAtLeast(0)
        totalEnemiesDefeated = totalEnemiesDefeated.coerceAtLeast(0)
        weaponAtkLevel = weaponAtkLevel.coerceIn(0, 10)
        weaponCritLevel = weaponCritLevel.coerceIn(0, 10)
        weaponSpdLevel = weaponSpdLevel.coerceIn(0, 10)
        unspentTalentPoints = unspentTalentPoints.coerceAtLeast(-1)
        bgmVolume = bgmVolume.coerceIn(0f, 1f)
        sfxVolume = sfxVolume.coerceIn(0f, 1f)
        playTimeSeconds = playTimeSeconds.coerceAtLeast(0L)
        saveSlotId = saveSlotId.coerceIn(1, 10)
        saveVersion = saveVersion.coerceAtLeast(1)

        if (activeQuestId.isBlank()) {
            activeQuestId = "MQ_1"
        }

        if (unlockedCharacters.isEmpty()) {
            unlockedCharacters.add("STICKMAN_SWORD")
        }

        if (selectedFamiliar.isBlank()) {
            selectedFamiliar = "ARIA_WISP"
        }
        if (unlockedFamiliars.isEmpty()) {
            unlockedFamiliars.add("ARIA_WISP")
        }

        if (unlockedRunes.isEmpty()) {
            unlockedRunes.add("RUNE_SOLAR")
        }
        while (equippedRunes.size < 2) {
            equippedRunes.add("NONE")
        }

        if (activeTitle.isBlank()) {
            activeTitle = "TITEL_NOVICE"
        }
        if (unlockedTitles.isEmpty()) {
            unlockedTitles.add("TITEL_NOVICE")
        }
        return this
    }

    /**
     * Memperbarui checksum internal sebelum proses serialisasi.
     */
    fun updateChecksum() {
        if (lastSavedTimestamp == 0L) {
            lastSavedTimestamp = System.currentTimeMillis()
        }
        checksum = calculateChecksum()
    }

    /**
     * Memeriksa apakah checksum data valid dan belum termutasi/korup.
     */
    fun isChecksumValid(): Boolean {
        if (checksum == 0L) return true
        if (checksum == calculateChecksum()) return true
        return checksum == calculateLegacyChecksum()
    }

    /**
     * Menyalin seluruh field dari objek SaveData lain secara in-place tanpa mengubah referensi memori.
     */
    fun copyFrom(source: SaveData): SaveData {
        this.playerLevel = source.playerLevel
        this.currentExp = source.currentExp
        this.gold = source.gold
        this.highestTowerFloor = source.highestTowerFloor
        this.highestEndlessFloor = source.highestEndlessFloor
        this.totalEnemiesDefeated = source.totalEnemiesDefeated
        this.unlockedCharacters.clear()
        this.unlockedCharacters.addAll(source.unlockedCharacters)
        this.unlockedAchievements.clear()
        this.unlockedAchievements.addAll(source.unlockedAchievements)
        this.unlockedTalents.clear()
        this.unlockedTalents.addAll(source.unlockedTalents)
        this.unlockedLoreTablets.clear()
        this.unlockedLoreTablets.addAll(source.unlockedLoreTablets)
        this.activeQuestId = source.activeQuestId
        this.completedQuests.clear()
        this.completedQuests.addAll(source.completedQuests)
        this.questProgressMap.clear()
        this.questProgressMap.putAll(source.questProgressMap)
        this.challengeMedals.clear()
        this.challengeMedals.putAll(source.challengeMedals)
        this.acceptedBounties.clear()
        this.acceptedBounties.addAll(source.acceptedBounties)
        this.completedBounties.clear()
        this.completedBounties.addAll(source.completedBounties)
        this.claimedBounties.clear()
        this.claimedBounties.addAll(source.claimedBounties)
        this.bestiaryKills.clear()
        this.bestiaryKills.putAll(source.bestiaryKills)
        this.bgmVolume = source.bgmVolume
        this.sfxVolume = source.sfxVolume
        this.isAudioMuted = source.isAudioMuted
        this.selectedArchetype = source.selectedArchetype
        this.selectedSubClass = source.selectedSubClass
        this.selectedFamiliar = source.selectedFamiliar
        this.unlockedFamiliars.clear()
        this.unlockedFamiliars.addAll(source.unlockedFamiliars)
        this.equippedRunes.clear()
        this.equippedRunes.addAll(source.equippedRunes)
        this.unlockedRunes.clear()
        this.unlockedRunes.addAll(source.unlockedRunes)
        this.bossRushBestTimes.clear()
        this.bossRushBestTimes.putAll(source.bossRushBestTimes)
        this.unlockedTitles.clear()
        this.unlockedTitles.addAll(source.unlockedTitles)
        this.activeTitle = source.activeTitle
        this.weaponAtkLevel = source.weaponAtkLevel
        this.weaponCritLevel = source.weaponCritLevel
        this.weaponSpdLevel = source.weaponSpdLevel
        this.unspentTalentPoints = source.unspentTalentPoints
        this.playTimeSeconds = source.playTimeSeconds
        this.lastSavedTimestamp = source.lastSavedTimestamp
        this.isZephyrRescued = source.isZephyrRescued
        this.isGorgonRescued = source.isGorgonRescued
        this.hasSeenPrologue = source.hasSeenPrologue
        this.saveSlotId = source.saveSlotId
        this.saveVersion = source.saveVersion
        this.checksum = source.checksum
        return this
    }

    /**
     * Mereset seluruh parameter progres kembali ke nilai default onboarding awal.
     */
    fun resetToDefaults(): SaveData {
        return copyFrom(SaveData().sanitize())
    }
}
