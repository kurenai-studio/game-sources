package com.stickman.tower.leaderboard

import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class LeaderboardManagerTest {

    @BeforeTest
    fun setUp() {
        LeaderboardManager.resetToDefaults()
    }

    @Test
    fun testDefaultRecordsLoaded() {
        val endless = LeaderboardManager.getEndlessRecords()
        assertTrue(endless.isNotEmpty(), "Endless records should have default entries")
        assertEquals("Kaelen", endless.first().playerName)
        assertEquals(25, endless.first().floorReached)

        val speedrun = LeaderboardManager.getSpeedrunRecords()
        assertTrue(speedrun.isNotEmpty(), "Speedrun records should have default entries")
        assertEquals("Zephyr", speedrun.first().playerName)
        assertEquals(245L, speedrun.first().clearTimeSeconds)
    }

    @Test
    fun testAddEndlessRecordSortingAndTrimming() {
        LeaderboardManager.clearAllRecords()

        for (i in 1..15) {
            val entry = LeaderboardEntry(
                playerName = "Knight_$i",
                characterArchetype = "BALANCED",
                floorReached = i,
                score = i * 1000L,
                clearTimeSeconds = 300L
            )
            LeaderboardManager.addEndlessRecord(entry)
        }

        val records = LeaderboardManager.getEndlessRecords()
        assertEquals(10, records.size, "Top records must be capped at 10")
        assertEquals("Knight_15", records.first().playerName)
        assertEquals(15000L, records.first().score)
        assertEquals("Knight_6", records.last().playerName)
    }

    @Test
    fun testAddSpeedrunRecordFastestTimeSorting() {
        LeaderboardManager.clearAllRecords()

        LeaderboardManager.addSpeedrunRecord(
            LeaderboardEntry(playerName = "Slow", score = 10000L, clearTimeSeconds = 600L)
        )
        LeaderboardManager.addSpeedrunRecord(
            LeaderboardEntry(playerName = "Fast", score = 9000L, clearTimeSeconds = 180L)
        )
        LeaderboardManager.addSpeedrunRecord(
            LeaderboardEntry(playerName = "Mid", score = 15000L, clearTimeSeconds = 300L)
        )

        val records = LeaderboardManager.getSpeedrunRecords()
        assertEquals("Fast", records[0].playerName)
        assertEquals("Mid", records[1].playerName)
        assertEquals("Slow", records[2].playerName)
    }

    @Test
    fun testLeaderboardEntryTimeFormatting() {
        val entry1 = LeaderboardEntry(clearTimeSeconds = 45L)
        assertEquals("00:45", entry1.getFormattedTime())

        val entry2 = LeaderboardEntry(clearTimeSeconds = 125L)
        assertEquals("02:05", entry2.getFormattedTime())

        val entry3 = LeaderboardEntry(clearTimeSeconds = 3665L)
        assertEquals("01:01:05", entry3.getFormattedTime())
    }
}
