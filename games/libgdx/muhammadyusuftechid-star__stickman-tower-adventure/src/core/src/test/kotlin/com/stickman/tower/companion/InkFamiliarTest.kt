package com.stickman.tower.companion

import com.badlogic.gdx.graphics.Color
import com.stickman.tower.character.Player
import com.stickman.tower.combat.FloatingText
import com.stickman.tower.enemy.BossEnemy
import com.stickman.tower.enemy.BossType
import com.stickman.tower.enemy.Enemy
import com.stickman.tower.enemy.EnemyType
import com.stickman.tower.rpg.CharacterStats
import com.stickman.tower.rpg.SaveData
import com.stickman.tower.vfx.ParticleManager
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Unit Test Komprehensif untuk Sistem Pendamping Roh Tinta (Ink Familiar Companion) - Fase 21.
 */
class InkFamiliarTest {

    @Test
    fun testFamiliarTypeDefinitions() {
        val types = FamiliarType.values()
        assertEquals(4, types.size, "Harus terdapat 4 entitas tipe roh pendamping tinta kanonikal")

        val expectedIds = listOf("NONE", "ARIA_WISP", "VULCAN_SPARK", "PHANTOM_SHADOW")
        val actualIds = types.map { it.id }
        assertEquals(expectedIds, actualIds, "ID tipe roh pendamping harus sesuai urutan")

        for (t in types) {
            assertTrue(t.displayName.isNotBlank(), "Display name tidak boleh kosong untuk: ${t.id}")
            assertTrue(t.subtitle.isNotBlank(), "Subtitle tidak boleh kosong untuk: ${t.id}")
            assertTrue(t.lore.isNotBlank(), "Lore tidak boleh kosong untuk: ${t.id}")
            assertTrue(t.unlockFloor >= 1, "Unlock floor harus minimal 1 untuk: ${t.id}")
            assertNotNull(t.primaryColor, "Primary color tidak boleh null untuk: ${t.id}")
            assertNotNull(t.secondaryColor, "Secondary color tidak boleh null untuk: ${t.id}")
        }
    }

    @Test
    fun testFamiliarTypeFromStringRobustness() {
        assertEquals(FamiliarType.ARIA_WISP, FamiliarType.fromString("ARIA_WISP"))
        assertEquals(FamiliarType.ARIA_WISP, FamiliarType.fromString("aria_wisp"))
        assertEquals(FamiliarType.VULCAN_SPARK, FamiliarType.fromString("VULCAN_SPARK"))
        assertEquals(FamiliarType.PHANTOM_SHADOW, FamiliarType.fromString("phantom_shadow"))
        assertEquals(FamiliarType.NONE, FamiliarType.fromString("NONE"))

        // Fallbacks aman
        assertEquals(FamiliarType.ARIA_WISP, FamiliarType.fromString(null))
        assertEquals(FamiliarType.ARIA_WISP, FamiliarType.fromString(""))
        assertEquals(FamiliarType.ARIA_WISP, FamiliarType.fromString("UNKNOWN_SPIRIT_RANDOM"))
    }

    @Test
    fun testFamiliarFollowKinematics() {
        val familiar = InkFamiliar(FamiliarType.ARIA_WISP)
        familiar.resetPosition(10f, 5f)

        assertEquals(10f, familiar.x)
        assertEquals(6.2f, familiar.y)
        assertEquals(0, familiar.projectiles.size)

        val stats = CharacterStats()
        val player = Player(spawnX = 15f, spawnY = 5f, stats = stats)
        val particleManager = ParticleManager()
        val floatingTexts = mutableListOf<FloatingText>()

        // Update delta
        familiar.update(
            delta = 0.5f,
            player = player,
            enemies = emptyList(),
            boss = null,
            particleManager = particleManager,
            floatingTexts = floatingTexts
        )

        // Posisi familiar harus bergerak mendekati bahu ksatria
        assertTrue(familiar.x > 10f, "Familiar harus bergerak mendekati pemain ke arah kanan")
    }

    @Test
    fun testFamiliarProjectileLifecycle() {
        val proj = FamiliarProjectile(
            x = 0f,
            y = 0f,
            vx = 10f,
            vy = 0f,
            damage = 20f,
            color = Color.CYAN,
            lifetime = 0.5f
        )

        assertFalse(proj.isDestroyed)
        proj.update(0.2f)
        assertEquals(2.0f, proj.x, 0.001f)
        assertFalse(proj.isDestroyed)

        proj.update(0.35f)
        assertTrue(proj.isDestroyed, "Proyektil harus hancur setelah masa pakai lifetime terlampaui")
    }

