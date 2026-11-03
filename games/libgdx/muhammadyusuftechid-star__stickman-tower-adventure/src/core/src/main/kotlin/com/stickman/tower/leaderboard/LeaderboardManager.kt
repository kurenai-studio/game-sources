package com.stickman.tower.leaderboard

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.Preferences
import com.badlogic.gdx.utils.Json
import com.badlogic.gdx.utils.JsonWriter
import com.stickman.tower.network.CloudSyncClient
import com.stickman.tower.network.NetworkSyncOutbox

/**
 * Pengelola Papan Peringkat Rekor Menara (Leaderboard Manager 10/10):
 * Menyimpan rekor lokal untuk Endless Ascent dan Campaign Speedrun,
 * mendukung serialisasi JSON, penyortiran otomatis, batasan Top 10,
 * serta integrasi Offline Outbox Sync Queue untuk sinkronisasi ke cloud.
 */
object LeaderboardManager {

    private const val PREFS_NAME = "stickman_tower_leaderboard"
    private const val KEY_ENDLESS = "records_endless"
    private const val KEY_SPEEDRUN = "records_speedrun"
    private const val MAX_RECORDS = 10

    // Antrean sinkronisasi jaringan offline
    val outbox = NetworkSyncOutbox()

    private val json = Json().apply {
        setOutputType(JsonWriter.OutputType.json)
    }

    private val endlessRecords = mutableListOf<LeaderboardEntry>()
    private val speedrunRecords = mutableListOf<LeaderboardEntry>()

    init {
        loadRecords()
    }

    /**
     * Memuat rekor dari penyimpanan lokal LibGDX Preferences.
     */
    fun loadRecords() {
        try {
            val prefs = getPreferences()
            if (prefs != null) {
                val endlessJson = prefs.getString(KEY_ENDLESS, "")
                if (endlessJson.isNotEmpty()) {
                    val loaded = json.fromJson(Array<LeaderboardEntry>::class.java, endlessJson)
                    endlessRecords.clear()
                    if (loaded != null) {
                        endlessRecords.addAll(loaded)
                    }
                }

                val speedrunJson = prefs.getString(KEY_SPEEDRUN, "")
                if (speedrunJson.isNotEmpty()) {
                    val loaded = json.fromJson(Array<LeaderboardEntry>::class.java, speedrunJson)
                    speedrunRecords.clear()
                    if (loaded != null) {
                        speedrunRecords.addAll(loaded)
                    }
                }
            }
        } catch (e: Exception) {
            // Fallback gracefully jika headless test runner tanpa Gdx.app
        }

        if (endlessRecords.isEmpty()) {
            populateDefaultEndlessRecords()
        }
        if (speedrunRecords.isEmpty()) {
            populateDefaultSpeedrunRecords()
        }
    }

    /**
     * Menyimpan rekor ke Preferences lokal.
     */
    fun saveRecords() {
        try {
            val prefs = getPreferences() ?: return
            prefs.putString(KEY_ENDLESS, json.toJson(endlessRecords.toTypedArray()))
            prefs.putString(KEY_SPEEDRUN, json.toJson(speedrunRecords.toTypedArray()))
            prefs.flush()
        } catch (e: Exception) {
            // Abaikan di lingkungan headless test
        }
    }

    /**
     * Menambahkan rekor Endless Ascent baru dan mengurutkan secara otomatis (Top 10).
     */
    fun addEndlessRecord(entry: LeaderboardEntry): Boolean {
        // Enqueue ke Outbox untuk sinkronisasi cloud offline-first
        outbox.enqueue(entry)

        endlessRecords.add(entry)
        endlessRecords.sortWith(compareByDescending<LeaderboardEntry> { it.score }
            .thenByDescending { it.floorReached }
            .thenBy { it.clearTimeSeconds })
        if (endlessRecords.size > MAX_RECORDS) {
            endlessRecords.subList(MAX_RECORDS, endlessRecords.size).clear()
        }
        val isTopTen = endlessRecords.contains(entry)
        saveRecords()
        return isTopTen
    }

    /**
     * Menambahkan rekor Speedrun kampanye baru dan mengurutkan secara otomatis (Waktu tercepat).
     */
    fun addSpeedrunRecord(entry: LeaderboardEntry): Boolean {
        // Enqueue ke Outbox untuk sinkronisasi cloud offline-first
        outbox.enqueue(entry)

        speedrunRecords.add(entry)
        speedrunRecords.sortWith(compareBy<LeaderboardEntry> { it.clearTimeSeconds }
            .thenByDescending { it.score })
        if (speedrunRecords.size > MAX_RECORDS) {
            speedrunRecords.subList(MAX_RECORDS, speedrunRecords.size).clear()
        }
        val isTopTen = speedrunRecords.contains(entry)
        saveRecords()
        return isTopTen
    }

    /**
     * Menyinkronkan seluruh antrean rekor offline ke server cloud backend.
     */
    fun syncWithCloud(client: CloudSyncClient): Int {
        return outbox.flush(client)
    }

    fun getEndlessRecords(): List<LeaderboardEntry> = endlessRecords.toList()

    fun getSpeedrunRecords(): List<LeaderboardEntry> = speedrunRecords.toList()

    fun clearAllRecords() {
        endlessRecords.clear()
        speedrunRecords.clear()
        saveRecords()
    }

    fun resetToDefaults() {
        endlessRecords.clear()
        speedrunRecords.clear()
        populateDefaultEndlessRecords()
        populateDefaultSpeedrunRecords()
        saveRecords()
    }

    private fun populateDefaultEndlessRecords() {
        endlessRecords.add(LeaderboardEntry(playerName = "Kaelen", characterArchetype = "BALANCED", floorReached = 25, score = 15800L, clearTimeSeconds = 840L))
        endlessRecords.add(LeaderboardEntry(playerName = "Zephyr", characterArchetype = "AGILE", floorReached = 22, score = 13400L, clearTimeSeconds = 720L))
        endlessRecords.add(LeaderboardEntry(playerName = "Gorgon", characterArchetype = "HEAVY", floorReached = 18, score = 11200L, clearTimeSeconds = 960L))
        endlessRecords.add(LeaderboardEntry(playerName = "Valerius", characterArchetype = "BALANCED", floorReached = 15, score = 9500L, clearTimeSeconds = 610L))
        endlessRecords.add(LeaderboardEntry(playerName = "Oakhaven", characterArchetype = "HEAVY", floorReached = 12, score = 7800L, clearTimeSeconds = 550L))
    }

    private fun populateDefaultSpeedrunRecords() {
        speedrunRecords.add(LeaderboardEntry(playerName = "Zephyr", characterArchetype = "AGILE", floorReached = 10, score = 25000L, clearTimeSeconds = 245L))
        speedrunRecords.add(LeaderboardEntry(playerName = "Kaelen", characterArchetype = "BALANCED", floorReached = 10, score = 22000L, clearTimeSeconds = 310L))
        speedrunRecords.add(LeaderboardEntry(playerName = "Gorgon", characterArchetype = "HEAVY", floorReached = 10, score = 19500L, clearTimeSeconds = 415L))
        speedrunRecords.add(LeaderboardEntry(playerName = "Aria", characterArchetype = "BALANCED", floorReached = 10, score = 18000L, clearTimeSeconds = 480L))
    }

    private fun getPreferences(): Preferences? {
        return try {
            Gdx.app?.getPreferences(PREFS_NAME)
        } catch (e: Exception) {
            null
        }
    }
}
