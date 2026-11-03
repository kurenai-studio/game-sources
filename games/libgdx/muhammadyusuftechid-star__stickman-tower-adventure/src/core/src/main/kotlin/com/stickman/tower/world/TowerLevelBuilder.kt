package com.stickman.tower.world

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.math.Rectangle
import com.stickman.tower.enemy.BossEnemy
import com.stickman.tower.enemy.BossType
import com.stickman.tower.enemy.Enemy
import com.stickman.tower.enemy.EnemyType
import com.stickman.tower.physics.Platform
import com.stickman.tower.endless.FloorMutator
import com.stickman.tower.narrative.DialogueRegistry

/**
 * Pembangun Level Menara Bertingkat (Tower Level Builder).
 * Mengimplementasikan 10 Lantai Kampanye Cerita Utama (The 10-Floor Story Odyssey)
 * yang terbagi dalam 4 Babak Epik (Act I - Act IV), 5 Pertarungan Bos Legendaris,
 * Prasasti Batu Hitam Kuno (The Lore Tablets), Tempat Perlindungan Vulcanus,
 * serta Generator Prosedural Dinamis untuk Mode Endless Spire (Lantai 11 ke atas).
 */
object TowerLevelBuilder {

    fun buildFloor(floorNumber: Int, mutator: FloorMutator? = null): TowerFloor {
        val floor = when (floorNumber) {
            1 -> buildFloor1()
            2 -> buildFloor2()
            3 -> buildFloor3()
            4 -> buildFloor4()
            5 -> buildFloor5()
            6 -> buildFloor6()
            7 -> buildFloor7()
            8 -> buildFloor8()
            9 -> buildFloor9()
            10 -> buildFloor10()
            11 -> buildFloor11()
            12 -> buildFloor12()
            13 -> buildFloor13()
            14 -> buildFloor14()
            15 -> buildFloor15()
            16 -> buildFloor16()
            17 -> buildFloor17()
            18 -> buildFloor18()
            19 -> buildFloor19()
            20 -> buildFloor20()
            21 -> buildFloor21()
            22 -> buildFloor22()
            23 -> buildFloor23()
            24 -> buildFloor24()
            25 -> buildFloor25()
            26 -> buildFloor26()
            27 -> buildFloor27()
            28 -> buildFloor28()
            29 -> buildFloor29()
            30 -> buildFloor30()
            31 -> buildFloor31()
            32 -> buildFloor32()
            33 -> buildFloor33()
            34 -> buildFloor34()
            35 -> buildFloor35()
            36 -> buildFloor36()
            37 -> buildFloor37()
            38 -> buildFloor38()
            39 -> buildFloor39()
            40 -> buildFloor40()
            41 -> buildFloor41()
            42 -> buildFloor42()
            43 -> buildFloor43()
            44 -> buildFloor44()
            45 -> buildFloor45()
            46 -> buildFloor46()
            47 -> buildFloor47()
            48 -> buildFloor48()
            49 -> buildFloor49()
            50 -> buildFloor50()
            else -> buildEndlessFloor(floorNumber, mutator ?: FloorMutator.getRandomMutator(floorNumber))
        }
        return floor.copy(environmentalProps = getEnvironmentalPropsForFloor(floorNumber))
    }

    fun getEnvironmentalPropsForFloor(floorNumber: Int): List<EnvironmentalProp> {
        return when (floorNumber) {
            1 -> listOf(
                EnvironmentalProp(x = 1.0f, y = 5.0f, width = 0.6f, height = 2.4f, type = PropType.BROKEN_CHAIN),
                EnvironmentalProp(x = 14.0f, y = 1.0f, width = 1.2f, height = 2.0f, type = PropType.BEHEADED_STATUE),
                EnvironmentalProp(x = 7.0f, y = 3.5f, width = 1.8f, height = 1.4f, type = PropType.INK_SPLATTER_MURAL)
            )
            2 -> listOf(
                EnvironmentalProp(x = 8.0f, y = 8.0f, width = 0.6f, height = 2.8f, type = PropType.BROKEN_CHAIN),
                EnvironmentalProp(x = 20.0f, y = 1.0f, width = 1.0f, height = 1.8f, type = PropType.BEHEADED_STATUE),
                EnvironmentalProp(x = 16.0f, y = 7.5f, width = 1.6f, height = 1.2f, type = PropType.INK_SPLATTER_MURAL)
            )
            3 -> listOf(
                EnvironmentalProp(x = 3.0f, y = 6.0f, width = 0.6f, height = 2.5f, type = PropType.BROKEN_CHAIN),
                EnvironmentalProp(x = 22.0f, y = 1.0f, width = 1.4f, height = 2.2f, type = PropType.BEHEADED_STATUE),
                EnvironmentalProp(x = 12.0f, y = 4.0f, width = 2.2f, height = 1.6f, type = PropType.INK_SPLATTER_MURAL)
            )
            4 -> listOf(
                EnvironmentalProp(x = 5.0f, y = 1.0f, width = 1.4f, height = 2.2f, type = PropType.SHATTERED_BOOKSHELF),
                EnvironmentalProp(x = 18.0f, y = 4.8f, width = 1.4f, height = 2.2f, type = PropType.SHATTERED_BOOKSHELF),
                EnvironmentalProp(x = 11.0f, y = 1.0f, width = 0.8f, height = 1.8f, type = PropType.LEAKING_ALCHEMY_VAT)
            )
            5 -> listOf(
                EnvironmentalProp(x = 12.0f, y = 1.0f, width = 1.4f, height = 2.4f, type = PropType.BEHEADED_STATUE),
                EnvironmentalProp(x = 42.0f, y = 1.0f, width = 1.2f, height = 2.0f, type = PropType.LEAKING_ALCHEMY_VAT),
                EnvironmentalProp(x = 72.0f, y = 1.0f, width = 1.4f, height = 2.4f, type = PropType.BEHEADED_STATUE)
            )
            6 -> listOf(
                EnvironmentalProp(x = 18.0f, y = 1.2f, width = 2.2f, height = 1.8f, type = PropType.TITAN_ANVIL),
                EnvironmentalProp(x = 35.0f, y = 3.5f, width = 1.6f, height = 2.2f, type = PropType.SHATTERED_BOOKSHELF),
                EnvironmentalProp(x = 55.0f, y = 1.0f, width = 1.2f, height = 2.0f, type = PropType.LEAKING_ALCHEMY_VAT)
            )
            7 -> listOf(
                EnvironmentalProp(x = 15.0f, y = 6.0f, width = 2.0f, height = 3.0f, type = PropType.VOID_WALL_CRACK),
                EnvironmentalProp(x = 56.0f, y = 8.0f, width = 2.4f, height = 3.5f, type = PropType.VOID_WALL_CRACK),
                EnvironmentalProp(x = 90.0f, y = 5.0f, width = 2.0f, height = 3.0f, type = PropType.VOID_WALL_CRACK)
            )
            8 -> listOf(
                EnvironmentalProp(x = 22.0f, y = 4.0f, width = 1.8f, height = 2.5f, type = PropType.VOID_WALL_CRACK),
                EnvironmentalProp(x = 68.0f, y = 8.5f, width = 1.6f, height = 2.2f, type = PropType.BLOOD_ECLIPSE_ALTAR),
                EnvironmentalProp(x = 105.0f, y = 5.0f, width = 1.8f, height = 2.5f, type = PropType.VOID_WALL_CRACK)
            )
            9 -> listOf(
                EnvironmentalProp(x = 20.0f, y = 5.0f, width = 1.8f, height = 2.5f, type = PropType.INK_SPLATTER_MURAL),
                EnvironmentalProp(x = 58.0f, y = 1.0f, width = 1.6f, height = 2.4f, type = PropType.LEAKING_ALCHEMY_VAT),
                EnvironmentalProp(x = 92.0f, y = 6.0f, width = 1.8f, height = 2.5f, type = PropType.VOID_WALL_CRACK)
            )
            10 -> listOf(
                EnvironmentalProp(x = 12.0f, y = 1.0f, width = 1.2f, height = 5.0f, type = PropType.PURE_CANVAS_PILLAR),
                EnvironmentalProp(x = 34.0f, y = 4.2f, width = 1.5f, height = 2.2f, type = PropType.FROZEN_GOLDEN_BRUSH),
                EnvironmentalProp(x = 65.0f, y = 1.0f, width = 1.2f, height = 5.0f, type = PropType.PURE_CANVAS_PILLAR)
            )
            11 -> listOf(
                EnvironmentalProp(x = 18.0f, y = 4.5f, width = 1.4f, height = 2.2f, type = PropType.SHATTERED_BOOKSHELF),
                EnvironmentalProp(x = 55.0f, y = 1.0f, width = 1.2f, height = 2.0f, type = PropType.LEAKING_ALCHEMY_VAT),
                EnvironmentalProp(x = 92.0f, y = 6.0f, width = 0.6f, height = 2.5f, type = PropType.BROKEN_CHAIN)
            )
            12 -> listOf(
                EnvironmentalProp(x = 24.0f, y = 5.5f, width = 0.6f, height = 2.8f, type = PropType.BROKEN_CHAIN),
                EnvironmentalProp(x = 68.0f, y = 1.0f, width = 1.8f, height = 1.6f, type = PropType.TITAN_ANVIL),
                EnvironmentalProp(x = 108.0f, y = 7.0f, width = 1.4f, height = 2.2f, type = PropType.SHATTERED_BOOKSHELF)
            )
            13 -> listOf(
                EnvironmentalProp(x = 18.0f, y = 1.2f, width = 2.4f, height = 2.0f, type = PropType.TITAN_ANVIL),
                EnvironmentalProp(x = 35.0f, y = 3.8f, width = 1.6f, height = 2.2f, type = PropType.SHATTERED_BOOKSHELF),
                EnvironmentalProp(x = 75.0f, y = 1.0f, width = 1.2f, height = 4.5f, type = PropType.PURE_CANVAS_PILLAR)
            )
            14 -> listOf(
                EnvironmentalProp(x = 22.0f, y = 1.0f, width = 1.4f, height = 2.2f, type = PropType.LEAKING_ALCHEMY_VAT),
                EnvironmentalProp(x = 62.0f, y = 5.5f, width = 0.6f, height = 2.5f, type = PropType.BROKEN_CHAIN),
                EnvironmentalProp(x = 110.0f, y = 1.0f, width = 1.4f, height = 2.2f, type = PropType.LEAKING_ALCHEMY_VAT)
            )
            15 -> listOf(
                EnvironmentalProp(x = 15.0f, y = 1.0f, width = 1.8f, height = 1.6f, type = PropType.TITAN_ANVIL),
                EnvironmentalProp(x = 45.0f, y = 1.0f, width = 1.4f, height = 2.4f, type = PropType.BEHEADED_STATUE),
                EnvironmentalProp(x = 78.0f, y = 1.0f, width = 1.4f, height = 2.2f, type = PropType.LEAKING_ALCHEMY_VAT)
            )
            16 -> listOf(
                EnvironmentalProp(x = 25.0f, y = 6.0f, width = 0.6f, height = 2.6f, type = PropType.BROKEN_CHAIN),
                EnvironmentalProp(x = 72.0f, y = 1.0f, width = 1.4f, height = 2.2f, type = PropType.LEAKING_ALCHEMY_VAT),
                EnvironmentalProp(x = 115.0f, y = 5.5f, width = 0.6f, height = 2.6f, type = PropType.BROKEN_CHAIN)
            )
            17 -> listOf(
                EnvironmentalProp(x = 16.0f, y = 3.5f, width = 1.6f, height = 2.2f, type = PropType.SHATTERED_BOOKSHELF),
                EnvironmentalProp(x = 64.0f, y = 1.0f, width = 1.4f, height = 2.4f, type = PropType.BEHEADED_STATUE),
                EnvironmentalProp(x = 120.0f, y = 4.0f, width = 1.6f, height = 2.2f, type = PropType.SHATTERED_BOOKSHELF)
            )
            18 -> listOf(
                EnvironmentalProp(x = 28.0f, y = 7.0f, width = 0.6f, height = 3.0f, type = PropType.BROKEN_CHAIN),
                EnvironmentalProp(x = 75.0f, y = 1.0f, width = 1.4f, height = 2.2f, type = PropType.LEAKING_ALCHEMY_VAT),
                EnvironmentalProp(x = 122.0f, y = 7.0f, width = 0.6f, height = 3.0f, type = PropType.BROKEN_CHAIN)
            )
            19 -> listOf(
                EnvironmentalProp(x = 22.0f, y = 1.0f, width = 1.4f, height = 2.4f, type = PropType.BEHEADED_STATUE),
                EnvironmentalProp(x = 70.0f, y = 6.5f, width = 0.6f, height = 2.8f, type = PropType.BROKEN_CHAIN),
                EnvironmentalProp(x = 125.0f, y = 1.0f, width = 1.4f, height = 2.4f, type = PropType.BEHEADED_STATUE)
            )
            20 -> listOf(
                EnvironmentalProp(x = 14.0f, y = 1.0f, width = 2.2f, height = 1.8f, type = PropType.TITAN_ANVIL),
                EnvironmentalProp(x = 52.0f, y = 1.0f, width = 1.4f, height = 5.0f, type = PropType.PURE_CANVAS_PILLAR),
                EnvironmentalProp(x = 88.0f, y = 5.5f, width = 0.6f, height = 3.0f, type = PropType.BROKEN_CHAIN)
            )
            21 -> listOf(
                EnvironmentalProp(x = 18.0f, y = 1.2f, width = 2.0f, height = 1.8f, type = PropType.TITAN_ANVIL),
                EnvironmentalProp(x = 64.0f, y = 1.0f, width = 1.4f, height = 2.4f, type = PropType.BEHEADED_STATUE),
                EnvironmentalProp(x = 112.0f, y = 6.0f, width = 0.6f, height = 2.8f, type = PropType.BROKEN_CHAIN)
            )
            22 -> listOf(
                EnvironmentalProp(x = 24.0f, y = 1.0f, width = 1.4f, height = 2.2f, type = PropType.LEAKING_ALCHEMY_VAT),
                EnvironmentalProp(x = 72.0f, y = 1.2f, width = 2.2f, height = 1.8f, type = PropType.TITAN_ANVIL),
                EnvironmentalProp(x = 120.0f, y = 5.5f, width = 0.6f, height = 2.8f, type = PropType.BROKEN_CHAIN)
            )
            23 -> listOf(
                EnvironmentalProp(x = 20.0f, y = 5.5f, width = 0.6f, height = 3.0f, type = PropType.BROKEN_CHAIN),
                EnvironmentalProp(x = 75.0f, y = 1.0f, width = 1.4f, height = 2.2f, type = PropType.LEAKING_ALCHEMY_VAT),
                EnvironmentalProp(x = 125.0f, y = 5.5f, width = 0.6f, height = 3.0f, type = PropType.BROKEN_CHAIN)
            )
            24 -> listOf(
                EnvironmentalProp(x = 25.0f, y = 1.0f, width = 1.4f, height = 2.4f, type = PropType.BEHEADED_STATUE),
                EnvironmentalProp(x = 70.0f, y = 1.2f, width = 2.2f, height = 1.8f, type = PropType.TITAN_ANVIL),
                EnvironmentalProp(x = 118.0f, y = 1.0f, width = 1.4f, height = 2.4f, type = PropType.BEHEADED_STATUE)
            )
            25 -> listOf(
                EnvironmentalProp(x = 16.0f, y = 1.2f, width = 2.2f, height = 1.8f, type = PropType.TITAN_ANVIL),
                EnvironmentalProp(x = 52.0f, y = 1.0f, width = 1.4f, height = 2.2f, type = PropType.LEAKING_ALCHEMY_VAT),
                EnvironmentalProp(x = 88.0f, y = 1.0f, width = 1.2f, height = 4.5f, type = PropType.PURE_CANVAS_PILLAR)
            )
            26 -> listOf(
                EnvironmentalProp(x = 22.0f, y = 6.0f, width = 2.2f, height = 3.2f, type = PropType.VOID_WALL_CRACK),
                EnvironmentalProp(x = 68.0f, y = 1.0f, width = 1.4f, height = 2.4f, type = PropType.BEHEADED_STATUE),
                EnvironmentalProp(x = 115.0f, y = 7.0f, width = 2.4f, height = 3.5f, type = PropType.VOID_WALL_CRACK)
            )
            27 -> listOf(
                EnvironmentalProp(x = 28.0f, y = 7.5f, width = 2.5f, height = 3.8f, type = PropType.VOID_WALL_CRACK),
                EnvironmentalProp(x = 74.0f, y = 1.0f, width = 1.2f, height = 5.0f, type = PropType.PURE_CANVAS_PILLAR),
                EnvironmentalProp(x = 120.0f, y = 8.0f, width = 2.5f, height = 3.8f, type = PropType.VOID_WALL_CRACK)
            )
            28 -> listOf(
                EnvironmentalProp(x = 25.0f, y = 7.0f, width = 2.4f, height = 3.5f, type = PropType.VOID_WALL_CRACK),
                EnvironmentalProp(x = 70.0f, y = 5.5f, width = 0.6f, height = 3.0f, type = PropType.BROKEN_CHAIN),
                EnvironmentalProp(x = 122.0f, y = 7.5f, width = 2.5f, height = 3.8f, type = PropType.VOID_WALL_CRACK)
            )
            29 -> listOf(
                EnvironmentalProp(x = 24.0f, y = 7.0f, width = 2.5f, height = 3.8f, type = PropType.VOID_WALL_CRACK),
                EnvironmentalProp(x = 72.0f, y = 1.0f, width = 1.2f, height = 5.0f, type = PropType.PURE_CANVAS_PILLAR),
                EnvironmentalProp(x = 126.0f, y = 7.0f, width = 2.5f, height = 3.8f, type = PropType.VOID_WALL_CRACK)
            )
            30 -> listOf(
                EnvironmentalProp(x = 15.0f, y = 1.0f, width = 1.4f, height = 5.0f, type = PropType.PURE_CANVAS_PILLAR),
                EnvironmentalProp(x = 55.0f, y = 4.5f, width = 1.6f, height = 2.4f, type = PropType.FROZEN_GOLDEN_BRUSH),
                EnvironmentalProp(x = 92.0f, y = 1.0f, width = 1.4f, height = 5.0f, type = PropType.PURE_CANVAS_PILLAR)
            )
            41, 42, 43, 44 -> listOf(
                EnvironmentalProp(x = 20.0f, y = 1.0f, width = 1.4f, height = 5.5f, type = PropType.PURE_CANVAS_PILLAR),
                EnvironmentalProp(x = 65.0f, y = 4.5f, width = 1.6f, height = 2.4f, type = PropType.FROZEN_GOLDEN_BRUSH),
                EnvironmentalProp(x = 110.0f, y = 1.0f, width = 1.4f, height = 5.5f, type = PropType.PURE_CANVAS_PILLAR)
            )
            45 -> listOf(
                EnvironmentalProp(x = 18.0f, y = 1.0f, width = 1.6f, height = 6.0f, type = PropType.PURE_CANVAS_PILLAR),
                EnvironmentalProp(x = 55.0f, y = 4.5f, width = 1.8f, height = 2.8f, type = PropType.FROZEN_GOLDEN_BRUSH),
                EnvironmentalProp(x = 95.0f, y = 1.0f, width = 1.6f, height = 6.0f, type = PropType.PURE_CANVAS_PILLAR)
            )
            46, 47, 48, 49 -> listOf(
                EnvironmentalProp(x = 25.0f, y = 1.0f, width = 1.5f, height = 5.5f, type = PropType.PURE_CANVAS_PILLAR),
                EnvironmentalProp(x = 75.0f, y = 4.0f, width = 1.6f, height = 2.5f, type = PropType.FROZEN_GOLDEN_BRUSH),
                EnvironmentalProp(x = 125.0f, y = 1.0f, width = 1.5f, height = 5.5f, type = PropType.PURE_CANVAS_PILLAR)
            )
            50 -> listOf(
                EnvironmentalProp(x = 15.0f, y = 1.0f, width = 2.0f, height = 7.0f, type = PropType.PURE_CANVAS_PILLAR),
                EnvironmentalProp(x = 55.0f, y = 5.0f, width = 2.4f, height = 3.5f, type = PropType.FROZEN_GOLDEN_BRUSH),
                EnvironmentalProp(x = 95.0f, y = 1.0f, width = 2.0f, height = 7.0f, type = PropType.PURE_CANVAS_PILLAR)
            )
            else -> listOf(
                EnvironmentalProp(x = 6.0f, y = 4.0f, width = 1.8f, height = 2.5f, type = PropType.VOID_WALL_CRACK)
            )
        }
    }

    // =========================================================================
    // BABAK I: UJIAN INISIASI (ACT I: THE INITIATION — LANTAI 1 S/D 3)
    // =========================================================================

    private fun buildFloor1(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val baseColor = Color(0.18f, 0.24f, 0.32f, 1f)
        val wallColor = Color(0.14f, 0.18f, 0.24f, 1f)
        val platColor = Color(0.24f, 0.35f, 0.48f, 1f)

        // Lantai Dasar Bentang Luas (115m) & Dinding Batas
        platforms.add(Platform(x = -10f, y = 0f, width = 125f, height = 1f, color = baseColor))
        platforms.add(Platform(x = -10f, y = 1f, width = 1f, height = 15f, color = wallColor))
        platforms.add(Platform(x = 114f, y = 1f, width = 1f, height = 15f, color = wallColor))

        // Koridor Platform Bertingkat & One-Way Stepping
        // Sektor Barat (0m - 35m)
        platforms.add(Platform(x = 4.0f, y = 2.4f, width = 5.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 12.0f, y = 4.0f, width = 4.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 19.5f, y = 5.6f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 19.5f, y = 2.5f, width = 5.0f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 28.0f, y = 3.8f, width = 5.5f, height = 0.5f, color = platColor))

        // Sektor Tengah (36m - 75m)
        platforms.add(Platform(x = 37.0f, y = 2.4f, width = 4.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 44.5f, y = 4.2f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 53.0f, y = 6.0f, width = 5.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 61.5f, y = 4.2f, width = 5.0f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 69.0f, y = 2.5f, width = 5.5f, height = 0.5f, color = platColor))

        // Sektor Timur (76m - 110m) Menuju Gerbang Menara
        platforms.add(Platform(x = 77.0f, y = 4.2f, width = 5.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 85.5f, y = 5.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 85.5f, y = 2.6f, width = 5.0f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 94.0f, y = 4.0f, width = 5.5f, height = 0.5f, color = platColor))

        val spikes = listOf(
            SpikeHazard(x = 14.0f, y = 1.0f, width = 3.0f, height = 0.5f),
            SpikeHazard(x = 43.0f, y = 1.0f, width = 3.5f, height = 0.5f),
            SpikeHazard(x = 79.0f, y = 1.0f, width = 3.5f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 22.0f, y = 6.1f),
            TreasureChest(x = 55.5f, y = 6.5f),
            TreasureChest(x = 88.0f, y = 6.3f)
        )

        val enemies = listOf(
            Enemy(spawnX = 7.0f, spawnY = 2.9f, type = EnemyType.MELEE),
            Enemy(spawnX = 22.0f, spawnY = 6.1f, type = EnemyType.RANGED),
            Enemy(spawnX = 32.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 47.0f, spawnY = 4.7f, type = EnemyType.RANGED),
            Enemy(spawnX = 56.0f, spawnY = 6.5f, type = EnemyType.MELEE),
            Enemy(spawnX = 72.0f, spawnY = 3.0f, type = EnemyType.FLYING),
            Enemy(spawnX = 88.0f, spawnY = 6.3f, type = EnemyType.RANGED),
            Enemy(spawnX = 96.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 21.0f,
                y = 5.6f,
                tabletId = "TABLET_1",
                title = "Tablet I: Catatan Hari ke-47",
                text = "Hari ke-47. Kami tiba di gerbang bawah dengan 100 prajurit terbaik. Tubuh kami telah menghitam, jari-jari menyatu menjadi garis padat. Makanan tak lagi berasa, namun pedang terasa seratus kali lebih ringan. Jika catatan ini kau temukan, ketahuilah: jangan pernah berhenti bergerak saat berada di atas platform."
            )
        )

        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(1))

