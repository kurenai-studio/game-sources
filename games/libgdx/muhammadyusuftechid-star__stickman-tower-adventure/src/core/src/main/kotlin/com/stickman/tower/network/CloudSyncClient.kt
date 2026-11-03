package com.stickman.tower.network

import com.stickman.tower.leaderboard.LeaderboardEntry

/**
 * Status hasil sinkronisasi jaringan cloud.
 */
enum class SyncStatus {
    SUCCESS,
    NETWORK_ERROR,
    AUTHENTICATION_FAILED,
    TAMPER_DETECTED,
    CONFLICT_RESOLVED
}

data class CloudSyncResult(
    val status: SyncStatus,
    val message: String,
    val remoteRank: Int? = null
)

/**
 * Kontrak antarmuka layanan Cloud & Backend untuk Stickman Tower Adventure.
 * Menangani sinkronisasi papan peringkat global, penyimpanan cloud save,
 * dan verifikasi keabsahan data permainan (Anti-Tamper).
 */
interface CloudSyncClient {
    val isOnline: Boolean
    fun uploadLeaderboardRecord(entry: LeaderboardEntry): CloudSyncResult
    fun fetchGlobalLeaderboard(isSpeedrun: Boolean, limit: Int = 10): List<LeaderboardEntry>
    fun uploadCloudSave(signedTransportPayload: String): CloudSyncResult
    fun fetchCloudSave(slotId: Int): String?
}

/**
 * Mock Cloud Sync Client untuk simulasi jaringan, pengujian offline,
 * dan automated unit testing tanpa ketergantungan server live.
 */
class MockCloudSyncClient(
    override var isOnline: Boolean = true
) : CloudSyncClient {

    private val remoteEndlessRecords = mutableListOf<LeaderboardEntry>()
    private val remoteSpeedrunRecords = mutableListOf<LeaderboardEntry>()
    private val remoteCloudSaves = mutableMapOf<Int, String>()
    val uploadedPayloads = mutableListOf<String>()

    override fun uploadLeaderboardRecord(entry: LeaderboardEntry): CloudSyncResult {
        if (!isOnline) {
            return CloudSyncResult(SyncStatus.NETWORK_ERROR, "Koneksi jaringan terputus (Offline)")
        }

        // Verifikasi integritas tanda tangan anti-cheat
        if (!entry.isSignatureValid()) {
            return CloudSyncResult(SyncStatus.TAMPER_DETECTED, "Verifikasi integritas skor gagal: Tanda tangan tidak valid!")
        }

        val targetList = if (entry.score > 0) remoteEndlessRecords else remoteSpeedrunRecords
        // Idempotency check: hindari duplikasi record dengan ID yang sama
        if (targetList.any { it.id == entry.id }) {
            return CloudSyncResult(SyncStatus.SUCCESS, "Rekor sudah tercatat sebelumnya (Idempotent)")
        }

        targetList.add(entry)
        targetList.sort()
        val rank = targetList.indexOf(entry) + 1
        return CloudSyncResult(SyncStatus.SUCCESS, "Rekor berhasil diunggah ke leaderboard cloud", rank)
    }

    override fun fetchGlobalLeaderboard(isSpeedrun: Boolean, limit: Int): List<LeaderboardEntry> {
        if (!isOnline) return emptyList()
        val list = if (isSpeedrun) remoteSpeedrunRecords else remoteEndlessRecords
        return list.take(limit)
    }

    override fun uploadCloudSave(signedTransportPayload: String): CloudSyncResult {
        if (!isOnline) {
            return CloudSyncResult(SyncStatus.NETWORK_ERROR, "Koneksi jaringan terputus (Offline)")
        }
        uploadedPayloads.add(signedTransportPayload)
        remoteCloudSaves[1] = signedTransportPayload
        return CloudSyncResult(SyncStatus.SUCCESS, "Penyimpanan cloud berhasil diperbarui")
    }

    override fun fetchCloudSave(slotId: Int): String? {
        if (!isOnline) return null
        return remoteCloudSaves[slotId]
    }

    fun clear() {
        remoteEndlessRecords.clear()
        remoteSpeedrunRecords.clear()
        remoteCloudSaves.clear()
        uploadedPayloads.clear()
    }
}
