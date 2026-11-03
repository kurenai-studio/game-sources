package com.stickman.tower.world

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.MathUtils
import com.badlogic.gdx.math.Rectangle
import com.stickman.tower.vfx.ParticleManager
import kotlin.math.sin

/**
 * Tipe Pakta Pengorbanan Anima Sementara (Temporal Pacts).
 * Memberikan buff dahsyat dengan konsekuensi handicap tertentu selama lantai aktif.
 */
enum class TemporalPact(
    val id: String,
    val displayName: String,
    val subtitle: String,
    val description: String,
    val primaryColor: Color
) {
    NONE(
        id = "NONE",
        displayName = "Tanpa Pakta",
        subtitle = "Jiwa Murni",
        description = "Tidak ada pakta pengorbanan yang terikat pada jiwa ksatria.",
        primaryColor = Color.GRAY
    ),

    CARNAGE(
        id = "CARNAGE",
        displayName = "Pakta Pembantaian",
        subtitle = "Haus Darah Mutlak",
        description = "+40% Critical Damage, namun pertahanan ksatria berkurang 15%.",
        primaryColor = Color(0.95f, 0.15f, 0.15f, 1f)
    ),

    GREED(
        id = "GREED",
        displayName = "Pakta Ketamakan",
        subtitle = "Panggilan Emas Gelap",
        description = "+60% Pecahan Aethel yang didapat, namun pergerakan musuh 20% lebih cepat.",
        primaryColor = Color(1.0f, 0.82f, 0.20f, 1f)
    ),

    SWIFTNESS(
        id = "SWIFTNESS",
        displayName = "Pakta Kecepatan Jiwa",
        subtitle = "Angin Dingin Kematian",
        description = "+35% Cooldown Reduction skill & dodge, namun Anima (HP) tidak dapat dipulihkan di lantai ini.",
        primaryColor = Color(0.35f, 0.85f, 1.0f, 1f)
    )
}

/**
 * Entitas Altar Pengorbanan Anima (Blood Altar).
 * Pilar obsidian kuno tempat pemain dapat mempersembahkan 25% Anima saat ini
 * demi mengikat salah satu dari 3 Pakta Sementara yang mengubah jalannya pertarungan.
 */
class BloodAltar(
    val x: Float,
    val y: Float
) {
    val width: Float = 1.6f
    val height: Float = 2.4f
    val bounds = Rectangle(x, y, width, height)

    var isActivated: Boolean = false
    var activePact: TemporalPact = TemporalPact.NONE
    var animTime: Float = 0f

    fun update(delta: Float, particleManager: ParticleManager) {
        animTime += delta

        // Efek partikel asap darah mengambang dari mangkuk altar
        if (animTime % 0.15f < delta) {
            val sparkColor = if (isActivated) activePact.primaryColor else Color.SCARLET
            particleManager.spawnHitSparks(
                x + width / 2f + MathUtils.random(-0.25f, 0.25f),
                y + height - 0.2f,
                count = if (isActivated) 2 else 1,
                color = sparkColor
            )
        }
    }

    fun isPlayerNear(playerX: Float, playerY: Float, playerW: Float, playerH: Float): Boolean {
        val centerX = x + width / 2f
        val centerY = y + height / 2f
        val pCenterX = playerX + playerW / 2f
        val pCenterY = playerY + playerH / 2f
        val dx = centerX - pCenterX
        val dy = centerY - pCenterY
        return (dx * dx + dy * dy) <= 6.25f // Radius interaksi 2.5 meter
    }

    fun render(shapeRenderer: ShapeRenderer) {
        // 1. Pilar Pondasi Obsidian Bawah
        shapeRenderer.setColor(0.08f, 0.05f, 0.08f, 0.95f)
        shapeRenderer.rect(x + 0.1f, y, width - 0.2f, 0.5f)

        // 2. Batang Pilar Tengah Berukir
        shapeRenderer.setColor(0.12f, 0.08f, 0.12f, 1f)
        shapeRenderer.rect(x + 0.35f, y + 0.5f, width - 0.7f, height - 1.1f)

        // Ukiran Garis Rune Merah Denyut
        val pulse = 0.5f + 0.5f * sin(animTime * 4.0f)
        val runeColor = if (isActivated) activePact.primaryColor else Color(0.9f, 0.15f, 0.2f, 0.85f * pulse)
        shapeRenderer.setColor(runeColor)
        shapeRenderer.rectLine(x + width / 2f, y + 0.65f, x + width / 2f, y + height - 0.85f, 0.05f)

        // 3. Mangkuk Sesaji Atas Altar
        shapeRenderer.setColor(0.16f, 0.10f, 0.16f, 1f)
        shapeRenderer.triangle(
            x, y + height - 0.4f,
            x + width, y + height - 0.4f,
            x + width / 2f, y + height - 0.85f
        )

        // 4. Perapian Api Anima Mengambang
        val firePulse = 0.18f + 0.04f * sin(animTime * 8.0f)
        val coreColor = if (isActivated) activePact.primaryColor else Color.FIREBRICK
        shapeRenderer.setColor(coreColor)
        shapeRenderer.circle(x + width / 2f, y + height - 0.25f, firePulse, 16)

        // Kilau Bintang Inti Api
        shapeRenderer.setColor(Color.WHITE)
        shapeRenderer.circle(x + width / 2f, y + height - 0.25f, firePulse * 0.4f, 10)
    }
}
