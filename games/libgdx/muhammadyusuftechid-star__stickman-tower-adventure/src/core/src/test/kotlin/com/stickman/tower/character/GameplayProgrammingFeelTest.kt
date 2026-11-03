package com.stickman.tower.character

import com.stickman.tower.combat.AttackPhase
import com.stickman.tower.combat.ComboStep
import com.stickman.tower.input.GameInput
import com.stickman.tower.physics.Platform
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Senior Gameplay Programmer Unit Test Suite:
 * Memvalidasi Platforming Feel (Jump Curve, Short-hop, Apex Float, Fast-fall),
 * One-Way Platform Drop-through, serta Attack Recovery Jump-Cancel.
 */
class GameplayProgrammingFeelTest {

    private class TestInput(
        private val moveLeft: Boolean = false,
        private val moveRight: Boolean = false,
        private val moveDown: Boolean = false,
        private val jumpJustPressed: Boolean = false,
        private val jumpPressed: Boolean = false,
        private val attackJustPressed: Boolean = false,
        private val dodgeJustPressed: Boolean = false
    ) : GameInput {
        override fun isMoveLeft(): Boolean = moveLeft
        override fun isMoveRight(): Boolean = moveRight
        override fun isMoveDown(): Boolean = moveDown
        override fun isJumpJustPressed(): Boolean = jumpJustPressed
        override fun isJumpPressed(): Boolean = jumpPressed
        override fun isAttackJustPressed(): Boolean = attackJustPressed
        override fun isDodgeJustPressed(): Boolean = dodgeJustPressed
        override fun isSkillJustPressed(): Boolean = false
        override fun isUltimateJustPressed(): Boolean = false
    }

    private val solidFloor = listOf(Platform(x = -10f, y = 0f, width = 30f, height = 1f))
    private val oneWayFloor = listOf(Platform(x = 0f, y = 3f, width = 6f, height = 0.4f, isOneWay = true))

    @Test
    fun testShortHopJumpCutVersusFullJump() {
        val playerShort = Player(spawnX = 2f, spawnY = 1.0f)
        val playerFull = Player(spawnX = 2f, spawnY = 1.0f)

        // 1. Inisialisasi grounded
        playerShort.update(0.016f, TestInput(), solidFloor)
        playerFull.update(0.016f, TestInput(), solidFloor)
        assertTrue(playerShort.isGrounded)
        assertTrue(playerFull.isGrounded)

        // 2. Trigger Jump di frame pertama
        val jumpTrigger = TestInput(jumpJustPressed = true, jumpPressed = true)
        playerShort.update(0.016f, jumpTrigger, solidFloor)
        playerFull.update(0.016f, jumpTrigger, solidFloor)

        // 3. Frame berikutnya: PlayerShort melepas tombol lompat (jumpPressed = false), PlayerFull tetap menahan
        val shortHopInput = TestInput(jumpPressed = false)
        val fullJumpInput = TestInput(jumpPressed = true)

        for (i in 0 until 12) {
            playerShort.update(0.016f, shortHopInput, solidFloor)
            playerFull.update(0.016f, fullJumpInput, solidFloor)
        }

        // Kecepatan ke atas PlayerShort harus terpotong secara tajam (snappy short-hop)
        assertTrue(
            playerFull.velocity.y > playerShort.velocity.y,
            "Full jump harus mempertahankan velocity ke atas lebih tinggi daripada short hop cut!"
        )
        assertTrue(
            playerFull.position.y > playerShort.position.y,
            "Full jump harus mencapai ketinggian lebih tinggi daripada short hop!"
        )
    }

    @Test
    fun testFastFallingMechanic() {
        val playerNormal = Player(spawnX = 2f, spawnY = 8.0f)
        val playerFastFall = Player(spawnX = 2f, spawnY = 8.0f)

        // Buat keduanya sedang jatuh bebas di udara
        playerNormal.velocity.y = -5.0f
        playerFastFall.velocity.y = -5.0f

        val normalFallInput = TestInput()
        val fastFallInput = TestInput(moveDown = true)

        for (i in 0 until 10) {
            playerNormal.update(0.016f, normalFallInput, emptyList())
            playerFastFall.update(0.016f, fastFallInput, emptyList())
        }

        assertTrue(
            playerFastFall.velocity.y < playerNormal.velocity.y,
            "Menahan tombol bawah di udara harus memicu fast-fall yang jatuh lebih cepat!"
        )
        assertTrue(
            playerFastFall.position.y < playerNormal.position.y,
            "Karakter fast fall harus berada pada elevasi lebih rendah!"
        )
    }

    @Test
    fun testOneWayPlatformDropThrough() {
        val platforms = listOf(
            Platform(x = -5f, y = 0f, width = 20f, height = 1f), // Lantai dasar solid
            Platform(x = 0f, y = 3f, width = 6f, height = 0.4f, isOneWay = true) // One-way di y = 3
        )
        val player = Player(spawnX = 2f, spawnY = 3.5f)

        // Biarkan mendarat di atas one-way platform
        for (i in 0 until 10) {
            player.update(0.016f, TestInput(), platforms)
        }
        assertTrue(player.isGrounded, "Pemain harus mendarat di atas one-way platform")
        assertEquals(3.4f, player.position.y, 0.05f, "Posisi Y harus bertumpu di top platform one-way (3.0 + 0.4)")

        // Tekan Down + Jump untuk Drop-through
        val dropThroughInput = TestInput(moveDown = true, jumpJustPressed = true)
        player.update(0.016f, dropThroughInput, platforms)

        assertTrue(player.ignoreOneWayTimer > 0f, "ignoreOneWayTimer harus aktif setelah Down + Jump")
        assertFalse(player.isGrounded, "Pemain tidak lagi grounded saat drop-through")
        assertTrue(player.velocity.y < 0f, "Velocity Y harus mengarah ke bawah")

        // Perbarui beberapa frame berikutnya untuk menembus platform
        for (i in 0 until 10) {
            player.update(0.016f, TestInput(), platforms)
        }

        assertTrue(
            player.position.y < 3.0f,
            "Pemain harus berhasil menembus ke bawah platform one-way!"
        )
    }

    @Test
    fun testRecoveryJumpCancel() {
        val player = Player(spawnX = 2f, spawnY = 1.0f)
        player.update(0.016f, TestInput(), solidFloor)
        assertTrue(player.isGrounded)

        // Pemicu Attack Hit 1
        player.update(0.016f, TestInput(attackJustPressed = true), solidFloor)
        assertEquals(AttackPhase.STARTUP, player.attackPhase)

        // Lewati frame startup (0.08s) dan active (0.10s) menuju RECOVERY (total > 0.18s)
        player.update(0.20f, TestInput(), solidFloor)
        assertEquals(AttackPhase.RECOVERY, player.attackPhase, "Pemain harus berada di fase RECOVERY serangan")

        // Tekan Jump saat masih di fase RECOVERY
        val jumpInput = TestInput(jumpJustPressed = true, jumpPressed = true)
        player.update(0.016f, jumpInput, solidFloor)

        // Recovery harus di-cancel menjadi INACTIVE dan pemain langsung melompat ke udara
        assertEquals(AttackPhase.INACTIVE, player.attackPhase, "Jump cancel harus menghentikan fase RECOVERY!")
        assertFalse(player.hitbox.isActive, "Hitbox harus non-aktif setelah jump cancel")
        assertTrue(player.velocity.y > 0f, "Pemain harus langsung memiliki velocity lompat ke atas")
    }
}
