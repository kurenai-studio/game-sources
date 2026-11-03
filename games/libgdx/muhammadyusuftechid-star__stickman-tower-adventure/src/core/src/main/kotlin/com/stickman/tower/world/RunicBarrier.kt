package com.stickman.tower.world

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle
import kotlin.math.sin

/**
 * RunicBarrier:
 * Pintu gerbang energi vertikal yang memblokir jalur pemain hingga RunicKey terkait ditemukan.
 * Menampilkan pilar penopang obsidian hitam dengan dinding energi berdenyut merah/ungu runik.
 */
class RunicBarrier(
    val x: Float,
    val y: Float,
    val width: Float = 0.8f,
    val height: Float = 5.5f,
    val barrierId: String,
    var isUnlocked: Boolean = false
) {
    val bounds = Rectangle(x, y, width, height)
    private var animTime = 0f

    fun unlock() {
        isUnlocked = true
    }

    fun update(delta: Float) {
        animTime += delta
    }

    fun render(shapeRenderer: ShapeRenderer) {
        if (isUnlocked) return

        val pulse = (sin(animTime * 6f) + 1f) * 0.5f

        // 1. Pilar Penopang Atas & Bawah
        shapeRenderer.setColor(0.12f, 0.08f, 0.16f, 0.95f)
        shapeRenderer.rect(x - 0.2f, y, width + 0.4f, 0.4f)
        shapeRenderer.rect(x - 0.2f, y + height - 0.4f, width + 0.4f, 0.4f)

        // 2. Dinding Energi Runik Berdenyut (Crimson / Violet Glow)
        shapeRenderer.setColor(0.9f, 0.15f + 0.15f * pulse, 0.25f + 0.25f * pulse, 0.70f + 0.25f * pulse)
        shapeRenderer.rect(x, y + 0.4f, width, height - 0.8f)

        // 3. Garis-garis Rune Inti yang Bersilang
        shapeRenderer.setColor(1f, 0.85f, 0.4f, 0.85f)
        shapeRenderer.rectLine(x + width / 2f, y + 0.4f, x + width / 2f, y + height - 0.4f, 0.08f)

        // Simbol Runic di Tengah
        val midY = y + height / 2f
        val runeSize = 0.4f + 0.05f * pulse
        shapeRenderer.circle(x + width / 2f, midY, runeSize, 12)
        shapeRenderer.setColor(0.15f, 0.05f, 0.08f, 0.95f)
        shapeRenderer.circle(x + width / 2f, midY, runeSize * 0.55f, 8)
    }
}

/**
 * RunicKey:
 * Kunci kristal runik yang melayang dan berputar di udara.
 * Membuka RunicBarrier dengan ID yang cocok saat disentuh pemain.
 */
class RunicKey(
    val x: Float,
    val y: Float,
    val targetBarrierId: String,
    var isCollected: Boolean = false
) {
    val bounds = Rectangle(x - 0.35f, y - 0.35f, 0.7f, 0.7f)
    private var animTime = 0f

    fun update(delta: Float) {
        animTime += delta
    }

    fun render(shapeRenderer: ShapeRenderer) {
        if (isCollected) return

        val floatY = y + sin(animTime * 4f) * 0.15f
        val pulse = (sin(animTime * 5f) + 1f) * 0.5f

        // Pendaran Aura Luar
        shapeRenderer.setColor(1f, 0.2f, 0.3f, 0.35f + 0.2f * pulse)
        shapeRenderer.circle(x, floatY, 0.55f, 16)

        // Inti Kristal Berlian Merah Emas
        shapeRenderer.setColor(1f, 0.85f, 0.25f, 0.95f)
        shapeRenderer.triangle(
            x, floatY + 0.35f,
            x - 0.25f, floatY,
            x + 0.25f, floatY
        )
        shapeRenderer.setColor(0.95f, 0.25f, 0.25f, 0.95f)
        shapeRenderer.triangle(
            x - 0.25f, floatY,
            x + 0.25f, floatY,
            x, floatY - 0.35f
        )
    }
}

/**
 * ZephyrCocoon:
 * Kepompong sutra kristal ungu raksasa di Sarang Lady Vespera (Lantai 10).
 * Menyandera Zephyr di ketinggian. Kaelen harus menyerangnya dengan 3 tebasan pedang
 * untuk membebaskan Zephyr dan memicu pertarungan Co-op Tag-Team.
 */
class ZephyrCocoon(
    val x: Float,
    val y: Float,
    val width: Float = 1.6f,
    val height: Float = 2.8f,
    var hitPoints: Int = 3,
    var isBroken: Boolean = false
) {
    val bounds = Rectangle(x, y, width, height)
    private var animTime = 0f
    private var hurtTimer = 0f

    val hitsRemaining: Int get() = hitPoints.coerceAtLeast(0)
    val hitsTaken: Int get() = (3 - hitPoints).coerceIn(0, 3)

    fun update(delta: Float) {
        animTime += delta
        if (hurtTimer > 0f) hurtTimer -= delta
    }

    fun takeHit(): Boolean {
        if (isBroken) return false
        hitPoints--
        hurtTimer = 0.25f
        if (hitPoints <= 0) {
            isBroken = true
            return true // Pecah
        }
        return false
    }

    fun render(shapeRenderer: ShapeRenderer) {
        if (isBroken) return

        val sway = sin(animTime * 3f) * 0.08f
        val cx = x + width / 2f + sway
        val cy = y + height / 2f

        // 1. Tali Sutra Kristal Menggantung dari Langit-Langit
        shapeRenderer.setColor(0.6f, 0.4f, 0.85f, 0.85f)
        shapeRenderer.rectLine(cx, y + height, cx - sway * 2f, y + height + 3.5f, 0.08f)

        // 2. Pendaran Aura Sutra Amethyst Beracun
        val isHurt = hurtTimer > 0f
        if (isHurt) {
            shapeRenderer.setColor(1f, 1f, 1f, 0.9f)
        } else {
            shapeRenderer.setColor(0.55f, 0.2f, 0.85f, 0.45f)
        }
        shapeRenderer.circle(cx, cy, width * 0.85f, 20)

        // 3. Badan Kepompong Oval Kristal
        shapeRenderer.setColor(0.20f, 0.08f, 0.32f, 0.95f)
        shapeRenderer.circle(cx, cy + 0.4f, width * 0.55f, 16)
        shapeRenderer.circle(cx, cy - 0.3f, width * 0.48f, 16)

        // 4. Anyaman Sutra Kristal Berpendar
        shapeRenderer.setColor(0.85f, 0.45f, 1f, 0.85f)
        shapeRenderer.rectLine(cx - 0.5f, cy + 0.5f, cx + 0.5f, cy - 0.4f, 0.06f)
        shapeRenderer.rectLine(cx + 0.5f, cy + 0.5f, cx - 0.5f, cy - 0.4f, 0.06f)
        shapeRenderer.rectLine(cx - 0.6f, cy, cx + 0.6f, cy, 0.06f)

        // 5. Siluet Bayangan Zephyr di Dalam Kepompong
        shapeRenderer.setColor(0.1f, 0.95f, 0.85f, 0.65f)
        shapeRenderer.circle(cx, cy + 0.35f, 0.22f, 8) // Kepala Zephyr bercahaya cyan
    }
}
