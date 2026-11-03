package com.stickman.tower.rpg

import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class SaveManagerTest {

    private val testStorage = InMemoryStorageAdapter()

    @BeforeTest
    fun setUp() {
        SaveManager.storageAdapter = testStorage
        SaveManager.currentSlotId = 1
        testStorage.clear()
    }

    @AfterTest
    fun tearDown() {
        testStorage.clear()
        SaveManager.currentSlotId = 1
        SaveManager.storageAdapter = LocalFileStorageAdapter()
    }

    @Test
    fun testSaveAndLoadIntegrity() {
        val initialData = SaveData(
            playerLevel = 15,
            currentExp = 350,
            gold = 4500,
            highestTowerFloor = 3,
            highestEndlessFloor = 8,
            totalEnemiesDefeated = 120,
            selectedArchetype = "HEAVY",
            selectedSubClass = "TITAN",
            unlockedCharacters = arrayListOf("STICKMAN_SWORD", "STICKMAN_SPEAR"),
            weaponAtkLevel = 4,
            weaponCritLevel = 2,
            weaponSpdLevel = 3
        )

        SaveManager.save(initialData)

        // Verifikasi berkas utama dan backup terbuat di storage
        assertTrue(testStorage.exists(SaveManager.SAVE_FILE_NAME))

        val loaded = SaveManager.load()
        assertEquals(15, loaded.playerLevel)
        assertEquals(350, loaded.currentExp)
        assertEquals(4500, loaded.gold)
        assertEquals(3, loaded.highestTowerFloor)
        assertEquals(8, loaded.highestEndlessFloor)
        assertEquals(120, loaded.totalEnemiesDefeated)
        assertEquals("HEAVY", loaded.selectedArchetype)
        assertEquals("TITAN", loaded.selectedSubClass)
        assertEquals(2, loaded.unlockedCharacters.size)
        assertTrue(loaded.unlockedCharacters.contains("STICKMAN_SPEAR"))
        assertEquals(4, loaded.weaponAtkLevel)
        assertEquals(2, loaded.weaponCritLevel)
        assertEquals(3, loaded.weaponSpdLevel)
        assertTrue(loaded.checksum > 0L)
        assertTrue(loaded.isChecksumValid())
    }

    @Test
    fun testChecksumDetectionAndSanitization() {
        val outOfBounds = SaveData(
            playerLevel = 9999, // Harus di-clamp ke 100
            currentExp = -50,   // Harus di-coerce ke 0
            gold = -500,        // Harus di-clamp ke 0
            highestTowerFloor = 0, // Harus di-clamp ke 1
            weaponAtkLevel = 99 // Harus di-clamp ke 10
        )

        outOfBounds.sanitize()
        assertEquals(100, outOfBounds.playerLevel)
        assertEquals(0, outOfBounds.currentExp)
        assertEquals(0, outOfBounds.gold)
        assertEquals(1, outOfBounds.highestTowerFloor)
        assertEquals(10, outOfBounds.weaponAtkLevel)

        outOfBounds.updateChecksum()
        assertTrue(outOfBounds.isChecksumValid())

        // Simulasi tampering / manipulasi memori
        outOfBounds.gold = 9999999
        assertFalse(outOfBounds.isChecksumValid(), "Checksum must detect untrusted modifications")
    }

    @Test
    fun testAtomicWriteAndRollingBackupRecovery() {
        // 1. Simpan data awal yang valid (Lv. 10)
        val validSave1 = SaveData(playerLevel = 10, gold = 1000, highestTowerFloor = 2)
        SaveManager.save(validSave1)

        // 2. Simpan revisi kedua (Lv. 12) -> save1 otomatis menjadi rolling backup (.bak)
        val validSave2 = SaveData(playerLevel = 12, gold = 1500, highestTowerFloor = 3)
        SaveManager.save(validSave2)

        assertTrue(testStorage.exists(SaveManager.BACKUP_FILE_NAME), "Rolling backup file must exist after secondary save")

        // 3. Simulasikan korupsi berkas utama (misal: ponsel mati mendadak saat menulis file utama)
        testStorage.writeString(SaveManager.SAVE_FILE_NAME, "{ corrupted json syntax error EOF...")

        // 4. Panggil load(): SaveManager harus mendeteksi error parsing dan otomatis pulih dari .bak
        val recovered = SaveManager.load()
        assertNotNull(recovered)
        assertTrue(recovered.playerLevel in listOf(10, 12))
        assertTrue(recovered.gold >= 1000)

        // Verifikasi file utama diperbaiki kembali dengan data yang pulih
        assertTrue(testStorage.readString(SaveManager.SAVE_FILE_NAME)!!.contains("\"playerLevel\""))
    }

    @Test
    fun testExportAndImportJson() {
        val original = SaveData(
            playerLevel = 25,
            gold = 99999,
            highestTowerFloor = 5,
            selectedArchetype = "AGILE"
        )
        SaveManager.save(original)

        val exportedJson = SaveManager.exportJson()
        assertTrue(exportedJson.contains("\"playerLevel\": 25"))
        assertTrue(exportedJson.contains("\"gold\": 99999"))

        // Hapus storage lokal
        testStorage.clear()

        // Impor kembali dari string JSON
        val importSuccess = SaveManager.importJson(exportedJson)
        assertTrue(importSuccess)

        val reloaded = SaveManager.load()
        assertEquals(25, reloaded.playerLevel)
        assertEquals(99999, reloaded.gold)
        assertEquals("AGILE", reloaded.selectedArchetype)
    }

    @Test
    fun testResetSaveClearsAllStorage() {
        val progress = SaveData(playerLevel = 50, gold = 500000)
        SaveManager.save(progress)

        // Lakukan reset save
        val defaultData = SaveManager.resetSave()
        assertEquals(1, defaultData.playerLevel)
        assertEquals(0, defaultData.gold)
        assertEquals(1, defaultData.highestTowerFloor)

        val loadedAfterReset = SaveManager.load()
        assertEquals(1, loadedAfterReset.playerLevel)
        assertEquals(0, loadedAfterReset.gold)
    }

    @Test
    fun testTalentPointsPersistenceAndRespec() {
        val talentManager = com.stickman.tower.talent.TalentManager()
        val saveData = SaveData(playerLevel = 10, unspentTalentPoints = 5)
        talentManager.loadFromSave(saveData)
        assertEquals(5, talentManager.talentPoints)

        // Belanjakan 1 poin untuk membuka talent Tier 1 Berserker
        val canUnlock = talentManager.unlockTalent("BS_BLOOD_RAGE")
        assertTrue(canUnlock)
        assertEquals(4, talentManager.talentPoints)
        assertTrue(talentManager.isTalentUnlocked("BS_BLOOD_RAGE"))

        // Sinkronisasi ke SaveData dan simpan secara atomik
        talentManager.syncToSave(saveData)
        assertEquals(4, saveData.unspentTalentPoints)
        SaveManager.save(saveData)

        // Muat kembali dari storage
        val reloadedSave = SaveManager.load()
        assertEquals(4, reloadedSave.unspentTalentPoints)
        assertTrue(reloadedSave.isChecksumValid())

        val newTalentManager = com.stickman.tower.talent.TalentManager()
        newTalentManager.loadFromSave(reloadedSave)
        assertEquals(4, newTalentManager.talentPoints)
        assertTrue(newTalentManager.isTalentUnlocked("BS_BLOOD_RAGE"))

        // Lakukan Respec dan verifikasi pengembalian poin
        newTalentManager.respec()
        assertEquals(5, newTalentManager.talentPoints)
        assertFalse(newTalentManager.isTalentUnlocked("BS_BLOOD_RAGE"))
    }

    @Test
    fun testSaveMigratorV1ToV2() {
        // Data format V1 lama (achievements dan talents digabung dalam unlockedCharacters)
        val legacyV1 = SaveData(
            playerLevel = 8,
            gold = 2500,
            saveVersion = 1,
            unlockedCharacters = arrayListOf("STICKMAN_SWORD", "ACHV_FIRST_BLOOD", "TALENT_BS_BLOOD_RAGE")
        )

        val migrated = SaveMigrator.migrate(legacyV1)
        assertTrue(migrated, "Migrator should return true when upgrade is applied")
        assertEquals(2, legacyV1.saveVersion, "SaveVersion should be upgraded to 2")
        assertTrue(legacyV1.unlockedAchievements.contains("FIRST_BLOOD"), "Achievements must be migrated to dedicated list")
        assertTrue(legacyV1.unlockedTalents.contains("BS_BLOOD_RAGE"), "Talents must be migrated to dedicated list")
        assertTrue(legacyV1.lastSavedTimestamp > 0L, "Timestamp should be generated")
        assertTrue(legacyV1.isChecksumValid(), "Checksum must be valid after migration")
    }

    @Test
    fun testMultiSlotStorageAndListing() {
        val slot1Data = SaveData(saveSlotId = 1, playerLevel = 10, gold = 1000, highestTowerFloor = 2)
        val slot2Data = SaveData(saveSlotId = 2, playerLevel = 25, gold = 50000, highestTowerFloor = 6)
        val slot3Data = SaveData(saveSlotId = 3, playerLevel = 45, gold = 200000, highestTowerFloor = 9)

        SaveManager.saveSlot(1, slot1Data)
        SaveManager.saveSlot(2, slot2Data)
        SaveManager.saveSlot(3, slot3Data)

        val slots = SaveManager.listSlots(3)
        assertEquals(3, slots.size)

        assertEquals(10, slots[0].playerLevel)
        assertFalse(slots[0].isEmpty)

        assertEquals(25, slots[1].playerLevel)
        assertEquals(50000, slots[1].gold)
        assertFalse(slots[1].isEmpty)

        assertEquals(45, slots[2].playerLevel)
        assertEquals(9, slots[2].highestTowerFloor)
        assertFalse(slots[2].isEmpty)

        // Delete slot 2 and verify isolation
        SaveManager.deleteSlot(2)
        val afterDelete = SaveManager.listSlots(3)
        assertEquals(10, afterDelete[0].playerLevel)
        assertTrue(afterDelete[1].isEmpty, "Slot 2 should now be empty")
        assertEquals(45, afterDelete[2].playerLevel, "Slot 3 must remain intact")
    }

    @Test
    fun testSignedTransportPayloadExportAndImport() {
        val original = SaveData(
            playerLevel = 30,
            gold = 88888,
            highestTowerFloor = 8,
            selectedArchetype = "MAGIC",
            unlockedAchievements = arrayListOf("FIRST_BLOOD", "MATRON_SLAYER"),
            unlockedLoreTablets = arrayListOf("TABLET_1", "TABLET_4")
        )

        val payload = SaveManager.exportPayload(original)
        assertTrue(payload.startsWith(SaveManager.TRANSPORT_PREFIX), "Payload must start with STK2. prefix")

        // Import to Slot 2
        val importSuccess = SaveManager.importPayload(payload, targetSlotId = 2)
        assertTrue(importSuccess, "Valid signed payload must import successfully")

        val loaded = SaveManager.loadSlot(2)
        assertEquals(30, loaded.playerLevel)
        assertEquals(88888, loaded.gold)
        assertEquals("MAGIC", loaded.selectedArchetype)
        assertTrue(loaded.unlockedAchievements.contains("MATRON_SLAYER"))
        assertTrue(loaded.unlockedLoreTablets.contains("TABLET_4"))
        assertTrue(loaded.isChecksumValid())

        // Test tampering protection: corrupt the signature
        val corruptedPayload = payload.substring(0, payload.length - 4) + "dead"
        val failedImport = SaveManager.importPayload(corruptedPayload, targetSlotId = 3)
        assertFalse(failedImport, "Corrupted payload signature must fail import")
    }

    @Test
    fun testCloudConflictResolution3WayMerge() {
        val local = SaveData(
            playerLevel = 14,
            gold = 3000,
            highestTowerFloor = 4,
            unlockedAchievements = arrayListOf("FIRST_BLOOD"),
            unlockedLoreTablets = arrayListOf("TABLET_1"),
            lastSavedTimestamp = 1000L
        )

        val remote = SaveData(
            playerLevel = 12,
            gold = 4500, // Remote has more gold
            highestTowerFloor = 5, // Remote is on a higher floor
            unlockedAchievements = arrayListOf("TOWER_GUARDIAN_DOWN"),
            unlockedLoreTablets = arrayListOf("TABLET_2"),
            lastSavedTimestamp = 2000L
        )

        val resolved = SaveManager.resolveConflict(local, remote)
        assertEquals(14, resolved.playerLevel, "Should retain higher level")
        assertEquals(4500, resolved.gold, "Should retain higher gold")
        assertEquals(5, resolved.highestTowerFloor, "Should retain higher tower floor")
        assertTrue(resolved.unlockedAchievements.contains("FIRST_BLOOD"))
        assertTrue(resolved.unlockedAchievements.contains("TOWER_GUARDIAN_DOWN"))
        assertTrue(resolved.unlockedLoreTablets.contains("TABLET_1"))
        assertTrue(resolved.unlockedLoreTablets.contains("TABLET_2"))
        assertTrue(resolved.isChecksumValid())
    }

    @Test
    fun testAsyncSaveNonBlocking() {
        val data = SaveData(playerLevel = 22, gold = 12000, highestTowerFloor = 4)
        val latch = CountDownLatch(1)
        var callbackSuccess = false

        SaveManager.saveAsync(data) { success ->
            callbackSuccess = success
            latch.countDown()
        }

        val completed = latch.await(3, TimeUnit.SECONDS)
        assertTrue(completed, "Async save must complete within timeout")
        assertTrue(callbackSuccess, "Async save callback should report success")

        val loaded = SaveManager.load()
        assertEquals(22, loaded.playerLevel)
        assertEquals(12000, loaded.gold)
    }
}