    @Test
    fun testSaveDataPersistenceAndIntegrity() {
        val save = SaveData()
        assertEquals("ARIA_WISP", save.selectedFamiliar)
        assertTrue(save.unlockedFamiliars.contains("ARIA_WISP"))

        val initialChecksum = save.calculateChecksum()
        assertTrue(initialChecksum > 0L)

        // Buka familiar baru dan verifikasi perubahan checksum FNV-1a
        save.unlockedFamiliars.add("VULCAN_SPARK")
        val withVulcanChecksum = save.calculateChecksum()
        assertNotEquals(initialChecksum, withVulcanChecksum, "Checksum harus berubah saat koleksi familiar bertambah")

        save.selectedFamiliar = "VULCAN_SPARK"
        val withSelectedChecksum = save.calculateChecksum()
        assertNotEquals(withVulcanChecksum, withSelectedChecksum, "Checksum harus berubah saat selectedFamiliar berubah")

        // Uji sanitasi
        val corruptedSave = SaveData(
            selectedFamiliar = "  ",
            unlockedFamiliars = arrayListOf()
        ).sanitize()

        assertEquals("ARIA_WISP", corruptedSave.selectedFamiliar, "Selected familiar yang blank harus disanitasi ke ARIA_WISP")
        assertTrue(corruptedSave.unlockedFamiliars.contains("ARIA_WISP"), "Unlocked familiars yang kosong harus otomatis menyertakan ARIA_WISP")
    }

    @Test
    fun testCombatProcSynergies() {
        val noneFamiliar = InkFamiliar(FamiliarType.NONE)
        val particleManager = ParticleManager()
        val floatingTexts = mutableListOf<FloatingText>()

        val enemy = Enemy(
            spawnX = 5f,
            spawnY = 2f,
            type = EnemyType.MELEE
        )

        val initialHp = enemy.health.currentHp

        // NONE Familiar tidak memicu apa pun pada attack hit atau parry
        noneFamiliar.onAttackHitProc(enemy, particleManager, floatingTexts)
        assertEquals(initialHp, enemy.health.currentHp)

        noneFamiliar.onParryProc(
            targetX = 5f,
            targetY = 2f,
            enemies = listOf(enemy),
            boss = null,
            particleManager = particleManager,
            floatingTexts = floatingTexts
        )
        assertEquals(initialHp, enemy.health.currentHp)
        assertTrue(floatingTexts.isEmpty())

        // PHANTOM_SHADOW pada Perfect Parry
        val phantomFamiliar = InkFamiliar(FamiliarType.PHANTOM_SHADOW)
        phantomFamiliar.onParryProc(
            targetX = 5f,
            targetY = 2f,
            enemies = listOf(enemy),
            boss = null,
            particleManager = particleManager,
            floatingTexts = floatingTexts
        )

        assertTrue(enemy.health.currentHp < initialHp, "Phantom Shadow harus memberikan kerusakan Echo Slash saat Perfect Parry")
        assertTrue(floatingTexts.any { it.text.contains("ECHO SLASH") }, "Harus memunculkan floating text Echo Slash")
    }

    @Test
    fun testBossEncounterSynergies() {
        val vulcanFamiliar = InkFamiliar(FamiliarType.VULCAN_SPARK)
        val particleManager = ParticleManager()
        val floatingTexts = mutableListOf<FloatingText>()

        val boss = BossEnemy(
            spawnX = 10f,
            spawnY = 2f,
            type = BossType.TOWER_GUARDIAN
        )

        val bossInitialHp = boss.health.currentHp

        // Lakukan beberapa hit untuk menguji burn proc probabilitas
        for (i in 0 until 10) {
            vulcanFamiliar.onAttackHitBossProc(boss, particleManager, floatingTexts)
        }

        // Jika proc terpicu, floating text "BARA PENEMPA" tercatat
        if (boss.health.currentHp < bossInitialHp) {
            assertTrue(floatingTexts.any { it.text.contains("BARA PENEMPA") })
        }
    }
}
