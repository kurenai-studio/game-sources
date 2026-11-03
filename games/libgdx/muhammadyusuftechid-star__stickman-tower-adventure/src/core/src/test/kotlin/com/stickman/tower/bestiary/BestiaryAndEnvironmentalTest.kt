package com.stickman.tower.bestiary

import com.stickman.tower.endless.FloorMutator
import com.stickman.tower.rpg.SaveData
import com.stickman.tower.world.EnvironmentalProp
import com.stickman.tower.world.PropType
import com.stickman.tower.world.TowerFloor
import com.stickman.tower.world.TowerLevelBuilder
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Unit Test Komprehensif untuk Penceritaan Lingkungan, Bestiarium Lapangan & Kurasi Visual (Fase 19).
 */
class BestiaryAndEnvironmentalTest {

    @Test
    fun testBestiaryEntriesIntegrity() {
        val entries = BestiaryManager.ENTRIES
        assertEquals(7, entries.size, "Bestiarium harus memuat 7 entitas kanonikal Menara Aethel")

        val expectedIds = listOf(
            "CRIMSON_GRUNT",
            "OBSIDIAN_KNIGHT",
            "AMETHYST_SNIPER",
            "SHADOW_PHANTOM",
            "BOSS_OAKHAVEN",
            "BOSS_MATRON",
            "BOSS_CALLIGRAPHER"
        )

        val actualIds = entries.map { it.id }
        assertEquals(expectedIds, actualIds, "ID monster pada Bestiarium harus sesuai dengan urutan kanonikal")

        for (entry in entries) {
            assertTrue(entry.name.isNotBlank(), "Nama entitas tidak boleh kosong: ${entry.id}")
            assertTrue(entry.title.isNotBlank(), "Gelar entitas tidak boleh kosong: ${entry.id}")
            assertTrue(entry.threatZone.isNotBlank(), "Zona ancaman tidak boleh kosong: ${entry.id}")
            assertTrue(entry.lore.isNotBlank(), "Catatan historis Aurelius tidak boleh kosong: ${entry.id}")
            assertTrue(entry.tactics.isNotBlank(), "Doktrin tempur Valerius tidak boleh kosong: ${entry.id}")
            assertTrue(entry.weakness.isNotBlank(), "Kelemahan taktis tidak boleh kosong: ${entry.id}")
            assertTrue(entry.colorHex.startsWith("#"), "Warna heksadesimal harus diawali #: ${entry.id}")
            assertEquals(7, entry.colorHex.length, "Format warna heksadesimal harus #RRGGBB: ${entry.id}")
        }
    }

    @Test
    fun testBestiaryGetById() {
        val grunt = BestiaryManager.getById("CRIMSON_GRUNT")
        assertNotNull(grunt)
        assertEquals("Crimson Grunt", grunt.name)

        val calligrapher = BestiaryManager.getById("BOSS_CALLIGRAPHER")
        assertNotNull(calligrapher)
        assertEquals("The Grand Calligrapher", calligrapher.name)

        // Case-insensitive lookup test
        val matron = BestiaryManager.getById("boss_matron")
        assertNotNull(matron)
        assertEquals("The Amethyst Matron", matron.name)

        val unknown = BestiaryManager.getById("non_existent_entity")
        assertEquals(null, unknown)
    }

    @Test
    fun testBestiaryKillTrackingAndSavePersistence() {
        val saveData = SaveData()
        val initialChecksum = saveData.calculateChecksum()

        // Verifikasi awal 0 kill
        assertEquals(0, BestiaryManager.getKillCount("CRIMSON_GRUNT", saveData))
        assertEquals(0, BestiaryManager.getKillCount("BOSS_CALLIGRAPHER", saveData))

        // Catat kill crimson_grunt
        BestiaryManager.recordKill("CRIMSON_GRUNT", saveData)
        BestiaryManager.recordKill("CRIMSON_GRUNT", saveData)
        BestiaryManager.recordKill("CRIMSON_GRUNT", saveData)
        assertEquals(3, BestiaryManager.getKillCount("CRIMSON_GRUNT", saveData))
        assertEquals(3, BestiaryManager.getKills(saveData, "CRIMSON_GRUNT"))

        // Catat kill boss
        BestiaryManager.recordKill("BOSS_CALLIGRAPHER", saveData)
        assertEquals(1, BestiaryManager.getKillCount("BOSS_CALLIGRAPHER", saveData))

        // Checksum harus berubah karena kill disimpan dalam SaveData
        val modifiedChecksum = saveData.calculateChecksum()
        assertFalse(initialChecksum == modifiedChecksum, "Checksum SaveData harus memperhitungkan bestiaryKills")

        // Catat ID tidak valid tidak boleh throw exception
        BestiaryManager.recordKill("", saveData)
        BestiaryManager.recordKill("unknown_entity", saveData)
        assertEquals(1, BestiaryManager.getKillCount("unknown_entity", saveData))
    }

    @Test
    fun testEnvironmentalPropsGenerationAcrossFloors() {
        // Lantai 1..10 harus memiliki prop lingkungan sesuai babak (Act)
        for (floor in 1..10) {
            val props = TowerLevelBuilder.getEnvironmentalPropsForFloor(floor)
            assertTrue(props.isNotEmpty(), "Lantai $floor harus memiliki environmental props bercerita")

            for (prop in props) {
                assertTrue(prop.x > 0f, "Posisi X prop harus berada di dalam batas lantai: $prop")
                assertTrue(prop.y >= 0f, "Posisi Y prop tidak boleh negatif: $prop")
                assertTrue(prop.type.displayName.isNotBlank(), "Nama prop tidak boleh kosong: $prop")
            }
        }

        // Cek spesifik Act 1 (Lantai 1-3)
        val act1Props = TowerLevelBuilder.getEnvironmentalPropsForFloor(1)
        assertTrue(act1Props.any { it.type.actBelonging == 1 })

        // Cek spesifik Act 2 (Lantai 4-6)
        val act2Props = TowerLevelBuilder.getEnvironmentalPropsForFloor(5)
        assertTrue(act2Props.any { it.type.actBelonging == 2 })

        // Cek spesifik Act 3 / Act 4 (Lantai 7-10)
        val act3Props = TowerLevelBuilder.getEnvironmentalPropsForFloor(10)
        assertTrue(act3Props.any { it.type.actBelonging >= 3 })
    }

    @Test
    fun testEnvironmentalPropUpdateAndAnimation() {
        for (type in PropType.values()) {
            val prop = EnvironmentalProp(
                x = 10f,
                y = 1f,
                width = 1.5f,
                height = 2f,
                type = type
            )

            val initialAnim = prop.animTime
            prop.update(0.25f)
            assertEquals(initialAnim + 0.25f, prop.animTime, 0.001f)
        }
    }

    @Test
    fun testTowerFloorIntegrationWithProps() {
        val emptyFloor = TowerFloor(floorNumber = 1)
        assertTrue(emptyFloor.environmentalProps.isEmpty())

        val builtFloor = TowerLevelBuilder.buildFloor(1)
        assertTrue(builtFloor.environmentalProps.isNotEmpty(), "Floor 1 hasil buildFloor harus memiliki props")

        val endlessFloor = TowerLevelBuilder.buildEndlessFloor(15, FloorMutator.NONE)
        assertTrue(endlessFloor.environmentalProps.isNotEmpty(), "Endless Floor 15 harus memiliki props lingkungan")
    }
}
