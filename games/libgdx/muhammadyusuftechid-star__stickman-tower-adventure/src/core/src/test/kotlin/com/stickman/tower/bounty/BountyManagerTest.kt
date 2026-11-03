package com.stickman.tower.bounty

import com.stickman.tower.rpg.SaveData
import com.stickman.tower.rpg.SaveManager
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class BountyManagerTest {

    @BeforeTest
    fun setUp() {
        BountyManager.resetForTest()
    }

    @Test
    fun testBountyRegistryIntegrity() {
        val all = BountyRegistry.getAll()
        assertEquals(3, all.size, "Must have 3 canonical Bounty Contracts")

        val berserker = BountyRegistry.getById("BOUNTY_BERSERKER")
        assertNotNull(berserker)
        assertEquals(2, berserker.targetFloor)
        assertTrue(berserker.affixes.contains(BountyAffix.THORNS))

        val voidWeaver = BountyRegistry.getForFloor(4)
        assertNotNull(voidWeaver)
        assertEquals("BOUNTY_VOID_WEAVER", voidWeaver.id)
        assertTrue(voidWeaver.affixes.contains(BountyAffix.VAMPIRIC))

        val dreadnought = BountyRegistry.getForFloor(7)
        assertNotNull(dreadnought)
        assertEquals("BOUNTY_DREADNOUGHT", dreadnought.id)
        assertTrue(dreadnought.affixes.contains(BountyAffix.HASTE))
    }

    @Test
    fun testContractLifecycle() {
        val bountyId = "BOUNTY_BERSERKER"
        val saveData = SaveData(gold = 50, currentExp = 100)

        // 1. Status Awal: AVAILABLE
        assertEquals(BountyStatus.AVAILABLE, BountyManager.getStatus(bountyId))
        assertFalse(BountyManager.recordSlain(bountyId), "Target tidak bisa ditumbangkan sebelum kontrak diterima")

        // 2. Terima Kontrak: ACCEPTED
        assertTrue(BountyManager.acceptContract(bountyId))
        assertEquals(BountyStatus.ACCEPTED, BountyManager.getStatus(bountyId))
        assertFalse(BountyManager.acceptContract(bountyId), "Kontrak yang sedang berjalan tidak bisa diterima ulang")

        // 3. Afiks aktif saat diburu di lantai target
        val activeAffixes = BountyManager.getActiveAffixesForFloor(2)
        assertEquals(1, activeAffixes.size)
        assertEquals(BountyAffix.THORNS, activeAffixes[0])

        // 4. Tumbangkan Target: SLAIN
        val cleared = BountyManager.onFloorCleared(2)
        assertNotNull(cleared)
        assertEquals(bountyId, cleared.id)
        assertEquals(BountyStatus.SLAIN, BountyManager.getStatus(bountyId))

        // Afiks tidak lagi aktif setelah target tertumbangkan
        assertTrue(BountyManager.getActiveAffixesForFloor(2).isEmpty())

        // 5. Klaim Hadiah: CLAIMED
        var claimedGold = 0
        var claimedExp = 0
        val success = BountyManager.claimReward(bountyId, saveData) { gold, exp, _ ->
            claimedGold = gold
            claimedExp = exp
        }

        assertTrue(success)
        assertEquals(300, claimedGold)
        assertEquals(500, claimedExp)
        assertEquals(350, saveData.gold)
        assertEquals(600, saveData.currentExp)
        assertEquals(BountyStatus.CLAIMED, BountyManager.getStatus(bountyId))

        // Tidak bisa diklaim dua kali
        assertFalse(BountyManager.claimReward(bountyId, saveData))
    }

    @Test
    fun testSaveDataSyncAndConflictResolution() {
        val local = SaveData(saveSlotId = 1, lastSavedTimestamp = 1000L)
        val remote = SaveData(saveSlotId = 1, lastSavedTimestamp = 2000L)

        // Local menerima BOUNTY_BERSERKER
        BountyManager.acceptContract("BOUNTY_BERSERKER")
        BountyManager.syncToSaveData(local)

        // Remote telah menumbangkan BOUNTY_VOID_WEAVER
        BountyManager.resetForTest()
        BountyManager.acceptContract("BOUNTY_VOID_WEAVER")
        BountyManager.recordSlain("BOUNTY_VOID_WEAVER")
        BountyManager.syncToSaveData(remote)

        // Resolusi konflik 3-way merge
        val merged = SaveManager.resolveConflict(local, remote)

        assertTrue(merged.acceptedBounties.contains("BOUNTY_BERSERKER"), "Merged save harus mempertahankan accepted bounty lokal")
        assertTrue(merged.completedBounties.contains("BOUNTY_VOID_WEAVER"), "Merged save harus mempertahankan slain bounty remote")
        assertTrue(merged.isChecksumValid(), "Checksum hasil merge harus valid")
    }
}