        return TowerFloor(
            floorNumber = 1,
            floorName = "Lantai 1: Lower Bastion",
            mapBounds = Rectangle(-10f, -1f, 125f, 16f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 50.0f, y = 1.0f),
            exitPortal = StageExit(x = 104.0f, y = 1.0f),
            isBossFloor = false,
            actTitle = "ACT I: THE INITIATION",
            actSubtitle = "LOWER BASTION",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues
        )
    }

    private fun buildFloor2(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val baseColor = Color(0.16f, 0.20f, 0.26f, 1f)
        val wallColor = Color(0.12f, 0.15f, 0.20f, 1f)
        val platColor = Color(0.22f, 0.30f, 0.42f, 1f)

        // Lantai Dasar Bentang Luas (120m) & Tembok Menara Tinggi
        platforms.add(Platform(x = -10f, y = 0f, width = 130f, height = 1f, color = baseColor))
        platforms.add(Platform(x = -10f, y = 1f, width = 1f, height = 18f, color = wallColor))
        platforms.add(Platform(x = 119f, y = 1f, width = 1f, height = 18f, color = wallColor))

        // Rute Panjatan Vertikal Berkelanjutan
        platforms.add(Platform(x = 3.0f, y = 2.4f, width = 4.0f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 9.5f, y = 4.2f, width = 4.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 16.5f, y = 6.0f, width = 5.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 24.0f, y = 7.6f, width = 5.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 24.0f, y = 3.2f, width = 4.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 33.0f, y = 5.0f, width = 5.0f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 41.0f, y = 3.2f, width = 5.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 49.0f, y = 5.2f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 57.5f, y = 7.2f, width = 6.0f, height = 0.5f, color = platColor))

        platforms.add(Platform(x = 66.0f, y = 5.0f, width = 5.0f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 73.5f, y = 3.2f, width = 5.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 81.5f, y = 5.2f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 90.0f, y = 7.2f, width = 6.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 99.0f, y = 4.5f, width = 5.0f, height = 0.35f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 12.0f, y = 1.0f, width = 3.0f, height = 0.5f),
            SpikeHazard(x = 35.0f, y = 1.0f, width = 3.5f, height = 0.5f),
            SpikeHazard(x = 68.0f, y = 1.0f, width = 3.5f, height = 0.5f),
            SpikeHazard(x = 92.0f, y = 1.0f, width = 3.5f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 26.5f, y = 8.1f),
            TreasureChest(x = 60.0f, y = 7.7f),
            TreasureChest(x = 93.0f, y = 7.7f)
        )

        val enemies = listOf(
            Enemy(spawnX = 10.0f, spawnY = 4.7f, type = EnemyType.MELEE),
            Enemy(spawnX = 26.0f, spawnY = 8.1f, type = EnemyType.RANGED),
            Enemy(spawnX = 44.0f, spawnY = 3.7f, type = EnemyType.MELEE),
            Enemy(spawnX = 60.0f, spawnY = 7.7f, type = EnemyType.FLYING),
            Enemy(spawnX = 76.0f, spawnY = 3.7f, type = EnemyType.MELEE),
            Enemy(spawnX = 93.0f, spawnY = 7.7f, type = EnemyType.RANGED)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 59.0f,
                y = 7.2f,
                tabletId = "TABLET_2",
                title = "Tablet II: Catatan Para Pendaki",
                text = "Kutukan gravitasi ini bukan dari bumi, melainkan dari langit. Para dewa tidak ingin kita terbang. Mereka memasang duri-duri obsidian ini agar darah kita kembali menyuburkan tanah. Jangan pernah ragu saat melangkah: hanya mereka yang terus bergerak yang sampai ke puncak."
            )
        )

        return TowerFloor(
            floorNumber = 2,
            floorName = "Lantai 2: Spire of Hazards",
            mapBounds = Rectangle(-10f, -1f, 130f, 18f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 52.0f, y = 1.0f),
            exitPortal = StageExit(x = 108.0f, y = 1.0f),
            isBossFloor = false,
            actTitle = "ACT I: THE INITIATION",
            actSubtitle = "SPIRE OF HAZARDS",
            loreTablets = loreTablets,
            storyDialogues = emptyList()
        )
    }

    private fun buildFloor3(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val baseColor = Color(0.20f, 0.14f, 0.22f, 1f)
        val wallColor = Color(0.14f, 0.10f, 0.16f, 1f)
        val platColor = Color(0.28f, 0.20f, 0.32f, 1f)

        // Peta Bentang Luas (125m) dengan Runic Barrier Pertama di x = 88m
        platforms.add(Platform(x = -10f, y = 0f, width = 135f, height = 1f, color = baseColor))
        platforms.add(Platform(x = -10f, y = 1f, width = 1f, height = 18f, color = wallColor))
        platforms.add(Platform(x = 124f, y = 1f, width = 1f, height = 18f, color = wallColor))

        // Koridor Bawah & Tangga Menuju Menara Kunci (Key Tower)
        platforms.add(Platform(x = 4.0f, y = 2.4f, width = 4.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 11.5f, y = 4.2f, width = 5.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 19.5f, y = 6.0f, width = 5.5f, height = 0.5f, color = platColor))

        platforms.add(Platform(x = 28.0f, y = 4.0f, width = 5.0f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 36.0f, y = 3.0f, width = 5.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 44.5f, y = 5.0f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 53.5f, y = 7.0f, width = 5.5f, height = 0.5f, color = platColor))

        // Altar Kunci Runik (Runic Key Platform di Ketinggian)
        platforms.add(Platform(x = 62.0f, y = 8.5f, width = 7.0f, height = 0.6f, color = Color(0.38f, 0.18f, 0.28f, 1f)))
        platforms.add(Platform(x = 62.0f, y = 3.5f, width = 5.5f, height = 0.35f, isOneWay = true))

        // Koridor Lanjut Menuju Pintu Runic Barrier
        platforms.add(Platform(x = 72.0f, y = 4.5f, width = 5.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 80.5f, y = 3.0f, width = 5.5f, height = 0.5f, color = platColor))

        // Melewati Barrier Menuju Exit Portal
        platforms.add(Platform(x = 94.0f, y = 3.5f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 103.0f, y = 5.2f, width = 6.5f, height = 0.5f, color = platColor))

        val spikes = listOf(
            SpikeHazard(x = 14.0f, y = 1.0f, width = 3.5f, height = 0.5f),
            SpikeHazard(x = 38.0f, y = 1.0f, width = 4.0f, height = 0.5f),
            SpikeHazard(x = 74.0f, y = 1.0f, width = 4.0f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 21.0f, y = 6.5f),
            TreasureChest(x = 67.0f, y = 9.1f), // Hadiah di samping kunci
            TreasureChest(x = 106.0f, y = 5.7f)
        )

        val enemies = listOf(
            Enemy(spawnX = 13.0f, spawnY = 4.7f, type = EnemyType.MELEE),
            Enemy(spawnX = 22.0f, spawnY = 6.5f, type = EnemyType.RANGED),
            Enemy(spawnX = 47.0f, spawnY = 5.5f, type = EnemyType.MELEE),
            Enemy(spawnX = 64.0f, spawnY = 9.1f, type = EnemyType.RANGED), // Penjaga Kunci
            Enemy(spawnX = 66.5f, spawnY = 9.1f, type = EnemyType.MELEE),  // Penjaga Kunci
            Enemy(spawnX = 74.0f, spawnY = 5.0f, type = EnemyType.FLYING),
            Enemy(spawnX = 97.0f, spawnY = 4.0f, type = EnemyType.MELEE)
        )

        // Barrier di x = 88m & Kunci di x = 65m, y = 9m
        val barrierId = "BARRIER_FLOOR_3"
        val runicBarriers = listOf(
            RunicBarrier(x = 88.0f, y = 1.0f, width = 0.8f, height = 6.5f, barrierId = barrierId)
        )
        val runicKeys = listOf(
            RunicKey(x = 65.0f, y = 9.2f, targetBarrierId = barrierId)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 20.0f,
                y = 6.0f,
                tabletId = "TABLET_3",
                title = "Tablet III: Segel Gerbang Kuno",
                text = "Pintu gerbang energi merah di depan dijaga oleh Segel Runik Bawah. Jangan membuang waktu mendobraknya dengan pedang biasa: carilah Inti Kristal Kunci di atas menara arsip samping untuk mendisipasi penghalangnya!"
            )
        )

        return TowerFloor(
            floorNumber = 3,
            floorName = "Lantai 3: The Sealed Armory",
            mapBounds = Rectangle(-10f, -1f, 135f, 18f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 48.0f, y = 1.0f),
            exitPortal = StageExit(x = 114.0f, y = 1.0f),
            isBossFloor = false,
            actTitle = "ACT I: THE INITIATION",
            actSubtitle = "THE SEALED ARMORY",
            loreTablets = loreTablets,
            storyDialogues = emptyList(),
            runicBarriers = runicBarriers,
            runicKeys = runicKeys
        )
    }

    // =========================================================================
    // BABAK II: RAHASIA TINTA & LOGAM ABADI (ACT II: SECRETS OF THE INK — LANTAI 4 S/D 6)
    // =========================================================================

    private fun buildFloor4(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val amethystFloor = Color(0.20f, 0.15f, 0.28f, 1f)
        val amethystWall = Color(0.14f, 0.10f, 0.22f, 1f)
        val crystalPlatform = Color(0.26f, 0.20f, 0.38f, 1f)

        // Perpustakaan Kaca Kristal Amethyst Bentang Luas (120m)
        platforms.add(Platform(x = -10f, y = 0f, width = 130f, height = 1f, color = amethystFloor))
        platforms.add(Platform(x = -10f, y = 1f, width = 1f, height = 18f, color = amethystWall))
        platforms.add(Platform(x = 119f, y = 1f, width = 1f, height = 18f, color = amethystWall))

        // Meja-meja Arsip Kuno & Tangga Kaca Kristal
        platforms.add(Platform(x = 3.0f, y = 2.4f, width = 5.0f, height = 0.5f, color = crystalPlatform))
        platforms.add(Platform(x = 10.5f, y = 4.2f, width = 4.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 17.5f, y = 6.0f, width = 6.0f, height = 0.5f, color = crystalPlatform))
        platforms.add(Platform(x = 26.0f, y = 4.2f, width = 5.0f, height = 0.5f, color = crystalPlatform))
        platforms.add(Platform(x = 33.5f, y = 6.2f, width = 5.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 42.0f, y = 3.5f, width = 5.5f, height = 0.5f, color = crystalPlatform))
        platforms.add(Platform(x = 50.5f, y = 5.5f, width = 6.0f, height = 0.5f, color = crystalPlatform))
        platforms.add(Platform(x = 59.0f, y = 7.5f, width = 6.5f, height = 0.5f, color = crystalPlatform))
        platforms.add(Platform(x = 68.0f, y = 5.0f, width = 5.0f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 75.5f, y = 3.5f, width = 5.5f, height = 0.5f, color = crystalPlatform))
        platforms.add(Platform(x = 83.5f, y = 5.5f, width = 6.0f, height = 0.5f, color = crystalPlatform))
        platforms.add(Platform(x = 92.0f, y = 7.5f, width = 6.5f, height = 0.5f, color = crystalPlatform))
        platforms.add(Platform(x = 101.0f, y = 4.5f, width = 5.5f, height = 0.35f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 13.0f, y = 1.0f, width = 3.0f, height = 0.5f),
            SpikeHazard(x = 36.0f, y = 1.0f, width = 3.5f, height = 0.5f),
            SpikeHazard(x = 70.0f, y = 1.0f, width = 3.5f, height = 0.5f),
            SpikeHazard(x = 94.0f, y = 1.0f, width = 3.5f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 20.0f, y = 6.5f),
            TreasureChest(x = 61.5f, y = 8.0f),
            TreasureChest(x = 94.5f, y = 8.0f)
        )

        val enemies = listOf(
            Enemy(spawnX = 12.0f, spawnY = 4.7f, type = EnemyType.MELEE),
            Enemy(spawnX = 19.0f, spawnY = 6.5f, type = EnemyType.RANGED),
            Enemy(spawnX = 35.0f, spawnY = 6.7f, type = EnemyType.FLYING),
            Enemy(spawnX = 52.0f, spawnY = 6.0f, type = EnemyType.MELEE),
            Enemy(spawnX = 61.0f, spawnY = 8.0f, type = EnemyType.RANGED),
            Enemy(spawnX = 77.0f, spawnY = 4.0f, type = EnemyType.MELEE),
            Enemy(spawnX = 94.0f, spawnY = 8.0f, type = EnemyType.RANGED)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 19.5f,
                y = 6.0f,
                tabletId = "TABLET_4",
                title = "Tablet IV: Kutukan Sang Penulis",
                text = "Mereka menyebut kami monster karena kami menggunakan panah amethyst dari kejauhan. Tapi mereka tidak mengerti: mendekati bilah pedang di menara ini berarti kematian. Kami menyegel diri dalam ruang arsip ini untuk mencari penawar racun tinta... namun tinta itu sendiri telah menjadi darah kami."
            )
        )

        val storyDialogues = listOf(
            StoryDialogue(
                triggerX = 2.0f,
                triggerY = 1.5f,
                triggerRadius = 3.0f,
                lines = listOf(
                    DialogueLine(
                        speaker = "Aria",
                        title = "Sang Gema Warna Terakhir",
                        text = "Perpustakaan Kaca Hitam... di sinilah para cendekiawan Amethyst Weavers meneliti rahasia Tinta Primordial sebelum mereka dikutuk menjadi pemanah bayangan.",
                        speakerColor = Color.CYAN
                    )
                )
            )
        )

        return TowerFloor(
            floorNumber = 4,
            floorName = "Lantai 4: The Sunken Archives",
            mapBounds = Rectangle(-10f, -1f, 130f, 18f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 54.0f, y = 1.0f),
            exitPortal = StageExit(x = 110.0f, y = 1.0f),
            isBossFloor = false,
            actTitle = "ACT II: SECRETS OF THE INK",
            actSubtitle = "THE SUNKEN ARCHIVES",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues,
            bloodAltar = BloodAltar(x = 65.0f, y = 1.0f)
        )
    }

    private fun buildFloor5(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val arenaFloor = Color(0.22f, 0.18f, 0.16f, 1f)
        val arenaWall = Color(0.14f, 0.11f, 0.10f, 1f)
        val pillarColor = Color(0.32f, 0.25f, 0.20f, 1f)

        // Colosseum Obsidian Bentang Luas (95m)
        platforms.add(Platform(x = -10f, y = 0f, width = 105f, height = 1.2f, color = arenaFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 22f, color = arenaWall))
        platforms.add(Platform(x = 94f, y = 1.2f, width = 1.2f, height = 22f, color = arenaWall))

        // Platform Berundak Sayap Kiri (Tribun Pengamat Barat)
        platforms.add(Platform(x = 5.0f, y = 3.5f, width = 6.0f, height = 0.5f, color = pillarColor))
        platforms.add(Platform(x = 13.5f, y = 6.0f, width = 7.0f, height = 0.5f, color = pillarColor))
        platforms.add(Platform(x = 23.0f, y = 4.2f, width = 5.5f, height = 0.35f, isOneWay = true))

        // Platform Akrobatik Tengah (Mengindari Shield Shockwave Oakhaven)
        platforms.add(Platform(x = 34.0f, y = 5.2f, width = 8.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 48.0f, y = 6.8f, width = 7.0f, height = 0.4f, isOneWay = true))

        // Platform Berundak Sayap Kanan (Tribun Pengamat Timur)
        platforms.add(Platform(x = 61.0f, y = 4.2f, width = 5.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 70.0f, y = 6.0f, width = 7.0f, height = 0.5f, color = pillarColor))
        platforms.add(Platform(x = 80.0f, y = 3.5f, width = 6.0f, height = 0.5f, color = pillarColor))

        val chests = listOf(
            TreasureChest(x = 15.0f, y = 6.5f),
            TreasureChest(x = 72.0f, y = 6.5f)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 6.0f,
                y = 4.0f,
                tabletId = "TABLET_5",
                title = "Tablet V: Prasasti Colosseum Oakhaven",
                text = "Di arena pasir hitam ini, General Oakhaven bersumpah bahwa tak seorang pun berhak melangkah ke lantai atas tanpa membuktikan ketahanan tekadnya. Perisai besarnya tak tertembus dari depan: pancing serangannya dan tebas dari belakang!"
            )
        )

        val boss = BossEnemy(spawnX = 48.0f, spawnY = 1.5f, type = BossType.TOWER_GUARDIAN)
        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(5))

        return TowerFloor(
            floorNumber = 5,
            floorName = "Lantai 5: The Obsidian Colosseum",
            mapBounds = Rectangle(-10f, -1f, 105f, 24f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = emptyList(),
            chests = chests,
            enemies = emptyList(),
            boss = boss,
            checkpoint = Checkpoint(x = 2.0f, y = 1.2f),
            exitPortal = StageExit(x = 86.0f, y = 1.2f),
            isBossFloor = true,
            actTitle = "SAGA I: THE ASHEN DEPTHS",
            actSubtitle = "THE OBSIDIAN COLOSSEUM",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues
        )
    }

    private fun buildFloor6(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val forgeFloor = Color(0.28f, 0.18f, 0.12f, 1f)
        val forgeWall = Color(0.18f, 0.10f, 0.08f, 1f)
        val anvilStone = Color(0.42f, 0.25f, 0.14f, 1f)

        // Bengkel Tempa Logam Vulcanus (Zona Aman / Safe Haven — Bentang 90m)
        platforms.add(Platform(x = -10f, y = 0f, width = 100f, height = 1.2f, color = forgeFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 18f, color = forgeWall))
        platforms.add(Platform(x = 89f, y = 1.2f, width = 1.2f, height = 18f, color = forgeWall))

        // Meja Tempa, Rak Senjata, & Tungku Perapian Emas
        platforms.add(Platform(x = 6.0f, y = 2.5f, width = 6.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 16.0f, y = 1.2f, width = 9.0f, height = 0.8f, color = anvilStone))
        platforms.add(Platform(x = 29.0f, y = 3.5f, width = 7.0f, height = 0.5f, color = anvilStone))
        platforms.add(Platform(x = 40.0f, y = 2.5f, width = 6.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 50.0f, y = 3.8f, width = 8.0f, height = 0.5f, color = anvilStone))
        platforms.add(Platform(x = 64.0f, y = 2.5f, width = 6.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 74.0f, y = 3.5f, width = 7.0f, height = 0.5f, color = anvilStone))

        val chests = listOf(
            TreasureChest(x = 18.0f, y = 2.0f),
            TreasureChest(x = 31.0f, y = 4.0f),
            TreasureChest(x = 53.0f, y = 4.3f),
            TreasureChest(x = 76.0f, y = 4.0f)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 19.5f,
                y = 2.0f,
                tabletId = "TABLET_6",
                title = "Tablet VI: Wasiat Sang Penempa Vulcanus",
                text = "Besi meteorit ini adalah satu-satunya benda di semesta yang tidak mempan terhadap Tinta Primordial. Istirahatlah sejenak, Kaelen. Di atas sana, langit menara telah retak dan bayangan ratu amethyst menanti."
            )
        )

        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(6))

        return TowerFloor(
            floorNumber = 6,
            floorName = "Lantai 6: The Iron Foundry",
            mapBounds = Rectangle(-10f, -1f, 100f, 18f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = emptyList(),
            chests = chests,
            enemies = emptyList(),
            boss = null,
            checkpoint = Checkpoint(x = 17.5f, y = 2.0f),
            exitPortal = StageExit(x = 82.0f, y = 1.2f),
            isBossFloor = false,
            actTitle = "SAGA I: THE ASHEN DEPTHS",
            actSubtitle = "THE IRON FOUNDRY",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues,
            isSafeZone = true
        )
    }

    private fun buildFloor7(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val astralColor = Color(0.16f, 0.22f, 0.36f, 1f)
        val voidFloor = Color(0.10f, 0.14f, 0.22f, 1f)

        // Tebing Melayang Angkasa Kosmis (Bentang Luas 125m, Gravitasi Rendah -35%)
        platforms.add(Platform(x = -10f, y = 0f, width = 135f, height = 0.8f, color = voidFloor))
        platforms.add(Platform(x = -10f, y = 0.8f, width = 1f, height = 22f, color = astralColor))
        platforms.add(Platform(x = 124f, y = 0.8f, width = 1f, height = 22f, color = astralColor))

        // Rute Lompatan Pulau Terapung Udara
        platforms.add(Platform(x = 3.0f, y = 2.5f, width = 5.0f, height = 0.5f, color = astralColor))
        platforms.add(Platform(x = 12.0f, y = 4.8f, width = 5.5f, height = 0.5f, color = astralColor))
        platforms.add(Platform(x = 21.5f, y = 7.0f, width = 6.0f, height = 0.5f, color = astralColor))
        platforms.add(Platform(x = 31.0f, y = 5.2f, width = 5.0f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 39.5f, y = 3.5f, width = 5.5f, height = 0.5f, color = astralColor))
        platforms.add(Platform(x = 48.5f, y = 6.0f, width = 6.5f, height = 0.5f, color = astralColor))
        platforms.add(Platform(x = 58.0f, y = 8.5f, width = 7.5f, height = 0.6f, color = astralColor)) // Pulau Altar Darah
        platforms.add(Platform(x = 69.0f, y = 6.2f, width = 5.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 77.5f, y = 4.5f, width = 6.0f, height = 0.5f, color = astralColor))
        platforms.add(Platform(x = 87.0f, y = 7.0f, width = 6.5f, height = 0.5f, color = astralColor))
        platforms.add(Platform(x = 97.0f, y = 5.5f, width = 5.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 105.5f, y = 7.5f, width = 7.0f, height = 0.6f, color = astralColor)) // Puncak Exit

        val spikes = listOf(
            SpikeHazard(x = 8.0f, y = 0.8f, width = 3.5f, height = 0.5f),
            SpikeHazard(x = 26.0f, y = 0.8f, width = 4.0f, height = 0.5f),
            SpikeHazard(x = 44.0f, y = 0.8f, width = 4.0f, height = 0.5f),
            SpikeHazard(x = 72.0f, y = 0.8f, width = 4.5f, height = 0.5f),
            SpikeHazard(x = 92.0f, y = 0.8f, width = 4.0f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 23.0f, y = 7.5f),
            TreasureChest(x = 62.0f, y = 9.1f),
            TreasureChest(x = 89.0f, y = 7.5f),
            TreasureChest(x = 108.0f, y = 8.1f)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 22.0f,
                y = 7.0f,
                tabletId = "TABLET_7",
                title = "Tablet VII: Tebing Angkasa Retak",
                text = "Di luar retakan menara ini, gravitasi melemah drastis. Ruang dan waktu dirobek oleh kekuatan Tinta Primordial. Lompatlah dengan penuh keyakinan di antara pulau-pulau melayang!"
            )
        )

        val enemies = listOf(
            Enemy(spawnX = 13.0f, spawnY = 5.3f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 23.0f, spawnY = 7.5f, type = EnemyType.RANGED),
            Enemy(spawnX = 35.0f, spawnY = 6.5f, type = EnemyType.FLYING),
            Enemy(spawnX = 51.0f, spawnY = 6.5f, type = EnemyType.MELEE),
            Enemy(spawnX = 67.0f, spawnY = 7.5f, type = EnemyType.FLYING),
            Enemy(spawnX = 89.0f, spawnY = 7.5f, type = EnemyType.RANGED),
            Enemy(spawnX = 99.0f, spawnY = 6.0f, type = EnemyType.SHIELDED)
        )

        val storyDialogues = listOf(
            StoryDialogue(
                triggerX = 1.0f,
                triggerY = 1.5f,
                triggerRadius = 3.0f,
                lines = listOf(
                    DialogueLine(
                        speaker = "Aria",
                        title = "Sang Gema Warna Terakhir",
                        text = "Dinding menara di lantai ini hancur total... Rasakan ringannya lompatanmu! Gravitasi di sini hanya 65% dari biasanya. Gunakan itu untuk melayang melintasi jurang tak berdasar!",
                        speakerColor = Color.CYAN
                    )
                )
            )
        )

        return TowerFloor(
            floorNumber = 7,
            floorName = "Lantai 7: The Fractured Precipice",
            mapBounds = Rectangle(-10f, -1f, 135f, 22f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 50.0f, y = 6.0f),
            exitPortal = StageExit(x = 109.0f, y = 7.5f),
            isBossFloor = false,
            actTitle = "SAGA I: THE ASHEN DEPTHS",
            actSubtitle = "THE FRACTURED PRECIPICE",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues,
            bloodAltar = BloodAltar(x = 60.0f, y = 8.5f),
            gravityScale = 0.65f
        )
    }

    private fun buildFloor8(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val baseColor = Color(0.14f, 0.16f, 0.22f, 1f)
        val wallColor = Color(0.10f, 0.11f, 0.16f, 1f)
        val platColor = Color(0.22f, 0.26f, 0.36f, 1f)

        // Balairung Gema Bayangan Bentang Luas (130m) dengan Runic Barrier ke-2 di x = 94m
        platforms.add(Platform(x = -10f, y = 0f, width = 140f, height = 1f, color = baseColor))
        platforms.add(Platform(x = -10f, y = 1f, width = 1f, height = 20f, color = wallColor))
        platforms.add(Platform(x = 129f, y = 1f, width = 1f, height = 20f, color = wallColor))

        // Koridor Akrobatik & Menara Pengamat Menuju Kunci Runik
        platforms.add(Platform(x = 4.0f, y = 2.4f, width = 4.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 12.0f, y = 4.2f, width = 5.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 21.0f, y = 6.2f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 30.0f, y = 4.2f, width = 5.0f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 38.0f, y = 3.2f, width = 5.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 47.0f, y = 5.2f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 56.5f, y = 7.2f, width = 6.0f, height = 0.5f, color = platColor))

        // Menara Puncak Kunci Runik Lantai 8 (x = 72m, y = 9.5m)
        platforms.add(Platform(x = 68.0f, y = 9.0f, width = 8.5f, height = 0.6f, color = Color(0.36f, 0.20f, 0.32f, 1f)))
        platforms.add(Platform(x = 68.0f, y = 4.0f, width = 6.0f, height = 0.35f, isOneWay = true))

        // Koridor Lanjut Menuju Runic Barrier di x = 94m
        platforms.add(Platform(x = 80.0f, y = 4.5f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 88.0f, y = 3.0f, width = 5.5f, height = 0.5f, color = platColor))

        // Area Pasca Barrier Menuju Gerbang Menara
        platforms.add(Platform(x = 100.0f, y = 3.5f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 109.0f, y = 5.5f, width = 6.5f, height = 0.5f, color = platColor))

        val spikes = listOf(
            SpikeHazard(x = 15.0f, y = 1.0f, width = 3.5f, height = 0.5f),
            SpikeHazard(x = 42.0f, y = 1.0f, width = 4.0f, height = 0.5f),
            SpikeHazard(x = 82.0f, y = 1.0f, width = 4.5f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 22.5f, y = 6.7f),
            TreasureChest(x = 74.0f, y = 9.6f), // Hadiah di samping Runic Key
            TreasureChest(x = 112.0f, y = 6.0f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 4.7f, type = EnemyType.MELEE),
            Enemy(spawnX = 23.0f, spawnY = 6.7f, type = EnemyType.RANGED),
            Enemy(spawnX = 49.0f, spawnY = 5.7f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 70.0f, spawnY = 9.6f, type = EnemyType.RANGED), // Penjaga Kunci
            Enemy(spawnX = 73.0f, spawnY = 9.6f, type = EnemyType.SHIELDED), // Penjaga Kunci
            Enemy(spawnX = 82.0f, spawnY = 5.0f, type = EnemyType.FLYING),
            Enemy(spawnX = 102.0f, spawnY = 4.0f, type = EnemyType.MELEE)
        )

        val barrierId = "BARRIER_FLOOR_8"
        val runicBarriers = listOf(
            RunicBarrier(x = 94.0f, y = 1.0f, width = 0.8f, height = 7.0f, barrierId = barrierId)
        )
        val runicKeys = listOf(
            RunicKey(x = 72.0f, y = 9.6f, targetBarrierId = barrierId)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 21.0f,
                y = 6.2f,
                tabletId = "TABLET_8",
                title = "Tablet VIII: Gerbang Segel Gema",
                text = "Balairung ini dijaga oleh Segel Runik Gema. Ratu laba-laba di atas telah memerintahkan para pelindungnya mengunci jalan masuk menuju sarang intinya. Panjatlah menara cermin di tengah untuk merampas Kunci Runik ungu!"
            )
        )

        return TowerFloor(
            floorNumber = 8,
            floorName = "Lantai 8: The Hall of Echoes",
            mapBounds = Rectangle(-10f, -1f, 140f, 20f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 50.0f, y = 1.0f),
            exitPortal = StageExit(x = 118.0f, y = 1.0f),
            isBossFloor = false,
            actTitle = "SAGA I: THE ASHEN DEPTHS",
            actSubtitle = "THE HALL OF ECHOES",
            loreTablets = loreTablets,
            storyDialogues = emptyList(),
            runicBarriers = runicBarriers,
            runicKeys = runicKeys
        )
    }

    private fun buildFloor9(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val violetFloor = Color(0.24f, 0.12f, 0.28f, 1f)
        val violetWall = Color(0.16f, 0.08f, 0.20f, 1f)
        val webPlatform = Color(0.35f, 0.20f, 0.42f, 1f)

        // Koridor Sarang Sutra Kristal Amethyst (Bentang Luas 120m)
        platforms.add(Platform(x = -10f, y = 0f, width = 130f, height = 1f, color = violetFloor))
        platforms.add(Platform(x = -10f, y = 1f, width = 1f, height = 20f, color = violetWall))
        platforms.add(Platform(x = 119f, y = 1f, width = 1f, height = 20f, color = violetWall))

        // Jaring Sutra Gantung & Platform Kristal Amethyst
        platforms.add(Platform(x = 4.0f, y = 2.5f, width = 5.0f, height = 0.5f, color = webPlatform))
        platforms.add(Platform(x = 12.0f, y = 4.5f, width = 5.5f, height = 0.5f, color = webPlatform))
        platforms.add(Platform(x = 20.5f, y = 6.5f, width = 6.0f, height = 0.5f, color = webPlatform))
        platforms.add(Platform(x = 29.5f, y = 4.2f, width = 5.0f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 38.0f, y = 3.5f, width = 5.5f, height = 0.5f, color = webPlatform))
        platforms.add(Platform(x = 47.0f, y = 5.8f, width = 6.5f, height = 0.5f, color = webPlatform))
        platforms.add(Platform(x = 56.5f, y = 8.0f, width = 6.5f, height = 0.5f, color = webPlatform))
        platforms.add(Platform(x = 66.0f, y = 5.0f, width = 5.0f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 74.0f, y = 3.5f, width = 6.0f, height = 0.5f, color = webPlatform))
        platforms.add(Platform(x = 83.0f, y = 5.8f, width = 6.5f, height = 0.5f, color = webPlatform))
        platforms.add(Platform(x = 92.5f, y = 7.8f, width = 6.5f, height = 0.5f, color = webPlatform))
        platforms.add(Platform(x = 102.0f, y = 4.5f, width = 5.5f, height = 0.35f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 15.0f, y = 1.0f, width = 3.5f, height = 0.5f),
            SpikeHazard(x = 41.0f, y = 1.0f, width = 4.0f, height = 0.5f),
            SpikeHazard(x = 76.0f, y = 1.0f, width = 4.0f, height = 0.5f),
            SpikeHazard(x = 95.0f, y = 1.0f, width = 4.0f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 22.0f, y = 7.0f),
            TreasureChest(x = 58.0f, y = 8.5f),
            TreasureChest(x = 94.0f, y = 8.3f)
        )

        val enemies = listOf(
            Enemy(spawnX = 13.0f, spawnY = 5.0f, type = EnemyType.MELEE),
            Enemy(spawnX = 22.0f, spawnY = 7.0f, type = EnemyType.RANGED),
            Enemy(spawnX = 35.0f, spawnY = 6.5f, type = EnemyType.FLYING),
            Enemy(spawnX = 49.0f, spawnY = 6.3f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 58.0f, spawnY = 8.5f, type = EnemyType.RANGED),
            Enemy(spawnX = 72.0f, spawnY = 6.5f, type = EnemyType.FLYING),
            Enemy(spawnX = 85.0f, spawnY = 6.3f, type = EnemyType.RANGED),
            Enemy(spawnX = 94.0f, spawnY = 8.3f, type = EnemyType.SHIELDED)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 20.0f,
                y = 6.5f,
                tabletId = "TABLET_9",
                title = "Tablet IX: Peringatan Sarang Sutra",
                text = "Sarang Lady Vespera tepat di atas kita. Udara di sini berbau racun miasma amethyst dan getaran benang sutra. Kabarnya seorang penjelajah bertopeng bayangan terperangkap dalam kepompong kristal di aula utama..."
            )
        )

        val storyDialogues = listOf(
            StoryDialogue(
                triggerX = 2.0f,
                triggerY = 1.5f,
                triggerRadius = 3.0f,
                lines = listOf(
                    DialogueLine(
                        speaker = "Aria",
                        title = "Sang Gema Warna Terakhir",
                        text = "Udara di koridor ini sangat dingin dan dipenuhi jaring sutra ungu... Aku merasakan detak jiwa seseorang di lantai 10! Cepatlah, sebelum kepompong kristal itu menelan jiwanya seutuhnya!",
                        speakerColor = Color.CYAN
                    )
                )
            )
        )

        return TowerFloor(
            floorNumber = 9,
            floorName = "Lantai 9: The Weavers' Passage",
            mapBounds = Rectangle(-10f, -1f, 130f, 20f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 52.0f, y = 1.0f),
            exitPortal = StageExit(x = 108.0f, y = 1.0f),
            isBossFloor = false,
            actTitle = "SAGA I: THE ASHEN DEPTHS",
            actSubtitle = "THE WEAVERS' PASSAGE",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues
        )
    }

    private fun buildFloor10(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val violetFloor = Color(0.20f, 0.10f, 0.26f, 1f)
        val violetWall = Color(0.14f, 0.06f, 0.18f, 1f)
        val crystalMat = Color(0.32f, 0.16f, 0.40f, 1f)

        // The Violet Sanctum — Arena Bos Lady Vespera & Kepompong Zephyr (Bentang Luas 85m)
        platforms.add(Platform(x = -10f, y = 0f, width = 95f, height = 1.2f, color = violetFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 22f, color = violetWall))
        platforms.add(Platform(x = 84f, y = 1.2f, width = 1.2f, height = 22f, color = violetWall))

        // Platform Tumpuan Tempur Menghindari Volley Panah & Kabut Miasma Vespera
        platforms.add(Platform(x = 6.0f, y = 3.5f, width = 6.0f, height = 0.5f, color = crystalMat))
        platforms.add(Platform(x = 18.0f, y = 5.5f, width = 6.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 30.0f, y = 4.5f, width = 8.0f, height = 0.5f, color = crystalMat)) // Platform Tumpuan di atas Kepompong Zephyr
        platforms.add(Platform(x = 44.0f, y = 6.5f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 58.0f, y = 4.0f, width = 7.0f, height = 0.5f, color = crystalMat))
        platforms.add(Platform(x = 70.0f, y = 5.8f, width = 6.0f, height = 0.4f, isOneWay = true))

        val chests = listOf(
            TreasureChest(x = 2.0f, y = 1.2f),
            TreasureChest(x = 76.0f, y = 1.2f)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 4.0f,
                y = 1.2f,
                tabletId = "TABLET_10",
                title = "Tablet X: Ambang Sarang Ratu Sutra",
                text = "Lady Vespera mengendalikan seluruh laba-laba dan panah bayangan di Ashen Depths. Di tengah ruangan ini terdapat kepompong kristal sutra tebal tempat ia memerangkap Zephyr. Hancurkan kepompong itu (3 tebasan pedang) untuk membebaskan Zephyr dan bertarung bersama sebagai Tag-Team!"
            )
        )

        val boss = BossEnemy(spawnX = 52.0f, spawnY = 1.5f, type = BossType.AMETHYST_MATRON)
        val zephyrCocoon = ZephyrCocoon(x = 34.0f, y = 1.2f, width = 1.6f, height = 2.4f)
        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(10))

        return TowerFloor(
            floorNumber = 10,
            floorName = "Lantai 10: The Violet Sanctum",
            mapBounds = Rectangle(-10f, -1f, 95f, 22f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = emptyList(),
            chests = chests,
            enemies = emptyList(),
            boss = boss,
            checkpoint = Checkpoint(x = 2.0f, y = 1.2f),
            exitPortal = StageExit(x = 76.0f, y = 1.2f),
            isBossFloor = true,
            actTitle = "SAGA I: THE ASHEN DEPTHS",
            actSubtitle = "THE VIOLET SANCTUM",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues,
            zephyrCocoon = zephyrCocoon
        )
    }

    // =========================================================================
    // SAGA II: THE SUNKEN ARCHIVES & CLOCKWORK FOUNDRY (LANTAI 11 S/D 20)
    // =========================================================================

    private fun buildFloor11(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val gearSteel = Color(0.25f, 0.22f, 0.20f, 1f)
        val brassPlate = Color(0.42f, 0.35f, 0.22f, 1f)
        val ventGrate = Color(0.18f, 0.16f, 0.15f, 1f)

        // Lantai Dasar Berongga Ventilasi (Bentang Luas 135m)
        platforms.add(Platform(x = -10f, y = 0f, width = 145f, height = 1.2f, color = gearSteel))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 22f, color = gearSteel))
        platforms.add(Platform(x = 134f, y = 1.2f, width = 1.2f, height = 22f, color = gearSteel))

        // Platform Ventilasi Roda Gigi Sempit (Dirancang untuk Kelincahan Zephyr)
        platforms.add(Platform(x = 8.0f, y = 3.5f, width = 7.0f, height = 0.5f, color = brassPlate))
        platforms.add(Platform(x = 18.0f, y = 5.8f, width = 6.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 28.0f, y = 3.8f, width = 8.5f, height = 0.5f, color = brassPlate))
        platforms.add(Platform(x = 42.0f, y = 6.2f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 54.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = ventGrate))
        platforms.add(Platform(x = 68.0f, y = 6.5f, width = 6.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 79.0f, y = 4.0f, width = 8.0f, height = 0.5f, color = brassPlate))
        platforms.add(Platform(x = 92.0f, y = 6.0f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 104.0f, y = 3.8f, width = 9.0f, height = 0.5f, color = ventGrate))
        platforms.add(Platform(x = 118.0f, y = 5.2f, width = 6.0f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 22.0f, y = 1.2f, width = 3.5f, height = 0.6f),
            SpikeHazard(x = 64.0f, y = 1.2f, width = 4.0f, height = 0.6f),
            SpikeHazard(x = 98.0f, y = 1.2f, width = 3.5f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 20.0f, y = 6.3f),
            TreasureChest(x = 57.0f, y = 4.8f),
            TreasureChest(x = 107.0f, y = 4.4f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 32.0f, spawnY = 4.4f, type = EnemyType.RANGED),
            Enemy(spawnX = 48.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 60.0f, spawnY = 4.8f, type = EnemyType.RANGED),
            Enemy(spawnX = 74.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 85.0f, spawnY = 4.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 112.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 18.0f,
                y = 1.2f,
                tabletId = "TABLET_11",
                title = "Tablet XI: Jejak Sang Penyusup Malam",
                text = "Catatan Zephyr: Aku berhasil menembus ventilasi lantai 11. Di bawah sini, roda-roda gigi raksasa berputar tanpa pelumas. Ksatria berzirah berat takkan pernah muat lewat sini. Aku harus mematikan katup uap utama sebelum Kaelen menyusul."
            )
        )

        return TowerFloor(
            floorNumber = 11,
            floorName = "Lantai 11: The Clockwork Conduits",
            mapBounds = Rectangle(-10f, -1f, 145f, 24f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 56.0f, y = 4.8f),
            exitPortal = StageExit(x = 125.0f, y = 1.2f),
            actTitle = "SAGA II: CLOCKWORK FOUNDRY",
            actSubtitle = "THE CLOCKWORK CONDUITS",
            loreTablets = loreTablets
        )
    }

    private fun buildFloor12(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val gearDark = Color(0.22f, 0.19f, 0.18f, 1f)
        val bronzeBevel = Color(0.48f, 0.38f, 0.24f, 1f)
        val ironMesh = Color(0.30f, 0.28f, 0.26f, 1f)

        // Bentang Luas 140m
        platforms.add(Platform(x = -10f, y = 0f, width = 150f, height = 1.2f, color = gearDark))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 24f, color = gearDark))
        platforms.add(Platform(x = 139f, y = 1.2f, width = 1.2f, height = 24f, color = gearDark))

        // Platform Roda Gigi Jam Kosmis
        platforms.add(Platform(x = 6.0f, y = 3.6f, width = 7.5f, height = 0.5f, color = bronzeBevel))
        platforms.add(Platform(x = 17.0f, y = 6.0f, width = 6.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 27.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = ironMesh))
        platforms.add(Platform(x = 40.0f, y = 6.8f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 52.0f, y = 4.5f, width = 8.5f, height = 0.5f, color = bronzeBevel))
        platforms.add(Platform(x = 65.0f, y = 7.0f, width = 6.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 76.0f, y = 4.2f, width = 9.5f, height = 0.5f, color = ironMesh))
        platforms.add(Platform(x = 90.0f, y = 6.5f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 102.0f, y = 4.0f, width = 9.0f, height = 0.5f, color = bronzeBevel))
        platforms.add(Platform(x = 116.0f, y = 6.2f, width = 7.5f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 20.0f, y = 1.2f, width = 4.0f, height = 0.6f),
            SpikeHazard(x = 60.0f, y = 1.2f, width = 4.5f, height = 0.6f),
            SpikeHazard(x = 96.0f, y = 1.2f, width = 4.0f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 29.0f, y = 4.8f),
            TreasureChest(x = 78.0f, y = 4.8f),
            TreasureChest(x = 105.0f, y = 4.6f)
        )

        val enemies = listOf(
            Enemy(spawnX = 12.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 30.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 44.0f, spawnY = 7.4f, type = EnemyType.RANGED),
            Enemy(spawnX = 58.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 80.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 94.0f, spawnY = 7.1f, type = EnemyType.RANGED),
            Enemy(spawnX = 110.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 22.0f,
                y = 1.2f,
                tabletId = "TABLET_12",
                title = "Tablet XII: Detak Jantung Mekanikal",
                text = "Roda-roda gigi ini berputar mengikuti jam kosmis semesta. Setiap detik yang berdentang di lantai 12 adalah satu abad waktu fana yang terhapus di dunia bawah. Waktu di sini tidak mengalir, melainkan digiling."
            )
        )

        return TowerFloor(
            floorNumber = 12,
            floorName = "Lantai 12: The Mechanical Heart",
            mapBounds = Rectangle(-10f, -1f, 150f, 26f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 54.0f, y = 5.1f),
            exitPortal = StageExit(x = 130.0f, y = 1.2f),
            actTitle = "SAGA II: CLOCKWORK FOUNDRY",
            actSubtitle = "THE MECHANICAL HEART",
            loreTablets = loreTablets
        )
    }

    private fun buildFloor13(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val sanctuaryFloor = Color(0.24f, 0.18f, 0.15f, 1f)
        val hearthStone = Color(0.38f, 0.28f, 0.20f, 1f)
        val anvilBench = Color(0.50f, 0.38f, 0.25f, 1f)

        // Suaka Tempa Vulcanus — Safe Hub II (Bentang Luas 130m, Bebas Musuh)
        platforms.add(Platform(x = -10f, y = 0f, width = 140f, height = 1.2f, color = sanctuaryFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 20f, color = sanctuaryFloor))
        platforms.add(Platform(x = 129f, y = 1.2f, width = 1.2f, height = 20f, color = sanctuaryFloor))

        // Platform Tingkat Peristirahatan & Area Kerja Penempa
        platforms.add(Platform(x = 12.0f, y = 3.5f, width = 12.0f, height = 0.6f, color = hearthStone))
        platforms.add(Platform(x = 30.0f, y = 5.0f, width = 10.0f, height = 0.5f, isOneWay = true))
        platforms.add(Platform(x = 46.0f, y = 3.5f, width = 14.0f, height = 0.6f, color = anvilBench))
        platforms.add(Platform(x = 66.0f, y = 5.2f, width = 9.5f, height = 0.5f, isOneWay = true))
        platforms.add(Platform(x = 82.0f, y = 3.8f, width = 12.0f, height = 0.6f, color = hearthStone))
        platforms.add(Platform(x = 100.0f, y = 5.0f, width = 9.0f, height = 0.5f, isOneWay = true))

        val chests = listOf(
            TreasureChest(x = 16.0f, y = 4.2f),
            TreasureChest(x = 52.0f, y = 4.2f),
            TreasureChest(x = 88.0f, y = 4.5f)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 25.0f,
                y = 1.2f,
                tabletId = "TABLET_13",
                title = "Tablet XIII: Buku Harian Vulcanus",
                text = "Hari ke-10,420. Dua siluet muda tiba di suakaku: seorang pendekar berpedang dan seorang gadis bertopeng belati. Aku menolak membiarkan mereka mati sia-sia. Tungkuku akan menempa bilah mereka dengan serpihan meteorit bintang."
            )
        )

        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(13))

        return TowerFloor(
            floorNumber = 13,
            floorName = "Lantai 13: Vulcanus Sanctuary",
            mapBounds = Rectangle(-10f, -1f, 140f, 20f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = emptyList(),
            chests = chests,
            enemies = emptyList(),
            checkpoint = Checkpoint(x = 20.0f, y = 1.2f),
            exitPortal = StageExit(x = 118.0f, y = 1.2f),
            isBossFloor = false,
            actTitle = "SAGA II: CLOCKWORK FOUNDRY",
            actSubtitle = "VULCANUS SANCTUARY",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues,
            isSafeZone = true
        )
    }

    private fun buildFloor14(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val lavaFloor = Color(0.20f, 0.14f, 0.12f, 1f)
        val ironBridge = Color(0.40f, 0.32f, 0.28f, 1f)
        val redHotSteel = Color(0.55f, 0.30f, 0.20f, 1f)

        // Jembatan Baja Pijar Melintasi Kawah (Bentang Luas 145m)
        platforms.add(Platform(x = -10f, y = 0f, width = 155f, height = 1.2f, color = lavaFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 24f, color = lavaFloor))
        platforms.add(Platform(x = 144f, y = 1.2f, width = 1.2f, height = 24f, color = lavaFloor))

        // Jembatan Gantung Baja di Atas Lahar
        platforms.add(Platform(x = 8.0f, y = 3.8f, width = 8.0f, height = 0.45f, color = ironBridge))
        platforms.add(Platform(x = 20.0f, y = 6.0f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 32.0f, y = 4.2f, width = 9.0f, height = 0.45f, color = redHotSteel))
        platforms.add(Platform(x = 46.0f, y = 6.5f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 58.0f, y = 4.0f, width = 9.5f, height = 0.45f, color = ironBridge))
        platforms.add(Platform(x = 72.0f, y = 6.8f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 84.0f, y = 4.2f, width = 9.0f, height = 0.45f, color = redHotSteel))
        platforms.add(Platform(x = 98.0f, y = 6.2f, width = 8.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 112.0f, y = 4.0f, width = 9.0f, height = 0.45f, color = ironBridge))
        platforms.add(Platform(x = 126.0f, y = 5.8f, width = 7.0f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 22.0f, y = 1.2f, width = 5.0f, height = 0.6f),
            SpikeHazard(x = 64.0f, y = 1.2f, width = 5.5f, height = 0.6f),
            SpikeHazard(x = 104.0f, y = 1.2f, width = 5.0f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 34.0f, y = 4.8f),
            TreasureChest(x = 86.0f, y = 4.8f),
            TreasureChest(x = 114.0f, y = 4.6f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 24.0f, spawnY = 6.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 36.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 52.0f, spawnY = 1.2f, type = EnemyType.FLYING),
            Enemy(spawnX = 62.0f, spawnY = 4.6f, type = EnemyType.MELEE),
            Enemy(spawnX = 88.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 102.0f, spawnY = 6.8f, type = EnemyType.RANGED),
            Enemy(spawnX = 120.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 16.0f,
                y = 1.2f,
                tabletId = "TABLET_14",
                title = "Tablet XIV: Resep Bintang Vulcanus",
                text = "Campurkan serpihan batu bintang dengan koin emas yang kau jarah dari monster. Emas itu bukan uang dewa; itu adalah butiran cahaya mentari yang dipadatkan oleh darah pengorbanan para martir."
            )
        )

        return TowerFloor(
            floorNumber = 14,
            floorName = "Lantai 14: The Molten Crucible",
            mapBounds = Rectangle(-10f, -1f, 155f, 26f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 60.0f, y = 4.6f),
            exitPortal = StageExit(x = 135.0f, y = 1.2f),
            actTitle = "SAGA II: CLOCKWORK FOUNDRY",
            actSubtitle = "THE MOLTEN CRUCIBLE",
            loreTablets = loreTablets
        )
    }

    private fun buildFloor15(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val forgeFloor = Color(0.24f, 0.14f, 0.12f, 1f)
        val ironPillar = Color(0.42f, 0.28f, 0.22f, 1f)
        val moltenGrate = Color(0.58f, 0.32f, 0.18f, 1f)

        // Singgasana Ignis — Arena Bos Forge-Master Ignis (Bentang Luas 100m)
        platforms.add(Platform(x = -10f, y = 0f, width = 110f, height = 1.2f, color = forgeFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 24f, color = forgeFloor))
        platforms.add(Platform(x = 99f, y = 1.2f, width = 1.2f, height = 24f, color = forgeFloor))

        // Platform Berundak Bertarung Menghindari Earthshaker Slam & Molten Core
        platforms.add(Platform(x = 6.0f, y = 3.6f, width = 6.5f, height = 0.5f, color = ironPillar))
        platforms.add(Platform(x = 16.0f, y = 5.8f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 28.0f, y = 4.2f, width = 8.5f, height = 0.5f, color = moltenGrate))
        platforms.add(Platform(x = 42.0f, y = 6.5f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 56.0f, y = 4.5f, width = 9.0f, height = 0.5f, color = ironPillar))
        platforms.add(Platform(x = 70.0f, y = 6.8f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 82.0f, y = 4.0f, width = 7.5f, height = 0.5f, color = moltenGrate))

        val chests = listOf(
            TreasureChest(x = 2.0f, y = 1.2f),
            TreasureChest(x = 92.0f, y = 1.2f)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 4.0f,
                y = 1.2f,
                tabletId = "TABLET_15",
                title = "Tablet XV: Api Terakhir Sebelum Kebekuan",
                text = "Ignis adalah murid terbaikku sebelum ia meminum terak baja cair demi keabadian. Ia menjadi raksasa tanpa rasa sakit, tapi juga tanpa jiwa. Bebaskan dia dengan belas kasihan pedangmu."
            )
        )

        val boss = BossEnemy(
            spawnX = 55.0f,
            spawnY = 1.5f,
            type = BossType.CRIMSON_SOVEREIGN,
            customMaxHp = 900f,
            customName = "FORGE-MASTER IGNIS"
        )
        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(15))

        return TowerFloor(
            floorNumber = 15,
            floorName = "Lantai 15: The Forge Sovereign",
            mapBounds = Rectangle(-10f, -1f, 110f, 24f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = emptyList(),
            chests = chests,
            enemies = emptyList(),
            boss = boss,
            checkpoint = Checkpoint(x = 2.0f, y = 1.2f),
            exitPortal = StageExit(x = 90.0f, y = 1.2f),
            isBossFloor = true,
            actTitle = "SAGA II: CLOCKWORK FOUNDRY",
            actSubtitle = "THE FORGE SOVEREIGN",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues
        )
    }

    private fun buildFloor16(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val pipeSteel = Color(0.22f, 0.20f, 0.22f, 1f)
        val brassConduit = Color(0.45f, 0.36f, 0.26f, 1f)
        val steamVent = Color(0.32f, 0.28f, 0.28f, 1f)

        // Saluran Pipa Bertekanan Tinggi (Bentang Luas 145m)
        platforms.add(Platform(x = -10f, y = 0f, width = 155f, height = 1.2f, color = pipeSteel))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 24f, color = pipeSteel))
        platforms.add(Platform(x = 144f, y = 1.2f, width = 1.2f, height = 24f, color = pipeSteel))

        // Pipa-Pipa Berundak dan Platform Gantung
        platforms.add(Platform(x = 8.0f, y = 3.6f, width = 8.5f, height = 0.5f, color = brassConduit))
        platforms.add(Platform(x = 20.0f, y = 6.0f, width = 6.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 31.0f, y = 4.0f, width = 9.0f, height = 0.5f, color = steamVent))
        platforms.add(Platform(x = 45.0f, y = 6.5f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 58.0f, y = 4.2f, width = 9.5f, height = 0.5f, color = brassConduit))
        platforms.add(Platform(x = 72.0f, y = 6.8f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 84.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = steamVent))
        platforms.add(Platform(x = 98.0f, y = 6.2f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 110.0f, y = 4.0f, width = 9.0f, height = 0.5f, color = brassConduit))
        platforms.add(Platform(x = 124.0f, y = 5.8f, width = 7.0f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 22.0f, y = 1.2f, width = 4.5f, height = 0.6f),
            SpikeHazard(x = 64.0f, y = 1.2f, width = 4.8f, height = 0.6f),
            SpikeHazard(x = 102.0f, y = 1.2f, width = 4.5f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 33.0f, y = 4.6f),
            TreasureChest(x = 86.0f, y = 4.8f),
            TreasureChest(x = 112.0f, y = 4.6f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 24.0f, spawnY = 6.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 38.0f, spawnY = 4.6f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 54.0f, spawnY = 1.2f, type = EnemyType.FLYING),
            Enemy(spawnX = 66.0f, spawnY = 4.8f, type = EnemyType.MELEE),
            Enemy(spawnX = 90.0f, spawnY = 4.8f, type = EnemyType.RANGED),
            Enemy(spawnX = 104.0f, spawnY = 6.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 118.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 24.0f,
                y = 1.2f,
                tabletId = "TABLET_16",
                title = "Tablet XVI: Uap Bertekanan Tinggi",
                text = "Tekanan uap di lantai 16 mampu menghancurkan zirah besi. Hanya mereka yang mampu meluncur dengan refleks kilat yang dapat melompati pipa-pipa panas ini."
            )
        )

        return TowerFloor(
            floorNumber = 16,
            floorName = "Lantai 16: The Steam Conduits",
            mapBounds = Rectangle(-10f, -1f, 155f, 26f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 60.0f, y = 4.8f),
            exitPortal = StageExit(x = 135.0f, y = 1.2f),
            actTitle = "SAGA II: CLOCKWORK FOUNDRY",
            actSubtitle = "THE STEAM CONDUITS",
            loreTablets = loreTablets
        )
    }

    private fun buildFloor17(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val bunkerStone = Color(0.20f, 0.18f, 0.16f, 1f)
        val ironSupport = Color(0.38f, 0.32f, 0.28f, 1f)
        val rubbleMat = Color(0.30f, 0.26f, 0.22f, 1f)

        // Bunker Pengungsi Kawah Tempa (Bentang Luas 150m)
        platforms.add(Platform(x = -10f, y = 0f, width = 160f, height = 1.2f, color = bunkerStone))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 24f, color = bunkerStone))
        platforms.add(Platform(x = 149f, y = 1.2f, width = 1.2f, height = 24f, color = bunkerStone))

        // Platform Reruntuhan Pelindung Bunker
        platforms.add(Platform(x = 8.0f, y = 3.8f, width = 8.0f, height = 0.5f, color = ironSupport))
        platforms.add(Platform(x = 20.0f, y = 6.0f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 32.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = rubbleMat))
        platforms.add(Platform(x = 46.0f, y = 6.5f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 60.0f, y = 4.2f, width = 9.5f, height = 0.5f, color = ironSupport))
        platforms.add(Platform(x = 74.0f, y = 6.8f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 86.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = rubbleMat))
        platforms.add(Platform(x = 100.0f, y = 6.2f, width = 8.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 114.0f, y = 4.0f, width = 9.0f, height = 0.5f, color = ironSupport))
        platforms.add(Platform(x = 128.0f, y = 5.8f, width = 7.0f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 24.0f, y = 1.2f, width = 4.5f, height = 0.6f),
            SpikeHazard(x = 68.0f, y = 1.2f, width = 5.0f, height = 0.6f),
            SpikeHazard(x = 108.0f, y = 1.2f, width = 4.5f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 34.0f, y = 4.8f),
            TreasureChest(x = 88.0f, y = 4.8f),
            TreasureChest(x = 116.0f, y = 4.6f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 26.0f, spawnY = 6.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 38.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 56.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 76.0f, spawnY = 7.4f, type = EnemyType.RANGED),
            Enemy(spawnX = 92.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 122.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 15.0f,
                y = 1.2f,
                tabletId = "TABLET_17",
                title = "Tablet XVII: Jeritan di Bawah Kawah",
                text = "Di bawah lantai kawah ini, ribuan warga bersembunyi di dalam bunker. Di atas kepala mereka, pilar titan menopang jutaan ton batu. Seorang raksasa sedang menahannya seorang diri... bertahanlah, Gorgon!"
            )
        )

        return TowerFloor(
            floorNumber = 17,
            floorName = "Lantai 17: The Ash Refuge",
            mapBounds = Rectangle(-10f, -1f, 160f, 26f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 62.0f, y = 4.8f),
            exitPortal = StageExit(x = 140.0f, y = 1.2f),
            actTitle = "SAGA II: CLOCKWORK FOUNDRY",
            actSubtitle = "THE ASH REFUGE",
            loreTablets = loreTablets
        )
    }

    private fun buildFloor18(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val chainFloor = Color(0.22f, 0.16f, 0.14f, 1f)
        val moltenSteel = Color(0.50f, 0.28f, 0.20f, 1f)
        val ironChainLink = Color(0.36f, 0.32f, 0.30f, 1f)

        // Koridor Rantai Lahar (Bentang Luas 150m)
        platforms.add(Platform(x = -10f, y = 0f, width = 160f, height = 1.2f, color = chainFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 26f, color = chainFloor))
        platforms.add(Platform(x = 149f, y = 1.2f, width = 1.2f, height = 26f, color = chainFloor))

        // Platform Penopang Katup Rantai Lahar
        platforms.add(Platform(x = 8.0f, y = 3.8f, width = 8.0f, height = 0.5f, color = ironChainLink))
        platforms.add(Platform(x = 22.0f, y = 6.2f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 34.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = moltenSteel))
        platforms.add(Platform(x = 48.0f, y = 6.6f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 62.0f, y = 4.2f, width = 9.5f, height = 0.5f, color = ironChainLink))
        platforms.add(Platform(x = 76.0f, y = 7.0f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 90.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = moltenSteel))
        platforms.add(Platform(x = 104.0f, y = 6.5f, width = 8.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 118.0f, y = 4.0f, width = 9.0f, height = 0.5f, color = ironChainLink))
        platforms.add(Platform(x = 132.0f, y = 6.0f, width = 7.0f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 26.0f, y = 1.2f, width = 5.0f, height = 0.6f),
            SpikeHazard(x = 70.0f, y = 1.2f, width = 5.5f, height = 0.6f),
            SpikeHazard(x = 112.0f, y = 1.2f, width = 5.0f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 36.0f, y = 4.8f),
            TreasureChest(x = 92.0f, y = 4.8f),
            TreasureChest(x = 120.0f, y = 4.6f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 26.0f, spawnY = 6.8f, type = EnemyType.RANGED),
            Enemy(spawnX = 40.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 58.0f, spawnY = 1.2f, type = EnemyType.FLYING),
            Enemy(spawnX = 78.0f, spawnY = 7.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 94.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 124.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 30.0f,
                y = 1.2f,
                tabletId = "TABLET_18",
                title = "Tablet XVIII: Rantai Baja yang Merah Membara",
                text = "Rantai-rantai ini mengikat katup lahar. Jika tidak ada yang memotongnya dari tiga sudut secara bersamaan, pilar lantai 20 akan roboh menimpa para pengungsi."
            )
        )

        return TowerFloor(
            floorNumber = 18,
            floorName = "Lantai 18: The Molten Chains",
            mapBounds = Rectangle(-10f, -1f, 160f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 64.0f, y = 4.8f),
            exitPortal = StageExit(x = 140.0f, y = 1.2f),
            actTitle = "SAGA II: CLOCKWORK FOUNDRY",
            actSubtitle = "THE MOLTEN CHAINS",
            loreTablets = loreTablets
        )
    }

    private fun buildFloor19(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val bastionDark = Color(0.18f, 0.16f, 0.15f, 1f)
        val titanRampart = Color(0.35f, 0.30f, 0.25f, 1f)
        val brokenSlab = Color(0.28f, 0.24f, 0.20f, 1f)

        // Ambang Paladin Terakhir (Bentang Luas 155m)
        platforms.add(Platform(x = -10f, y = 0f, width = 165f, height = 1.2f, color = bastionDark))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 26f, color = bastionDark))
        platforms.add(Platform(x = 154f, y = 1.2f, width = 1.2f, height = 26f, color = bastionDark))

        // Platform Runtuh Menuju Ambang Kawah Titan
        platforms.add(Platform(x = 8.0f, y = 3.8f, width = 8.5f, height = 0.5f, color = titanRampart))
        platforms.add(Platform(x = 22.0f, y = 6.2f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 34.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = brokenSlab))
        platforms.add(Platform(x = 48.0f, y = 6.6f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 62.0f, y = 4.4f, width = 9.5f, height = 0.5f, color = titanRampart))
        platforms.add(Platform(x = 78.0f, y = 7.0f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 92.0f, y = 4.4f, width = 9.5f, height = 0.5f, color = brokenSlab))
        platforms.add(Platform(x = 108.0f, y = 6.8f, width = 8.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 122.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = titanRampart))
        platforms.add(Platform(x = 136.0f, y = 6.0f, width = 7.0f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 26.0f, y = 1.2f, width = 5.0f, height = 0.6f),
            SpikeHazard(x = 72.0f, y = 1.2f, width = 5.5f, height = 0.6f),
            SpikeHazard(x = 116.0f, y = 1.2f, width = 5.0f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 36.0f, y = 4.8f),
            TreasureChest(x = 94.0f, y = 5.0f),
            TreasureChest(x = 124.0f, y = 4.8f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 28.0f, spawnY = 6.8f, type = EnemyType.RANGED),
            Enemy(spawnX = 42.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 64.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 82.0f, spawnY = 7.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 98.0f, spawnY = 5.0f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 128.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 28.0f,
                y = 1.2f,
                tabletId = "TABLET_19",
                title = "Tablet XIX: Keteguhan Paladin Terakhir",
                text = "Pundakku remuk, namun jika aku melangkah mundur satu jengkal saja, dunia di bawah kakiku akan musnah. Datanglah, siapa pun yang masih memiliki pedang... bantulah aku mengunci pilar ini!"
            )
        )

        return TowerFloor(
            floorNumber = 19,
            floorName = "Lantai 19: The Titan Ramparts",
            mapBounds = Rectangle(-10f, -1f, 165f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 66.0f, y = 5.0f),
            exitPortal = StageExit(x = 145.0f, y = 1.2f),
            actTitle = "SAGA II: CLOCKWORK FOUNDRY",
            actSubtitle = "THE TITAN RAMPARTS",
            loreTablets = loreTablets
        )
    }

    private fun buildFloor20(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val slagFloor = Color(0.24f, 0.16f, 0.14f, 1f)
        val calderaWall = Color(0.16f, 0.12f, 0.10f, 1f)
        val titanMat = Color(0.40f, 0.30f, 0.22f, 1f)

        // Ambang Tungku Titan — Arena Bos Slag Colossus & Penyelamatan Pilar Gorgon (Bentang Luas 110m)
        platforms.add(Platform(x = -10f, y = 0f, width = 120f, height = 1.2f, color = slagFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 24f, color = calderaWall))
        platforms.add(Platform(x = 109f, y = 1.2f, width = 1.2f, height = 24f, color = calderaWall))

        // Platform Berundak Arena untuk Tumpuan Menghindari Hantaman Slag Colossus
        platforms.add(Platform(x = 6.0f, y = 3.6f, width = 6.5f, height = 0.5f, color = titanMat))
        platforms.add(Platform(x = 18.0f, y = 5.8f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 30.0f, y = 4.5f, width = 8.5f, height = 0.5f, color = titanMat)) // Platform Tumpuan di atas Pilar Titan Gorgon
        platforms.add(Platform(x = 46.0f, y = 6.5f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 62.0f, y = 4.2f, width = 8.5f, height = 0.5f, color = titanMat))
        platforms.add(Platform(x = 76.0f, y = 6.8f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 90.0f, y = 4.0f, width = 7.5f, height = 0.5f, color = titanMat))

        val chests = listOf(
            TreasureChest(x = 2.0f, y = 1.2f),
            TreasureChest(x = 100.0f, y = 1.2f)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 5.0f,
                y = 1.2f,
                tabletId = "TABLET_20",
                title = "Tablet XX: Patahnya Rantai Beban",
                text = "Kaelen mengalihkan monster, Zephyr memotong tuas, dan Gorgon membelah raksasa terak. Tiga pahlawan kini berdiri bersama. Gerbang kawah tempa telah terbuka, menuju bentangan basalt dan langit retak!"
            )
        )

        val boss = BossEnemy(
            spawnX = 62.0f,
            spawnY = 1.5f,
            type = BossType.SHADOW_DOPPELGANGER,
            customMaxHp = 1200f,
            customName = "THE SLAG COLOSSUS"
        )
        val titanPillar = TitanPillar(x = 35.0f, y = 1.2f, width = 3.8f, height = 9.5f)
        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(20))

        return TowerFloor(
            floorNumber = 20,
            floorName = "Lantai 20: The Titan Caldera",
            mapBounds = Rectangle(-10f, -1f, 120f, 26f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = emptyList(),
            chests = chests,
            enemies = emptyList(),
            boss = boss,
            checkpoint = Checkpoint(x = 2.0f, y = 1.2f),
            exitPortal = StageExit(x = 98.0f, y = 1.2f),
            isBossFloor = true,
            actTitle = "SAGA II: CLOCKWORK FOUNDRY",
            actSubtitle = "THE TITAN CALDERA",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues,
            titanPillar = titanPillar
        )
    }

    // =========================================================================
    // SAGA III: BASALT CRATER & THE ASTRAL THRESHOLD (LANTAI 21 S/D 30)
    // =========================================================================

    private fun buildFloor21(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val basaltFloor = Color(0.18f, 0.15f, 0.14f, 1f)
        val rockBevel = Color(0.32f, 0.25f, 0.22f, 1f)
        val lavaRock = Color(0.42f, 0.28f, 0.20f, 1f)

        // Lantai Dasar Kawah Basalt (Bentang Luas 140m)
        platforms.add(Platform(x = -10f, y = 0f, width = 150f, height = 1.2f, color = basaltFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 24f, color = basaltFloor))
        platforms.add(Platform(x = 139f, y = 1.2f, width = 1.2f, height = 24f, color = basaltFloor))

        // Platform Tumpuan Melompati Parit Magma
        platforms.add(Platform(x = 8.0f, y = 3.6f, width = 8.0f, height = 0.5f, color = rockBevel))
        platforms.add(Platform(x = 20.0f, y = 6.0f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 32.0f, y = 4.0f, width = 9.0f, height = 0.5f, color = lavaRock))
        platforms.add(Platform(x = 45.0f, y = 6.5f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 60.0f, y = 4.2f, width = 9.5f, height = 0.5f, color = rockBevel))
        platforms.add(Platform(x = 74.0f, y = 6.8f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 86.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = lavaRock))
        platforms.add(Platform(x = 100.0f, y = 6.2f, width = 8.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 114.0f, y = 4.0f, width = 9.0f, height = 0.5f, color = rockBevel))
        platforms.add(Platform(x = 126.0f, y = 5.8f, width = 7.0f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 24.0f, y = 1.2f, width = 4.5f, height = 0.6f),
            SpikeHazard(x = 68.0f, y = 1.2f, width = 5.0f, height = 0.6f),
            SpikeHazard(x = 106.0f, y = 1.2f, width = 4.5f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 34.0f, y = 4.6f),
            TreasureChest(x = 88.0f, y = 4.8f),
            TreasureChest(x = 116.0f, y = 4.6f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 26.0f, spawnY = 6.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 38.0f, spawnY = 4.6f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 64.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 78.0f, spawnY = 7.4f, type = EnemyType.RANGED),
            Enemy(spawnX = 92.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 120.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 18.0f,
                y = 1.2f,
                tabletId = "TABLET_21",
                title = "Tablet XXI: Langkah Raksasa Berbaja",
                text = "Catatan Gorgon: Pedang raksasaku kini memimpin barisan. Di lantai 21, dinding-dinding batu basalt ini terlalu tebal untuk ditebas pedang biasa. Biarkan palu dan otot bajaku meremukkan jalan untuk kita bertiga."
            )
        )

        val basaltWalls = listOf(
            TitanBasaltWall(x = 55.0f, y = 1.2f, width = 1.6f, height = 4.5f)
        )

        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(21))

        return TowerFloor(
            floorNumber = 21,
            floorName = "Lantai 21: The Basalt Breach",
            mapBounds = Rectangle(-10f, -1f, 150f, 26f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 62.0f, y = 4.8f),
            exitPortal = StageExit(x = 130.0f, y = 1.2f),
            actTitle = "SAGA III: BASALT CRATER & ASTRAL RIFT",
            actSubtitle = "THE BASALT BREACH",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues,
            basaltWalls = basaltWalls
        )
    }

    private fun buildFloor22(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val calderaFloor = Color(0.20f, 0.16f, 0.14f, 1f)
        val rockEdge = Color(0.35f, 0.28f, 0.24f, 1f)
        val obsidianSlab = Color(0.28f, 0.24f, 0.22f, 1f)

        // Bentang Luas 145m
        platforms.add(Platform(x = -10f, y = 0f, width = 155f, height = 1.2f, color = calderaFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 24f, color = calderaFloor))
        platforms.add(Platform(x = 144f, y = 1.2f, width = 1.2f, height = 24f, color = calderaFloor))

        // Platform Berundak Obsidian Kawah
        platforms.add(Platform(x = 8.0f, y = 3.6f, width = 8.5f, height = 0.5f, color = rockEdge))
        platforms.add(Platform(x = 22.0f, y = 6.2f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 34.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = obsidianSlab))
        platforms.add(Platform(x = 48.0f, y = 6.6f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 62.0f, y = 4.4f, width = 9.5f, height = 0.5f, color = rockEdge))
        platforms.add(Platform(x = 76.0f, y = 7.0f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 90.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = obsidianSlab))
        platforms.add(Platform(x = 104.0f, y = 6.5f, width = 8.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 118.0f, y = 4.0f, width = 9.0f, height = 0.5f, color = rockEdge))
        platforms.add(Platform(x = 130.0f, y = 6.0f, width = 7.0f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 26.0f, y = 1.2f, width = 4.8f, height = 0.6f),
            SpikeHazard(x = 70.0f, y = 1.2f, width = 5.2f, height = 0.6f),
            SpikeHazard(x = 110.0f, y = 1.2f, width = 4.8f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 36.0f, y = 4.8f),
            TreasureChest(x = 92.0f, y = 4.8f),
            TreasureChest(x = 120.0f, y = 4.6f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 26.0f, spawnY = 6.8f, type = EnemyType.RANGED),
            Enemy(spawnX = 40.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 58.0f, spawnY = 1.2f, type = EnemyType.FLYING),
            Enemy(spawnX = 80.0f, spawnY = 7.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 94.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 124.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 22.0f,
                y = 1.2f,
                tabletId = "TABLET_22",
                title = "Tablet XXII: Kawah Basalt Hitam",
                text = "Batu basalt di sini membeku dari lahar purba. Musuh-musuh di lantai ini dilapisi pelat batu tebal. Serangan ringan hanya akan memantul; hanya hantaman berkekuatan titan yang mampu memecahkan pertahanan mereka."
            )
        )

        return TowerFloor(
            floorNumber = 22,
            floorName = "Lantai 22: The Obsidian Caldera",
            mapBounds = Rectangle(-10f, -1f, 155f, 26f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 64.0f, y = 5.0f),
            exitPortal = StageExit(x = 135.0f, y = 1.2f),
            actTitle = "SAGA III: BASALT CRATER & ASTRAL RIFT",
            actSubtitle = "THE OBSIDIAN CALDERA",
            loreTablets = loreTablets
        )
    }

    private fun buildFloor23(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val damFloor = Color(0.24f, 0.18f, 0.14f, 1f)
        val goldStone = Color(0.48f, 0.38f, 0.22f, 1f)
        val magmaSlab = Color(0.55f, 0.32f, 0.18f, 1f)

        // Bendungan Lahar Emas (Bentang Luas 145m)
        platforms.add(Platform(x = -10f, y = 0f, width = 155f, height = 1.2f, color = damFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 26f, color = damFloor))
        platforms.add(Platform(x = 144f, y = 1.2f, width = 1.2f, height = 26f, color = damFloor))

        // Platform Bendungan Melintasi Danau Lahar
        platforms.add(Platform(x = 8.0f, y = 3.8f, width = 8.5f, height = 0.5f, color = goldStone))
        platforms.add(Platform(x = 22.0f, y = 6.2f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 34.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = magmaSlab))
        platforms.add(Platform(x = 48.0f, y = 6.6f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 62.0f, y = 4.4f, width = 9.5f, height = 0.5f, color = goldStone))
        platforms.add(Platform(x = 76.0f, y = 7.0f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 90.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = magmaSlab))
        platforms.add(Platform(x = 104.0f, y = 6.5f, width = 8.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 118.0f, y = 4.0f, width = 9.0f, height = 0.5f, color = goldStone))
        platforms.add(Platform(x = 130.0f, y = 6.0f, width = 7.0f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 26.0f, y = 1.2f, width = 5.0f, height = 0.6f),
            SpikeHazard(x = 72.0f, y = 1.2f, width = 5.5f, height = 0.6f),
            SpikeHazard(x = 112.0f, y = 1.2f, width = 5.0f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 36.0f, y = 4.8f),
            TreasureChest(x = 92.0f, y = 4.8f),
            TreasureChest(x = 120.0f, y = 4.6f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 26.0f, spawnY = 6.8f, type = EnemyType.RANGED),
            Enemy(spawnX = 40.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 58.0f, spawnY = 1.2f, type = EnemyType.FLYING),
            Enemy(spawnX = 78.0f, spawnY = 7.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 94.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 124.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 25.0f,
                y = 1.2f,
                tabletId = "TABLET_23",
                title = "Tablet XXIII: Bendungan Lahar Emas",
                text = "Di balik bendungan ini mengalir pigmen warna kuning mentari yang disaring dari padang pasir Aethelgard. Panasnya mampu melelehkan siluet biasa dalam sekejap."
            )
        )

        return TowerFloor(
            floorNumber = 23,
            floorName = "Lantai 23: The Golden Magma Dam",
            mapBounds = Rectangle(-10f, -1f, 155f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 64.0f, y = 5.0f),
            exitPortal = StageExit(x = 135.0f, y = 1.2f),
            actTitle = "SAGA III: BASALT CRATER & ASTRAL RIFT",
            actSubtitle = "THE GOLDEN MAGMA DAM",
            loreTablets = loreTablets
        )
    }

    private fun buildFloor24(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val martyrFloor = Color(0.20f, 0.17f, 0.16f, 1f)
        val slabStone = Color(0.36f, 0.30f, 0.26f, 1f)
        val tombMat = Color(0.30f, 0.25f, 0.22f, 1f)

        // Sarkofagus Para Martir Batu (Bentang Luas 150m)
        platforms.add(Platform(x = -10f, y = 0f, width = 160f, height = 1.2f, color = martyrFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 26f, color = martyrFloor))
        platforms.add(Platform(x = 149f, y = 1.2f, width = 1.2f, height = 26f, color = martyrFloor))

        // Platform Sarkofagus Paladin Batu
        platforms.add(Platform(x = 8.0f, y = 3.8f, width = 8.5f, height = 0.5f, color = slabStone))
        platforms.add(Platform(x = 22.0f, y = 6.2f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 34.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = tombMat))
        platforms.add(Platform(x = 48.0f, y = 6.6f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 62.0f, y = 4.4f, width = 9.5f, height = 0.5f, color = slabStone))
        platforms.add(Platform(x = 78.0f, y = 7.0f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 92.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = tombMat))
        platforms.add(Platform(x = 106.0f, y = 6.5f, width = 8.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 120.0f, y = 4.0f, width = 9.0f, height = 0.5f, color = slabStone))
        platforms.add(Platform(x = 132.0f, y = 6.0f, width = 7.0f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 26.0f, y = 1.2f, width = 5.0f, height = 0.6f),
            SpikeHazard(x = 72.0f, y = 1.2f, width = 5.5f, height = 0.6f),
            SpikeHazard(x = 114.0f, y = 1.2f, width = 5.0f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 36.0f, y = 4.8f),
            TreasureChest(x = 94.0f, y = 4.8f),
            TreasureChest(x = 122.0f, y = 4.6f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 26.0f, spawnY = 6.8f, type = EnemyType.RANGED),
            Enemy(spawnX = 40.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 64.0f, spawnY = 5.0f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 80.0f, spawnY = 7.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 96.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 126.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 28.0f,
                y = 1.2f,
                tabletId = "TABLET_24",
                title = "Tablet XXIV: Sarkofagus Para Martir Batu",
                text = "Di sini bersemayam para paladin Titan Bastion yang gugur. Pedang raksasa mereka ditancapkan sebagai nisan. Gorgon memberi hormat pada saudara-saudaranya sebelum melangkah maju."
            )
        )

        val basaltWalls = listOf(
            TitanBasaltWall(x = 65.0f, y = 1.2f, width = 1.6f, height = 4.5f),
            TitanBasaltWall(x = 115.0f, y = 1.2f, width = 1.6f, height = 4.5f)
        )

        return TowerFloor(
            floorNumber = 24,
            floorName = "Lantai 24: Sarcophagus of Stone Martyrs",
            mapBounds = Rectangle(-10f, -1f, 160f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 64.0f, y = 5.0f),
            exitPortal = StageExit(x = 140.0f, y = 1.2f),
            actTitle = "SAGA III: BASALT CRATER & ASTRAL RIFT",
            actSubtitle = "SARCOPHAGUS OF STONE MARTYRS",
            loreTablets = loreTablets,
            basaltWalls = basaltWalls
        )
    }

    private fun buildFloor25(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val magmaThrone = Color(0.24f, 0.15f, 0.12f, 1f)
        val basaltPillar = Color(0.40f, 0.28f, 0.22f, 1f)
        val fireStep = Color(0.55f, 0.32f, 0.18f, 1f)

        // Singgasana Raja Golem Magma — Arena Bos (Bentang Luas 105m)
        platforms.add(Platform(x = -10f, y = 0f, width = 115f, height = 1.2f, color = magmaThrone))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 26f, color = magmaThrone))
        platforms.add(Platform(x = 104f, y = 1.2f, width = 1.2f, height = 26f, color = magmaThrone))

        // Platform Berundak Bertarung Menghindari Hentakan Magma
        platforms.add(Platform(x = 6.0f, y = 3.6f, width = 6.5f, height = 0.5f, color = basaltPillar))
        platforms.add(Platform(x = 16.0f, y = 5.8f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 28.0f, y = 4.2f, width = 8.5f, height = 0.5f, color = fireStep))
        platforms.add(Platform(x = 42.0f, y = 6.5f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 58.0f, y = 4.5f, width = 9.0f, height = 0.5f, color = basaltPillar))
        platforms.add(Platform(x = 72.0f, y = 6.8f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 86.0f, y = 4.0f, width = 7.5f, height = 0.5f, color = fireStep))

        val chests = listOf(
            TreasureChest(x = 2.0f, y = 1.2f),
            TreasureChest(x = 96.0f, y = 1.2f)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 4.0f,
                y = 1.2f,
                tabletId = "TABLET_25",
                title = "Tablet XXV: Raja Golem Magma",
                text = "Makhluk ini terbentuk dari lahar yang menolak dingin. Hancurkan intinya dengan kombinasi serangan cepat Zephyr di punggung dan tebasan pemecah perisai Gorgon di dada."
            )
        )

        val boss = BossEnemy(
            spawnX = 60.0f,
            spawnY = 1.5f,
            type = BossType.TOWER_GUARDIAN,
            customMaxHp = 1400f,
            customName = "MAGMA GOLEM KING"
        )
        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(25))

        return TowerFloor(
            floorNumber = 25,
            floorName = "Lantai 25: Magma Golem Throne",
            mapBounds = Rectangle(-10f, -1f, 115f, 26f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = emptyList(),
            chests = chests,
            enemies = emptyList(),
            boss = boss,
            checkpoint = Checkpoint(x = 2.0f, y = 1.2f),
            exitPortal = StageExit(x = 94.0f, y = 1.2f),
            isBossFloor = true,
            actTitle = "SAGA III: BASALT CRATER & ASTRAL RIFT",
            actSubtitle = "MAGMA GOLEM THRONE",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues
        )
    }

    private fun buildFloor26(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val riftFloor = Color(0.14f, 0.16f, 0.22f, 1f)
        val cosmicStone = Color(0.22f, 0.28f, 0.38f, 1f)
        val starGlass = Color(0.28f, 0.35f, 0.46f, 1f)

        // Ambang Retakan Angkasa (Bentang Luas 150m)
        platforms.add(Platform(x = -10f, y = 0f, width = 160f, height = 1.2f, color = riftFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 28f, color = riftFloor))
        platforms.add(Platform(x = 149f, y = 1.2f, width = 1.2f, height = 28f, color = riftFloor))

        // Platform Retakan Kosmis
        platforms.add(Platform(x = 8.0f, y = 3.8f, width = 8.5f, height = 0.5f, color = cosmicStone))
        platforms.add(Platform(x = 22.0f, y = 6.2f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 34.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = starGlass))
        platforms.add(Platform(x = 48.0f, y = 6.6f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 62.0f, y = 4.4f, width = 9.5f, height = 0.5f, color = cosmicStone))
        platforms.add(Platform(x = 76.0f, y = 7.0f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 90.0f, y = 4.2f, width = 9.0f, height = 0.5f, color = starGlass))
        platforms.add(Platform(x = 104.0f, y = 6.5f, width = 8.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 118.0f, y = 4.0f, width = 9.0f, height = 0.5f, color = cosmicStone))
        platforms.add(Platform(x = 132.0f, y = 6.0f, width = 7.0f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 26.0f, y = 1.2f, width = 4.8f, height = 0.6f),
            SpikeHazard(x = 70.0f, y = 1.2f, width = 5.2f, height = 0.6f),
            SpikeHazard(x = 112.0f, y = 1.2f, width = 4.8f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 36.0f, y = 4.8f),
            TreasureChest(x = 92.0f, y = 4.8f),
            TreasureChest(x = 120.0f, y = 4.6f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 26.0f, spawnY = 6.8f, type = EnemyType.RANGED),
            Enemy(spawnX = 40.0f, spawnY = 4.8f, type = EnemyType.FLYING),
            Enemy(spawnX = 64.0f, spawnY = 1.2f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 80.0f, spawnY = 7.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 94.0f, spawnY = 4.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 124.0f, spawnY = 1.2f, type = EnemyType.FLYING)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 24.0f,
                y = 1.2f,
                tabletId = "TABLET_26",
                title = "Tablet XXVI: Ambang Retakan Angkasa",
                text = "Dinding batu mulai retak digantikan oleh pemandangan kosmos hitam berbintang cyan. Udara menipis, gravitasi mulai berfluktuasi secara liar."
            )
        )

        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(26))

        return TowerFloor(
            floorNumber = 26,
            floorName = "Lantai 26: The Shattered Firmament",
            mapBounds = Rectangle(-10f, -1f, 160f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 64.0f, y = 5.0f),
            exitPortal = StageExit(x = 140.0f, y = 1.2f),
            actTitle = "SAGA III: BASALT CRATER & ASTRAL RIFT",
            actSubtitle = "THE SHATTERED FIRMAMENT",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues
        )
    }

    private fun buildFloor27(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val cosmicFloor = Color(0.12f, 0.14f, 0.20f, 1f)
        val astralBridge = Color(0.24f, 0.32f, 0.44f, 1f)
        val nebulaStone = Color(0.30f, 0.38f, 0.50f, 1f)

        // Hembusan Angin Bintang (Bentang Luas 150m, Gravitasi Rendah 0.75f)
        platforms.add(Platform(x = -10f, y = 0f, width = 160f, height = 1.2f, color = cosmicFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 28f, color = cosmicFloor))
        platforms.add(Platform(x = 149f, y = 1.2f, width = 1.2f, height = 28f, color = cosmicFloor))

        // Platform Angkasa Melayang (Celah terkontrol <= 2.0m ramah semua karakter termasuk Gorgon)
        platforms.add(Platform(x = 6.0f, y = 3.2f, width = 12.0f, height = 0.5f, color = astralBridge))
        platforms.add(Platform(x = 20.0f, y = 5.5f, width = 12.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 34.0f, y = 4.2f, width = 12.0f, height = 0.5f, color = nebulaStone))
        platforms.add(Platform(x = 48.0f, y = 6.0f, width = 12.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 62.0f, y = 4.8f, width = 13.0f, height = 0.5f, color = astralBridge))
        platforms.add(Platform(x = 77.0f, y = 6.2f, width = 11.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 90.0f, y = 4.5f, width = 12.0f, height = 0.5f, color = nebulaStone))
        platforms.add(Platform(x = 104.0f, y = 6.0f, width = 12.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 118.0f, y = 4.2f, width = 12.0f, height = 0.5f, color = astralBridge))
        platforms.add(Platform(x = 132.0f, y = 5.8f, width = 10.0f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 26.0f, y = 1.2f, width = 5.0f, height = 0.6f),
            SpikeHazard(x = 72.0f, y = 1.2f, width = 5.5f, height = 0.6f),
            SpikeHazard(x = 112.0f, y = 1.2f, width = 5.0f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 36.0f, y = 4.8f),
            TreasureChest(x = 92.0f, y = 5.1f),
            TreasureChest(x = 120.0f, y = 4.8f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 1.2f, type = EnemyType.FLYING),
            Enemy(spawnX = 26.0f, spawnY = 7.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 40.0f, spawnY = 5.4f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 58.0f, spawnY = 1.2f, type = EnemyType.FLYING),
            Enemy(spawnX = 78.0f, spawnY = 8.4f, type = EnemyType.RANGED),
            Enemy(spawnX = 94.0f, spawnY = 5.4f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 124.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 26.0f,
                y = 1.2f,
                tabletId = "TABLET_27",
                title = "Tablet XXVII: Hembusan Angin Bintang",
                text = "Angin kosmis melolong menembus celah menara. Lompatan pemain kini melayang lebih tinggi, namun satu kesalahan langkah akan melemparkanmu ke jurang kehampaan."
            )
        )

        return TowerFloor(
            floorNumber = 27,
            floorName = "Lantai 27: The Starwind Chasm",
            mapBounds = Rectangle(-10f, -1f, 160f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 64.0f, y = 5.4f),
            exitPortal = StageExit(x = 140.0f, y = 1.2f),
            actTitle = "SAGA III: BASALT CRATER & ASTRAL RIFT",
            actSubtitle = "THE STARWIND CHASM",
            loreTablets = loreTablets,
            gravityScale = 0.75f
        )
    }

    private fun buildFloor28(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val meteorFloor = Color(0.12f, 0.12f, 0.18f, 1f)
        val meteorChunk = Color(0.25f, 0.30f, 0.42f, 1f)
        val voidRock = Color(0.18f, 0.22f, 0.32f, 1f)

        // Jembatan Meteorit (Bentang Luas 155m, Gravitasi Rendah 0.70f)
        platforms.add(Platform(x = -10f, y = 0f, width = 165f, height = 1.2f, color = meteorFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 28f, color = meteorFloor))
        platforms.add(Platform(x = 154f, y = 1.2f, width = 1.2f, height = 28f, color = meteorFloor))

        // Bongkahan Meteorit Melayang Bebas di Angkasa (Celah terkontrol <= 2.0m ramah Gorgon)
        platforms.add(Platform(x = 6.0f, y = 3.2f, width = 12.0f, height = 0.5f, color = meteorChunk))
        platforms.add(Platform(x = 20.0f, y = 5.5f, width = 12.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 34.0f, y = 4.2f, width = 12.0f, height = 0.5f, color = voidRock))
        platforms.add(Platform(x = 48.0f, y = 6.0f, width = 12.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 62.0f, y = 4.8f, width = 13.0f, height = 0.5f, color = meteorChunk))
        platforms.add(Platform(x = 77.0f, y = 6.2f, width = 11.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 90.0f, y = 4.5f, width = 12.0f, height = 0.5f, color = voidRock))
        platforms.add(Platform(x = 104.0f, y = 6.0f, width = 12.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 118.0f, y = 4.2f, width = 12.0f, height = 0.5f, color = meteorChunk))
        platforms.add(Platform(x = 132.0f, y = 5.8f, width = 10.0f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 26.0f, y = 1.2f, width = 5.0f, height = 0.6f),
            SpikeHazard(x = 72.0f, y = 1.2f, width = 5.5f, height = 0.6f),
            SpikeHazard(x = 116.0f, y = 1.2f, width = 5.0f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 36.0f, y = 4.8f),
            TreasureChest(x = 94.0f, y = 5.1f),
            TreasureChest(x = 124.0f, y = 4.8f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 1.2f, type = EnemyType.FLYING),
            Enemy(spawnX = 28.0f, spawnY = 7.8f, type = EnemyType.RANGED),
            Enemy(spawnX = 42.0f, spawnY = 5.4f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 64.0f, spawnY = 1.2f, type = EnemyType.FLYING),
            Enemy(spawnX = 82.0f, spawnY = 8.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 98.0f, spawnY = 5.4f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 128.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 28.0f,
                y = 1.2f,
                tabletId = "TABLET_28",
                title = "Tablet XXVIII: Jembatan Meteorit",
                text = "Platform di lantai ini berupa bongkahan meteorit yang melayang bebas. Bergeraklah serempak; momentum tiga pahlawan adalah penyeimbang gravitasi di sini."
            )
        )

        return TowerFloor(
            floorNumber = 28,
            floorName = "Lantai 28: The Meteorite Spire",
            mapBounds = Rectangle(-10f, -1f, 165f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 64.0f, y = 5.4f),
            exitPortal = StageExit(x = 145.0f, y = 1.2f),
            actTitle = "SAGA III: BASALT CRATER & ASTRAL RIFT",
            actSubtitle = "THE METEORITE SPIRE",
            loreTablets = loreTablets,
            gravityScale = 0.65f
        )
    }

    private fun buildFloor29(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val vortexFloor = Color(0.10f, 0.10f, 0.16f, 1f)
        val gravitySlab = Color(0.20f, 0.28f, 0.40f, 1f)
        val cosmicCrystal = Color(0.28f, 0.38f, 0.52f, 1f)

        // Pusaran Gravitasi Terbalik (Bentang Luas 155m, Gravitasi Sangat Rendah 0.55f)
        platforms.add(Platform(x = -10f, y = 0f, width = 165f, height = 1.2f, color = vortexFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 30f, color = vortexFloor))
        platforms.add(Platform(x = 154f, y = 1.2f, width = 1.2f, height = 30f, color = vortexFloor))

        // Platform Tingkat Melayang Tinggi (Celah terkontrol <= 2.0m ramah Gorgon)
        platforms.add(Platform(x = 6.0f, y = 3.2f, width = 12.0f, height = 0.5f, color = gravitySlab))
        platforms.add(Platform(x = 20.0f, y = 5.5f, width = 12.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 34.0f, y = 4.2f, width = 12.0f, height = 0.5f, color = cosmicCrystal))
        platforms.add(Platform(x = 48.0f, y = 6.0f, width = 12.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 62.0f, y = 4.8f, width = 13.0f, height = 0.5f, color = gravitySlab))
        platforms.add(Platform(x = 77.0f, y = 6.2f, width = 11.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 90.0f, y = 4.5f, width = 12.0f, height = 0.5f, color = cosmicCrystal))
        platforms.add(Platform(x = 104.0f, y = 6.0f, width = 12.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 118.0f, y = 4.2f, width = 12.0f, height = 0.5f, color = gravitySlab))
        platforms.add(Platform(x = 132.0f, y = 5.8f, width = 10.0f, height = 0.4f, isOneWay = true))

        val spikes = listOf(
            SpikeHazard(x = 26.0f, y = 1.2f, width = 5.0f, height = 0.6f),
            SpikeHazard(x = 72.0f, y = 1.2f, width = 5.5f, height = 0.6f),
            SpikeHazard(x = 116.0f, y = 1.2f, width = 5.0f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 36.0f, y = 4.8f),
            TreasureChest(x = 94.0f, y = 5.1f),
            TreasureChest(x = 124.0f, y = 4.8f)
        )

        val enemies = listOf(
            Enemy(spawnX = 14.0f, spawnY = 1.2f, type = EnemyType.FLYING),
            Enemy(spawnX = 28.0f, spawnY = 8.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 42.0f, spawnY = 5.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 64.0f, spawnY = 1.2f, type = EnemyType.FLYING),
            Enemy(spawnX = 82.0f, spawnY = 9.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 98.0f, spawnY = 5.8f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 128.0f, spawnY = 1.2f, type = EnemyType.FLYING)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 26.0f,
                y = 1.2f,
                tabletId = "TABLET_29",
                title = "Tablet XXIX: Pusaran Gravitasi Terbalik",
                text = "Lantai menjadi langit, langit menjadi jurang. Hukum fisika dewa berputarbalik. Kaelen memimpin langkah dengan keyakinan batin yang teguh."
            )
        )

        return TowerFloor(
            floorNumber = 29,
            floorName = "Lantai 29: Gravity Inversion Vortex",
            mapBounds = Rectangle(-10f, -1f, 165f, 30f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 64.0f, y = 5.4f),
            exitPortal = StageExit(x = 145.0f, y = 1.2f),
            actTitle = "SAGA III: BASALT CRATER & ASTRAL RIFT",
            actSubtitle = "GRAVITY INVERSION VORTEX",
            loreTablets = loreTablets,
            gravityScale = 0.55f
        )
    }

    private fun buildFloor30(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val mirrorFloor = Color(0.10f, 0.10f, 0.14f, 1f)
        val obsidianFrame = Color(0.20f, 0.18f, 0.24f, 1f)
        val darkGlass = Color(0.28f, 0.26f, 0.35f, 1f)

        // The Nexus of Reflections — Arena Bos Duel Cermin Tiga Bayangan (Bentang Luas 110m)
        platforms.add(Platform(x = -10f, y = 0f, width = 120f, height = 1.2f, color = mirrorFloor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 26f, color = mirrorFloor))
        platforms.add(Platform(x = 109f, y = 1.2f, width = 1.2f, height = 26f, color = mirrorFloor))

        // Platform Berundak Obsidian Reflektif
        platforms.add(Platform(x = 6.0f, y = 3.6f, width = 6.5f, height = 0.5f, color = obsidianFrame))
        platforms.add(Platform(x = 18.0f, y = 5.8f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 30.0f, y = 4.5f, width = 8.5f, height = 0.5f, color = darkGlass))
        platforms.add(Platform(x = 46.0f, y = 6.5f, width = 7.5f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 62.0f, y = 4.2f, width = 8.5f, height = 0.5f, color = obsidianFrame))
        platforms.add(Platform(x = 76.0f, y = 6.8f, width = 7.0f, height = 0.4f, isOneWay = true))
        platforms.add(Platform(x = 90.0f, y = 4.0f, width = 7.5f, height = 0.5f, color = darkGlass))

        val chests = listOf(
            TreasureChest(x = 2.0f, y = 1.2f),
            TreasureChest(x = 100.0f, y = 1.2f)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 5.0f,
                y = 1.2f,
                tabletId = "TABLET_30",
                title = "Tablet XXX: Duel Cermin Tiga Bayangan",
                text = "Di lantai 30 berdiri cermin jiwa. Ketiga pahlawan harus menghadapi bayangan keraguan mereka masing-masing: rasa bersalah Kaelen, trauma Zephyr, dan beban keputusasaan Gorgon. Menanglah atas dirimu sendiri!"
            )
        )

        val boss = BossEnemy(
            spawnX = 65.0f,
            spawnY = 1.5f,
            type = BossType.SHADOW_DOPPELGANGER,
            customMaxHp = 1600f,
            customName = "THE SHADOW DOPPELGANGER"
        )
        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(30))

        return TowerFloor(
            floorNumber = 30,
            floorName = "Lantai 30: The Nexus of Reflections",
            mapBounds = Rectangle(-10f, -1f, 120f, 26f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = emptyList(),
            chests = chests,
            enemies = emptyList(),
            boss = boss,
            checkpoint = Checkpoint(x = 2.0f, y = 1.2f),
            exitPortal = StageExit(x = 98.0f, y = 1.2f),
            isBossFloor = true,
            actTitle = "SAGA III: BASALT CRATER & ASTRAL RIFT",
            actSubtitle = "THE NEXUS OF REFLECTIONS",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues
        )
    }

    // =========================================================================
    // SAGA IV: RETAKAN ASTRAL & KUIL GERHANA DARAH MALAKOR (LANTAI 31 - 40)
    // =========================================================================

    private fun buildFloor31(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val starLight = Color(0.20f, 0.45f, 0.75f, 0.9f)
        val obsidianFloating = Color(0.12f, 0.12f, 0.18f, 1f)

        // Dimensi di Balik Kanvas (Bentang Luas 150m, Anomali Gravitasi Rendah 0.55G, Celah Terkontrol <= 2.5m)
        platforms.add(Platform(x = -10f, y = 0f, width = 48f, height = 1.2f, color = starLight))
        platforms.add(Platform(x = 40.5f, y = 2.4f, width = 22f, height = 0.5f, isOneWay = true, color = obsidianFloating))
        platforms.add(Platform(x = 65.0f, y = 4.6f, width = 24f, height = 0.5f, isOneWay = true, color = starLight))
        platforms.add(Platform(x = 91.5f, y = 2.8f, width = 24f, height = 0.5f, isOneWay = true, color = obsidianFloating))
        platforms.add(Platform(x = 118.0f, y = 0f, width = 42f, height = 1.2f, color = starLight))

        val spikes = listOf(
            SpikeHazard(x = 42.0f, y = 0f, width = 18.0f, height = 0.8f),
            SpikeHazard(x = 94.0f, y = 0f, width = 22.0f, height = 0.8f)
        )

        val chests = listOf(
            TreasureChest(x = 80.0f, y = 5.2f),
            TreasureChest(x = 138.0f, y = 1.2f)
        )

        val enemies = listOf(
            Enemy(spawnX = 30.0f, spawnY = 1.2f, type = EnemyType.RANGED),
            Enemy(spawnX = 52.0f, spawnY = 3.3f, type = EnemyType.FLYING),
            Enemy(spawnX = 78.0f, spawnY = 5.7f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 108.0f, spawnY = 3.9f, type = EnemyType.FLYING),
            Enemy(spawnX = 132.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 14.0f,
                y = 1.2f,
                tabletId = "TABLET_31",
                title = "Tablet XXXI: Dimensi di Balik Kanvas",
                text = "Dinding menara lenyap total di sini. Kita melangkah di atas jembatan cahaya yang melayang di ruang hampa antar-galaksi. Realitas sedang diuji."
            )
        )

        val prismAltar = PrismAltar(x = 22.0f, y = 1.2f)
        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(31))

        return TowerFloor(
            floorNumber = 31,
            floorName = "Lantai 31: Dimension Beyond the Canvas",
            mapBounds = Rectangle(-10f, -1f, 160f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 75.0f, y = 5.2f),
            exitPortal = StageExit(x = 142.0f, y = 1.2f),
            actTitle = "SAGA IV: ASTRAL RIFT & CRIMSON ECLIPSE",
            actSubtitle = "DIMENSION BEYOND THE CANVAS",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues,
            gravityScale = 0.55f,
            prismAltar = prismAltar
        )
    }

    private fun buildFloor32(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val darkAstral = Color(0.14f, 0.14f, 0.22f, 1f)
        val floatingIsle = Color(0.22f, 0.28f, 0.42f, 1f)

        // Kepulauan Batu Melayang (Bentang Luas 160m, Gravitasi Rendah 0.50G, Celah Terkontrol <= 2.5m)
        platforms.add(Platform(x = -10f, y = 0f, width = 38f, height = 1.2f, color = darkAstral))
        platforms.add(Platform(x = 30.5f, y = 2.8f, width = 20f, height = 0.6f, isOneWay = true, color = floatingIsle))
        platforms.add(Platform(x = 53.0f, y = 5.2f, width = 22f, height = 0.6f, isOneWay = true, color = floatingIsle))
        platforms.add(Platform(x = 77.5f, y = 3.6f, width = 22f, height = 0.6f, isOneWay = true, color = floatingIsle))
        platforms.add(Platform(x = 102.0f, y = 5.8f, width = 20f, height = 0.6f, isOneWay = true, color = floatingIsle))
        platforms.add(Platform(x = 124.5f, y = 3.2f, width = 18f, height = 0.6f, isOneWay = true, color = floatingIsle))
        platforms.add(Platform(x = 145.0f, y = 0f, width = 25f, height = 1.2f, color = darkAstral))

        val spikes = listOf(
            SpikeHazard(x = 30.0f, y = 0f, width = 110.0f, height = 0.8f) // Jurang hampa luas di bawah
        )

        val chests = listOf(
            TreasureChest(x = 82.0f, y = 4.3f),
            TreasureChest(x = 152.0f, y = 1.2f)
        )

        val enemies = listOf(
            Enemy(spawnX = 22.0f, spawnY = 1.2f, type = EnemyType.FLYING),
            Enemy(spawnX = 40.0f, spawnY = 3.8f, type = EnemyType.RANGED),
            Enemy(spawnX = 60.0f, spawnY = 7.0f, type = EnemyType.FLYING),
            Enemy(spawnX = 84.0f, spawnY = 4.8f, type = EnemyType.FLYING),
            Enemy(spawnX = 108.0f, spawnY = 7.6f, type = EnemyType.RANGED),
            Enemy(spawnX = 130.0f, spawnY = 4.2f, type = EnemyType.SHIELDED)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 24.0f,
                y = 1.2f,
                tabletId = "TABLET_32",
                title = "Tablet XXXII: Kepulauan Batu Melayang",
                text = "Pulau-pulau batu obsidian melayang bebas di angkasa. Zephyr melompat dengan lincah membuka portal warna, sementara Gorgon dan Kaelen bersiap menyambut serbuan monster terbang."
            )
        )

        return TowerFloor(
            floorNumber = 32,
            floorName = "Lantai 32: Floating Obsidian Archipelago",
            mapBounds = Rectangle(-10f, -1f, 170f, 30f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 80.0f, y = 4.3f),
            exitPortal = StageExit(x = 155.0f, y = 1.2f),
            actTitle = "SAGA IV: ASTRAL RIFT & CRIMSON ECLIPSE",
            actSubtitle = "FLOATING OBSIDIAN ARCHIPELAGO",
            loreTablets = loreTablets,
            gravityScale = 0.50f
        )
    }

    private fun buildFloor33(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val warpStone = Color(0.18f, 0.16f, 0.28f, 1f)
        val beamPlatform = Color(0.35f, 0.50f, 0.85f, 0.85f)

        // Labirin Singularitas (Bentang Luas 165m, Gravitasi Rendah 0.50G, Altar Prisma di Tengah, Celah <= 2.5m)
        platforms.add(Platform(x = -10f, y = 0f, width = 38f, height = 1.2f, color = warpStone))
        platforms.add(Platform(x = 30.5f, y = 3.0f, width = 22f, height = 0.5f, isOneWay = true, color = beamPlatform))
        platforms.add(Platform(x = 55.0f, y = 5.4f, width = 22f, height = 0.5f, isOneWay = true, color = warpStone))
        platforms.add(Platform(x = 79.5f, y = 7.6f, width = 24f, height = 0.5f, isOneWay = true, color = beamPlatform))
        platforms.add(Platform(x = 106.0f, y = 5.2f, width = 20f, height = 0.5f, isOneWay = true, color = warpStone))
        platforms.add(Platform(x = 128.5f, y = 2.8f, width = 18f, height = 0.5f, isOneWay = true, color = beamPlatform))
        platforms.add(Platform(x = 149.0f, y = 0f, width = 26f, height = 1.2f, color = warpStone))

        val spikes = listOf(
            SpikeHazard(x = 34.0f, y = 0f, width = 108.0f, height = 0.8f)
        )

        val chests = listOf(
            TreasureChest(x = 86.0f, y = 8.2f),
            TreasureChest(x = 158.0f, y = 1.2f)
        )

        val enemies = listOf(
            Enemy(spawnX = 24.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 42.0f, spawnY = 4.1f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 62.0f, spawnY = 6.7f, type = EnemyType.FLYING),
            Enemy(spawnX = 90.0f, spawnY = 9.5f, type = EnemyType.RANGED),
            Enemy(spawnX = 114.0f, spawnY = 6.5f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 136.0f, spawnY = 3.7f, type = EnemyType.FLYING)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 20.0f,
                y = 1.2f,
                tabletId = "TABLET_33",
                title = "Tablet XXXIII: Labirin Singularitas",
                text = "Ruang melengkung pada sudut 90 derajat. Waktu melambat saat proyektil musuh mendekat. Manfaatkan Perfect Parry untuk memantulkan hukum waktu dewa."
            )
        )

        val prismAltar = PrismAltar(x = 60.0f, y = 6.0f)

        return TowerFloor(
            floorNumber = 33,
            floorName = "Lantai 33: Labyrinth of Singularity",
            mapBounds = Rectangle(-10f, -1f, 175f, 30f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 84.0f, y = 8.2f),
            exitPortal = StageExit(x = 160.0f, y = 1.2f),
            actTitle = "SAGA IV: ASTRAL RIFT & CRIMSON ECLIPSE",
            actSubtitle = "LABYRINTH OF SINGULARITY",
            loreTablets = loreTablets,
            gravityScale = 0.50f,
            prismAltar = prismAltar
        )
    }

    private fun buildFloor34(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val voidFloor = Color(0.12f, 0.12f, 0.18f, 1f)
        val windPlate = Color(0.24f, 0.32f, 0.48f, 1f)

        // Gema Suara Orang Mati (Bentang Luas 160m, Gravitasi Rendah 0.55G, Celah Terkontrol <= 2.5m)
        platforms.add(Platform(x = -10f, y = 0f, width = 38f, height = 1.2f, color = voidFloor))
        platforms.add(Platform(x = 30.5f, y = 2.6f, width = 22f, height = 0.5f, isOneWay = true, color = windPlate))
        platforms.add(Platform(x = 55.0f, y = 4.8f, width = 24f, height = 0.5f, isOneWay = true, color = voidFloor))
        platforms.add(Platform(x = 81.5f, y = 3.4f, width = 22f, height = 0.5f, isOneWay = true, color = windPlate))
        platforms.add(Platform(x = 106.0f, y = 5.6f, width = 20f, height = 0.5f, isOneWay = true, color = voidFloor))
        platforms.add(Platform(x = 128.5f, y = 2.8f, width = 18f, height = 0.5f, isOneWay = true, color = windPlate))
        platforms.add(Platform(x = 149.0f, y = 0f, width = 21f, height = 1.2f, color = voidFloor))

        val spikes = listOf(
            SpikeHazard(x = 32.0f, y = 0f, width = 110.0f, height = 0.8f)
        )

        val chests = listOf(
            TreasureChest(x = 65.0f, y = 5.4f),
            TreasureChest(x = 155.0f, y = 1.2f)
        )

        val enemies = listOf(
            Enemy(spawnX = 26.0f, spawnY = 1.2f, type = EnemyType.RANGED),
            Enemy(spawnX = 44.0f, spawnY = 3.3f, type = EnemyType.FLYING),
            Enemy(spawnX = 66.0f, spawnY = 5.9f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 90.0f, spawnY = 4.1f, type = EnemyType.FLYING),
            Enemy(spawnX = 112.0f, spawnY = 6.7f, type = EnemyType.MELEE),
            Enemy(spawnX = 134.0f, spawnY = 3.5f, type = EnemyType.RANGED)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 24.0f,
                y = 1.2f,
                tabletId = "TABLET_34",
                title = "Tablet XXXIV: Gema Suara Orang Mati",
                text = "Angin kosmis membawa bisikan jutaan jiwa yang telah larut di bumi bawah: 'Teruslah mendaki... jangan biarkan kematian kami sia-sia...'"
            )
        )

        return TowerFloor(
            floorNumber = 34,
            floorName = "Lantai 34: Echoes of the Fallen Void",
            mapBounds = Rectangle(-10f, -1f, 170f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 88.0f, y = 4.0f),
            exitPortal = StageExit(x = 156.0f, y = 1.2f),
            actTitle = "SAGA IV: ASTRAL RIFT & CRIMSON ECLIPSE",
            actSubtitle = "ECHOES OF THE FALLEN VOID",
            loreTablets = loreTablets,
            gravityScale = 0.55f
        )
    }

    private fun buildFloor35(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val nestStone = Color(0.16f, 0.12f, 0.22f, 1f)
        val crystalPerch = Color(0.32f, 0.22f, 0.44f, 1f)

        // The Void Chimera's Nest — Arena Bos Sarang Kehampaan (Bentang Luas 115m)
        platforms.add(Platform(x = -10f, y = 0f, width = 135f, height = 1.2f, color = nestStone))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.5f, height = 24f, color = nestStone))
        platforms.add(Platform(x = 123.5f, y = 1.2f, width = 1.5f, height = 24f, color = nestStone))

        // Platform suspensi udara untuk manuver taktis menghadapi kepala Chimera
        platforms.add(Platform(x = 18f, y = 4.2f, width = 8f, height = 0.4f, isOneWay = true, color = crystalPerch))
        platforms.add(Platform(x = 36f, y = 6.8f, width = 10f, height = 0.4f, isOneWay = true, color = crystalPerch))
        platforms.add(Platform(x = 58f, y = 8.5f, width = 12f, height = 0.4f, isOneWay = true, color = crystalPerch))
        platforms.add(Platform(x = 82f, y = 6.8f, width = 10f, height = 0.4f, isOneWay = true, color = crystalPerch))
        platforms.add(Platform(x = 100f, y = 4.2f, width = 8f, height = 0.4f, isOneWay = true, color = crystalPerch))

        val chests = listOf(
            TreasureChest(x = 8.0f, y = 1.2f),
            TreasureChest(x = 110.0f, y = 1.2f)
        )

        val boss = BossEnemy(
            spawnX = 64.0f,
            spawnY = 2.0f,
            type = BossType.AMETHYST_MATRON,
            customMaxHp = 1800f,
            customName = "THE VOID CHIMERA"
        )
        boss.hitbox.damage = 38f

        val loreTablets = listOf(
            LoreTablet(
                x = 12.0f,
                y = 1.2f,
                tabletId = "TABLET_35",
                title = "Tablet XXXV: Chimera Kehampaan",
                text = "Monster raksasa bertentakel bintang menjaga gerbang menuju kuil gerhana. Hancurkan ketiga kepalanya dengan keahlian khas masing-masing pahlawan."
            )
        )

        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(35))

        return TowerFloor(
            floorNumber = 35,
            floorName = "Lantai 35: The Void Chimera's Nest",
            mapBounds = Rectangle(-10f, -1f, 125f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = emptyList(),
            chests = chests,
            enemies = emptyList(),
            boss = boss,
            checkpoint = Checkpoint(x = 4.0f, y = 1.2f),
            exitPortal = StageExit(x = 105.0f, y = 1.2f),
            isBossFloor = true,
            actTitle = "SAGA IV: ASTRAL RIFT & CRIMSON ECLIPSE",
            actSubtitle = "THE VOID CHIMERA'S NEST",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues,
            gravityScale = 0.65f
        )
    }

    private fun buildFloor36(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val gothicStone = Color(0.12f, 0.08f, 0.10f, 1f)
        val crimsonArch = Color(0.28f, 0.10f, 0.14f, 1f)

        // Ambang Katedral Gotik (Bentang Luas 150m, Gerhana Bulan Merah, Celah Terkontrol <= 2.0m)
        platforms.add(Platform(x = -10f, y = 0f, width = 52f, height = 1.2f, color = gothicStone))
        platforms.add(Platform(x = 44f, y = 2.8f, width = 20f, height = 0.5f, isOneWay = true, color = crimsonArch))
        platforms.add(Platform(x = 66f, y = 5.0f, width = 22f, height = 0.5f, isOneWay = true, color = gothicStone))
        platforms.add(Platform(x = 90f, y = 3.2f, width = 22f, height = 0.5f, isOneWay = true, color = crimsonArch))
        platforms.add(Platform(x = 114f, y = 0f, width = 46f, height = 1.2f, color = gothicStone))

        val spikes = listOf(
            SpikeHazard(x = 52.0f, y = 0f, width = 12.0f, height = 0.8f),
            SpikeHazard(x = 88.0f, y = 0f, width = 24.0f, height = 0.8f)
        )

        val chests = listOf(
            TreasureChest(x = 76.0f, y = 5.5f),
            TreasureChest(x = 135.0f, y = 1.2f)
        )

        val enemies = listOf(
            Enemy(spawnX = 32.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 54.0f, spawnY = 3.7f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 76.0f, spawnY = 6.3f, type = EnemyType.RANGED),
            Enemy(spawnX = 100.0f, spawnY = 3.9f, type = EnemyType.FLYING),
            Enemy(spawnX = 125.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 18.0f,
                y = 1.2f,
                tabletId = "TABLET_36",
                title = "Tablet XXXVI: Ambang Katedral Gotik",
                text = "Dinding batu mulai retak digantikan pemandangan gotik hitam pekat di bawah gerhana bulan merah darah. Cahaya cyan kosmis perlahan memerah."
            )
        )

        val prismAltar = PrismAltar(x = 24.0f, y = 1.2f)
        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(36))

        return TowerFloor(
            floorNumber = 36,
            floorName = "Lantai 36: Gothic Cathedral Threshold",
            mapBounds = Rectangle(-10f, -1f, 160f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 75.0f, y = 5.5f),
            exitPortal = StageExit(x = 145.0f, y = 1.2f),
            actTitle = "SAGA IV: ASTRAL RIFT & CRIMSON ECLIPSE",
            actSubtitle = "GOTHIC CATHEDRAL THRESHOLD",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues,
            prismAltar = prismAltar
        )
    }

    private fun buildFloor37(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val velvetCarpet = Color(0.42f, 0.08f, 0.12f, 1f)
        val gothicPillar = Color(0.14f, 0.08f, 0.10f, 1f)

        // Koridor Beludru Merah (Bentang Luas 160m, Celah Terkontrol <= 2.0m)
        platforms.add(Platform(x = -10f, y = 0f, width = 180f, height = 1.2f, color = velvetCarpet))
        platforms.add(Platform(x = 24f, y = 3.0f, width = 20f, height = 0.5f, isOneWay = true, color = gothicPillar))
        platforms.add(Platform(x = 46f, y = 5.2f, width = 24f, height = 0.5f, isOneWay = true, color = gothicPillar))
        platforms.add(Platform(x = 72f, y = 3.8f, width = 24f, height = 0.5f, isOneWay = true, color = gothicPillar))
        platforms.add(Platform(x = 98f, y = 5.4f, width = 24f, height = 0.5f, isOneWay = true, color = gothicPillar))
        platforms.add(Platform(x = 124f, y = 3.2f, width = 22f, height = 0.5f, isOneWay = true, color = gothicPillar))

        val spikes = listOf(
            SpikeHazard(x = 42.0f, y = 1.2f, width = 7.0f, height = 0.6f),
            SpikeHazard(x = 98.0f, y = 1.2f, width = 5.0f, height = 0.6f)
        )

        val chests = listOf(
            TreasureChest(x = 58.0f, y = 5.7f),
            TreasureChest(x = 148.0f, y = 1.2f)
        )

        val enemies = listOf(
            Enemy(spawnX = 32.0f, spawnY = 3.9f, type = EnemyType.MELEE),
            Enemy(spawnX = 58.0f, spawnY = 6.5f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 85.0f, spawnY = 4.7f, type = EnemyType.RANGED),
            Enemy(spawnX = 112.0f, spawnY = 6.9f, type = EnemyType.FLYING),
            Enemy(spawnX = 138.0f, spawnY = 4.1f, type = EnemyType.SHIELDED)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 20.0f,
                y = 1.2f,
                tabletId = "TABLET_37",
                title = "Tablet XXXVII: Koridor Beludru Merah",
                text = "Tirai beludru katedral basah oleh tetesan darah. Musuh di lantai ini meregenerasi luka mereka di bawah sinar bulan merah. Pancing mereka ke bayangan pilar!"
            )
        )

        return TowerFloor(
            floorNumber = 37,
            floorName = "Lantai 37: Crimson Velvet Corridor",
            mapBounds = Rectangle(-10f, -1f, 170f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 84.0f, y = 4.3f),
            exitPortal = StageExit(x = 155.0f, y = 1.2f),
            actTitle = "SAGA IV: ASTRAL RIFT & CRIMSON ECLIPSE",
            actSubtitle = "CRIMSON VELVET CORRIDOR",
            loreTablets = loreTablets
        )
    }

    private fun buildFloor38(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val sacrificialStone = Color(0.18f, 0.08f, 0.10f, 1f)
        val marbleBalcony = Color(0.28f, 0.16f, 0.18f, 1f)

        // Altar Pengorbanan Anima (Bentang Luas 165m, Celah Terkontrol <= 2.0m)
        platforms.add(Platform(x = -10f, y = 0f, width = 62f, height = 1.2f, color = sacrificialStone))
        platforms.add(Platform(x = 54f, y = 3.2f, width = 22f, height = 0.5f, isOneWay = true, color = marbleBalcony))
        platforms.add(Platform(x = 78f, y = 0f, width = 46f, height = 1.2f, color = sacrificialStone))
        platforms.add(Platform(x = 126f, y = 3.2f, width = 18f, height = 0.5f, isOneWay = true, color = marbleBalcony))
        platforms.add(Platform(x = 146f, y = 0f, width = 29f, height = 1.2f, color = sacrificialStone))

        val spikes = listOf(
            SpikeHazard(x = 50.0f, y = 0f, width = 28.0f, height = 0.8f),
            SpikeHazard(x = 123.0f, y = 0f, width = 22.0f, height = 0.8f)
        )

        val chests = listOf(
            TreasureChest(x = 64.0f, y = 3.7f),
            TreasureChest(x = 158.0f, y = 1.2f)
        )

        val enemies = listOf(
            Enemy(spawnX = 35.0f, spawnY = 1.2f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 62.0f, spawnY = 4.1f, type = EnemyType.RANGED),
            Enemy(spawnX = 92.0f, spawnY = 1.2f, type = EnemyType.FLYING),
            Enemy(spawnX = 112.0f, spawnY = 1.2f, type = EnemyType.MELEE),
            Enemy(spawnX = 134.0f, spawnY = 4.3f, type = EnemyType.SHIELDED)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 22.0f,
                y = 1.2f,
                tabletId = "TABLET_38",
                title = "Tablet XXXVIII: Altar Pengorbanan Anima",
                text = "Di atas altar ini para bangsawan menjual rakyat jelata demi keabadian daging. Darah mereka kini menuntut balas pada siapa pun yang lewat."
            )
        )

        val bloodAltar = BloodAltar(x = 95.0f, y = 1.2f)
        val prismAltar = PrismAltar(x = 30.0f, y = 1.2f)

        return TowerFloor(
            floorNumber = 38,
            floorName = "Lantai 38: Altar of Anima Sacrifice",
            mapBounds = Rectangle(-10f, -1f, 175f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 88.0f, y = 1.2f),
            exitPortal = StageExit(x = 162.0f, y = 1.2f),
            actTitle = "SAGA IV: ASTRAL RIFT & CRIMSON ECLIPSE",
            actSubtitle = "ALTAR OF ANIMA SACRIFICE",
            loreTablets = loreTablets,
            bloodAltar = bloodAltar,
            prismAltar = prismAltar
        )
    }

    private fun buildFloor39(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val catacombStone = Color(0.10f, 0.08f, 0.12f, 1f)
        val tombLedge = Color(0.24f, 0.14f, 0.18f, 1f)

        // Katakomba Darah Abadi (Bentang Luas 160m, Celah Terkontrol <= 2.0m)
        platforms.add(Platform(x = -10f, y = 0f, width = 48f, height = 1.2f, color = catacombStone))
        platforms.add(Platform(x = 40f, y = 2.8f, width = 20f, height = 0.5f, isOneWay = true, color = tombLedge))
        platforms.add(Platform(x = 62f, y = 5.0f, width = 24f, height = 0.5f, isOneWay = true, color = catacombStone))
        platforms.add(Platform(x = 88f, y = 3.2f, width = 22f, height = 0.5f, isOneWay = true, color = tombLedge))
        platforms.add(Platform(x = 112f, y = 5.2f, width = 22f, height = 0.5f, isOneWay = true, color = catacombStone))
        platforms.add(Platform(x = 136f, y = 0f, width = 34f, height = 1.2f, color = catacombStone))

        val spikes = listOf(
            SpikeHazard(x = 42.0f, y = 0f, width = 18.0f, height = 0.8f),
            SpikeHazard(x = 84.0f, y = 0f, width = 26.0f, height = 0.8f)
        )

        val chests = listOf(
            TreasureChest(x = 72.0f, y = 5.5f),
            TreasureChest(x = 152.0f, y = 1.2f)
        )

        val enemies = listOf(
            Enemy(spawnX = 28.0f, spawnY = 1.2f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 48.0f, spawnY = 3.7f, type = EnemyType.MELEE),
            Enemy(spawnX = 70.0f, spawnY = 6.3f, type = EnemyType.RANGED),
            Enemy(spawnX = 96.0f, spawnY = 3.9f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 120.0f, spawnY = 6.5f, type = EnemyType.FLYING),
            Enemy(spawnX = 145.0f, spawnY = 1.2f, type = EnemyType.MELEE)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 20.0f,
                y = 1.2f,
                tabletId = "TABLET_39",
                title = "Tablet XXXIX: Katakomba Darah Abadi",
                text = "Peti-peti marmer berlumur darah terbuka. Pasukan algojo bertaring bangkit. Gorgon menahan ayunan kapak eksekusi, Zephyr menusuk jantung mereka dari bayang-bayang."
            )
        )

        return TowerFloor(
            floorNumber = 39,
            floorName = "Lantai 39: Catacombs of the Undying",
            mapBounds = Rectangle(-10f, -1f, 170f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            checkpoint = Checkpoint(x = 72.0f, y = 5.5f),
            exitPortal = StageExit(x = 155.0f, y = 1.2f),
            actTitle = "SAGA IV: ASTRAL RIFT & CRIMSON ECLIPSE",
            actSubtitle = "CATACOMBS OF THE UNDYING",
            loreTablets = loreTablets
        )
    }

    private fun buildFloor40(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val throneMarble = Color(0.10f, 0.05f, 0.08f, 1f)
        val stainedGlassBeam = Color(0.48f, 0.10f, 0.16f, 0.9f)

        // Throne of the Crimson Sovereign — Arena Bos Malakor (Bentang Luas 110m)
        platforms.add(Platform(x = -10f, y = 0f, width = 130f, height = 1.2f, color = throneMarble))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.5f, height = 24f, color = throneMarble))
        platforms.add(Platform(x = 118.5f, y = 1.2f, width = 1.5f, height = 24f, color = throneMarble))

        // Platform balkon gotik megah tempat Malakor melompat dan menghujamkan pedang
        platforms.add(Platform(x = 16f, y = 3.8f, width = 9f, height = 0.4f, isOneWay = true, color = stainedGlassBeam))
        platforms.add(Platform(x = 34f, y = 6.4f, width = 12f, height = 0.4f, isOneWay = true, color = stainedGlassBeam))
        platforms.add(Platform(x = 55f, y = 8.5f, width = 14f, height = 0.4f, isOneWay = true, color = stainedGlassBeam))
        platforms.add(Platform(x = 78f, y = 6.4f, width = 12f, height = 0.4f, isOneWay = true, color = stainedGlassBeam))
        platforms.add(Platform(x = 98f, y = 3.8f, width = 9f, height = 0.4f, isOneWay = true, color = stainedGlassBeam))

        val chests = listOf(
            TreasureChest(x = 6.0f, y = 1.2f),
            TreasureChest(x = 108.0f, y = 1.2f)
        )

        val boss = BossEnemy(
            spawnX = 62.0f,
            spawnY = 2.0f,
            type = BossType.CRIMSON_SOVEREIGN,
            customMaxHp = 2200f,
            customName = "MALAKOR THE CRIMSON SOVEREIGN"
        )
        boss.hitbox.damage = 42f

        val loreTablets = listOf(
            LoreTablet(
                x = 12.0f,
                y = 1.2f,
                tabletId = "TABLET_40",
                title = "Tablet XL: Runtuhnya Takhta Pangeran Darah",
                text = "Malakor tersungkur di depan takhtanya seraya memuntahkan tinta merah: 'Kalian kira kalian menang? Di atas lantai 40... para dewa tidak lagi bermain dengan darah... mereka bermain dengan hukum penciptaan!'"
            )
        )

        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(40))

        return TowerFloor(
            floorNumber = 40,
            floorName = "Lantai 40: Throne of the Crimson Sovereign",
            mapBounds = Rectangle(-10f, -1f, 120f, 28f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = emptyList(),
            chests = chests,
            enemies = emptyList(),
            boss = boss,
            checkpoint = Checkpoint(x = 4.0f, y = 1.2f),
            exitPortal = StageExit(x = 100.0f, y = 1.2f),
            isBossFloor = true,
            actTitle = "SAGA IV: ASTRAL RIFT & CRIMSON ECLIPSE",
            actSubtitle = "THRONE OF THE CRIMSON SOVEREIGN",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues
        )
    }

    // =========================================================================
    // SAGA V: PUNCAK KANVAS KOSMIS & THE GRAND CALLIGRAPHER (LANTAI 41 S/D 50)
    // =========================================================================

    private fun buildFloor41(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val baseColor = Color(0.92f, 0.94f, 0.98f, 1f)
        val wallColor = Color(0.80f, 0.84f, 0.92f, 1f)
        val platColor = Color(0.88f, 0.92f, 0.98f, 1f)
        val goldColor = Color(0.95f, 0.85f, 0.40f, 1f)

        // Lantai Dasar Marmer Putih Suci (145m)
        platforms.add(Platform(x = -10f, y = 0f, width = 155f, height = 1.2f, color = baseColor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 30f, color = wallColor))
        platforms.add(Platform(x = 143.8f, y = 1.2f, width = 1.2f, height = 30f, color = wallColor))

        // Pilar & Tangga Marmer Bercahaya
        // Sektor 1 (0m - 45m)
        platforms.add(Platform(x = 6.0f, y = 2.6f, width = 5.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 15.0f, y = 4.4f, width = 6.0f, height = 0.5f, color = goldColor))
        platforms.add(Platform(x = 24.5f, y = 6.2f, width = 5.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 24.5f, y = 2.8f, width = 4.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 33.5f, y = 4.6f, width = 6.0f, height = 0.5f, color = goldColor))

        // Sektor 2 (46m - 90m)
        platforms.add(Platform(x = 43.0f, y = 2.6f, width = 5.0f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 51.5f, y = 4.8f, width = 6.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 61.5f, y = 6.6f, width = 6.0f, height = 0.5f, color = goldColor))
        platforms.add(Platform(x = 71.0f, y = 4.8f, width = 5.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 79.5f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))

        // Sektor 3 (91m - 140m)
        platforms.add(Platform(x = 89.0f, y = 4.6f, width = 6.0f, height = 0.5f, color = goldColor))
        platforms.add(Platform(x = 98.5f, y = 6.4f, width = 6.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 98.5f, y = 2.8f, width = 5.0f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 108.5f, y = 4.6f, width = 6.0f, height = 0.5f, color = goldColor))
        platforms.add(Platform(x = 118.0f, y = 3.0f, width = 6.5f, height = 0.5f, color = platColor))

        val spikes = listOf(
            SpikeHazard(x = 18.0f, y = 1.2f, width = 3.5f, height = 0.5f),
            SpikeHazard(x = 54.0f, y = 1.2f, width = 4.0f, height = 0.5f),
            SpikeHazard(x = 92.0f, y = 1.2f, width = 4.0f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 26.5f, y = 6.7f),
            TreasureChest(x = 64.0f, y = 7.1f),
            TreasureChest(x = 101.5f, y = 6.9f)
        )

        val enemies = listOf(
            Enemy(spawnX = 17.0f, spawnY = 4.9f, type = EnemyType.FLYING),
            Enemy(spawnX = 26.0f, spawnY = 6.7f, type = EnemyType.RANGED),
            Enemy(spawnX = 38.0f, spawnY = 1.2f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 54.0f, spawnY = 5.3f, type = EnemyType.MELEE),
            Enemy(spawnX = 64.0f, spawnY = 7.1f, type = EnemyType.FLYING),
            Enemy(spawnX = 82.0f, spawnY = 3.3f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 101.0f, spawnY = 6.9f, type = EnemyType.RANGED),
            Enemy(spawnX = 120.0f, spawnY = 3.5f, type = EnemyType.FLYING)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 22.0f,
                y = 4.2f,
                tabletId = "TABLET_41",
                title = "Tablet XLI: Tangga Marmer Putih Suci",
                text = "Cahaya merah darah memudar, digantikan oleh kilau marmer putih bersih dan aurora keemasan. Warna-warna spektrum kuno mulai berbisik di udara menara."
            )
        )

        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(41))

        return TowerFloor(
            floorNumber = 41,
            floorName = "Lantai 41: Tangga Marmer Putih Suci",
            mapBounds = Rectangle(-10f, -1f, 155f, 32f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 65.0f, y = 6.0f),
            exitPortal = StageExit(x = 128.0f, y = 1.2f),
            isBossFloor = false,
            actTitle = "SAGA V: THE CELESTIAL CANVAS & PRIMORDIAL ZENITH",
            actSubtitle = "THE TRANSCENDENTAL MARBLE",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues,
            prismAltar = PrismAltar(x = 8.0f, y = 1.2f)
        )
    }

    private fun buildFloor42(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val baseColor = Color(0.90f, 0.93f, 0.97f, 1f)
        val wallColor = Color(0.78f, 0.82f, 0.90f, 1f)
        val platColor = Color(0.85f, 0.90f, 0.98f, 1f)
        val prismColor = Color(0.75f, 0.90f, 1.0f, 1f)

        platforms.add(Platform(x = -10f, y = 0f, width = 160f, height = 1.2f, color = baseColor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 30f, color = wallColor))
        platforms.add(Platform(x = 148.8f, y = 1.2f, width = 1.2f, height = 30f, color = wallColor))

        // Pilar-pilar Spektrum Purba
        platforms.add(Platform(x = 7.0f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 16.5f, y = 4.6f, width = 5.5f, height = 0.5f, color = prismColor))
        platforms.add(Platform(x = 25.5f, y = 6.4f, width = 6.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 35.0f, y = 4.6f, width = 5.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 44.5f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 54.0f, y = 4.8f, width = 6.5f, height = 0.5f, color = prismColor))
        platforms.add(Platform(x = 64.0f, y = 6.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 73.5f, y = 4.8f, width = 5.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 83.0f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 92.5f, y = 4.8f, width = 6.5f, height = 0.5f, color = prismColor))
        platforms.add(Platform(x = 102.5f, y = 6.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 112.0f, y = 4.6f, width = 5.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 121.5f, y = 3.0f, width = 6.5f, height = 0.5f, color = platColor))

        val spikes = listOf(
            SpikeHazard(x = 20.0f, y = 1.2f, width = 4.0f, height = 0.5f),
            SpikeHazard(x = 58.0f, y = 1.2f, width = 4.5f, height = 0.5f),
            SpikeHazard(x = 96.0f, y = 1.2f, width = 4.5f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 28.0f, y = 6.9f),
            TreasureChest(x = 66.5f, y = 7.3f),
            TreasureChest(x = 105.0f, y = 7.3f)
        )

        val enemies = listOf(
            Enemy(spawnX = 18.0f, spawnY = 5.1f, type = EnemyType.RANGED),
            Enemy(spawnX = 27.0f, spawnY = 6.9f, type = EnemyType.FLYING),
            Enemy(spawnX = 40.0f, spawnY = 1.2f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 56.0f, spawnY = 5.3f, type = EnemyType.MELEE),
            Enemy(spawnX = 66.0f, spawnY = 7.3f, type = EnemyType.FLYING),
            Enemy(spawnX = 86.0f, spawnY = 3.3f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 104.0f, spawnY = 7.3f, type = EnemyType.RANGED),
            Enemy(spawnX = 124.0f, spawnY = 3.5f, type = EnemyType.FLYING)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 24.0f,
                y = 4.5f,
                tabletId = "TABLET_42",
                title = "Tablet XLII: Pilar-Pilar Spektrum Purba",
                text = "Di dalam pilar marmer ini terperangkap warna biru samudra dan hijau hutan. Anima Core ketiga pahlawan beresonansi menciptakan perisai fajar pelindung."
            )
        )

        return TowerFloor(
            floorNumber = 42,
            floorName = "Lantai 42: Pilar Spektrum Purba",
            mapBounds = Rectangle(-10f, -1f, 160f, 32f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 70.0f, y = 6.2f),
            exitPortal = StageExit(x = 132.0f, y = 1.2f),
            isBossFloor = false,
            actTitle = "SAGA V: THE CELESTIAL CANVAS & PRIMORDIAL ZENITH",
            actSubtitle = "PILLARS OF SPECTRUM",
            loreTablets = loreTablets
        )
    }

    private fun buildFloor43(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val baseColor = Color(0.92f, 0.94f, 0.98f, 1f)
        val wallColor = Color(0.80f, 0.84f, 0.92f, 1f)
        val platColor = Color(0.88f, 0.92f, 0.98f, 1f)
        val nonEuclidColor = Color(0.82f, 0.85f, 1.0f, 1f)

        platforms.add(Platform(x = -10f, y = 0f, width = 165f, height = 1.2f, color = baseColor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 32f, color = wallColor))
        platforms.add(Platform(x = 153.8f, y = 1.2f, width = 1.2f, height = 32f, color = wallColor))

        // Geometri Non-Euclidean Asimetris
        platforms.add(Platform(x = 8.0f, y = 3.0f, width = 5.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 17.5f, y = 5.0f, width = 6.0f, height = 0.5f, color = nonEuclidColor))
        platforms.add(Platform(x = 27.5f, y = 7.0f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 27.5f, y = 3.2f, width = 4.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 37.0f, y = 5.2f, width = 5.5f, height = 0.5f, color = nonEuclidColor))

        platforms.add(Platform(x = 46.5f, y = 3.2f, width = 5.0f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 55.5f, y = 5.4f, width = 6.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 66.0f, y = 7.4f, width = 6.0f, height = 0.5f, color = nonEuclidColor))
        platforms.add(Platform(x = 76.0f, y = 5.2f, width = 5.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 85.5f, y = 3.2f, width = 6.0f, height = 0.5f, color = platColor))

        platforms.add(Platform(x = 95.5f, y = 5.2f, width = 6.5f, height = 0.5f, color = nonEuclidColor))
        platforms.add(Platform(x = 106.0f, y = 7.2f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 116.0f, y = 5.0f, width = 5.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 125.5f, y = 3.2f, width = 6.5f, height = 0.5f, color = platColor))

        val spikes = listOf(
            SpikeHazard(x = 22.0f, y = 1.2f, width = 4.0f, height = 0.5f),
            SpikeHazard(x = 60.0f, y = 1.2f, width = 4.5f, height = 0.5f),
            SpikeHazard(x = 100.0f, y = 1.2f, width = 4.5f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 30.0f, y = 7.5f),
            TreasureChest(x = 68.5f, y = 7.9f),
            TreasureChest(x = 108.5f, y = 7.7f)
        )

        val enemies = listOf(
            Enemy(spawnX = 19.0f, spawnY = 5.5f, type = EnemyType.FLYING),
            Enemy(spawnX = 29.0f, spawnY = 7.5f, type = EnemyType.RANGED),
            Enemy(spawnX = 42.0f, spawnY = 1.2f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 58.0f, spawnY = 5.9f, type = EnemyType.MELEE),
            Enemy(spawnX = 68.0f, spawnY = 7.9f, type = EnemyType.FLYING),
            Enemy(spawnX = 89.0f, spawnY = 3.7f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 108.0f, spawnY = 7.7f, type = EnemyType.RANGED),
            Enemy(spawnX = 128.0f, spawnY = 3.7f, type = EnemyType.FLYING)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 30.0f,
                y = 4.8f,
                tabletId = "TABLET_43",
                title = "Tablet XLIII: Geometri Non-Euclidean",
                text = "Platform melayang dalam koordinat matematika empat dimensi. Pemain harus memecahkan puzzle rotasi warna primer untuk membuka gerbang surga."
            )
        )

        return TowerFloor(
            floorNumber = 43,
            floorName = "Lantai 43: Geometri Non-Euclidean",
            mapBounds = Rectangle(-10f, -1f, 165f, 34f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 75.0f, y = 7.0f),
            exitPortal = StageExit(x = 138.0f, y = 1.2f),
            isBossFloor = false,
            actTitle = "SAGA V: THE CELESTIAL CANVAS & PRIMORDIAL ZENITH",
            actSubtitle = "NON-EUCLIDEAN SPHERES",
            loreTablets = loreTablets,
            prismAltar = PrismAltar(x = 10.0f, y = 1.2f)
        )
    }

    private fun buildFloor44(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val baseColor = Color(0.90f, 0.93f, 0.97f, 1f)
        val wallColor = Color(0.78f, 0.82f, 0.90f, 1f)
        val platColor = Color(0.85f, 0.90f, 0.98f, 1f)
        val inkOceanColor = Color(0.20f, 0.22f, 0.30f, 1f)

        platforms.add(Platform(x = -10f, y = 0f, width = 170f, height = 1.2f, color = baseColor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 34f, color = wallColor))
        platforms.add(Platform(x = 158.8f, y = 1.2f, width = 1.2f, height = 34f, color = wallColor))

        // Jembatan Marmer di Atas Lautan Tinta Purba
        platforms.add(Platform(x = 7.5f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 17.0f, y = 4.8f, width = 6.5f, height = 0.5f, color = inkOceanColor))
        platforms.add(Platform(x = 27.0f, y = 6.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 36.5f, y = 4.8f, width = 5.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 46.0f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 55.5f, y = 5.0f, width = 6.5f, height = 0.5f, color = inkOceanColor))
        platforms.add(Platform(x = 66.0f, y = 7.0f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 76.0f, y = 5.0f, width = 5.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 85.5f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 95.5f, y = 5.0f, width = 6.5f, height = 0.5f, color = inkOceanColor))
        platforms.add(Platform(x = 106.0f, y = 7.0f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 116.0f, y = 4.8f, width = 5.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 125.5f, y = 3.0f, width = 6.5f, height = 0.5f, color = platColor))

        val spikes = listOf(
            SpikeHazard(x = 21.0f, y = 1.2f, width = 4.5f, height = 0.5f),
            SpikeHazard(x = 60.0f, y = 1.2f, width = 4.5f, height = 0.5f),
            SpikeHazard(x = 100.0f, y = 1.2f, width = 4.5f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 29.5f, y = 7.3f),
            TreasureChest(x = 68.5f, y = 7.5f),
            TreasureChest(x = 108.5f, y = 7.5f)
        )

        val enemies = listOf(
            Enemy(spawnX = 18.5f, spawnY = 5.3f, type = EnemyType.FLYING),
            Enemy(spawnX = 28.5f, spawnY = 7.3f, type = EnemyType.RANGED),
            Enemy(spawnX = 41.0f, spawnY = 1.2f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 57.5f, spawnY = 5.5f, type = EnemyType.MELEE),
            Enemy(spawnX = 68.0f, spawnY = 7.5f, type = EnemyType.FLYING),
            Enemy(spawnX = 89.0f, spawnY = 3.3f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 108.0f, spawnY = 7.5f, type = EnemyType.RANGED),
            Enemy(spawnX = 128.0f, spawnY = 3.5f, type = EnemyType.FLYING)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 28.0f,
                y = 4.5f,
                tabletId = "TABLET_44",
                title = "Tablet XLIV: Lautan Tinta Penciptaan",
                text = "Di bawah jembatan marmer terhampar samudra tinta hitam murni tempat seluruh galaksi digambar. Ombak pasang tinta menyapu berkala; berpeganglah pada pilar iman!"
            )
        )

        return TowerFloor(
            floorNumber = 44,
            floorName = "Lantai 44: Samudra Tinta Penciptaan",
            mapBounds = Rectangle(-10f, -1f, 170f, 34f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 80.0f, y = 6.5f),
            exitPortal = StageExit(x = 142.0f, y = 1.2f),
            isBossFloor = false,
            actTitle = "SAGA V: THE CELESTIAL CANVAS & PRIMORDIAL ZENITH",
            actSubtitle = "OCEAN OF CREATION",
            loreTablets = loreTablets
        )
    }

    private fun buildFloor45(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val baseColor = Color(0.94f, 0.96f, 1.0f, 1f)
        val wallColor = Color(0.82f, 0.86f, 0.94f, 1f)
        val platColor = Color(0.88f, 0.92f, 0.98f, 1f)
        val geometricColor = Color(0.78f, 0.88f, 1.0f, 1f)

        // Balairung Malaikat Geometri (150m)
        platforms.add(Platform(x = -10f, y = 0f, width = 160f, height = 1.2f, color = baseColor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 30f, color = wallColor))
        platforms.add(Platform(x = 148.8f, y = 1.2f, width = 1.2f, height = 30f, color = wallColor))

        // Platform Arena Duel Melayang
        platforms.add(Platform(x = 8.0f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 18.0f, y = 4.8f, width = 6.5f, height = 0.5f, color = geometricColor))
        platforms.add(Platform(x = 32.0f, y = 3.0f, width = 8.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 45.0f, y = 5.2f, width = 7.5f, height = 0.5f, color = geometricColor))
        platforms.add(Platform(x = 60.0f, y = 3.2f, width = 8.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 73.0f, y = 5.4f, width = 8.5f, height = 0.5f, color = geometricColor))
        platforms.add(Platform(x = 88.0f, y = 3.2f, width = 8.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 102.0f, y = 5.0f, width = 7.5f, height = 0.5f, color = geometricColor))
        platforms.add(Platform(x = 115.0f, y = 3.0f, width = 7.0f, height = 0.5f, color = platColor))

        val chests = listOf(
            TreasureChest(x = 20.0f, y = 5.3f),
            TreasureChest(x = 76.0f, y = 5.9f),
            TreasureChest(x = 118.0f, y = 3.5f)
        )

        val boss = BossEnemy(
            spawnX = 75.0f,
            spawnY = 1.2f,
            type = BossType.SHADOW_DOPPELGANGER,
            customMaxHp = 7500f,
            customName = "Archon of Pure Geometry"
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 15.0f,
                y = 1.2f,
                tabletId = "TABLET_45",
                title = "Tablet XLV: Malaikat Geometri Suci",
                text = "Archon tanpa wajah menghadang. Serangannya berupa garis laser putih pemotong realitas. Zephyr melesat menembus celah laser sementara Kaelen dan Gorgon meruntuhkan intinya."
            )
        )

        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(45))

        return TowerFloor(
            floorNumber = 45,
            floorName = "Lantai 45: Balairung Malaikat Geometri",
            mapBounds = Rectangle(-10f, -1f, 160f, 32f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = emptyList(),
            chests = chests,
            enemies = emptyList(),
            boss = boss,
            checkpoint = Checkpoint(x = 5.0f, y = 1.2f),
            exitPortal = StageExit(x = 125.0f, y = 1.2f),
            isBossFloor = true,
            actTitle = "SAGA V: THE CELESTIAL CANVAS & PRIMORDIAL ZENITH",
            actSubtitle = "ARCHON OF PURE GEOMETRY",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues,
            prismAltar = PrismAltar(x = 8.0f, y = 1.2f)
        )
    }

    private fun buildFloor46(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val baseColor = Color(0.92f, 0.94f, 0.98f, 1f)
        val wallColor = Color(0.80f, 0.84f, 0.92f, 1f)
        val platColor = Color(0.88f, 0.92f, 0.98f, 1f)
        val harpColor = Color(0.98f, 0.92f, 0.70f, 1f)

        platforms.add(Platform(x = -10f, y = 0f, width = 165f, height = 1.2f, color = baseColor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 34f, color = wallColor))
        platforms.add(Platform(x = 153.8f, y = 1.2f, width = 1.2f, height = 34f, color = wallColor))

        // Tangga Fajar Kosmis Melayang
        platforms.add(Platform(x = 7.5f, y = 2.6f, width = 5.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 16.5f, y = 4.4f, width = 6.0f, height = 0.5f, color = harpColor))
        platforms.add(Platform(x = 26.0f, y = 6.4f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 35.5f, y = 4.6f, width = 5.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 45.0f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 54.5f, y = 4.8f, width = 6.5f, height = 0.5f, color = harpColor))
        platforms.add(Platform(x = 65.0f, y = 6.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 75.0f, y = 4.8f, width = 5.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 84.5f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 94.0f, y = 4.8f, width = 6.5f, height = 0.5f, color = harpColor))
        platforms.add(Platform(x = 104.5f, y = 6.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 114.5f, y = 4.6f, width = 5.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 124.0f, y = 3.0f, width = 6.5f, height = 0.5f, color = platColor))

        val spikes = listOf(
            SpikeHazard(x = 20.0f, y = 1.2f, width = 4.0f, height = 0.5f),
            SpikeHazard(x = 59.0f, y = 1.2f, width = 4.5f, height = 0.5f),
            SpikeHazard(x = 99.0f, y = 1.2f, width = 4.5f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 28.5f, y = 6.9f),
            TreasureChest(x = 67.5f, y = 7.3f),
            TreasureChest(x = 107.0f, y = 7.3f)
        )

        val enemies = listOf(
            Enemy(spawnX = 18.0f, spawnY = 4.9f, type = EnemyType.FLYING),
            Enemy(spawnX = 28.0f, spawnY = 6.9f, type = EnemyType.RANGED),
            Enemy(spawnX = 40.0f, spawnY = 1.2f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 56.0f, spawnY = 5.3f, type = EnemyType.MELEE),
            Enemy(spawnX = 67.0f, spawnY = 7.3f, type = EnemyType.FLYING),
            Enemy(spawnX = 87.0f, spawnY = 3.3f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 106.0f, spawnY = 7.3f, type = EnemyType.RANGED),
            Enemy(spawnX = 126.0f, spawnY = 3.5f, type = EnemyType.FLYING)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 25.0f,
                y = 4.5f,
                tabletId = "TABLET_46",
                title = "Tablet XLVI: Tangga Fajar Kosmis",
                text = "Setiap anak tangga yang diinjak memancarkan nada musik sakral. Menara berguncang menyambut kedatangan tiga ksatria fana di depan singgasana dewa."
            )
        )

        return TowerFloor(
            floorNumber = 46,
            floorName = "Lantai 46: Tangga Fajar Kosmis",
            mapBounds = Rectangle(-10f, -1f, 165f, 34f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 75.0f, y = 6.5f),
            exitPortal = StageExit(x = 136.0f, y = 1.2f),
            isBossFloor = false,
            actTitle = "SAGA V: THE CELESTIAL CANVAS & PRIMORDIAL ZENITH",
            actSubtitle = "THE DAWN HARP STAIRCASE",
            loreTablets = loreTablets
        )
    }

    private fun buildFloor47(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val baseColor = Color(0.90f, 0.93f, 0.97f, 1f)
        val wallColor = Color(0.78f, 0.82f, 0.90f, 1f)
        val platColor = Color(0.85f, 0.90f, 0.98f, 1f)
        val titanPillarColor = Color(0.94f, 0.90f, 0.78f, 1f)

        platforms.add(Platform(x = -10f, y = 0f, width = 170f, height = 1.2f, color = baseColor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 34f, color = wallColor))
        platforms.add(Platform(x = 158.8f, y = 1.2f, width = 1.2f, height = 34f, color = wallColor))

        // Ruang Tunggu Arsitek - Pilar-pilar Raksasa
        platforms.add(Platform(x = 8.0f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 18.0f, y = 4.8f, width = 6.5f, height = 0.5f, color = titanPillarColor))
        platforms.add(Platform(x = 28.5f, y = 6.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 38.0f, y = 4.8f, width = 5.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 47.5f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 57.0f, y = 5.0f, width = 6.5f, height = 0.5f, color = titanPillarColor))
        platforms.add(Platform(x = 67.5f, y = 7.0f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 77.5f, y = 5.0f, width = 5.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 87.0f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 97.0f, y = 5.0f, width = 6.5f, height = 0.5f, color = titanPillarColor))
        platforms.add(Platform(x = 107.5f, y = 7.0f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 117.5f, y = 4.8f, width = 5.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 127.0f, y = 3.0f, width = 6.5f, height = 0.5f, color = platColor))

        val spikes = listOf(
            SpikeHazard(x = 22.0f, y = 1.2f, width = 4.5f, height = 0.5f),
            SpikeHazard(x = 62.0f, y = 1.2f, width = 4.5f, height = 0.5f),
            SpikeHazard(x = 102.0f, y = 1.2f, width = 4.5f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 31.0f, y = 7.3f),
            TreasureChest(x = 70.0f, y = 7.5f),
            TreasureChest(x = 110.0f, y = 7.5f)
        )

        val enemies = listOf(
            Enemy(spawnX = 19.5f, spawnY = 5.3f, type = EnemyType.RANGED),
            Enemy(spawnX = 30.5f, spawnY = 7.3f, type = EnemyType.FLYING),
            Enemy(spawnX = 43.0f, spawnY = 1.2f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 59.0f, spawnY = 5.5f, type = EnemyType.MELEE),
            Enemy(spawnX = 70.0f, spawnY = 7.5f, type = EnemyType.FLYING),
            Enemy(spawnX = 91.0f, spawnY = 3.3f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 110.0f, spawnY = 7.5f, type = EnemyType.RANGED),
            Enemy(spawnX = 130.0f, spawnY = 3.5f, type = EnemyType.FLYING)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 30.0f,
                y = 5.0f,
                tabletId = "TABLET_47",
                title = "Tablet XLVII: Ruang Tunggu Para Arsitek",
                text = "Lukisan-lukisan sejarah seluruh peradaban yang pernah diciptakan dan dihapus terpampang di dinding pilar setinggi seratus meter. Kita bukan peradaban pertama yang dihancurkan."
            )
        )

        return TowerFloor(
            floorNumber = 47,
            floorName = "Lantai 47: Ruang Tunggu Para Arsitek",
            mapBounds = Rectangle(-10f, -1f, 170f, 34f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 80.0f, y = 6.5f),
            exitPortal = StageExit(x = 142.0f, y = 1.2f),
            isBossFloor = false,
            actTitle = "SAGA V: THE CELESTIAL CANVAS & PRIMORDIAL ZENITH",
            actSubtitle = "ANTECHAMBER OF ARCHITECTS",
            loreTablets = loreTablets,
            prismAltar = PrismAltar(x = 10.0f, y = 1.2f)
        )
    }

    private fun buildFloor48(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val baseColor = Color(0.94f, 0.96f, 1.0f, 1f)
        val wallColor = Color(0.82f, 0.86f, 0.94f, 1f)
        val platColor = Color(0.88f, 0.92f, 0.98f, 1f)
        val thresholdColor = Color(1.0f, 0.92f, 0.75f, 1f)

        platforms.add(Platform(x = -10f, y = 0f, width = 175f, height = 1.2f, color = baseColor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 36f, color = wallColor))
        platforms.add(Platform(x = 163.8f, y = 1.2f, width = 1.2f, height = 36f, color = wallColor))

        // Ambang Kanvas Primordial
        platforms.add(Platform(x = 8.5f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 18.5f, y = 4.8f, width = 6.5f, height = 0.5f, color = thresholdColor))
        platforms.add(Platform(x = 29.0f, y = 6.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 38.5f, y = 4.8f, width = 5.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 48.0f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 58.0f, y = 5.0f, width = 6.5f, height = 0.5f, color = thresholdColor))
        platforms.add(Platform(x = 68.5f, y = 7.0f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 78.5f, y = 5.0f, width = 5.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 88.0f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 98.0f, y = 5.0f, width = 6.5f, height = 0.5f, color = thresholdColor))
        platforms.add(Platform(x = 108.5f, y = 7.0f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 118.5f, y = 4.8f, width = 5.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 128.5f, y = 3.0f, width = 6.5f, height = 0.5f, color = platColor))

        val spikes = listOf(
            SpikeHazard(x = 22.0f, y = 1.2f, width = 4.5f, height = 0.5f),
            SpikeHazard(x = 62.0f, y = 1.2f, width = 4.5f, height = 0.5f),
            SpikeHazard(x = 102.0f, y = 1.2f, width = 4.5f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 31.5f, y = 7.3f),
            TreasureChest(x = 71.0f, y = 7.5f),
            TreasureChest(x = 111.0f, y = 7.5f)
        )

        val enemies = listOf(
            Enemy(spawnX = 20.0f, spawnY = 5.3f, type = EnemyType.FLYING),
            Enemy(spawnX = 31.0f, spawnY = 7.3f, type = EnemyType.RANGED),
            Enemy(spawnX = 44.0f, spawnY = 1.2f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 60.0f, spawnY = 5.5f, type = EnemyType.MELEE),
            Enemy(spawnX = 71.0f, spawnY = 7.5f, type = EnemyType.FLYING),
            Enemy(spawnX = 92.0f, spawnY = 3.3f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 111.0f, spawnY = 7.5f, type = EnemyType.RANGED),
            Enemy(spawnX = 132.0f, spawnY = 3.5f, type = EnemyType.FLYING)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 25.0f,
                y = 4.8f,
                tabletId = "TABLET_48",
                title = "Tablet XLVIII: Ambang Kanvas Primordial",
                text = "Aria memancarkan cahaya pendar terangnya: 'Kaelen, Zephyr, Gorgon... saat kalian melangkah menembus pintu ini, tidak ada lagi jalan kembali. Takdir seluruh Aethelgard ada di tangan kalian.'"
            )
        )

        return TowerFloor(
            floorNumber = 48,
            floorName = "Lantai 48: Ambang Kanvas Primordial",
            mapBounds = Rectangle(-10f, -1f, 175f, 36f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 85.0f, y = 6.5f),
            exitPortal = StageExit(x = 146.0f, y = 1.2f),
            isBossFloor = false,
            actTitle = "SAGA V: THE CELESTIAL CANVAS & PRIMORDIAL ZENITH",
            actSubtitle = "PRIMORDIAL THRESHOLD",
            loreTablets = loreTablets,
            bloodAltar = BloodAltar(x = 70.0f, y = 1.2f),
            prismAltar = PrismAltar(x = 8.0f, y = 1.2f)
        )
    }

    private fun buildFloor49(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val baseColor = Color(0.96f, 0.96f, 1.0f, 1f)
        val wallColor = Color(0.85f, 0.88f, 0.95f, 1f)
        val platColor = Color(0.90f, 0.94f, 1.0f, 1f)
        val goldenColonnadeColor = Color(1.0f, 0.88f, 0.45f, 1f)

        platforms.add(Platform(x = -10f, y = 0f, width = 180f, height = 1.2f, color = baseColor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 36f, color = wallColor))
        platforms.add(Platform(x = 168.8f, y = 1.2f, width = 1.2f, height = 36f, color = wallColor))

        // Kolonade Emas Sumpah Triad
        platforms.add(Platform(x = 9.0f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 19.5f, y = 4.8f, width = 6.5f, height = 0.5f, color = goldenColonnadeColor))
        platforms.add(Platform(x = 30.5f, y = 6.8f, width = 6.5f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 40.5f, y = 4.8f, width = 5.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 50.0f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 60.5f, y = 5.0f, width = 6.5f, height = 0.5f, color = goldenColonnadeColor))
        platforms.add(Platform(x = 71.5f, y = 7.0f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 81.5f, y = 5.0f, width = 5.5f, height = 0.35f, isOneWay = true))

        platforms.add(Platform(x = 91.0f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 101.5f, y = 5.0f, width = 6.5f, height = 0.5f, color = goldenColonnadeColor))
        platforms.add(Platform(x = 112.5f, y = 7.0f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 122.5f, y = 4.8f, width = 5.5f, height = 0.35f, isOneWay = true))
        platforms.add(Platform(x = 132.5f, y = 3.0f, width = 6.5f, height = 0.5f, color = platColor))

        val spikes = listOf(
            SpikeHazard(x = 24.0f, y = 1.2f, width = 4.5f, height = 0.5f),
            SpikeHazard(x = 65.0f, y = 1.2f, width = 4.5f, height = 0.5f),
            SpikeHazard(x = 106.0f, y = 1.2f, width = 4.5f, height = 0.5f)
        )

        val chests = listOf(
            TreasureChest(x = 33.0f, y = 7.3f),
            TreasureChest(x = 74.0f, y = 7.5f),
            TreasureChest(x = 115.0f, y = 7.5f)
        )

        val enemies = listOf(
            Enemy(spawnX = 21.0f, spawnY = 5.3f, type = EnemyType.FLYING),
            Enemy(spawnX = 33.0f, spawnY = 7.3f, type = EnemyType.RANGED),
            Enemy(spawnX = 46.0f, spawnY = 1.2f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 63.0f, spawnY = 5.5f, type = EnemyType.MELEE),
            Enemy(spawnX = 74.0f, spawnY = 7.5f, type = EnemyType.FLYING),
            Enemy(spawnX = 95.0f, spawnY = 3.3f, type = EnemyType.SHIELDED),
            Enemy(spawnX = 115.0f, spawnY = 7.5f, type = EnemyType.RANGED),
            Enemy(spawnX = 136.0f, spawnY = 3.5f, type = EnemyType.FLYING)
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 35.0f,
                y = 5.2f,
                tabletId = "TABLET_49",
                title = "Tablet XLIX: Sumpah Triad of Dawn",
                text = "Ketiga pahlawan menyatukan bilah senjata mereka di ambang gerbang emas: 'Demi warna yang dirampas, demi jiwa yang larut, demi fajar yang merdeka: hari ini, dewa takdir akan jatuh!'"
            )
        )

        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(49))

        return TowerFloor(
            floorNumber = 49,
            floorName = "Lantai 49: Kolonade Emas Sumpah Triad",
            mapBounds = Rectangle(-10f, -1f, 180f, 36f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 85.0f, y = 6.5f),
            exitPortal = StageExit(x = 150.0f, y = 1.2f),
            isBossFloor = false,
            actTitle = "SAGA V: THE CELESTIAL CANVAS & PRIMORDIAL ZENITH",
            actSubtitle = "VOW OF THE TRIAD OF DAWN",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues
        )
    }

    private fun buildFloor50(): TowerFloor {
        val platforms = mutableListOf<Platform>()
        val baseColor = Color(0.98f, 0.98f, 1.0f, 1f)
        val wallColor = Color(0.88f, 0.90f, 0.98f, 1f)
        val platColor = Color(0.92f, 0.95f, 1.0f, 1f)
        val divineGold = Color(1.0f, 0.90f, 0.50f, 1f)

        // Singgasana Kanvas Primordial - Piringan Cakrawala Melayang (120m)
        platforms.add(Platform(x = -10f, y = 0f, width = 130f, height = 1.2f, color = baseColor))
        platforms.add(Platform(x = -10f, y = 1.2f, width = 1.2f, height = 30f, color = wallColor))
        platforms.add(Platform(x = 118.8f, y = 1.2f, width = 1.2f, height = 30f, color = wallColor))

        // Panggung Singgasana Dewa Bertingkat
        platforms.add(Platform(x = 8.0f, y = 2.8f, width = 6.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 18.0f, y = 4.8f, width = 6.5f, height = 0.5f, color = divineGold))
        platforms.add(Platform(x = 32.0f, y = 3.2f, width = 8.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 45.0f, y = 5.4f, width = 8.0f, height = 0.5f, color = divineGold))
        platforms.add(Platform(x = 58.0f, y = 3.2f, width = 8.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 71.0f, y = 5.4f, width = 8.5f, height = 0.5f, color = divineGold))
        platforms.add(Platform(x = 85.0f, y = 3.2f, width = 8.0f, height = 0.5f, color = platColor))
        platforms.add(Platform(x = 98.0f, y = 5.0f, width = 7.5f, height = 0.5f, color = divineGold))

        val chests = listOf(
            TreasureChest(x = 20.0f, y = 5.3f),
            TreasureChest(x = 74.0f, y = 5.9f),
            TreasureChest(x = 101.0f, y = 5.5f)
        )

        val boss = BossEnemy(
            spawnX = 70.0f,
            spawnY = 1.2f,
            type = BossType.GRAND_CALLIGRAPHER,
            customMaxHp = 15000f,
            customName = "The Grand Calligrapher"
        )

        val loreTablets = listOf(
            LoreTablet(
                x = 15.0f,
                y = 1.2f,
                tabletId = "TABLET_50",
                title = "Tablet L: Patahnya Pena Takdir Semesta",
                text = "Bilah pedang Kaelen, belati Zephyr, dan godam Gorgon menghantam tepat di tengah batang The Primordial Stylus. KRAAAAKKK! Pena terbelah dua. Cawan tinta meledak. Fajar kosmis merekah. Kita bukan lagi coretan dewa; kita adalah pelukis dari hidup kita sendiri!"
            )
        )

        val storyDialogues = listOfNotNull(DialogueRegistry.getSceneForFloor(50))

        return TowerFloor(
            floorNumber = 50,
            floorName = "Lantai 50: The Zenith of Destiny - The Grand Calligrapher",
            mapBounds = Rectangle(-10f, -1f, 130f, 32f),
            spawnX = 0f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = emptyList(),
            chests = chests,
            enemies = emptyList(),
            boss = boss,
            checkpoint = Checkpoint(x = 4.0f, y = 1.2f),
            exitPortal = StageExit(x = 105.0f, y = 1.2f),
            isBossFloor = true,
            actTitle = "SAGA V: THE CELESTIAL CANVAS & PRIMORDIAL ZENITH",
            actSubtitle = "THE ZENITH OF DESTINY",
            loreTablets = loreTablets,
            storyDialogues = storyDialogues,
            prismAltar = PrismAltar(x = 6.0f, y = 1.2f)
        )
    }

    // =========================================================================
    // POST-GAME: PARADOKS ENDLESS SPIRE (LANTAI 51 KE ATAS)
    // =========================================================================

    fun buildEndlessFloor(floorNumber: Int, mutator: FloorMutator): TowerFloor {
        val endlessRank = (floorNumber - 50).coerceAtLeast(1)
        val hpScale = 1.0f + endlessRank * 0.15f
        val dmgScale = (1.0f + endlessRank * 0.12f) * mutator.enemyDamageMultiplier
        val isBossFloor = (floorNumber % 5 == 0)

        val platforms = mutableListOf<Platform>()
        val spikes = mutableListOf<SpikeHazard>()
        val chests = mutableListOf<TreasureChest>()
        val enemies = mutableListOf<Enemy>()

        if (isBossFloor) {
            // Apex Boss Hall Variant
            platforms.add(Platform(x = -5f, y = 0f, width = 34f, height = 1.2f, color = Color(0.18f, 0.10f, 0.22f, 1f)))
            platforms.add(Platform(x = -5f, y = 1.2f, width = 1.2f, height = 16f, color = Color(0.12f, 0.06f, 0.16f, 1f)))
            platforms.add(Platform(x = 27.8f, y = 1.2f, width = 1.2f, height = 16f, color = Color(0.12f, 0.06f, 0.16f, 1f)))

            platforms.add(Platform(x = 2.5f, y = 2.9f, width = 4.5f, height = 0.35f, isOneWay = true))
            platforms.add(Platform(x = 16.5f, y = 2.9f, width = 4.5f, height = 0.35f, isOneWay = true))
            platforms.add(Platform(x = 9.5f, y = 4.8f, width = 5.0f, height = 0.35f, isOneWay = true))

            chests.add(TreasureChest(x = 0.5f, y = 1.2f))

            // Rotasi Bos Menara di Endless Spire
            val bossType = when ((floorNumber / 5) % 5) {
                1 -> BossType.AMETHYST_MATRON
                2 -> BossType.SHADOW_DOPPELGANGER
                3 -> BossType.CRIMSON_SOVEREIGN
                4 -> BossType.GRAND_CALLIGRAPHER
                else -> BossType.TOWER_GUARDIAN
            }

            val boss = BossEnemy(spawnX = 18.0f, spawnY = 1.5f, type = bossType)
            boss.health.setMaxHp(boss.health.maxHp * hpScale)
            boss.hitbox.damage *= dmgScale

            return TowerFloor(
                floorNumber = floorNumber,
                floorName = "Endless Spire: Floor $floorNumber [BOSS: ${mutator.title}]",
                mapBounds = Rectangle(-5f, -1f, 34f, 17f),
                spawnX = 0f,
                spawnY = 1.5f,
                platforms = platforms,
                spikes = emptyList(),
                chests = chests,
                enemies = emptyList(),
                boss = boss,
                checkpoint = Checkpoint(x = 1.5f, y = 1.2f),
                exitPortal = StageExit(x = 24.5f, y = 1.2f),
                isBossFloor = true,
                actTitle = "EPILOGUE: THE ENDLESS PARADOX",
                actSubtitle = "FLOOR $floorNumber",
                environmentalProps = getEnvironmentalPropsForFloor(floorNumber)
            )
        }

        // Non-Boss Procedural Variants (0 = Ascent, 1 = Gauntlet, 2 = Colosseum)
        val variant = floorNumber % 3
        val mapWidth = 42f
        val mapHeight = 16f

        platforms.add(Platform(x = -8f, y = 0f, width = mapWidth, height = 1f, color = Color(0.15f, 0.18f, 0.25f, 1f)))
        platforms.add(Platform(x = -8f, y = 1f, width = 1f, height = mapHeight, color = Color(0.10f, 0.12f, 0.18f, 1f)))
        platforms.add(Platform(x = mapWidth - 9f, y = 1f, width = 1f, height = mapHeight, color = Color(0.10f, 0.12f, 0.18f, 1f)))

        when (variant) {
            0 -> {
                // Vertical Ascent Spire (Kenaikan bertahap 1.45m - 1.75m)
                platforms.add(Platform(x = 2f, y = 2.4f, width = 4.0f, height = 0.35f, isOneWay = true))
                platforms.add(Platform(x = 7.0f, y = 4.0f, width = 4.5f, height = 0.5f, color = Color(0.22f, 0.28f, 0.38f, 1f)))
                platforms.add(Platform(x = 12.5f, y = 5.6f, width = 4.0f, height = 0.35f, isOneWay = true))
                platforms.add(Platform(x = 17.5f, y = 4.0f, width = 4.5f, height = 0.5f, color = Color(0.22f, 0.28f, 0.38f, 1f)))
                platforms.add(Platform(x = 23.0f, y = 5.6f, width = 4.5f, height = 0.35f, isOneWay = true))
                platforms.add(Platform(x = 28.5f, y = 3.8f, width = 3.5f, height = 0.35f, isOneWay = true))

                spikes.add(SpikeHazard(x = 4.5f, y = 1.0f, width = 2.0f, height = 0.5f))
                spikes.add(SpikeHazard(x = 14.5f, y = 1.0f, width = 2.5f, height = 0.5f))
                chests.add(TreasureChest(x = 13.5f, y = 6.0f))
            }
            1 -> {
                // Gauntlet of Peril
                platforms.add(Platform(x = 2.5f, y = 2.4f, width = 4.5f, height = 0.5f, color = Color(0.24f, 0.32f, 0.44f, 1f)))
                platforms.add(Platform(x = 8.5f, y = 3.8f, width = 4.0f, height = 0.35f, isOneWay = true))
                platforms.add(Platform(x = 14.0f, y = 5.4f, width = 4.5f, height = 0.5f, color = Color(0.24f, 0.32f, 0.44f, 1f)))
                platforms.add(Platform(x = 20.0f, y = 4.0f, width = 4.5f, height = 0.5f, color = Color(0.24f, 0.32f, 0.44f, 1f)))
                platforms.add(Platform(x = 26.0f, y = 5.6f, width = 4.5f, height = 0.35f, isOneWay = true))

                spikes.add(SpikeHazard(x = 7.5f, y = 1.0f, width = 2.5f, height = 0.5f))
                spikes.add(SpikeHazard(x = 19.0f, y = 1.0f, width = 2.5f, height = 0.5f))
                chests.add(TreasureChest(x = 15.5f, y = 6.0f))
            }
            else -> {
                // Tiered Colosseum (Puncak tengah dapat diakses dari kedua sisi)
                platforms.add(Platform(x = 2.5f, y = 2.4f, width = 5.0f, height = 0.5f, color = Color(0.26f, 0.35f, 0.48f, 1f)))
                platforms.add(Platform(x = 9.0f, y = 4.2f, width = 5.0f, height = 0.5f, color = Color(0.26f, 0.35f, 0.48f, 1f)))
                platforms.add(Platform(x = 18.0f, y = 4.2f, width = 5.0f, height = 0.5f, color = Color(0.26f, 0.35f, 0.48f, 1f)))
                platforms.add(Platform(x = 24.5f, y = 2.4f, width = 5.0f, height = 0.5f, color = Color(0.26f, 0.35f, 0.48f, 1f)))

                platforms.add(Platform(x = 13.5f, y = 6.0f, width = 5.0f, height = 0.35f, isOneWay = true))

                spikes.add(SpikeHazard(x = 14.5f, y = 1.0f, width = 3.0f, height = 0.5f))
                chests.add(TreasureChest(x = 15.5f, y = 6.5f))
            }
        }

        if (mutator == FloorMutator.SPIKE_FRENZY) {
            spikes.add(SpikeHazard(x = 1.0f, y = 1.0f, width = 2.0f, height = 0.5f))
            spikes.add(SpikeHazard(x = 25.0f, y = 1.0f, width = 2.5f, height = 0.5f))
        }

        // Spawn scaled enemies across all 4 archetypes
        enemies.add(Enemy(spawnX = 5.0f, spawnY = 1.2f, type = EnemyType.SHIELDED))
        enemies.add(Enemy(spawnX = 11.0f, spawnY = 5.0f, type = EnemyType.RANGED))
        enemies.add(Enemy(spawnX = 17.0f, spawnY = 6.0f, type = EnemyType.FLYING))
        enemies.add(Enemy(spawnX = 23.0f, spawnY = 5.0f, type = EnemyType.RANGED))
        enemies.add(Enemy(spawnX = 27.0f, spawnY = 1.2f, type = EnemyType.MELEE))

        for (enemy in enemies) {
            enemy.health.setMaxHp(enemy.health.maxHp * hpScale)
            enemy.hitbox.damage *= dmgScale
        }

        return TowerFloor(
            floorNumber = floorNumber,
            floorName = "Endless Spire: Floor $floorNumber [${mutator.title}]",
            mapBounds = Rectangle(-8f, -1f, mapWidth, mapHeight),
            spawnX = -1f,
            spawnY = 1.5f,
            platforms = platforms,
            spikes = spikes,
            chests = chests,
            enemies = enemies,
            boss = null,
            checkpoint = Checkpoint(x = 16.0f, y = 6.0f),
            exitPortal = StageExit(x = mapWidth - 12f, y = 1.0f),
            isBossFloor = false,
            actTitle = "EPILOGUE: THE ENDLESS PARADOX",
            actSubtitle = "FLOOR $floorNumber",
            environmentalProps = getEnvironmentalPropsForFloor(floorNumber),
            bloodAltar = if (floorNumber % 3 == 0) BloodAltar(x = 13.5f, y = 1.0f) else null
        )
    }
}
