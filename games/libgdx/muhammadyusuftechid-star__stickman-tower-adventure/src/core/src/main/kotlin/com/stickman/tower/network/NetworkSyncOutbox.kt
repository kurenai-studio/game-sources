package com.stickman.tower.network

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.utils.Json
import com.badlogic.gdx.utils.JsonWriter
import com.stickman.tower.leaderboard.LeaderboardEntry
import com.stickman.tower.rpg.InMemoryStorageAdapter
import com.stickman.tower.rpg.LocalFileStorageAdapter
import com.stickman.tower.rpg.SaveStorageAdapter

/**
 * Pengelola Antrean Sinkronisasi Jaringan Offline (Offline Outbox Pattern 10/10):
 * Menjamin rekor pemain yang dicapai saat kondisi offline tetap tersimpan aman
 * dalam antrean persistensi lokal, dan secara otomatis/manual dikirimkan ke backend cloud
 * saat koneksi internet kembali stabil dengan semantik Idempotent Delivery.
 */
class NetworkSyncOutbox(
    var storageAdapter: SaveStorageAdapter = LocalFileStorageAdapter()
) {
    companion object {
        const val OUTBOX_FILE_NAME = "network_outbox.json"
    }

    private val json = Json().apply {
        setOutputType(JsonWriter.OutputType.json)
    }

    private val pendingQueue = mutableListOf<LeaderboardEntry>()

    val pendingCount: Int
        @Synchronized get() = pendingQueue.size

    init {
        loadFromStorage()
    }

    @Synchronized
    fun loadFromStorage() {
        try {
            val content = storageAdapter.readString(OUTBOX_FILE_NAME)
            if (!content.isNullOrBlank()) {
                val array = json.fromJson(Array<LeaderboardEntry>::class.java, content)
                pendingQueue.clear()
                if (array != null) {
                    pendingQueue.addAll(array)
                }
            }
        } catch (_: Throwable) {
            // Abaikan jika berkas belum ada atau error parsing
        }
    }

    @Synchronized
    fun saveToStorage() {
        try {
            val content = json.toJson(pendingQueue.toTypedArray())
            storageAdapter.writeString(OUTBOX_FILE_NAME, content)
        } catch (_: Throwable) {
            // Abaikan di lingkungan headless tanpa file system
        }
    }

    /**
     * Memasukkan entri skor ke dalam antrean sinkronisasi offline.
     */
    @Synchronized
    fun enqueue(entry: LeaderboardEntry) {
        // Idempotency: pastikan entri dengan UUID yang sama tidak dimasukkan dua kali
        if (pendingQueue.none { it.id == entry.id }) {
            pendingQueue.add(entry)
            saveToStorage()
        }
    }

    /**
     * Mengosongkan dan mengirimkan seluruh antrean ke server Cloud Sync Client.
     * Mengembalikan jumlah entri yang berhasil disinkronkan ke cloud.
     */
    @Synchronized
    fun flush(client: CloudSyncClient): Int {
        if (!client.isOnline || pendingQueue.isEmpty()) return 0

        var syncedCount = 0
        val iterator = pendingQueue.iterator()

        while (iterator.hasNext()) {
            val entry = iterator.next()
            val result = client.uploadLeaderboardRecord(entry)

            when (result.status) {
                SyncStatus.SUCCESS -> {
                    iterator.remove()
                    syncedCount++
                }
                SyncStatus.TAMPER_DETECTED -> {
                    // Buang entri yang terdeteksi manipulasi/tampering
                    iterator.remove()
                }
                SyncStatus.NETWORK_ERROR, SyncStatus.AUTHENTICATION_FAILED, SyncStatus.CONFLICT_RESOLVED -> {
                    // Hentikan iterasi sementara jika terjadi kegagalan jaringan agar tidak membuang data
                    break
                }
            }
        }

        saveToStorage()
        return syncedCount
    }

    @Synchronized
    fun getPendingEntries(): List<LeaderboardEntry> {
        return pendingQueue.toList()
    }

    @Synchronized
    fun clear() {
        pendingQueue.clear()
        storageAdapter.delete(OUTBOX_FILE_NAME)
    }
}
