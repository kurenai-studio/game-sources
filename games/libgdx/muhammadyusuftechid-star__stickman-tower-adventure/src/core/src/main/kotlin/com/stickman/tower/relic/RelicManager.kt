package com.stickman.tower.relic

import com.badlogic.gdx.graphics.Color
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.audio.HapticManager
import com.stickman.tower.character.Player
import com.stickman.tower.combat.FloatingText
import com.stickman.tower.enemy.BossEnemy
import com.stickman.tower.enemy.Enemy
import com.stickman.tower.vfx.ParticleManager
import kotlin.math.hypot

/**
 * Pengelola Relik Pasif Aktif Pemain (Fase 10):
 * Mengontrol perolehan relik, efek passive runtime (Vampirism, Thunderstrike, Triple Jump, Chrono Haste),
 * serta visualisasi ikon relic pada antarmuka.
 */
class RelicManager {

    val activeRelics = mutableSetOf<RelicType>()

    fun has(type: RelicType): Boolean = activeRelics.contains(type)

    fun add(type: RelicType): Boolean {
        val added = activeRelics.add(type)
        if (added) {
            AudioManager.playLevelUp()
            HapticManager.vibrateHeavy()
        }
        return added
    }

    fun clear() {
        activeRelics.clear()
    }

    /**
     * Efek saat musuh atau minion ditumbangkan:
     * - Vampiric Fang: Memulihkan 5% Max HP pemain.
     */
    fun onEnemyDefeated(
        player: Player,
        floatingTexts: MutableList<FloatingText>,
        particleManager: ParticleManager
    ) {
        if (has(RelicType.VAMPIRIC_FANG) && !player.health.isDead) {
            val healAmount = player.health.maxHp * 0.05f
            player.health.heal(healAmount)
            AudioManager.playChest()
            HapticManager.vibrateLight()

            val px = player.position.x + player.width / 2f
            val py = player.position.y + player.height / 2f
            particleManager.spawnHitSparks(px, py, count = 8, color = Color.GREEN)
            floatingTexts.add(
                FloatingText(
                    text = "+${healAmount.toInt()} HP",
                    worldX = px,
                    worldY = player.position.y + player.height + 0.35f,
                    color = Color.GREEN,
                    duration = 1.0f
                )
            )
        }
    }

    /**
     * Efek saat pukulan kombo mendarat pada musuh:
     * - Thunder Charm: Menyambar musuh terdekat dengan petir 30 DMG setiap kombo kelipatan 10x.
     */
    fun onComboHit(
        comboCount: Int,
        player: Player,
        enemies: List<Enemy>,
        boss: BossEnemy?,
        floatingTexts: MutableList<FloatingText>,
        particleManager: ParticleManager
    ) {
        if (!has(RelicType.THUNDER_CHARM) || comboCount <= 0 || comboCount % 10 != 0) return

        val px = player.position.x + player.width / 2f
        val py = player.position.y + player.height / 2f

        // Cari target hidup terdekat dalam radius 8 meter
        var nearestEnemy: Enemy? = null
        var nearestDist = 8.0f

        for (e in enemies) {
            if (!e.health.isDead) {
                val ex = e.position.x + e.width / 2f
                val ey = e.position.y + e.height / 2f
                val d = hypot(ex - px, ey - py)
                if (d < nearestDist) {
                    nearestDist = d
                    nearestEnemy = e
                }
            }
        }

        if (nearestEnemy != null) {
            val ex = nearestEnemy.position.x + nearestEnemy.width / 2f
            val ey = nearestEnemy.position.y + nearestEnemy.height / 2f
            nearestEnemy.takeHit(damage = 30f, knockX = 0f, knockY = 4f)

            AudioManager.playSlashHeavy()
            HapticManager.vibrateHeavy()
            particleManager.spawnHitSparks(ex, ey, count = 15, color = Color.YELLOW)
            floatingTexts.add(
                FloatingText(
                    text = "⚡ THUNDER! -30",
                    worldX = ex,
                    worldY = ey + 1.2f,
                    color = Color(1f, 0.9f, 0.2f, 1f),
                    duration = 1.4f
                )
            )
            return
        }

        // Jika tidak ada musuh biasa, sambar Bos jika aktif
        if (boss != null && !boss.health.isDead) {
            val bx = boss.position.x + boss.width / 2f
            val by = boss.position.y + boss.height / 2f
            boss.takeHit(30f, 0f, 2f)

            AudioManager.playSlashHeavy()
            HapticManager.vibrateHeavy()
            particleManager.spawnHitSparks(bx, by, count = 20, color = Color.YELLOW)
            floatingTexts.add(
                FloatingText(
                    text = "⚡ THUNDER! -30",
                    worldX = bx,
                    worldY = by + 2.0f,
                    color = Color(1f, 0.9f, 0.2f, 1f),
                    duration = 1.4f
                )
            )
        }
    }

    /**
     * Multiplier cooldown skill & dash:
     * - Chronos Hourglass memberikan reduksi 25% (multiplier 0.75f).
     */
    fun getCooldownMultiplier(): Float {
        return if (has(RelicType.CHRONOS_HOURGLASS)) 0.75f else 1.0f
    }

    /**
     * Jumlah lompatan di udara:
     * - Wings of Hermes memberikan Triple Jump (2 air jumps). Default: Double Jump (1 air jump).
     */
    fun getMaxAirJumps(): Int {
        return if (has(RelicType.WINGS_OF_HERMES)) 2 else 1
    }
}
