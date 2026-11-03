package com.stickman.tower.network

import com.stickman.tower.leaderboard.LeaderboardEntry
import com.stickman.tower.leaderboard.LeaderboardManager
import com.stickman.tower.rpg.InMemoryStorageAdapter
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Unit Test Suite untuk Network & Backend Architecture (10/10 Standard):
 * - Anti-Tamper Signature Verification
 * - Offline Outbox Queueing & Persistence
 * - Mock Cloud Sync & Idempotent Delivery
 * - Tampered Data Rejection
 */
class NetworkSyncTest {

    private lateinit var mockStorage: InMemoryStorageAdapter
    private lateinit var outbox: NetworkSyncOutbox
    private lateinit var cloudClient: MockCloudSyncClient

    @Before
    fun setUp() {
        mockStorage = InMemoryStorageAdapter()
        outbox = NetworkSyncOutbox(storageAdapter = mockStorage)
        cloudClient = MockCloudSyncClient(isOnline = true)
        cloudClient.clear()
    }

    @Test
    fun testLeaderboardSignatureIntegrity() {
        val entry = LeaderboardEntry(
            playerName = "Kaelen",
            characterArchetype = "BALANCED",
            floorReached = 50,
            score = 99999L,
            clearTimeSeconds = 1200L
        )

        // 1. Tanda tangan asli harus valid
        assertTrue("Signature asli harus sah", entry.isSignatureValid())

        // 2. Jika skor dimutasi tanpa memperbarui signature (cheating), validasi harus gagal
        val tamperedEntry = entry.copy(score = 9999999L)
        assertFalse("Data yang dimutasi harus terdeteksi dan tidak valid", tamperedEntry.isSignatureValid())
    }

    @Test
    fun testOfflineOutboxQueueing() {
        val entry1 = LeaderboardEntry(playerName = "Zephyr", floorReached = 20, score = 35000L)
        val entry2 = LeaderboardEntry(playerName = "Gorgon", floorReached = 30, score = 55000L)

        outbox.enqueue(entry1)
        outbox.enqueue(entry2)

        assertEquals("Outbox harus memiliki 2 entri pending", 2, outbox.pendingCount)

        // Verifikasi persistensi tersimpan di storage adapter
        assertTrue("Outbox storage file harus terbentuk", mockStorage.exists(NetworkSyncOutbox.OUTBOX_FILE_NAME))

        // Buat instance outbox baru untuk mensimulasikan restart game
        val restoredOutbox = NetworkSyncOutbox(storageAdapter = mockStorage)
        assertEquals("Entri pending harus tetap ada setelah restart", 2, restoredOutbox.pendingCount)
    }

    @Test
    fun testCloudSyncFlushSuccess() {
        val entry1 = LeaderboardEntry(playerName = "Kaelen", floorReached = 45, score = 80000L)
        val entry2 = LeaderboardEntry(playerName = "Zephyr", floorReached = 50, score = 95000L)

        outbox.enqueue(entry1)
        outbox.enqueue(entry2)

        // Saat online, lakukan flush
        cloudClient.isOnline = true
        val synced = outbox.flush(cloudClient)

        assertEquals("Kedua entri harus berhasil tersinkronisasi", 2, synced)
        assertEquals("Outbox harus kosong setelah flush sukses", 0, outbox.pendingCount)

        // Verifikasi di cloud backend
        val cloudRecords = cloudClient.fetchGlobalLeaderboard(isSpeedrun = false)
        assertEquals("Cloud harus memiliki 2 rekor", 2, cloudRecords.size)
        assertEquals("Rekor skor tertinggi (Zephyr) harus menempati ranking 1", "Zephyr", cloudRecords[0].playerName)
    }

    @Test
    fun testCloudSyncOfflineFailure() {
        val entry = LeaderboardEntry(playerName = "Gorgon", floorReached = 10, score = 15000L)
        outbox.enqueue(entry)

        // Simulasikan koneksi offline
        cloudClient.isOnline = false
        val synced = outbox.flush(cloudClient)

        assertEquals("Tidak ada entri yang terkirim saat offline", 0, synced)
        assertEquals("Entri harus tetap tersimpan aman di outbox", 1, outbox.pendingCount)
    }

    @Test
    fun testCloudSyncTamperRejection() {
        val legitEntry = LeaderboardEntry(playerName = "Kaelen", floorReached = 5, score = 5000L)
        val hackedEntry = legitEntry.copy(score = 8888888L) // Skor dinaikkan secara ilegal

        outbox.enqueue(hackedEntry)

        cloudClient.isOnline = true
        val synced = outbox.flush(cloudClient)

        assertEquals("Entri curang harus ditolak", 0, synced)
        assertEquals("Entri curang harus dibuang dari outbox", 0, outbox.pendingCount)

        val cloudRecords = cloudClient.fetchGlobalLeaderboard(isSpeedrun = false)
        assertTrue("Cloud tidak boleh menyimpan entri curang", cloudRecords.isEmpty())
    }

    @Test
    fun testLeaderboardManagerIntegration() {
        LeaderboardManager.outbox.storageAdapter = mockStorage
        LeaderboardManager.outbox.clear()

        val entry = LeaderboardEntry(playerName = "Hero", floorReached = 35, score = 60000L)
        LeaderboardManager.addEndlessRecord(entry)

        assertEquals("LeaderboardManager harus otomatis mengantrekan ke outbox", 1, LeaderboardManager.outbox.pendingCount)

        val synced = LeaderboardManager.syncWithCloud(cloudClient)
        assertEquals("LeaderboardManager harus berhasil menyinkronkan ke cloud", 1, synced)
        assertEquals("Outbox LeaderboardManager harus kosong setelah sync", 0, LeaderboardManager.outbox.pendingCount)
    }
}
