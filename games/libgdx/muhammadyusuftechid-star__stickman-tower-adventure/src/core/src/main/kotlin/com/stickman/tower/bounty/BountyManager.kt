package com.stickman.tower.bounty

import com.stickman.tower.rpg.SaveData

/**
 * Manajer pengelola Papan Buronan Elit (The Spire Bounty Board).
 * Mengatur penerimaan kontrak, penjejakan mutasi monster per lantai, dan klaim imbalan.
 */
object BountyManager {

    private val acceptedBounties = mutableSetOf<String>()
    private val slainBounties = mutableSetOf<String>()
    private val claimedBounties = mutableSetOf<String>()

    /**
     * Memuat status buronan dari SaveData pemain.
     */
    fun loadFromSaveData(saveData: SaveData) {
        acceptedBounties.clear()
        slainBounties.clear()
        claimedBounties.clear()

        acceptedBounties.addAll(saveData.acceptedBounties)
        slainBounties.addAll(saveData.completedBounties)
        claimedBounties.addAll(saveData.claimedBounties)
    }

    /**
     * Menyinkronkan status buronan ke SaveData pemain.
     */
    fun syncToSaveData(saveData: SaveData) {
        saveData.acceptedBounties.clear()
        saveData.acceptedBounties.addAll(acceptedBounties)

        saveData.completedBounties.clear()
        saveData.completedBounties.addAll(slainBounties)

        saveData.claimedBounties.clear()
        saveData.claimedBounties.addAll(claimedBounties)
    }

    /**
     * Mengambil status terkini dari sebuah kontrak buronan.
     */
    fun getStatus(bountyId: String): BountyStatus {
        return when {
            claimedBounties.contains(bountyId) -> BountyStatus.CLAIMED
            slainBounties.contains(bountyId) -> BountyStatus.SLAIN
            acceptedBounties.contains(bountyId) -> BountyStatus.ACCEPTED
            else -> BountyStatus.AVAILABLE
        }
    }

    /**
     * Menerima kontrak perburuan monster elit.
     */
    fun acceptContract(bountyId: String): Boolean {
        val contract = BountyRegistry.getById(bountyId) ?: return false
        val status = getStatus(bountyId)
        if (status != BountyStatus.AVAILABLE) return false

        acceptedBounties.add(contract.id)
        return true
    }

    /**
     * Mencatat penumbangan monster elit pada lantai tertentu.
     * Mengembalikan kontrak buronan yang berhasil diselesaikan jika ada.
     */
    fun onFloorCleared(floor: Int): BountyContract? {
        val contract = BountyRegistry.getForFloor(floor) ?: return null
        if (getStatus(contract.id) == BountyStatus.ACCEPTED) {
            acceptedBounties.remove(contract.id)
            slainBounties.add(contract.id)
            return contract
        }
        return null
    }

    /**
     * Mencatat penyelesaian spesifik perburuan langsung berdasarkan ID kontrak.
     */
    fun recordSlain(bountyId: String): Boolean {
        val contract = BountyRegistry.getById(bountyId) ?: return false
        if (getStatus(contract.id) == BountyStatus.ACCEPTED) {
            acceptedBounties.remove(contract.id)
            slainBounties.add(contract.id)
            return true
        }
        return false
    }

    /**
     * Mengambil daftar afiks mutasi monster yang aktif pada lantai tertentu jika kontrak sedang diburu.
     */
    fun getActiveAffixesForFloor(floor: Int): List<BountyAffix> {
        val contract = BountyRegistry.getForFloor(floor) ?: return emptyList()
        return if (getStatus(contract.id) == BountyStatus.ACCEPTED) {
            contract.affixes
        } else {
            emptyList()
        }
    }

    /**
     * Mengklaim hadiah atas keberhasilan menumbangkan monster buronan elit.
     */
    fun claimReward(
        bountyId: String,
        saveData: SaveData,
        onSuccess: ((gold: Int, exp: Int, bonusDesc: String) -> Unit)? = null
    ): Boolean {
        val contract = BountyRegistry.getById(bountyId) ?: return false
        if (getStatus(bountyId) != BountyStatus.SLAIN) return false

        saveData.gold += contract.rewardGold
        saveData.currentExp += contract.rewardExp

        slainBounties.remove(bountyId)
        claimedBounties.add(bountyId)
        syncToSaveData(saveData)

        onSuccess?.invoke(contract.rewardGold, contract.rewardExp, contract.bonusRewardDesc)
        return true
    }

    /**
     * Mereset seluruh status untuk keperluan automated unit testing.
     */
    fun resetForTest() {
        acceptedBounties.clear()
        slainBounties.clear()
        claimedBounties.clear()
    }
}
