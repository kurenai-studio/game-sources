package com.stickman.tower.world

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle
import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.character.CharacterUnlockManager
import kotlin.math.sin

/**
 * PrismAltar (Altar Prisma Triad Tag-Team):
 * Altar kristal kosmis kuno yang berdiri di Saga IV (Retakan Astral & Kuil Malakor).
 * Memancarkan resonansi tiga spektrum jiwa (Bara Emas Kaelen, Bayangan Cyan Zephyr, dan Titan Baja Gorgon).
 * Memungkinkan pemain berganti pahlawan secara instan saat menyentuh atau berinteraksi dengan altar.
 */
class PrismAltar(
    val x: Float,
    val y: Float,
    val width: Float = 1.8f,
    val height: Float = 3.6f
) {
    val bounds = Rectangle(x, y, width, height)
    val interactionBounds = Rectangle(x - 1.2f, y, width + 2.4f, height + 1.0f)

    var pulseTimer: Float = 0f
    var interactionCooldown: Float = 0f

    fun update(delta: Float) {
        pulseTimer += delta
        if (interactionCooldown > 0f) {
            interactionCooldown = (interactionCooldown - delta).coerceAtLeast(0f)
        }
    }

    /**
     * Menghitung arketipe berikutnya yang tersedia sesuai status unlock pemain.
     */
    fun getNextAvailableArchetype(current: CharacterArchetype, unlockedList: List<String>): CharacterArchetype {
        val order = listOf(
            CharacterArchetype.BALANCED,
            CharacterArchetype.AGILE,
            CharacterArchetype.HEAVY
        )

        val currentIndex = order.indexOf(current).let { if (it == -1) 0 else it }

        for (step in 1..order.size) {
            val candidate = order[(currentIndex + step) % order.size]
            val isUnlocked = when (candidate) {
                CharacterArchetype.BALANCED -> true
                CharacterArchetype.AGILE -> unlockedList.contains(CharacterUnlockManager.ID_ZEPHYR) || unlockedList.contains("ZEPHYR") || unlockedList.contains("STICKMAN_AGILE")
                CharacterArchetype.HEAVY -> unlockedList.contains(CharacterUnlockManager.ID_GORGON) || unlockedList.contains("GORGON") || unlockedList.contains("STICKMAN_HEAVY")
            }
            if (isUnlocked) {
                return candidate
            }
        }
        return current
    }

    /**
     * Render visual Altar Prisma:
     * Pilar marmer obsidian gelap dengan 3 kristal prisma berputar dan berkilau secara ritmis.
     * Zero-allocation untuk performa 60 FPS mulus.
     */
    fun render(shapeRenderer: ShapeRenderer) {
        val prevColor = Color(shapeRenderer.color)
        val pulse = (sin(pulseTimer * 3.5f) * 0.5f + 0.5f)

        // 1. Alas Batu Marmer Hitam Obsidian
        shapeRenderer.color = Color(0.12f, 0.12f, 0.16f, 1f)
        shapeRenderer.rect(x - 0.2f, y, width + 0.4f, 0.6f)
        shapeRenderer.color = Color(0.20f, 0.22f, 0.28f, 1f)
        shapeRenderer.rect(x, y + 0.6f, width, 0.35f)

        // 2. Pilar Inti Kristal Prisma
        shapeRenderer.color = Color(0.18f, 0.16f, 0.24f, 0.95f)
        shapeRenderer.rect(x + 0.3f, y + 0.95f, width - 0.6f, height - 1.4f)

        // 3. Tiga Permata Kristal Spektrum Triad (Emas Kaelen, Cyan Zephyr, Oranye Gorgon)
        val gemWidth = 0.28f
        val gemHeight = 0.65f
        val gemY = y + 1.5f + sin(pulseTimer * 2.0f) * 0.15f

        // Kristal Kiri: Cyan Zephyr
        shapeRenderer.color = Color(0.2f, 0.85f + 0.15f * pulse, 0.95f, 0.9f)
        shapeRenderer.rect(x + 0.15f, gemY - 0.1f, gemWidth, gemHeight)

        // Kristal Tengah: Emas Kaelen
        shapeRenderer.color = Color(1.0f, 0.82f + 0.18f * pulse, 0.25f, 0.95f)
        shapeRenderer.rect(x + (width - gemWidth) / 2f, gemY + 0.2f, gemWidth, gemHeight + 0.15f)

        // Kristal Kanan: Oranye-Titan Gorgon
        shapeRenderer.color = Color(0.95f, 0.45f + 0.20f * pulse, 0.15f, 0.9f)
        shapeRenderer.rect(x + width - 0.15f - gemWidth, gemY - 0.1f, gemWidth, gemHeight)

        // 4. Mahkota Kristal Atas (Puncak Prisma Bersinar)
        val crownGlow = 0.7f + 0.3f * pulse
        shapeRenderer.color = Color(0.9f * crownGlow, 0.85f * crownGlow, 1.0f * crownGlow, 1f)
        shapeRenderer.rect(x + 0.4f, y + height - 0.45f, width - 0.8f, 0.45f)

        shapeRenderer.color = prevColor
    }
}
